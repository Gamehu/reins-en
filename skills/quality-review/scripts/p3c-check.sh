#!/usr/bin/env bash
# Checks changed Java files with Alibaba P3C (p3c-pmd 2.1.1).
# P3C 2.1.1 is built on PMD 6.15.0 and is incompatible with PMD 7,
# so PMD 6.15.0 is downloaded and run on its own, independent of the project's build config.
# Usage: p3c-check.sh [file.java ...]; with no arguments, checks the changed .java files in the working tree (including untracked new files).
# Exit codes: 0 no violations and no parse gaps; 2 violations; 3 no violations but some files could not be parsed (coverage gap); 1 script or tool error.
# When both kinds of result occur, the exit code is 2, but both are listed in the output; callers should read both.

set -euo pipefail

PMD_VERSION=6.15.0
P3C_VERSION=2.1.1
KOTLIN_VERSION=1.3.72
CACHE_DIR="${P3C_HOME:-${HOME:-$PWD}/.cache/p3c-check}"
PMD_DIR="$CACHE_DIR/pmd-bin-$PMD_VERSION"
P3C_JAR="$CACHE_DIR/p3c-pmd-$P3C_VERSION.jar"
KOTLIN_JAR="$CACHE_DIR/kotlin-stdlib-$KOTLIN_VERSION.jar"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RULESET="$SCRIPT_DIR/p3c-all.xml"

# Pinned SHA-256 of the downloads. They are fetched from the network and executed by java, so the content is verified, not just the HTTP status.
# Values come from the first download of the URLs below on 2026-10-15; update them when upgrading versions.
PMD_SHA256=af294bec4629892121d88daa72785a6a12b48c7f51c759cb764ae598414d7f97
P3C_SHA256=e7afec9340a0f30f56f4fdcd3b9c49e79ed24253719fcb9f457f5bcb43e54860
KOTLIN_SHA256=3856a7349ebacd6d1be6802b2fed9c4dc2c5a564ea92b6b945ac988243d4b16b

if ! command -v java >/dev/null 2>&1; then
  echo "p3c-check: java not found" >&2
  exit 1
fi

sha256_of() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | cut -d' ' -f1
  else
    sha256sum "$1" | cut -d' ' -f1
  fi
}

# Download to a temp file and move it into place only after verification, so an interrupted download never leaves a cache entry that looks complete.
# Timeouts and retries keep the check from hanging forever on network trouble.
fetch() {
  local url="$1" dest="$2" expected="$3" tmp
  tmp="$dest.part"
  echo "p3c-check: downloading $(basename "$dest")" >&2
  if ! curl -fsSL --connect-timeout 10 --max-time 300 --retry 3 --retry-delay 2 -o "$tmp" "$url"; then
    rm -f "$tmp"
    echo "p3c-check: download failed: $url" >&2
    exit 1
  fi
  if [ "$(sha256_of "$tmp")" != "$expected" ]; then
    rm -f "$tmp"
    echo "p3c-check: checksum mismatch for $(basename "$dest"), refused" >&2
    exit 1
  fi
  mv "$tmp" "$dest"
}

mkdir -p "$CACHE_DIR"
if [ ! -d "$PMD_DIR" ]; then
  fetch "https://github.com/pmd/pmd/releases/download/pmd_releases/$PMD_VERSION/pmd-bin-$PMD_VERSION.zip" \
    "$CACHE_DIR/pmd-bin-$PMD_VERSION.zip" "$PMD_SHA256"
  # Unzip into a staging directory and rename only on success, so an interrupted unzip leaves no half-built directory
  STAGE="$(mktemp -d "$CACHE_DIR/stage.XXXXXX")"
  if ! unzip -q -o "$CACHE_DIR/pmd-bin-$PMD_VERSION.zip" -d "$STAGE"; then
    rm -rf "$STAGE" "$CACHE_DIR/pmd-bin-$PMD_VERSION.zip"
    echo "p3c-check: failed to unzip PMD" >&2
    exit 1
  fi
  mv "$STAGE/pmd-bin-$PMD_VERSION" "$PMD_DIR"
  rm -rf "$STAGE" "$CACHE_DIR/pmd-bin-$PMD_VERSION.zip"
fi
if [ ! -f "$P3C_JAR" ]; then
  fetch "https://repo1.maven.org/maven2/com/alibaba/p3c/p3c-pmd/$P3C_VERSION/p3c-pmd-$P3C_VERSION.jar" \
    "$P3C_JAR" "$P3C_SHA256"
fi
# Some P3C rules are written in Kotlin and need kotlin-stdlib at runtime (same version as p3c's kotlin.version)
if [ ! -f "$KOTLIN_JAR" ]; then
  fetch "https://repo1.maven.org/maven2/org/jetbrains/kotlin/kotlin-stdlib/$KOTLIN_VERSION/kotlin-stdlib-$KOTLIN_VERSION.jar" \
    "$KOTLIN_JAR" "$KOTLIN_SHA256"
fi

if [ "$#" -gt 0 ]; then
  FILES="$(printf '%s,' "$@")"
else
  # Tracked .java files changed against HEAD (staged or not), plus untracked new .java files;
  # keep only files that still exist. Filter with if rather than && so a failed test does not make the whole pipeline return non-zero.
  # core.quotePath=false keeps non-ASCII paths from being C-style escaped, which would make [ -f ] think they do not exist.
  # Skip files under any directory starting with . (such as .claude/); only implementation code is checked
  FILES="$({ git -c core.quotePath=false diff --name-only HEAD --diff-filter=ACMR -- '*.java'
             git -c core.quotePath=false ls-files --others --exclude-standard -- '*.java'; } \
           | { grep -v -e '^\.' -e '/\.' || true; } \
           | while read -r f; do
               if [ -f "$f" ]; then printf '%s,' "$f"; fi
             done)"
fi
FILES="${FILES%,}"
if [ -z "$FILES" ]; then
  echo "p3c-check: no Java files to check" >&2
  exit 0
fi

# PMD 6's -d takes a comma-separated file list; exit code 4 means violations were found
OUT="$(mktemp)"
trap 'rm -f "$OUT"' EXIT
set +e
java -cp "$PMD_DIR/lib/*:$P3C_JAR:$KOTLIN_JAR" net.sourceforge.pmd.PMD \
  -d "$FILES" -R "$RULESET" -f text -no-cache > "$OUT" 2>&1
status=$?
set -e
cat "$OUT"

# PMD may still return the "violations" exit code when a single file fails to parse, so parse gaps are counted separately rather than read from the exit code.
# PMD 6.15 cannot parse newer syntax such as record; those files are P3C coverage gaps and need manual review.
GAPS="$(grep 'PMDException' "$OUT" || true)"

# PMD exit code 4 = violations; any other non-zero value is a tool error, mapped to 1 so it does not clash with this script's 2 and 3
case "$status" in
  0|4) ;;
  *) echo "p3c-check: PMD failed with exit code $status" >&2; exit 1 ;;
esac

violations=0
if [ "$status" -eq 4 ]; then violations=1; fi

if [ -n "$GAPS" ]; then
  echo "p3c-check: these files could not be parsed and are not covered by P3C (review by hand; usually newer syntax such as record):" >&2
  printf '%s\n' "$GAPS" | cut -f1 | sed 's/^/  /' >&2
fi

if [ "$violations" -eq 1 ]; then
  echo "p3c-check: violations found (see output above)" >&2
  exit 2
fi
if [ -n "$GAPS" ]; then
  echo "p3c-check: no violations, but some files are not covered" >&2
  exit 3
fi
echo "p3c-check: no violations" >&2

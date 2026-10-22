---
name: quality-review
description: Independent code quality review of the current change. By default runs two tracks in parallel, an independent-context review subagent (loading language-specific rules) and a P3C check for Java changes; small changes are reviewed directly by the main flow; open-code-review (ocr) is slow and expensive and runs only after the user confirms. First checks the code against the approved plan and flags decisions that are not in it, then lists issues sorted by severity, each with file and line and a simpler alternative. Use when the user asks for a "code review" or to "review this", or after a slice is implemented. The reviewer does not inherit the implementation conversation. Reports issues only; does not modify code.
---

# quality-review: independent code quality review

Purpose: find code that "works but is ugly, amateurish or unprofessional", and over-design. This skill only reports issues; it does not modify code.

## Steps

1. **Prepare the input and detect languages**
   - Scope: review only code and implementation-related config. Ignore every directory whose name starts with `.` (such as `.claude/`, `.git/`, `.github/`, `.idea/`) and everything in it, including skills, tool config and IDE files.
   - Run `git diff HEAD --stat -- ':(exclude,glob)**/.*/**'` and `git diff HEAD -- ':(exclude,glob)**/.*/**'`, and save the diff as `review-input.diff` in a temp directory (the one the host provides, otherwise a system temp directory outside the repository).
   - When appending untracked files, also skip paths that contain a directory starting with `.` (filter the output of `git ls-files --others --exclude-standard` with `grep -v '/\.'` and `grep -v '^\.'`).
   - Narrow the scope: if the user named files or directories, run the commands above for those paths only (append the paths after `--`, and filter untracked files the same way). Otherwise, look at the `--stat` file list first; leave out changes that clearly do not belong to this task (such as other uncommitted work) and list the excluded files under "Review coverage".
   - Size note: if the diff (including untracked files) exceeds about 2000 lines, open the report with "Change is too large; consider splitting it before review", and state under "Review coverage" which parts were only sampled. The threshold is a note, not a blocker.
   - Detect languages from file extensions: `.java` loads `references/java.md`; `.ts` and `.tsx` load `references/ts.md`. Load both when both appear; other languages use only this file's checklist.
   - Find the project docs (such as `CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md`, README). Project conventions come from these files and take precedence over the defaults in references.
   - Find the approved plan for this change (the path of the plan document, or a file the user names), and the slice number this review covers. If the plan exists only in the conversation, save the text the user approved as `plan.md` in the same temp directory, without any implementation explanations. If no plan can be found, ask the user; if the user confirms there is none, write "no plan, not checked" under "Plan check". For a small change (see step 2), do not ask; write "no plan, not checked" directly.
   - Re-review: when this review follows fixes for the previous round's issues, an incremental re-review is allowed, still run independently by the subagent. Its scope:
     - whether each issue in the previous report has been fixed;
     - the full diff of every file that changed compared with the previous `review-input.diff` (before generating this round's diff, rename the previous file to `review-input.prev.diff`).
     Switch to a full review if any of these holds:
     - the plan has changed;
     - the changed parts touch external interfaces, the data model, transactions, concurrency or permissions;
     - the changed parts exceed about 300 lines;
     - the previous report or diff cannot be found.
     Note "incremental re-review" and the baseline (the previous report's path) under "Review coverage".
     Issues the previous round marked "won't change" are not raised again as they were; one may be raised again with new evidence, citing the previous entry's location and stating what the new evidence is.
   - The author's own blind spots: if `risk-walkthrough` was run for this slice, save its "Not checked" section verbatim as `unchecked.md` in the same temp directory. If it was not run, write "no author-reported blind spots" under "Review coverage".
   - Do not pass the implementation conversation, reasoning or "why I wrote it this way" explanations to any of the tracks below.

2. **Start the review**
   - Track A (subagent), track C (P3C) and the executable checks of step 4 start in the same turn, in parallel; they do not depend on each other.
   - Small change: when the in-scope diff (including untracked files) is about 300 lines or fewer and involves one language, do not start a subagent. The main flow reviews directly against the "Checklist" (still without referring to the implementation conversation) and notes "small change, not an independent-context review" under "Review coverage". The rules for tracks B and C are unchanged.
   - Track B (ocr) never runs automatically. If the host provides a structured question tool (such as AskUserQuestion in Claude Code), use it to ask; otherwise ask in text and stop until the user replies; never run it first. The question states the size of this change (files, lines) and that time and token cost grow with size (for reference: a diff of about 10,000 lines takes around 10 minutes and millions of tokens). The options are "run ocr" and "don't run", with "don't run" as the default recommendation. Run it only if the user chooses "run ocr"; if they choose "don't run", cancel or do not answer, write "ocr not run (not approved by user)" under "Review coverage".
   - If the user clearly agreed before this turn, it may run directly, but the report must state on what basis.

   **Track A: review subagent**
   Use the host's independent-context subagent (such as the Agent tool in Claude Code, `general-purpose` type). The prompt includes:
   - If the host does not support subagents, the main flow reviews on its own without referring to the implementation conversation, and notes "not an independent-context review" under "Review coverage".
   - The absolute path of the diff file
   - The absolute path of the plan file, and the slice number this review covers
   - The absolute path of `unchecked.md` (when it exists), with an explicit instruction: check every place it lists first, then do the rest of the checks
   - The full "Checklist" section of this skill
   - The full text of the matching `references/*.md`
   - The paths of the project docs, with an instruction to read them in full before starting the review
   - The output format (see "Output format")
   - An explicit instruction: read only, do not modify files; if there are no issues, write "none"; do not pad the list, do not praise
   - An explicit instruction: review around the diff; other files may be searched and opened to verify a checklist item (such as whether a similar implementation already exists, or how callers use it), but no browsing unrelated to the checklist

   **Track B: open-code-review (only after the user confirms)**
   Run `ocr review --format json --audience agent --exclude '.*/**,**/.*/**' -o <temp dir>/ocr.json`. `--exclude` leaves out every directory starting with `.`, so tool files are not reviewed. It reviews the remaining changes in the working tree and writes JSON. It usually takes longer than a foreground command timeout, so run it in the background (such as `run_in_background` in Claude Code) and read the result when it finishes.
   - The main flow reads the JSON `comments` array; each entry has `path`, `start_line`, `end_line`, `severity` (high/medium/low), `category` and `content`.
   - `tool_calls.failure_details` may record failed reads of files that do not exist (the model referred to deleted or renamed files). These do not affect the conclusions, but a comment based only on a nonexistent file should be ignored, with a note in the report.
   - If ocr is not installed or no model endpoint is configured, it fails immediately. Report "ocr not run" and the reason; do not skip it silently.

   **Track C: P3C (Java changes only)**
   Run `scripts/p3c-check.sh` (relative to this skill's directory). It checks the changed `.java` files in the working tree, including untracked new files.
   - Exit code `0`: no violations and no coverage gaps; `2`: violations; `3`: no violations but some files could not be parsed (coverage gap); `1`: script or tool error.
   - Both kinds of result can occur together; the exit code is then `2`, but the output lists both violations and unparsed files. **Always read both parts of the output**, not just the exit code.
   - Unparsed files are P3C coverage gaps; list them under "Review coverage" and have the subagent review them by hand.
   - P3C 2.1.1 is built on PMD 6.15.0 and cannot parse newer syntax such as `record`; such files appear in the unparsed list.
   - The script downloads its tools on its own, verifies SHA-256, and does not depend on the project's build config.

3. **Checklist** (the subagent goes through every item)

   **Plan check** (first, by decision)
   - Find the decisions the diff introduces: business rules, sources of data and decisions (including local copies, mappings, defaults), new types or abstractions, external interfaces and contracts, data model, external calls, user-visible behavior, failure strategy, new config and dependencies, scope changes.
   - Map each decision to a plan entry number or the plan text. Check structural decisions (modules, types, interfaces) against the plan's structure skeleton; check source decisions against the source of truth in the plan's constraints; check new abstractions, dependencies and components against the plan's "abstraction and dependency budget". Mechanical code needed to carry out an entry (wiring, fields, mapping, logging, tests, etc.) belongs to that entry and is not flagged separately.
   - Flag a decision that is not in the plan as `off-plan`: `file:line`, the decision (one sentence), the closest plan entry ("none" if there is none). Flag it even if it looks reasonable or necessary.
   - Flag one that differs from the plan (same entry, but different implementation, data source or scope) as `differs from plan`, quoting the plan text.
   - When an entry of this slice has no implementation in the diff, search the existing code first:
     - already implemented and consistent with the plan: note the location, do not flag;
     - already implemented but differing from the plan: flag `differs from plan`;
     - confirmed still missing: flag `not implemented`;
     - cannot be confirmed: flag `unverified`, stating what evidence is missing.

   **Readability and structure**
   - Are names clear and consistent with the surrounding code; are any names misleading?
   - Methods over 50 lines; single responsibility; nesting too deep (no early return where one fits)?
   - Is there duplicated logic, and is the duplication worth extracting (more abstraction is not always better)?
   - Do comments restate the code; do public APIs have doc comments?

   **Professional practice**
   - Does the code hand-write something the project's frameworks or the standard library already provide?
   - Error handling: swallowed exceptions, empty `catch`, overly broad exception types, sensitive data in logs
   - Language-specific rules are in the matching `references/*.md`

   **Over-design** (focus)
   - Interfaces or abstract classes with a single implementation
   - Parameters, config options or extension points nobody uses
   - Generic layers, registries or plugin mechanisms for "might need it later"
   - Several layers where one function or one SQL statement would do
   - A parallel version built around existing project scripts, modules or tools, or the same capability implemented twice

   **Tests**
   - Do the tests verify behavior or implementation details?
   - Can the tests catch errors: for key decisions and error paths, ask "if this logic were removed, which test would fail?"; if none, flag a test gap
   - Where do expected values come from: asserted values should come from the requirements, a plan entry or existing tests. Expected values copied from what the implementation outputs today (snapshots, hard-coded computed results) only prove the code has not changed, not that it is right; flag a test gap and say where the expected value should come from
   - Do acceptance tests exercise the real capability: if the capability under acceptance (file system, database, parser, etc.) is mocked out, it is not acceptance evidence; mocking dependencies inside unit tests per project convention is not covered by this item
   - Do the tests use the project's established test infrastructure, without bringing in a conflicting alternative?

   **Data and security**
   - Do database changes follow the project's migration and column comment conventions?
   - Hard-coded passwords, tokens or connection strings?
   - Correct transaction boundaries; per-row queries in loops (N+1)?

4. **Executable checks** (started by the main flow alongside the review in step 2; results go at the end of the report)
   - Find the static check, lint and type check commands in the project docs and build config (such as Makefile, `package.json`, Gradle, Maven) and run them for the languages in the change.
   - Do not run tests by default. Cite the test results from implementation or from `risk-walkthrough`'s verification, naming the source; a cited result must have been run after the last code change. If there is no such result, write "tests not run (no results for the current code)" and recommend running them. Run tests only when the user asks.
   - If there is no such command, note "not configured in project"; give the reason for any check not run.

5. **Summary**
   - "Plan check" results form their own section at the top of the report, grouped by plan entry, not mixed with quality issues.
   - With track A, the main flow's summary only verifies each track's evidence (whether the file, line and quoted code are real); it does not redo the full review. Drop issues whose evidence does not hold, and note under "Review coverage" which ones were dropped and why.
   - Merge the results of all tracks and deduplicate (same file, nearby lines, same issue count as one).
   - Tag each issue with its source: `subagent`, `ocr`, `p3c`; issues raised by two or more tracks get higher priority.
   - Sort by severity, using these levels:
     - Must fix: wrong behavior, regressions, data loss or inconsistency, security issues, a test that claims to cover an error but cannot catch it;
     - Should fix: off-plan design, over-design, test gaps, missing error handling, violations of project conventions;
     - Nits: naming, comments, docs out of sync with code, and other issues that do not affect behavior.
     When unsure, pick the lower level and state in the description what would raise it. Include P3C rules only as decided by the adoption table in `references/java.md`; leave out rules not adopted.
   - For each issue, give "how it is now" and "a simpler or more professional way", without changing the code for the user.
   - Note any link to the hard points from `risk-walkthrough`.
   - If a track failed or did not run, say so under "Review coverage".

## Output format

```
## Plan check
- Plan: <plan file path>
- `file:line` off-plan | differs from plan | not implemented | unverified: decision → closest plan entry
## Must fix
- `file:line` issue [source: subagent / ocr / p3c, may be several]
  - Now: ...
  - Better: ...
## Should fix
## Nits (optional)
## Executable checks (commands actually run and results)
## Review coverage (whether subagent / ocr / p3c ran, and what was not covered)
```

Every issue must have a file and line. Write "none" for an empty category. The main flow hands the summary to the user, who decides what to change, and saves the report as `review-report.md` in the temp directory as the baseline for a re-review. Once the user replies, append the disposition to the end of each issue in `review-report.md`: `Disposition: change` or `Disposition: won't change (reason)`; if the user gave no reason, write "not stated".

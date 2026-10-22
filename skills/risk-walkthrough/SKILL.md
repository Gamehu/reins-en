---
name: risk-walkthrough
description: After implementation, explain the hard parts of this change and list deviations from the approved plan, so the user can quickly check for drift before review. Use when the user asks to "walk through the hard parts" or "explain the implementation", or when a slice is done and ready for review. Report only; do not modify code.
---

# risk-walkthrough: explaining the hard parts

Purpose: there is too much code to review line by line, so explain only the parts that most need human judgment, and check for deviations from the plan. This skill only reports; it does not change code.

## Length

- At most 5 hard points and at most 8 deviation entries. When there are more, merge the minor ones into one "other minor deviations" entry, listing each one's number and a one-line description.
- Keep the whole output within about one and a half screens. Details can come when the user asks; do not lay everything out at once.

## Steps

1. **Scope**
   - Run `git status` and `git diff --stat` and list the files changed.
   - Cover only this slice's changes; do not comment on unrelated files.

2. **Pick the hard points (3–5)**
   Prefer these categories; if none apply, do not force any:
   - Transaction boundaries, concurrency and locking, idempotency
   - Permission and authorization checks
   - External calls, degradation, retries, timeouts
   - Cross-module interaction (events, inter-module interfaces)
   - Complex branching or state transitions
   - Database migrations and data consistency

3. **Describe each hard point in this format**
   - **Location**: `path:line`
   - **What it does**: 3–5 sentences on the logic (explain why it is done this way; do not translate the code line by line)
   - **Invariant**: what constraint this code maintains
   - **State after failure**: where data and flow stop on an exception or interruption
   - **Alternative**: an approach considered but not taken, and why
   - **Test coverage**: which test covers it; say so explicitly if none does
   - **Difference from the plan's flow**: if the plan's "Key flows" has a matching flow, compare input, key steps, failure state and output and list the differences; if not, note "flow not in the plan"

4. **Deviation check**
   Against the approved plan (note it if there is none), list:
   - **Source-of-truth check (do this first; never merge or skip it)**: if the plan says the authoritative source of some data or decision is outside this repository or elsewhere, check whether this change re-implements the same decision or data locally (a home-made mapping, defaults, a constant table, a cached copy, etc.). Any occurrence is a deviation and is not downgraded because "it works".
     - How to search: take the key nouns from the plan's constraints and "external capabilities to reuse", search the diff for them, and confirm the source at each hit.
     - For each: where it is implemented locally (file:line), the plan's source of truth for that data (plan location), and how they differ.
     - These deviations are listed as their own entries and do not count toward the "other minor deviations" merge.
   - **Skeleton check**: against the plan's structure skeleton, list what is in the skeleton but missing or moved in the code; extra modules, types or interfaces in the code; core types whose fields or interface signatures differ from the skeleton. If the plan has no skeleton, note "no skeleton, checked against the plan text".
   - Dependencies or components outside the "abstraction and dependency budget" (third-party libraries, caches, message queues, new services, etc.)
   - Changes that cross the "non-goals"
   - Places where the implementation differs from the plan
   - Slice boundary changes: merging, splitting or reordering slices all count as deviations
   Each entry is labeled either **needs your decision** or **in the plan**.
   - Only something the plan text states explicitly can be labeled "in the plan", with the plan's file and line. Merged or reordered slices are always "needs your decision", even if the user agreed verbally.
   - For a deviation the user agreed to verbally, write "user agreed verbally (date)" and still label it "needs your decision", so the user can confirm whether to record it in the plan.
   - Each "needs your decision" entry has three lines only: what the deviation is (one sentence), one recommended option, and the consequence of not choosing it (one sentence). No comparison table of options unless the user asks.

5. **Self-check and open items**
   - List the verification that was run (build, tests, static checks, etc., with commands taken from the project docs or build config) and the results.
   - For verification not run, give the reason; do not write "verified".
   - Anything claimed as "fixed" or "passing" must cite the command and output of a rerun in this session; otherwise write "not rerun".
   - Numbers (file counts, line counts, test counts, addresses, versions) must come from command output or file text, not memory. The same fact must be consistent everywhere it appears; if it is not, list the inconsistency for the user to check instead of picking one.
   - List leftover TODOs or known defects, marked `TODO(issue)` or `FIXME`.
   - **Not checked (required)**: list the paths, branches, input forms and environments this change did not verify (such as UI flows not walked by hand, external calls covered only by mocks, untested error branches), each with a one-sentence reason it was not checked. If everything was checked, write "none" and list the commands or tests that show it. This section is handed to `quality-review`, whose independent review covers it first.

## Output format

```
## Scope of change
## Hard points
### 1. <name> (location)
...
## Deviation check
## Verification
## Not checked
## For you to decide
```

List "For you to decide" by number, each with only the question and the recommended option, in the form "N. question → Recommended: xxx". Stop after listing them all; do not fix anything. Once the user replies by number (such as "1 accept, 2 change"), update the plan or the code accordingly.

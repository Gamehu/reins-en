# Java review reference

Applies to `.java` changes. Formatting is governed by the project's configured formatter and is not a review item.

## Priority

1. **Executable checks**: `scripts/p3c-check.sh` (P3C 2.1.1) and the project's own static checks (such as PMD, Checkstyle, SpotBugs). Take their results as given; the reviewer does not re-judge them.
2. **Project conventions**: rules in the project docs (such as author tags, DTO style, layering and module boundaries, test infrastructure).
3. **Google Java Style**: the default for naming, Javadoc, imports and formatting.
4. **P3C 2.1.1**: adopted only where 1–3 do not cover it and the P3C rule is reasonable.

On conflict, the earlier item wins; note "handled per X" in the report.

## Google Java Style essentials (for the reviewer to check)

- Classes in UpperCamelCase, methods and variables in lowerCamelCase, constants in UPPER_SNAKE_CASE.
- Public types and methods have Javadoc whose first sentence is a summary; `@param`, `@return` and `@throws` as needed.
- Each top-level type lives in its own file.
- No wildcard imports.
- Comments explain "why", not restate the code.

## P3C rule adoption table

| P3C rule | Handling | Notes |
|---|---|---|
| Constants in upper case with underscores | Adopt | Same as Google |
| Magic values (strings, numbers) | Adopt (production code) | In test code, a hint only, not a blocker |
| `@Transactional` must specify `rollbackFor` | Adopt | Spring rolls back only on runtime exceptions by default; being explicit is safer |
| Class comment must include `@author` | Per project convention | Adopt when the project requires author tags; otherwise leave out |
| Put the constant first in `equals` | Adopt | Avoids null pointer exceptions |
| Test class name suffix | Per project convention | Follow the majority style in the project and keep it consistent |
| Creating thread pools by hand | Adopt | Use a managed executor with explicit capacity, naming and rejection policy |
| Formatting, indentation, line width | Do not adopt | Governed by Google and the project formatter |

## P3C coverage gaps

- PMD 6.15 cannot parse newer syntax such as `record`. P3C does not check those files; the reviewer must cover their field comments, naming and invariants by hand.
- Exit code `3` from the script lists the unparsed files; the report's "coverage" section must name them.

## Additional checks during review

- External calls (HTTP, messaging, other services) inside transactional methods, and whether the database stays consistent when they fail.
- Per-row database queries in loops (N+1).
- Exceptions: do not swallow them, do not catch `Exception` and only call `printStackTrace`; logs must not contain passwords or full tokens.
- Whether `record`s and generated `toString()` methods expose sensitive fields such as passwords or tokens.
- Whether cross-module calls respect the boundaries the project defines (interfaces, events) instead of depending on another module's internals.
- Versioned database migrations that have already run must not be edited; changes go into a new migration file.

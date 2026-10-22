# TypeScript / React review reference

Applies to `.ts` and `.tsx` changes. Formatting is governed by the project's configured formatter and is not a review item.

## Priority

1. **Executable checks**: the project's configured lint and type checks (such as ESLint, `tsc --noEmit`). Take their results as given.
2. **Project conventions**: front-end rules and directory layout in the project docs.
3. **The defaults below** and **Google TypeScript Style**: used when the project says nothing else.

On conflict, the earlier item wins; note it in the report.

## Defaults (checked when the project says nothing else)

- Function components with Hooks; no class components.
- One way of defining types (`interface` / `type`) across the repository, not mixed.
- Union types over `enum`; discriminated unions for state machines.
- No `any`: use `unknown` plus type guards at boundaries; use `never` for exhaustive `switch` checks.
- Custom Hooks declare their return type explicitly instead of relying on inference.
- Components wrapping native elements `extend` the native attribute types and pass through `...rest`.
- Early return for loading or error states to reduce nesting.
- List `key`s use stable unique IDs, never array indexes.
- Business logic lives in hooks or services; presentational components stay pure.
- `const` and `let`, never `var`; prefer `?.` and `??`.
- Exported functions and components have TSDoc/JSDoc that does not repeat the TypeScript types.

## Google TypeScript Style essentials

- Prefer named exports (follow the project's current style; do not mass-edit existing code).
- Use `/** ... */` doc comments whose first sentence describes the behavior.
- No `namespace`, no `@ts-ignore` (use `@ts-expect-error` with a reason when unavoidable).

## Boundaries and layout

- Respect the module boundary rules the project configures (lint rules or project docs).
- Code that needs to be shared across modules should be moved to the project's shared directory, not copied.

## Additional checks during review

- Are Effect dependency arrays complete; are there unnecessary Effects (values computable during render should not be synced into state through an Effect)?
- Do async requests handle failure, cancellation and setState after unmount?
- Hard-coded API addresses, keys or passwords?
- Generic components or Hooks introduced for "might need it later"; with a single use, they should be inlined.

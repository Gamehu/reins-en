---
name: spike-design
description: Before any code is written, turn a requirement, POC or spike into a reviewable implementation plan (goals, non-goals, constraints, approach, structure skeleton, key flows, abstraction and dependency budget, slice plan). Use when the user brings a new requirement, POC or spike, or asks to "discuss the plan first". Write no code until the user approves the plan; once implementing, every decision that appears in the code must come from the plan.
---

# spike-design: plan review before implementation

Purpose: lay the plan out for the user to review before any code is written, to prevent over-design and drift. This skill only produces a plan; it does not modify files.

## Steps

1. **Clarify goals and boundaries**
   - If requirement or design documents already exist (from any tool or author), read them first. Adopt the goals, non-goals and constraints they already state, citing the source (file:line). Ask only about the gaps; do not re-ask questions they answer. Where a document conflicts with the code or the current state, list it under "Questions for you"; do not rewrite it yourself.
   - State the problem to solve, the acceptance criteria and the **non-goals** (what is explicitly out of scope).
   - First decide the task type: **designing something new**, or **integrating with an existing system**. In integration tasks, the capabilities and interfaces of external systems (third-party services, other teams' repositories, deployed platforms) are fixed constraints:
     - Default non-goal: changing the code or deployment of an external system. If a change is truly needed, list it separately as an "external dependency gap" for the user to decide; do not put it in the recommended approach.
     - Do not redesign architecture the external system has already settled. Only answer "how do we connect this repository using its existing interfaces".
   - When some data or decision has its source of truth in an external system or another location, the plan must state that this repository only consumes the result and does not keep a local copy or default of its own. Write this into "Constraints" so the later deviation check can compare against it.
   - If the user has already given a direction, do not propose alternatives from scratch; evaluate the user's approach instead (see step 4).

2. **Constraint list (before the approach)**
   List the constraints that will shape the approach. Anything the code and documents cannot answer becomes a question for the user; do not assume:
   - Call frequency: can the hot path call an external service on every request?
   - Freshness: how long may permission, configuration or data changes take to apply? Can the external system push changes, or can we only pull?
   - Who can change what: which systems can be modified, which can only be configured, which cannot be touched at all.
   - Runtime: language or framework versions, network direction (can the other side call us back?).

3. **Reuse check (before design)**
   - This repository: search for similar implementations and prefer existing patterns, modules and data structures.
   - External systems: list the existing interfaces you will use, the calling identity and what they return, with the source of each conclusion.
   - List "existing code and capabilities to reuse" and "code that must be added".
   - Optional: when designing something new, ask the user whether to research mature implementations or standard practice (open-source projects, official docs, specifications). Do it only if the user agrees, and cite sources; otherwise skip it.

4. **Approach**
   - No direction from the user: give 2–3 approaches, each with the idea, modules involved and main risks; recommend one and explain why.
   - Direction from the user: evaluate only that approach, pointing out what must be corrected and why; do not start over.
   - The simpler the better. Do not recommend designs for "might need it later".
   - **Structure skeleton**: express the recommended approach's structure as a skeleton, used as the reference for implementation and review.
     - New modules or files: location and a one-line responsibility.
     - Core types (passed across modules or carrying core data): key fields. Core interfaces: signatures. Leave out other types.
     - Every new abstraction in the skeleton must appear in the abstraction and dependency budget.
   - **Key flows**: only the hard parts (transactions, concurrency, external calls, complex state transitions, etc.), at most 3–5; leave ordinary flows out. For each:
     - Input: source and shape.
     - Key steps: the state change at each step, and where data and flow stop on failure.
     - Output: where the result goes.

5. **Abstraction and dependency budget (mandatory)**
   - Abstractions: for every new interface, abstract class, base class, registry, config option, cache, scheduled job or generic layer in the recommended approach, list:
     - Name and location
     - Current number of implementations (an interface with one implementation is rejected by default unless there is a clear reason)
     - Why it is needed now ("might need it later" is not accepted)
     - How the code would look without it
   - Dependencies: for every new third-party library, infrastructure component (cache, message queue, new service, middleware, etc.) and tool, list:
     - Name and version
     - Purpose
     - Why existing dependencies or built-in capabilities are not enough
     - Cost: maintenance, licensing, runtime resources, deployment changes

   Delete any abstraction or dependency without a reason. The budget defaults to 0.

6. **Project constraint check**
   - Read the project docs (such as `CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md`, README) and check the plan against their architecture, module boundaries, interface, data and migration conventions. Cite the location of any rule the plan breaks.
   - What happens on failure: raise the question only; degrade, abort or retry is the user's decision.
   - At what scale does it break?
   - Do data and flows close: can it leave orphaned data, can every flow finish?
   - Do not refactor modules unrelated to this task along the way.

7. **Slice plan**
   - Split the implementation into independently reviewable slices of about 300 changed lines or fewer, and mark dependencies between slices.
   - Give each slice a completion criterion (verifiable behavior or tests).
   - List each slice's decisions with numbers (such as `S1-1`, `S1-2`). Write decisions only, not implementation details: sources of data and decisions, the part of the skeleton it covers, external interfaces and contracts, data model, external calls, user-visible behavior and branches, failure strategy (degrade, retry or abort), new config and dependencies, scope boundaries. Implementation and review both trace back to these numbers.
   - Premises that must first be verified in a real environment go into a verification slice at the front, with no code.

8. **Output and stop**
   Before output, check for contradictions: within the plan, between the plan and the project docs, and between the plan and what the user has asked for. List any under "Questions for you"; do not resolve them yourself.

   Output in this structure, then **wait for the user to approve**:

   ```
   ## Goals and acceptance
   ## Non-goals (explicitly out of scope)
   ## Constraints (confirmed / to confirm)
   ## Existing code and external capabilities to reuse
   ## Approach (comparison, or evaluation of the user's approach)
   ## Structure skeleton
   ## Key flows
   ## Abstraction and dependency budget
   ## Slice plan
   ## Questions for you
   ```

   - Tag every conclusion about external system behavior with its source: `measured`, `read in code` (with file:line), or `inferred`. An `inferred` conclusion cannot be a premise of the plan; verify it or list it as to be confirmed.
   - Do not start coding before the user approves.

## While implementing (after the plan is approved)

- Mechanical code needed to carry out a decision (wiring, fields, mapping, logging, tests for in-plan behavior, etc.) can be written directly without its own plan entry.
- Code that introduces a decision the plan does not contain is improvising and must not be written directly: new business rules, new data sources or local copies, abstractions or dependencies outside the budget, new config, scope changes, self-chosen failure strategies. Stop, add it to the plan as described in "When revising the plan", get the user's approval, then write the code.
- When a slice is done, list where each decision entry is implemented; list unimplemented entries separately.
- When a slice's structure clearly drifts from the skeleton, do not keep patching the drifted code. Find the cause first (unclear plan, conflicting constraints or a wrong skeleton), fix the plan, then redo the slice. Whether to discard the code already written is the user's decision.

## When revising the plan

- Update only the plan; write no code.
- Start with "Changes from the previous version" (what was added, removed or overturned, and why), then give the complete plan.
- Every version keeps the structure skeleton, key flows, abstraction and dependency budget and slice plan; none of them is dropped in a revision.
- If the user corrects the same conclusion more than twice, stop, restate your understanding of the constraints and ask the user to confirm before continuing.

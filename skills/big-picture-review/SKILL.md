---
name: big-picture-review
description: Use when reviewing or revising a product, workflow, system, or architecture proposal or design document, or when asked whether a submitted proposal or review is reasonable. Also use when exploring an approach whose overall direction is still open.
---

# Big-picture review

Keep the real need and the complete path to the desired outcome in view while thinking through a proposal. A polished local solution can still fail the task. Reassess the direction when new information arrives, then spend detail only where it affects the outcome.

## Work from the need outward

1. State the need in plain language: who is trying to do what, under which conditions, and what observable result would count as success. Preserve the user's stated scope and decisions. Mark assumptions that are still unverified.
2. Walk one representative scenario from its trigger to its final outcome. Identify the people, systems, decisions, and handoffs that must work. Add a contrasting scenario when it could expose a different outcome or disprove a central assumption. The level of detail should fit the question; a brief conversation may need only two sentences.
3. Compare the proposed approach with that path. Ask whether it solves the actual need, covers the whole path, respects the boundaries, and puts each decision in the right place. If a central step is missing or based on a false premise, explain that first. Reconsider the approach before polishing its parts.
4. Examine the few details that decide whether the approach works. Check relevant evidence, including existing behavior, constraints, and authoritative references when needed. Separate observed facts, stated requirements, proposals, and assumptions. Apply the same scrutiny to the current implementation and to claims from the user, experts, documents, other products, AI, and official references. Code and references can establish how a system behaves. Use the current need and scenario to decide whether that behavior fits.
5. Judge complexity against the current need. For each substantial mechanism, explain which present scenario requires it and whether a simpler use of existing capabilities would work. When simplifying, verify that the required behavior still has a concrete owner and can reach the desired outcome. Preserve necessary complexity without turning possible future needs into current requirements.
6. Give a clear judgment: keep the direction, change a part, or rethink it. Name the decisive reason, a workable next move, and only the unresolved questions that can change the decision. Once the direction is sound, hand off to the requested deliverable or planning workflow and follow its confirmation requirements.

## Keep decisions and claims traceable

- **Record confirmed decisions.** For a proposal document that goes through revisions, keep a short numbered record of explicitly confirmed goals, boundaries, fields, and terms in the proposal or a companion file. Reuse an existing record and include a short quote or reference for each decision. Before revising, check the record and ask the user to decide on any proposed change to a confirmed item before adopting it.
- **Resolve repeated misunderstandings.** If the user corrects the same misunderstanding twice, restate your understanding of the need and the affected decisions. Get the user's confirmation before revising those parts again. Treat a new preference or change in scope as a new decision.
- **Test required extensibility.** When extensibility is a requirement, walk through adding one representative source, channel, or variant. Use configuration for differences that fit the same behavior, and justify a new mechanism only when the required behavior differs. Keep unknown configuration values open. Verify an unknown that could change the structure, or make the recommendation conditional on it.
- **Check scope boundaries.** When a proposal or document marks a part as "out of scope" or a "separate slice", check whether it shares data, config, entry points or records with this proposal. If it does, confirm the two sides are consistent, and raise any inconsistency as an overall issue. Out of scope only means it is not done this time, not that it is unrelated to this proposal.
- **Use the user's terminology.** Reuse established terms and, where appropriate for the audience, the system and table names from the task. Use neutral examples in shared material when the original names are sensitive. Define any new term only if an existing term cannot express the distinction.
- **Support material guarantees.** When claiming that something always or never happens, state the conditions and point to the evidence, such as an observed test or the code that enforces it. Mark inferences as such. If the evidence does not establish the guarantee, state it as a condition or an assumption to verify.

## Treat incoming views consistently

A user instruction may settle a goal, boundary, or preference. A claim about facts or a proposed solution still deserves examination. Apply the same standard to your own earlier conclusions and to material from other people or tools. If evidence conflicts with an explicit user decision, explain the conflict and its consequence; do not silently override the decision. Do not manufacture objections merely to appear independent.

When a new comment pulls the discussion toward a narrow detail, check whether it changes the need, the end-to-end path, or a key premise. If it does, revisit the overall judgment. If it does not, resolve it at the appropriate level and return to the main question.

## Example

An organization wants records from several systems to represent the same person. A draft spends pages on field precedence. Before reviewing its precedence rules, trace how a record from each system is recognized as that person and what happens when an identifier differs or is reused. If that identity path is incomplete, state the gap and revise the overall approach. Only then decide which precedence rules matter.

## Response shape

Lead with the overall judgment and the scenario that supports it. Explain the key assumption or missing handoff, then the smallest useful correction. Include detailed findings only when they affect that judgment or the requested deliverable. Use plain language and a diagram only when it makes the path easier to understand.

When asked to assess feedback with multiple items, give the overall judgment first. For each item, say whether it holds, partly holds, does not hold, or needs verification. Give the reason and say whether it affects the overall direction or a detail. Include the smallest useful fix for a substantiated issue and cite any conflicting confirmed decision.


---
name: whole-picture-review
description: Use when exploring, designing, revising, or reviewing a product, workflow, system, or architecture and the overall approach may be wrong despite plausible details. Also use when new proposals, feedback, examples, or source material could change the direction.
license: MIT
---

# Whole-picture review

Keep the real need and the complete path to the desired outcome in view while thinking through a proposal. A polished local solution can still fail the task. Reassess the direction when new information arrives, then spend detail only where it affects the outcome.

## Work from the need outward

1. State the need in plain language: who is trying to do what, under which conditions, and what observable result would count as success. Preserve the user's stated scope and decisions. Mark assumptions that are still unverified.
2. Walk one representative scenario from its trigger to its final outcome. Identify the people, systems, decisions, and handoffs that must work. Add a contrasting scenario when it could expose a different outcome or disprove a central assumption. The level of detail should fit the question; a brief conversation may need only two sentences.
3. Compare the proposed approach with that path. Ask whether it solves the actual need, covers the whole path, respects the boundaries, and puts each decision in the right place. If a central step is missing or based on a false premise, explain that first. Reconsider the approach before polishing its parts.
4. Examine the few details that decide whether the approach works. Check relevant evidence, including existing behavior, constraints, and authoritative references when needed. Separate observed facts, stated requirements, proposals, and assumptions. Do not treat any source as correct merely because it is the user, an expert, an existing document, a successful product, an AI response, or an official reference. An official reference can establish a product's behavior without proving that behavior fits this task.
5. Judge complexity against the current need. For each substantial mechanism, explain which present scenario requires it and whether a simpler use of existing capabilities would work. When simplifying, verify that the required behavior still has a concrete owner and can reach the desired outcome. Preserve necessary complexity without turning possible future needs into current requirements.
6. Give a clear judgment: keep the direction, change a part, or rethink it. Name the decisive reason, a workable next move, and only the unresolved questions that can change the decision. If the user asks for a document, interface, or implementation, continue with that deliverable after the direction is sound.

## Treat incoming views consistently

A user instruction may settle a goal, boundary, or preference. A claim about facts or a proposed solution still deserves examination. Apply the same standard to your own earlier conclusions and to material from other people or tools. If evidence conflicts with an explicit user decision, explain the conflict and its consequence; do not silently override the decision. Do not manufacture objections merely to appear independent.

When a new comment pulls the discussion toward a narrow detail, check whether it changes the need, the end-to-end path, or a key premise. If it does, revisit the overall judgment. If it does not, resolve it at the appropriate level and return to the main question.

## Example

An organization wants records from several systems to represent the same person. A draft spends pages on field precedence. Before reviewing its precedence rules, trace how a record from each system is recognized as that person and what happens when an identifier differs or is reused. If that identity path is incomplete, state the gap and revise the overall approach. Only then decide which precedence rules matter.

## Response shape

Lead with the overall judgment and the scenario that supports it. Explain the key assumption or missing handoff, then the smallest useful correction. Include detailed findings only when they affect that judgment or the requested deliverable. Use plain language and a diagram only when it makes the path easier to understand.

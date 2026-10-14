---
name: matt-workflow
description: Run a Matt Pocock grill-with-docs, implement, and two-axis code-review flow with a clean context per phase.
---

# Matt workflow

Coordinate three explicit handoffs through `subagent`; use `initialContext: "empty"` whenever a child session is first created.

1. Pin the pre-work VCS fixed point and effort name.
2. Start `grill-me-with-docs` in a new named session such as `matt-grill-<effort>`. Relay its single question to the user, then continue the same child session with each answer. This phase completes only when it returns ready document paths and the user approves them.
3. Run `implement` ephemerally. Pass the approved document paths, fixed point, acceptance criteria, exclusions, and relevant user decisions. Do not clone parent history.
4. Run `code-review` ephemerally. Pass the same fixed point and spec paths. It performs Standards and Spec reviews in further fresh contexts.
5. Return implementation verification plus the two review axes. Keep unresolved findings explicit.

Each phase learns only from repository state and its explicit handoff. Never reuse the grill session for implementation or review.

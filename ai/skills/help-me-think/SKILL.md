---
name: help-me-think
description: >
  Explore a spike, ADR, or open engineering problem with a decision tree; produces an
  options/decision doc and follow-up work tickets instead of an implementation spec. Use when
  starting a spike, weighing architectural options, or when the user asks to "help me think".
---

Explore an open problem with the user until the direction is clear, then capture the options and
decision in a spike or ADR and break the resulting work into follow-up tickets. Each ticket gets
its own spec-grilling session later; this skill stays at **decision altitude**.

Read these references before starting:

- `~/.dotfiles/ai/skills/load-engineering-context/SKILL.md` (where drafts, spikes, and tickets live)
- `~/.agents/skills/grilling/SKILL.md` (the design-tree round format: `❓ Q1` + `➡️` recommended answer)

## Process

1. **Name the destination and audience.** Before branching into options, settle what decision this
   session is reaching (a spike recommendation, an ADR, or a go/no-go proposal) and who will read
   it (engineering, product, or both). The destination fixes the scope.
2. **Explore breadth-first in rounds.** Map the problem as a design tree using `grilling`'s round
   format to narrow in on the problem being solved and its cost/benefit decisions. Fan out across
   the major axes first: problem definition, constraints, candidate options, cost/benefit
   trade-offs, risks, and rough sizing.
   - Look up codebase and external facts yourself using fresh subagents; only put decisions to the
     user.
   - **Check upgrades to current solutions first.** Before designing something custom, check
     whether upgrading an existing dependency, internal wrapper, SDK, or platform service would
     solve the problem directly. Surface those upgrades early as considered options so they are
     weighed up front, even if ruled out.
   - **Capture fog of war as open questions.** Anything that blocks a final call or cannot be
     answered in this session becomes an actionable open question with a clear owner (the user,
     Product, or another team) so it can be assigned and resolved.
   - **Keep implementation detail out of the spike/ADR.** Whenever a question drops into schema
     details, exact event contracts, low-level edge cases, file-by-file wiring, or test plans, stop
     drilling there and park it in a **Parked for spec** list tied to the relevant follow-up ticket.
   - **Mark out-of-scope boundaries explicitly** so ruled-out work does not creep back in.
3. **Confirm shared understanding.** The exploration phase is complete only when the decision
   frontier is empty: the problem is sharp, candidate options and cost/benefit trade-offs are
   weighed, unresolved items are captured as owned open questions, and the follow-up work slices
   are confirmed by the user.
4. **Produce two separate outputs.** Never merge the spike/ADR and the implementation spec into one
   file:
   - **Spike or ADR:** problem, owned open questions up front (if any), considered options with
     cost/benefit trade-offs, recommended direction (or open proposal), risks, and rough LOE. Apply
     the engineering branch of `~/.dotfiles/ai/skills/writing-voice/SKILL.md` and
     `~/.dotfiles/ai/skills/unslop/SKILL.md`.
   - **Follow-up tickets:** scoped work drafts routed per `load-engineering-context` (local
     `Issues/<effort>/` drafts marked `needs-triage`, ready to refine or publish to Jira). Each
     ticket states the problem, scope boundary, and any parked implementation notes to feed into its
     own future spec-grilling session.

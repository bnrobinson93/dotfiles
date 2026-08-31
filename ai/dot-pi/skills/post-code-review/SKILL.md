---
name: post-code-review
description: After code implementation, dispatch fresh Ryan backend and Sara frontend reviews before handoff.
---

# Post-code review

After implementation and tests:

1. Identify the exact diff/fixed point and originating spec. If the diff is empty, stop.
2. Pick reviewers by matching the changed behavior against the `ryan-review` and `sara-review` skill descriptions, which own the scope definitions. Run both when the change spans both.
3. Call the selected reviewers together through `subagent`. Every call is ephemeral with `initialContext: "empty"`. Pass the fixed point, diff command, spec path or requirements, and reviewer-specific file scope explicitly. Parent conversation history is not a handoff.
4. Report each review separately. Fix confirmed findings within the original scope, then run the affected reviewer once more. Stop after that verification pass and surface remaining judgment calls.

An enclosing workflow with its own named review phase owns review instead.

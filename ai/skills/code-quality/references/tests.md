# Tests

Prefer TDD while building. Run the smallest subset that answers the question. Before running
the full suite, ask whether Brad already has it running.

Favor small, readable suites with explicit setup and minimal magic. A single test follows one
meaningful workflow end to end, even when that makes it long and assertion-heavy. One test with
six assertions beats six tiny tests that each rebuild the same setup.

These are language-agnostic. The mechanism differs (Vitest/Jest, Go `testing`); the principle
holds.

- Prefer fewer, longer tests when the assertions belong to one workflow. Treat each test like a
  manual tester's script: one setup, then as many actions and assertions as the journey needs.
- Don't split one flow into many tiny tests to satisfy "one assertion per test." Related
  assertions in one test are a feature.
- Keep test files flat. Avoid deep nesting of test groups. Table-driven tests in Go are fine,
  but each case is a full workflow, not a fragment of one.
- Inline the setup each test needs rather than hiding it in `beforeEach`/`afterEach` or a
  sprawling `TestMain`. Avoid shared mutable state across cases: if the next assertion depends
  on the same object, request, or response, it belongs in the same test.
- Build helpers that return ready-to-run objects (factories), not globals.
- Keep feature-specific fakes in that feature's test file. When several features truly share a
  helper, move it to a neutral test-helper file instead of making one feature's tests own
  another feature's setup.
- Derive fixture values through the same production helper the code under test uses, then pass
  them in. Hand-written SQL or string concatenation drifts from production formatting and
  canonicalization, so the test passes against the wrong shape.
- Don't test what the type system already guarantees.
- Register cleanup only when there is real cleanup, using the language's scoped mechanism (JS
  `using`/`Symbol.dispose`, Go `t.Cleanup`/`defer`). Skip the ceremony otherwise.
- Reach for newer language tools when they read more cleanly: `await using` with
  `Symbol.asyncDispose` in JS, `t.Cleanup` and `t.Parallel` in Go.
- Keep intent obvious in the name: "auth handler returns 400 for invalid JSON".
- Write tests that run offline. No public internet, no third-party services. Prefer local fakes
  and fixtures (`httptest`, in-memory DBs, MSW).
- Keep the bar for adding tests high, especially slow integration and e2e ones. Fast unit tests
  for logic; a very small number of important happy-path e2e journeys.
- Assert intermediate states inside the workflow that causes them rather than adding isolated
  tests for incidental loading or transition states.
- Skip regression tests for bugs unlikely to recur unless the flow justifies the maintenance.
- Favor behavior-focused assertions (structured output, user-visible outcomes, stable
  contracts) over asserting that a string blob contains incidental copy. In React, assert what
  the user sees and does (Testing Library), not state or props.
- Do not add BDD tests unless Brad explicitly asks. Leave acceptance-suite ownership to QA.

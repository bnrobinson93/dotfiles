---
name: ryan-review
description: Senior PR review — security, data correctness, over-engineering, repo fit. Use for a Ryan-style or senior engineering review, or when the user mentions ryan/ryanulit/ryanulites.
---

# Ryan Review

Review changes like a senior engineer who wants the repo smaller, safer, and more coherent. Put actionable feedback first, then a short fix overview.

## Workflow

1. The diff's best outcome is getting shorter. Hunt over-engineering alongside correctness, security, and repo fit. Review as Ryan — his own instincts below, not another reviewer's or the author's personal bar.
2. Load Hunk when available:
   - Run `hunk skill path`.
   - Read the returned `SKILL.md`.
   - Use `hunk session review --repo . --json` first, then `--include-patch` only for files that need raw diff.
   - If no Hunk session exists, attempt the tuicr skill. If that doesn't exist either, ask the user to open Hunk or fall back to the VCS diff.
3. Discover repo context before judging the diff:
   - Read applicable `AGENTS.md` files.
   - Detect JJ vs Git and inspect current diff.
   - Search existing helpers, clients, handlers, tests, migrations, and workflow scripts before calling something new or duplicated.
4. Review in this order:
   - Security and auth boundaries.
   - Data correctness, migrations, and API contracts.
   - Over-engineering, duplication, and tech debt.
   - Tests and operational fit.
5. Leave Hunk inline comments for concrete findings. Do not comment on every hunk.

## Ryan Fingerprint

Use these recurring review instincts from `ryanulit` PR feedback:

- Ask why a layer, flag, env var, dependency, interface, interceptor, or workflow exists before accepting it.
- Prefer stdlib/native/platform code over new dependencies or hand-rolled logic. Build URLs, paths, and queries with structured constructors/parsers, not string surgery.
- Shape public methods around domain operations. Prefer specific names over generic `Build` or `Parse`, keep multi-step invariants in one use-case method, and test observable behavior instead of making internal phases public for tests.
- Treat config as construction data. Pass cohesive, validated config into constructors at the composition root, then inject ready collaborators. Avoid parallel config structs, copied fields, and downstream guards or fallbacks for states already rejected at startup.
- In Go, put interfaces at the consumer boundary and keep providers concrete. The consumer declares the smallest behavior it needs; provider packages should not publish interfaces shaped by their own implementation or tests.
- Reuse existing repo helpers; duplicated functions should be called out with the existing location.
- Keep migrations focused. Avoid schema/user/extension churn unless required. Name DB objects consistently.
- Hide DB details behind the DB client: SQL, UUID/null conversion, pagination safety, and query naming belong there.
- Prefer one canonical column as the source of truth over several redundant derived columns that must stay in sync. Parse/derive the rest on demand.
- Pass `ctx` through request chains; use cancellation-capable APIs such as `AbortController`.
- Validate config once at startup, then trust that invariant downstream. Do not duplicate config/version facts in docs, workflows, and code.
- Keep auth facts from trusted context/token claims, not user-supplied params, unless the product explicitly requires delegation.
- Check aliases, groups, tenant/org claims, visibility trimming, and entitlement scope. These are common security/correctness edges.
- Prefer integration tests for DB/service behavior. Test public behavior at the highest practical seam; avoid tests for implementation phases, test-only production-like duplicates, and throwaway `cmd` test tools.
- Trust guarantees from authoritative boundaries — generated/proto validation, or data read back from your own DB. Do not revalidate what a trusted internal source already ensures without a reason.
- Keep API contracts about caller needs, not backend mechanics. Storage regions, internal endpoints, fallback state, and similar provider details stay internal unless clients must act on them.
- Delete thin wrappers, one-use mappers, and explanatory comments that restate code. An abstraction earns its keep through real policy, reuse, or a meaningful boundary.
- Question CI/workflow duplication; call existing make/script entrypoints when possible.
- Flag hard-coded endpoints only when they lack rationale or a clear operational owner.
- Treat caches as design changes, not harmless optimizations. Require ownership, staleness, invalidation, and security boundaries.
- Check the ticket scope. If the ask is "disable UI arrows," do not silently build sorting.
- Accept deliberate "fine for now" simplifications when the risk is tracked or pre-GA, but name the follow-up trigger.

## Findings To Hunt

- `security:` caller can pass org/tenant/user ID that should come from token/context.
- `security:` entitlement check misses aliases, groups, workspace/folder ownership, or visibility trimming.
- `security:` dependency added where stdlib/platform package covers the need.
- `dup:` new function repeats an existing helper, handler pattern, migration helper, query helper, script, or test factory.
- `yagni:` one-off interface, interceptor, env var, config knob, provider, wrapper, or future feature path.
- `boundary:` config or provider details cross layers instead of becoming a validated, constructed collaborator at the composition root.
- `interface:` provider owns an interface or exposes internal phases so tests can mock them; move the narrow interface to the consumer and test the complete operation.
- `debt:` docs/workflows/code repeat source-of-truth values such as Go/Node/pnpm versions, defaults, routes, or commands.
- `db:` migration mixes concerns, cascades data unexpectedly, lacks rollback thought, fights sqlc/Postgres conventions, or stores redundant derived columns instead of one canonical value.
- `api:` contract exposes backend mechanics, ignores existing proto/protovalidate guarantees, or bypasses established service composition.
- `test:` test targets implementation phases, does not exercise production behavior, duplicates production logic, or should be integration coverage.
- `ops:` observability/CI/retry behavior is too aggressive, too hidden, or disconnected from deploy/gitops reality.
- `scope:` PR implements more than the ticket asked for or should be split into smaller trackable PRs.
- `delete:` dead code, unused flexibility, speculative feature. Nothing replaces it.
- `stdlib:` hand-rolled thing the standard library ships. Name the function.
- `native:` dependency or code doing what the platform already does. Name the feature.
- `shrink:` same logic, fewer lines. Show the shorter form.

A single smoke test or `assert`-based self-check is the minimum, not bloat — never flag it for deletion.

## Output

Lead with findings, highest severity first:

```text
Feedback
- path/to/file.go:L42 security: orgID comes from request param, so caller can ask about another org. Pull orgID from authenticated claims/context.
- path/to/file.go:L88 dup: this repeats existing parse helper in internal/foo. Reuse that helper and delete this copy.

Fix overview
- Move tenant/user derivation into the existing auth/context path.
- Replace duplicated parser with internal/foo helper and keep tests on the shared behavior.

net: -120 lines possible.
```

Close with `net: -<N> lines possible.` when anything is cuttable.

If no findings: `Lean already. Ship.`

Keep comments short. Prefer questions only when the code may be valid and needs context: "What requires this new dependency over net/smtp?" Do not praise, summarize obvious code, or write a feature tour.

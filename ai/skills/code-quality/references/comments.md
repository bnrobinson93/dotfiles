# Comments

Say it in the code. A comment is the last resort, the thing you reach for when the language
cannot hold the meaning. It explains *why*. The code explains *what*.

Before writing one:

1. Rename the variable or function so the name carries the meaning.
2. Extract the confusing expression into an explicitly named chunk.
3. Only when the reason still cannot live in code, write the comment.

❌ Bad

```go
// Check to see if the employee is eligible for full benefits
if ((employee.flags & HOURLY_FLAG) > 0) && (employee.age > 65) {
    // ...
}
```

✅ Good

```go
if employee.isEligibleForFullBenefits() {
    // ...
}
```

## The comments that survive

This list is closed. A comment outside it gets deleted.

- **Gotchas.** Non-obvious code that breaks core functionality if removed or changed. Name the
  consequence, not the mechanics.
- **Public interfaces**, one or two lines, where the language expects it (Go doc comments). The
  types carry the shape; the comment carries what they cannot.
- **Intent and constraints code cannot hold**: ordering rationale, a security constraint, an
  external contract, a thread-safety or long-running warning.
- **A regex**, decoded in plain words.
- **Canonical tags**: `TODO`, `NOTE`, `INFO`, `WARN`/`WARNING`, `HACK`, `PERF`, `FIX`,
  `ponytail`. Clear TODOs before check-in where you can.
- **Copyright headers** the repo requires.

```js
// WARNING: removing this line will break everything. Do not touch unless you know what you're doing
```

When the same *why* already lives at its real home (the function it describes, an ADR, a spec),
leave it there and let the call site stay quiet.

## Delete on sight

- Anything restating what the code or a type signature already says. It is clutter that must be
  kept in sync for no gain.
- Mumbling: half a thought, an author's note, a reminder, a question nobody answered.
- Journal or changelog entries. Version control tracks that.
- Long javadoc on functions and variables where types would do.
- Noise: a block quote wrapping one line, position markers, closing-brace labels. Functions
  should be tight enough that none of these help.
- Commented-out code.
- Comments about code elsewhere. A comment describes what it sits next to.

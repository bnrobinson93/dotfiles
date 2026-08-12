---
name: simplify
description: Simplify and streamline code. This should be used automatically whenever coding is done and ready for user review before handing back to the user.
---

# Simplify

Review changes in the current branch or jj bookmark, or in the state the user specifies.

1. Ensure names are relevant and precise. Use clear names such as `isConfigured` instead of `complete` as the latter feels like a verb, not a state

2. Combine related concepts. If two types, functions, or constants overlap, combine them

3. If a value can be computed from values already in scope, avoid passing as a prop/argument and simply build it

4. Scope: only touch code in the staged diff

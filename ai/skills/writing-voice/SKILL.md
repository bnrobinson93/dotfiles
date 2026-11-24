---
name: writing-voice
description: >
  Write in Brad's voice, never Claude's. Use for prose another human will read: docs, READMEs,
  decision docs, essays, PR descriptions, publishable comments, talks, and teachings. Not for
  coding chat, status updates, or caveman mode.
---

# Writing Voice

## Default process

1. Identify audience and artifact, then pick the matching branch below.
2. Draft for clarity first, style second.
3. Cut filler, hedging, throat-clearing, and repeated points. Aim to cut the first draft by a third.
4. Read aloud for rhythm. If it sounds like writing, rewrite it.
5. End cleanly. Skip summary paragraphs unless the reader needs one.

## Branches

### Engineering docs (ADRs, spikes, specs, READMEs, PR descriptions, review comments)

Write like an engineer talking to peers, not a slide deck or a LinkedIn essay.

- Use plain `###` subheadings and normal sentences in bullets. Skip bold micro-slogan prefixes on
  paragraphs and bullets; reserve bold lead-ins only for short scan keys (a field name, option
  name, or question label)
- State facts directly. Reserve a punchy line for either a single ~6-word summary up front or one
  closing line that drives the main point home. Turn stacked `"X, not Y"` contrasts into plain
  statements
- Name each system or component once and repeat that name instead of cycling synonyms
- Keep evidence concrete: commit counts, line counts, flags, file paths, real payloads

### Teachings, talks, essays, and personal notes

Read `~/.dotfiles/ai/skills/writing-voice/teaching-voice.md` before drafting or editing in this
register.

## Pronoun and coaching rule

Never inject Claude's voice into Brad's writing.

- When drafting on his behalf, write **as him**, not as an assistant looking over his shoulder
- In coach or review mode, phrase feedback in the **third person** ("the author should...", "this
  paragraph buries the lead"), not the second ("you should...")
- In prose written on his behalf, "you" addresses the *reader of the piece*, never the author

## Shared craft rules

Apply Orwell's six rules from *Politics and the English Language*, Strunk's *omit needless words*,
active voice, emphatic word last, and Zinsser's clutter test. On top of those:

- No em-dashes or en-dashes. Use a comma or end the sentence
- First sentence carries the load. Rewrite it last and rewrite it most
- After every sentence, ask what the reader wants to know next, then answer that
- Use contractions when they sound natural. Sentences may open with *but*, never with *however*
- Use *that* unless the meaning forces *which* (and a comma)
- Skip synonyms for *said*, and spend exclamation points sparingly
- For bullets and lists, omit trailing periods; keep `?` or `!` when the bullet ends on one

## Markdown references

- Use footnote references for supporting ADRs, issues, specs, and source links when a body claim
  points at them
- Put each footnote definition immediately below the paragraph or list block containing the first
  reference, even when referenced again later
- Leave links with no body reference under one `## Links` section
- For mixed source lists, skip subheaders and prefix each bullet with the source (e.g. `adr:` or
  `platform:`)

## Ownership

This skill outranks `unslop`. `unslop` runs after this skill to catch AI tells on written prose;
where the two disagree on Brad's voice (especially in spoken scripts and teachings), this skill
wins.

## Checklist before returning a draft

1. Matched the right branch (plain peer prose for engineering docs; `teaching-voice.md` for talks
   and essays)?
2. No bold-caption bullet walls and no stacked `"X, not Y"` contrasts?
3. Cut filler, passive constructions, and repeated explanations?
4. Sentences short, active, and concrete?
5. Third-person coaching if giving feedback rather than a rewrite?

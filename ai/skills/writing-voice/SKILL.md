---
name: writing-voice
description: >
  Write in Brad's voice, never Claude's. Use for prose another human will read: docs, READMEs,
  decision docs, essays, PR descriptions, publishable comments. Not for coding chat, status
  updates, or caveman mode.
---

# Writing Voice

## Default process

1. Identify audience and artifact: README, design doc, comment, essay, note, post, PR.
2. Draft with clarity first, style second.
3. Tighten aggressively. Cut filler, hedging, throat-clearing, and repeated points. Cut the first draft by a third.
4. Read aloud for rhythm. If it sounds like writing, rewrite it.
5. End cleanly. No summary paragraph unless the user explicitly wants one.

## The voice (from Brad's published teachings + periodic notes)

- **Co-pilgrim, not lecturer.** "We," "our," "us." Pose the tension; walk through it together. Land on application, not pronouncement
- **Conversational asides land hard.** "First, what on earth? So random!" "the easy answer is tough love every time!" Short interjections break up exposition and mark a real person thinking out loud
- **No em-dashes.** His natural use sits between a paren and a comma (a soft pause), but em-dash now reads as an AI tell. Use a comma, or end the sentence
- **Bullet-led structure with embedded callouts.** Section headers (Context / The Case For / The Case Against / Closing Thoughts / Application); bullets carry the argument; quotes/scripture indented as evidence; numbered sub-lists for enumerated pitfalls
- **Pithy reframes earn their keep.** "Be a thermostat, not a thermometer." "If you want to go fast, go alone. If you want to go far, go together." One memorable line beats a paragraph
- **Specificity over abstraction.** Hebrew/Greek roots with Strong's-style citation when relevant; concrete numbers; named patterns ("passivity trap," "guilt loop")
- **Terse self-honesty in a casual register.** No throat-clearing. Name the trap by its name
- **Close with a question or a jolt, not a summary**
- For bullets and lists, no ending periods. Keep a closing question mark or exclamation mark when the bullet ends on one

## Pronoun & voice rule (the core feedback)

Never inject Claude's voice into Brad's writing. "I don't want your voice in my writing."

- When generating copy on his behalf, write **as him**, not as an assistant peering over his shoulder.
- In coach/edit mode, phrase guidance in the **third person** ("the author should…", "this paragraph buries the lead"), not the second ("you should…").
- In any prose written on his behalf, "you" addresses the *reader of the piece* — never Claude advising Brad.

## Craft rules

Simple writing is persuasive writing. A good argument in five sentences sways more people than a brilliant one in a hundred. The reader's attention is the scarce resource, so make them work as little as possible.

The baseline is the canon, which you already know: **Orwell's six rules** from *Politics and the English Language*, plus Strunk's *omit needless words*, *use the active voice*, and *place the emphatic word last*. Apply them as written. Zinsser's clutter test decides the close calls: strip every sentence to its cleanest components.

What the canon does not give you, and Brad wants anyway:

- Cut the first draft by a third. That is the target, not a figure of speech
- One provocative thought per piece. Not two, not five. One
- The first sentence carries the whole load. Rewrite it last and rewrite it most
- After every sentence, ask what the reader wants to know next. Then answer that
- Contractions when they sound natural. Sentences may open with *but*, never with *however*, which sags
- *That* unless the meaning forces *which* (and a comma)
- Don't strain for synonyms of *said*, and spend exclamation points like money
- End on a jolt. No summary, no "in conclusion." A quotation that lands the point is a fine last line, and bringing the lead full circle is better
- Read it aloud. If it sounds like writing, rewrite it. Sit with a hard sentence by deleting it and starting over

## Markdown references

- Use footnote references for supporting ADRs, issues, specs, and source links when a body claim points at them
- Put each footnote definition immediately below the paragraph or list block containing the first reference, even when referenced again later. Renderers move footnotes to the bottom anyway; local placement makes writing and updating easier
- Leave links with no body reference under one `## Links` section for later use
- For mixed source lists, skip subheaders. Prefix each bullet with the source, e.g. `adr:` or `platform:`

## Ownership

This skill is Brad's own voice and outranks every general style guide, `unslop` included.
`unslop` is the house default for text no voice skill claims, and it runs after this one to
catch AI tells. Where the two disagree, this skill wins.

## Checklist before returning a draft

1. Wrote in his voice (co-pilgrim, sparing em-dashes, conversational asides, pithy reframes, concrete specifics) — not mine?
2. Does the first sentence make the reader want the second?
3. Exactly one provocative point?
4. Cut every filler word and passive construction I can?
5. Sentences short and active, subjects before actions?
6. Ending jolts rather than summarizes?
7. If advice/edit output, "you" reserved for the author addressing the reader (third-person coaching)?

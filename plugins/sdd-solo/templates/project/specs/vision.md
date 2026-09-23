# Direction — layer 0

- **Status:** draft
- **Source:** <the owner's words · brief `<path>`>
- **Last updated:** ___

> The layer above BR. A BR answers *why build this slice*; this file answers *where we are going* and
> *what must not shrink* while the BR's evidence filter does its work. The real case behind it: one BR
> was narrowed three times over three adversarial passes — each time correctly, by the "no number, no
> Background" rule — until what was left was plainly smaller than the original intent, and no check saw
> it, because no layer held the intent.
>
> **Exempt from the "no numbers" rule.** Here a number is the owner's intent, not a fact needing a source.
> Leave `___` where something is unknown, but nobody demands evidence for a direction.
>
> The **owner** writes this, in plain words. `/sdd-solo:intake` only asks and transcribes; no agent
> writes any section here by itself. Editing this file is a `docs(vision): …` commit.

## Positioning
<One sentence: what this product is, who it is for, and what makes it different.>

## Do not narrow
<3–5 items. One line per thing no BR may ever push into Out of Scope. Shape:
`- **<short keyword>** — <explanation>`. `br-check` compares the **keyword** (case-insensitively) with
every Out of Scope line of every BR — a match is red, unless that line says
`deliberately narrowed — owner decided YYYY-MM-DD`.
The keyword is the phrase someone would actually write in Out of Scope ("write path", "offline"),
not the whole sentence.>
- **<keyword 1>** — <item 1>
- **<keyword 2>** — <item 2>
- **<keyword 3>** — <item 3>

## Crafts and slices
<Each craft is a folder `specs/<craft>/`; `core` is the shared core, a sibling of the crafts. Each slice
is one `br-###/` inside that folder. A BR declares `**Slice:** <craft> · <slice name>` — the slice name
must appear in this table.>

| Craft | Slice | BR | State | Opens when |
|---|---|---|---|---|
| core | <login · console> | BR-### | active | — |
| <craft 1> | slice 1 "<discovery>" | BR-### | active | — |
| <craft 1> | slice 2 "<operations>" | ___ | waiting | slice 1 done |
| <craft 2> | ___ | ___ | conditional | <craft 1> "done" (section below) |

**One craft** is open at a time. The next craft opens when the previous one is "done" by the section
below — not when it feels exciting.

## What "done" means per craft
<The condition for closing one craft so the next may open. Two halves: the pack runs without a developer,
and at least one operations slice (the write path) has shipped. The number of days is the owner's intent —
runxops settled on 2026-09-18: 7 consecutive days.>
- <craft 1>: the pack runs ___ consecutive days with no developer fixes **and** at least one operations slice has shipped (BR-___ implemented)
- <craft 2>: ___

## Reverse ledger
<Append-only. When a UC or a BR finds the direction wrong at some point, record it here instead of quietly
editing the sections above. One line each: date · who found it · before → after.>
- YYYY-MM-DD — UC-### corrects the direction at ___: <before> → <after>

## Open Questions
- [ ] <a question about direction the owner has not settled> (interim decision: ___)

## History
- v1 (YYYY-MM-DD): initial

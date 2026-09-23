---
name: sdd-process
description: The background knowledge of the SDD-Solo process — the 5 requirement layers (Direction/BR/UC/Entity/AC), the ID system, the specs/ tree by core|craft × slice, the core/craft boundary, the 14 steps per UC, how to write a UC/AC/RULE/DMN, when to use changes/. Use it when the user is writing or editing a spec, vision, AC, rule, entity, flow diagram, screen or ADR in a repo that has STATE.md, or asks what the process says to do next.
---

# SDD-Solo — how this system writes specs

Sources: the ebook *Spec Driven Development* (Nguyen The Huy), AIUP, GitHub Spec Kit, OpenSpec — **read to learn the shape of the artifacts, never depend on any of their commands**; Mermaid notation (flowchart, stateDiagram, sequenceDiagram), DMN, UML, Impact Mapping, User Story Mapping. This edition is for **one developer + an AI**: it keeps the book's artifacts and replaces every mechanism that needs a second person.

Reply in whatever language the user writes in; keep file names, IDs and slugs in English.

## The claim
A spec is the interface between three readers: the user today, the user three months from now, and every new AI session. The single goal: **let no business decision be made without anyone knowing it was made**. When a prompt is missing a rule, the model fills the gap with probability → that is a silent decision. Your job while working in this repo: **notice it and ask**, never fill it.

## Five layers, five questions, five places
| Layer | Question | File | Diagram |
|---|---|---|---|
| Direction | Where we are going, what must **not shrink** | `specs/vision.md` — layer 0, **written by the owner**, exempt from the "no numbers" rule | the `## Crafts and slices` table |
| BR | Why **this slice** | `specs/<core\|craft>/br-###/br.md` — one BR per slice, one file; `BR-000` in `specs/core/br-000/` is a fully written sample, read it first | Impact Map (Mermaid, must have ≥ 1 `-.->` branch) · Story Map |
| UC | Who does what | `specs/<core\|craft>/br-###/use-cases/UC-###-slug/UC-###.md` | Mermaid flow (`UC-###.flow.md`, same folder) · Sequence when a network is involved |
| Entity | Which concepts, which lifecycle | **one file per entity**: `specs/core/entities/<Name>.md` · `specs/<craft>/entities/<Name>.md` | Domain Model (classDiagram, in `entities/README.md`) · State Machine in the file of any entity with a status |
| AC | How we know it is right | inside the UC file, `### AC-#` Given/When/Then | — |
| RULE | A constraint crossing UCs | `specs/rules.md` (project-wide) · `specs/<craft>/rules.md` (craft-only) — **one `RULE-###` sequence for the whole project**; UCs and ACs cite the ID only | a DMN table at ≥ 3 conditions |

Layer 0 exists because none of the four layers below holds the **intent**: one BR was narrowed three times over three adversarial passes, each time correctly, until what was left was plainly smaller than what the owner wanted — and no check saw it. `vision.md` belongs to the owner: **an agent writes no section of it**, it only asks and transcribes. A UC or BR that finds the direction wrong → one line in `## Reverse ledger` and a question, never a quiet edit.

The spec/doc boundary: **the customer can feel it → spec** (`specs/`). Only the builder cares → doc (`specs/adr/`, `specs/<craft>/adr/`, `specs/decisions.md`). The process trace between agents (questions, review minutes, maps) → `notes/{hoi-dap,soat,ban-do}/`, **outside `specs/`**. How far along we are → `STATE.md` at the root.

## Three levels of place: root · core · craft (7.0)

The `specs/` tree is no longer split by `contexts/` — "bounded context" as a **folder unit** is gone (T3, 2026-09-18). The new axes are **`core | <craft>`** × **`br-###`**:

```
specs/
  vision.md · glossary.md · rules.md · architecture.md · decisions.md · adr/   ← ROOT: across the whole project
  changes/ · traceability.md
  core/entities/<Name>.md · core/br-###/{br.md, evidence.md, use-cases/…}      ← CORE: shared, a sibling of a craft
  <craft>/{glossary.md, rules.md, adr/, entities/<Name>.md, br-###/…}          ← CRAFT: ONE craft open at a time
notes/{hoi-dap,soat,ban-do}/                                                   ← process trace, outside specs/
tests/use-cases/<core|craft>/UC-###/AC-#.test.*
```

- **A craft** = one area of the business (eBay · Khai Kids · …), one folder each. `core` is the shared core, a **sibling** of a craft.
- **A slice** = one `BR-###`, one `br-###/` folder. One BR sequence for the whole project, never restarted per craft. Every BR declares `- **Slice:** <core | craft> · <slice name>`, and the slice name must appear in the `## Crafts and slices` table of `vision.md` — `br-check` is red when it is missing, when the craft does not match the folder, or when it is not in the table.
- **The boundary rule:** the root `specs/*.md`, `specs/adr/` and `specs/core/` **cite no craft's IDs**; a craft cites the root and `core` freely. `src/core` **does not import** `src/<craft>`. Core knows nothing of a craft; a craft knows core. `layer-check.sh` checks it mechanically; the githook `pre-commit.d/20-layer-boundary` blocks new debt.
- **One craft open at a time.** The next craft opens when the previous one is "done" by the `## What "done" means per craft` section of `vision.md` — not when it feels exciting.

The reading order of a new session: `STATE.md` → `specs/vision.md` → the root `specs/glossary.md` then `specs/<craft>/glossary.md` → the entity files the UC names → the UC plus the `RULE-###` it cites → `specs/decisions.md` and the ADRs → the source brief (`brief_path`). `context.sh UC-###` gathers exactly that order.

## The ID system
`BR-###` · `UC-###` · `UC-###/AC-#` · `RULE-###` · `CON-###` (inside a BR) · `SCR-###-#` (a screen of UC-###) · `ADR-###` · `CHG-###` (Phase 5). Commits: `<type>(ID): description`. Tests: `tests/use-cases/<core|craft>/UC-###/AC-#.test.*`, describe `"UC-### / AC-#: name"`.

`RULE-###`, `ADR-###` and `BR-###` each have **one sequence for the whole project**, whether the file sits at the root or inside a craft — a repeated number is red at the gate.

## Phase 1 — before there is any UC
`/sdd-solo:intake` is the way in. **Step 0 is layer 0:** with no `specs/vision.md` (or one still on the skeleton) intake asks the owner in plain words — where we are going · 3–5 things that must not shrink · which craft opens first and what "done" means — and then **transcribes**, never writes it for them. Every BR has to claim a `**Slice:**` from the `## Crafts and slices` table, so without layer 0 the seven questions below have nothing to stand on.

Then seven questions (what hurts · who hurts · what it costs · what happens if nothing is done · is there a way without software · what is deliberately not being done · measured by what) produce `specs/<core|craft>/br-###/br.md`; given a brief path, another agent's brief is converted into a BR under the rule **never invent a number** — a number with no source is `___` + an Open Question, even when the brief states one. Then `br-check.sh BR-###` checks it mechanically, and `/sdd-solo:adversarial BR-###` runs the three roles *the one who pays · the one who operates it forever · the sceptic*. The sceptic asks the most expensive question of the whole layer: **is this really a BR, or a solution already chosen and written backwards into a reason?**

Every `## Out of Scope` and `## Dropped from brief` line must say **where it goes**: `→ slice ___` · `→ reopen when ___` · `→ moved to: …` for an architecture item. Deferring with no destination is deferring into nothing — no mechanism carries it there. An Out of Scope line matching a keyword in `## Do not narrow` of `vision.md` makes `br-check` red, unless that line says `deliberately narrowed — owner decided YYYY-MM-DD`.

At this layer `___` is a valid answer and an invented number is not. `br-check` only **warns** about `___`, but goes **red** when a section still holds a `<...>` placeholder.

## The 14 steps of a UC (Phase 3)
① `/sdd-solo:start UC-###` → ② **fill in the UC's content with the user** (Actor · Trigger · Preconditions · Main Flow — a display step names its SCR-ID · Alternative · Exceptions · Postconditions) → ③ the user writes the RULEs (root `specs/rules.md` or `specs/<craft>/rules.md`, DMN if needed), **an entity file for every entity the UC names + `glossary.md`** (the root one for shared words, `specs/<craft>/glossary.md` for craft-only words), and the ACs → ④ draw the mermaid flow in `UC-###.flow.md` → ⑤ Claude Design per `.sdd/prompts/design-brief.md` → ⑥ cross-check SCR ↔ E# ↔ state → ⑦ `/sdd-solo:adversarial` (3 roles, fresh session) → ⑧ **re-read with an unprimed head**: `/sdd-solo:verify UC-###` (subagent; required since 6.0.0 — there is no "shut down and re-read tomorrow" door) → ⑨ `/sdd-solo:gate` (red/green) → ⑩ `/sdd-solo:design` — produces `design.md` + `tasks.md` in the UC folder, the user reads it and catches the mismatches → ⑪ write the code against `tasks.md` → ⑫ test against the ACs → ⑬ the five self-review questions → ⑭ `/sdd-solo:close` → `/sdd-solo:state`.

Four questions to remember: **Written? Drawn? Reviewed? Past the gate?**

**⑦ → ⑧ → ⑨ must be consecutive, with no edits in between (#41).** Apply **every** finding of ⑦ (wording, labels and neighbouring files included: the root and craft glossary · the entity files · a RULE's `Applies to`) **before** running ⑧. After ⑧, **any** commit touching the spec — even pure wording — makes gate ⑨ red with *"the spec moved after the re-read"*, because the gate requires the re-read commit to be the newest spec commit; editing after ⑧ means accepting a re-verification (since 6.3.0: `/sdd-solo:verify UC-### --since` reads only what changed). Real runxops case, UC-014: a round of wording fixes applied after verify → the gate went red; the rule was right, it had just never been written down for whoever was doing the work.

**Do not use another plugin's spec-generating commands for steps ② ③ ④.** They write into their own tree and ID system (`docs/`, where `BR-###` means a *rule*), while the DoR gate reads `specs/` and `BR-###` means a *requirement* — so the githook passes a commit tagged with an ID whose heading exists but means something else. The measurements and the specific command names are in CHANGELOG 3.x (#29); the hard rule here deliberately names nobody's commands (4.0.0).

**A step skipped on purpose gets one line in the UC file: `**Skip step <symbol>:** <reason>`.** Skipping with a recorded reason and skipping without anyone knowing produce **the same bytes on disk**, but six months later only the first one can still be read back. `/sdd-solo:status` lists three states: `✓` there is a trace · `–` skipped with a reason · `?` no trace at all.

## Which question must be settled before step ②, and which can wait

A real situation, in the owner's own words: *"I can't tell whether to go research the answer or just run `use-case-spec`. The flow gives me nothing to go on."* The boundary is real, it had simply never been written down:

| What the question changes | Example | What to do |
|---|---|---|
| **The shape** of the UC — who the actor is, where the data comes from, who is allowed | *"read from the existing Excel file, or pull from the marketplace?"* · *"is the first match made by hand, or guessed by machine and approved by a person?"* | **Settle it before step ②.** A Main Flow written on a wrong assumption gets thrown away, not reworded. |
| **A value** inside a step — a threshold, a deadline, an enum, a key | *"is the join key the supplier SKU or a generated code?"* · *"how many rows do we keep at most?"* | **It can wait.** Write `- [ ] <question> (interim decision: ___)` and make it a `RULE-###` later. `gate-check.sh --pre` does not count a `___` inside Open Questions as unfilled (#23). |

The one-sentence test: *if the answer is the opposite of my assumption, does Main Flow have to be rewritten?* Yes → settle it first. No → let it wait.

## How to write each thing

**A UC** — skeleton at `${CLAUDE_PLUGIN_ROOT}/templates/skel/use-case/UC-000.md`. Required: Actor, Trigger, Preconditions, Main Flow (a "the system shows" step must name its SCR-ID), Alternative Flows (Na.), Exceptions (E#: condition → screen → message in the customer's words → what the system does), Postconditions, ACs, Screens (the table Source | Screen | What the customer sees | Action), Dependencies, Open Questions (each with an interim decision). The evidence trail — Adversarial pass, Re-read, History — lives in `UC-###.trace.md` beside it (8.0.0), never in the UC body; the body carries one `## Evidence` pointer.

**An AC** — Given/When/Then, one for Main Flow and one per E#. Do not copy the rule: write "per RULE-004". Each AC becomes exactly one test file.

**Exception vs bug** — "an expired QR shows an error and offers a new one" is an exception (goes into the spec). "The app crashes when the QR expires" is a bug (does not).

**A RULE** — `## RULE-###: name` · a one-sentence statement · which UCs it applies to · its source · its status. Project-wide rules go in the root `specs/rules.md`; rules only one craft uses go in `specs/<craft>/rules.md`. **The IDs never collide between the two** — one sequence for the whole project. Several conditions → a DMN table, with the hit policy stated, and the parameters (numbers, thresholds) in their own parameter table — `___` when not settled, NEVER an estimated number.

**An entity** — **one file per entity** (skeleton `${CLAUDE_PLUGIN_ROOT}/templates/skel/entity.md`): `specs/core/entities/<Name>.md` when every craft shares it, `specs/<craft>/entities/<Name>.md` when only that craft uses it. The file name = the entity name in the code = the name in the glossary; the shared Domain Model lives in `entities/README.md`. Write it **before** step ⑦, not after. The three adversarial roles read the entity files the UC names as input, and gate ⑨ requires them to exist; before 3.3.0 the 14-step chain named this job nowhere, so it was usually done late. Changing the model after the three roles have run means rewording the ACs — nothing is lost, but it is wasted work. Mermaid `classDiagram` (names, relations, the fields worth noting tied to a RULE-ID), then `stateDiagram-v2` for every entity with a status; every arrow names **what pulls it** — usually a `UC-###`, but **not always**: when a state changes because of the outside world (the marketplace locks the account, a clock expires it, another system pushes it), name that cause and do not paste a fake `UC-###` on it to look complete. That is why the DoR gate only asks for **at least one** arrow carrying a real UC across the entity files the UC names, not for every arrow. A state with no way out gets a note saying that is a decision.

**Flow ↔ UC** (`UC-###.flow.md`, mermaid `flowchart`) — Actor = `subgraph` (only with ≥ 2 actors) · Trigger = the first node `S([...])`, with the trigger kind in the name · Main Flow = `T#[...]` · Alternative = `D#{...}` with the condition on the edge · Exception E# = an edge labelled `|E# ...|` → the end node `X#([E#: ...])` · Postcondition = the end node `P#([...])`. **Only labels between two `|` are counted** — node names do not count, even when they contain `E#`. The DoR gate cross-checks E# **both ways**: declared in the UC with no branch in the diagram → red; a label in the diagram the UC does not have → also red. `.bpmn` is still accepted but nothing in it can be counted.

**Screens (Claude Design)** — every E# has a screen state; every entity state is visible somewhere; no button or field is drawn without a source in the UC. An empty cell in the cross-check table means the spec is missing something, not the design.

**An ADR** — only when the decision is expensive to reverse AND a reasonable alternative was rejected. It must have an Alternatives considered section and at least one minus in Consequences. The test: if the customer cares, it is not an ADR, it is a RULE/AC.

## When to use `specs/changes/` (Phase 5)
The UC has `Status: implemented` **and** the change makes an old AC no longer true. Create `specs/changes/CHG-###-slug/` (proposal, delta ADDED/MODIFIED/REMOVED, design, tasks); the baseline in `specs/` only changes at archive time. Adding a new AC without breaking an old one → still Phase 3, History v+1.

## Rules for you (the AI) in this repo
- **Need a UC's context? Run `${CLAUDE_PLUGIN_ROOT}/scripts/context.sh UC-###`**, do not go picking up files yourself. It prints exactly the part that is in effect plus exactly the RULE/CON/ADR the UC cites (5.0.0); `--why` when you only need to know what decided the UC; `context.sh BR-###` (7.4) for a slice's context: the BR's decision sections, the slice's row in vision.md, the RULEs/ADRs it cites. The three sections `## Adversarial pass` · `## Re-read` · `## History` are the evidence trail — not input for writing code.
1. Hit a number, threshold, enum or permission the spec does not state → stop and ask. Do not pick a default.
1b. **A question that needs a person goes through the `AskUserQuestion` tool, never as prose at the end of a
   message** (5.2.0, #36). Measured at runxops in one day: four "settle first" questions written as bullets at
   the end of a message → the owner had to number their own answers, and answered half of them; the same day,
   the same person, the questions that went through `AskUserQuestion` (E1/E5/E9 of UC-009, the slice of UC-012)
   → answered decisively on the spot. Prose is for the reasoning *before* the question; a question buried in
   reasoning gets skimmed. The shape: at most 4 questions per turn · 2–4 options each, every option with a
   one-sentence **consequence** · the recommended option first, marked "(Recommended)" · **`Undecided — record
   an Open Question` is always one of the options** (`___` is valid at every layer). A question that *can wait*
   (a value change, see the table above) is not asked at all — write the Open Question with an interim decision.
   An open question with no options ("what hurts?", "who hurts?") is still asked in words; this rule is for
   questions that **choose between directions**.
   **Unless there is nobody at the other end** (7.0.1, #53): a session running under another agent's brief
   (orchestrate), `/sdd-solo:adversarial --phieu`, and `/sdd-solo:verify` (which never asks) — the question goes
   into a ticket in the question log or onto an `Undecided` line, never into `AskUserQuestion`. Asking when
   nobody will click means the turn hangs until it times out.
2. When the user answers → remind them to write it into the spec and commit `docs(UC-###)` before coding on.
3. Do not write code for a UC while `.sdd/gate/UC-###.ok` is missing, or while the UC folder has no `design.md`.
4. Use exactly the names in `specs/glossary.md` (root) and in the current craft's `specs/<craft>/glossary.md`. A word spelled the same but meaning something else gets a "Not to be confused with …" in the craft glossary — read both before naming a class, a function or a test.
4b. **Do not cite a craft's IDs from the root or `core`.** Writing `specs/*.md`, `specs/adr/`, or anything under `specs/core/` and wanting to mention a `RULE-###`/`ADR-###`/`UC-###`/`BR-###` that lives in `specs/<craft>/` → stop and ask: either that thing belongs to the core (move it up), or the sentence being written belongs to the craft. `layer-check.sh` checks it; in `src/`, `src/core` does not import `src/<craft>`.
5. Do not invent figures to fill a blank; leave `___`.
5b. **A number describing real data must carry the command that produced it.** A settled business number
   (a threshold, a deadline) is a decision and needs none; but *"427 rows are currently broken"* is a
   **measurement**, and a measurement with no command cannot be re-checked six months later. A number is the
   fastest-rotting thing in a spec: it was right when written, nobody updates it when the data changes, and a
   rotted number looks exactly like a correct one. `/sdd-solo:verify` can re-measure precisely because the
   command is in the file. The command should print **a fingerprint of the data** (source · row count · short
   `sha256` · last modified), and the spec records that fingerprint — so the next run can tell *the data
   changed* from *the spec is wrong* without guessing. A fingerprint does not catch the measuring command
   itself changing: **a measuring command makes a number re-checkable, it does not make it right.** And the
   command must **declare the data shape it assumes and stop outright if the shape has changed** — a number
   counted on a changed structure looks exactly like a correct one, so silence beats guessing. And it must
   print **both the raw and the filtered denominator** — `13/13` looks perfect, `16 raw → 3 placeholders
   removed → 13` tells the truth; a filtered ratio that does not say it was filtered is right about the number
   and still hides the part under discussion.
6. When asked to write an AC/UC/RULE: follow the template exactly, write the prose in the language the user is
   working in, and keep entity names and UC slugs in English.

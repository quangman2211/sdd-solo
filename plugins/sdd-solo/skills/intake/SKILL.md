---
name: intake
description: The first step of Phase 1 — the way into the whole process. Step 0 asks the owner and transcribes specs/vision.md (layer 0). With no argument it interviews question by question to pull an idea out into a BR-###; given a brief path it converts another agent's brief into a proper BR under the never-invent-a-number rules. The output is a specs/<core|craft>/br-###/br.md that passes br-check.sh.
disable-model-invocation: true
argument-hint: "[brief-path]"
allowed-tools: Bash Read Write Edit Grep AskUserQuestion
---

Reply in whatever language the user writes in; keep file names, IDs and slugs in English.

The way into Phase 1. `/sdd-solo:start` is step ① of a UC; this is step ① of the whole project.

**Ticket mode (7.3) — when running under another agent's brief** (the brief opens with `Vai:`/`Lượt`, or
`bash .sdd/scripts/role.sh --xem` reports a role other than the coordinator, or you are not sure there is a human at
the other end): **do not open `AskUserQuestion`** — nobody clicks it and the turn hangs until it times out (#53).
Every question you would have asked becomes a ticket: `bash .sdd/scripts/phieu.sh new "<task>" <role>` with
Question · Already looked up · If chosen wrong · The agent leans towards; leave whatever depends on it as `___` plus
an interim decision; then **STOP**, ending with `role.sh --ketqua <key> ket=chan hoi=#<n>`. When the owner types this
command themselves in their own session, ask as normal.

Pick the mode:
- **`$1` empty → interview.** The default mode and the most common situation.
- **`$1` is a file path → conversion.** Read the brief and split it into a BR under the rules in `references/brief-conversion.md`.

Before starting, read `specs/_intake.md` in the repo (the paper version of the question set) and
`specs/core/br-000/br.md` (the sample `BR-000`). If a real BR already exists (any `specs/*/br-*/` folder other than
`core/br-000/`), ask the user whether they want a new BR or to edit an existing one — **with `AskUserQuestion`**, one
option per existing BR. The seven interview questions of the interview mode are open questions, asked in words as written; the
`AskUserQuestion` rule (sdd-process 1b) is only for questions that choose between directions.

---

## Step 0 — layer 0, `specs/vision.md`, before any BR question

**Run this before both mode A and mode B.** Every BR has to declare `- **Slice:** <core | craft> · <slice name>` and
the slice name must be in the `## Crafts and slices` table of `vision.md` — `br-check` is red without it. Without
layer 0 the seven questions below have nothing to stand on, and the BR that comes out is red on its first check.

Check:

```bash
cat specs/vision.md 2>/dev/null | grep -n 'Positioning\|Do not narrow\|Crafts and slices' -A3
```

No file, or the sections are still the skeleton (`<One sentence: what this product is…>`, `<keyword 1>`, `___` under
`| Craft |`) → **ask the owner, three questions, one per turn, in plain words**:

1. *"What is this product, who is it for, and what makes it different? One sentence, the way you would say it to a friend."*
   → `## Positioning`
2. *"Name 3–5 things that must NOT shrink, however much gets cut later. What are they?"*
   → `## Do not narrow`, one line each: `- **<short keyword>** — <explanation>`. **The keyword must be the phrase
   someone would actually write in Out of Scope** ("write path", "offline"), not the whole sentence — `br-check`
   compares the keyword against every Out of Scope line of every BR.
3. *"Which craft opens first? And what does 'done' mean for it — what tells us we can open the next one?"*
   → `## Crafts and slices` (the table) and `## What "done" means per craft`.

**The discipline of step 0 — quite different from the seven BR questions:**

- **The owner writes it. You only ask and TRANSCRIBE.** Do not invent a "do not narrow" item, do not name a craft,
  do not fill in a "done" condition. If the owner says something ungrammatical, transcribe the ungrammatical
  sentence; do not improve it — improving it adds meaning.
- **Layer 0 is exempt from the "no numbers" rule.** A number here is **the owner's intent**, not a fact needing a
  source: *"the pack runs 7 consecutive days with no developer fixes"* records the 7 as written, no `___`, no demand
  for where it was measured. This is the only exception in the whole process — every layer below still forbids a
  number with no source.
- **Anything the owner has not thought about stays `___`** plus a `## Open Questions` line. "Not sure which craft
  opens next" is a valid answer.
- **Read the whole file back to the owner and wait for their agreement** before moving to the BR. If layer 0 is
  wrong, every adversarial round below will defend a wrong direction very diligently.

`vision.md` already properly written → read `## Do not narrow` and `## Crafts and slices`, say them back to the owner
in one sentence, and move on. Change nothing.

Its own commit: `git add specs/vision.md && git commit --only -m "docs(vision): layer 0 — <the one-sentence positioning>" -- specs/vision.md`.

---

---

## The mode body — read exactly one, now

Step 0 above and part C below apply to both modes and stay here. The body of the mode itself is in a file beside
this one; read it **before** asking the first question.

| `$1` | Read | It contains |
|---|---|---|
| empty | `references/interview-mode.md` | the discipline (one question per turn), the seven questions, what to do with the answers |
| a file path | `references/brief-conversion.md` | splitting the brief into a BR, `brief_path` in `.sdd/config`, anchoring the brief version in `br.md` |

Full path: `${CLAUDE_PLUGIN_ROOT}/skills/intake/references/<file>`. If the variable is not substituted:
`find ~/.claude/plugins -type f -name <file> -path '*sdd-solo*intake*' | head -1`.

Read one, not both. Nothing in Step 0 or part C depends on the other mode.

## C. Finishing (both modes)

1. **Ask which slice and which craft — before creating files.** With `AskUserQuestion`: one option per existing craft
   (`specs/<craft>/`, plus `core`), and one *"a new craft"* option. The craft follows from that; the slice name comes
   from the `## Crafts and slices` table of `vision.md`. A slice not in the table → ask the owner whether to add a row,
   **and only add it once the owner agrees** — `vision.md` belongs to the owner.

   `core` is the shared core, a **sibling** of a craft: choose `core` when every craft uses this slice (login, console,
   shared infrastructure). Unsure → ask, do not default to `core`.

2. **The BR number is the next one in the WHOLE PROJECT.** One `BR-###` sequence across every craft, never restarted:

```bash
ls -d specs/*/br-*/ 2>/dev/null | sed 's|.*/br-||; s|/$||' | sort -n | tail -1
```
   The largest + 1. Skip `br-000` (the sample).

3. **Create the slice:** copy `${CLAUDE_PLUGIN_ROOT}/templates/skel/br/` (`br.md` + `evidence.md`) to
   `specs/<core|craft>/br-###/`, replacing every `BR-000` with `BR-###`. A new craft → copy
   `${CLAUDE_PLUGIN_ROOT}/templates/skel/nghe/` to `specs/<craft>/` first (`README.md` · `glossary.md` · `rules.md` ·
   `entities/README.md`), and add the craft name to `nghe_paths=` in `.sdd/config`. (If the variable is not
   substituted: `find ~/.claude/plugins -type d -name skel -path '*sdd-solo*' | head -1`.)

   Write the line `- **Slice:** <core | craft> · <slice name>` into Metadata — **exactly the wording used in the
   `vision.md` table**. `br-check` is red when this line is missing, when the craft does not match the folder holding
   the BR, or when the slice name is not in the table.

   This is the first real BR → **delete the whole sample folder `specs/core/br-000/`**. A sample BR is useful exactly
   while there is nothing else to read. After that it is a FAKE ID SEQUENCE: `BR-000` carries its own
   `CON-001/002/003`, and `id_exists()` looks a CON up by grepping *the first matching line*. Real case at runxops:
   `UC-009` cited `CON-002` and the DoR gate matched *"payment records kept for 10 years under accounting rules"*;
   `architecture.md` said *"No eBay API calls. `CON-001` — personal account…"* and `design-check` reported green by
   pointing at *"shared hosting"*. That UC passed the gate with citations pointing at the wrong sections. To read the
   sample BR again, it is still in the plugin at `templates/project/specs/core/br-000/br.md`.

4. Draw the Impact Map: `WHY → WHO → HOW → WHAT`, and **at least one `-.->` branch** for Out of Scope.
   No dashed branch means nothing was mapped — just a straight line from the Goal down to work already decided on.
5. Run the check and print the output verbatim:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/br-check.sh" BR-###
```
(if `${CLAUDE_PLUGIN_ROOT}` is not substituted: `find ~/.claude/plugins -type f -name br-check.sh -path '*sdd-solo*' | head -1`).
Any ✗ → fix it with the user and run again. A `___` warning is **normal in Phase 1** — say so clearly, so the user does
not think they did something wrong.
6. Commit: `git add <br.md, evidence.md, and vision.md if edited> && git commit --only -m "docs(BR-###): intake — <BR name>" -- <exactly those files>` — name them explicitly, never `specs/` (P-29: `git add specs/` sweeps up another role's half-finished file).
7. STATE.md: `Working on: BR-### · Phase 1 — the BR is written`. `Next: /sdd-solo:adversarial BR-### (the three BR-layer roles), then /sdd-solo:start UC-### for the first UC`.
8. Tell the user two things: the remaining `___` are debt on the books, not mistakes; and the next step
   `/sdd-solo:adversarial BR-###` will question this very BR through three roles, especially the sceptic —
   *"is this really a BR, or a solution already chosen and written backwards into a reason?"*

Do not write code. Do not do technical design. Do not create a UC folder — that is `/sdd-solo:start`'s job.

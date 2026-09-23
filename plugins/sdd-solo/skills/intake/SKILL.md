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
- **`$1` is a file path → conversion.** Read the brief and split it into a BR under the rules in part B.

Before starting, read `specs/_intake.md` in the repo (the paper version of the question set) and
`specs/core/br-000/br.md` (the sample `BR-000`). If a real BR already exists (any `specs/*/br-*/` folder other than
`core/br-000/`), ask the user whether they want a new BR or to edit an existing one — **with `AskUserQuestion`**, one
option per existing BR. The seven interview questions in part A are open questions, asked in words as written; the
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

## A. Interview mode

**The discipline of this mode matters more than the question set:**

- **One question per turn.** Ask, wait for the answer, then ask the next. Never put all seven out at once — someone
  who is still vague will answer none of them.
- **Say back what you just heard in one sentence, then ask the next.** "So it is ___, is that right?" This is the
  cheapest place to catch a misunderstanding, and it shows the user they are being heard.
- **"I don't know" is a valid answer.** Write `___` and an Open Question line. Do not push.
- **You may suggest a COUNTING FRAME, never a THRESHOLD.** The two rules "do not suggest numbers" and "the way of
  measuring may not be empty" collide for someone who has never measured anything — they need an example, and every
  example carries a number. The boundary: *where to count · what to count · how often* may be offered; **the
  threshold inside that frame may not**, and stays `___` even after the user nods.
  A safe phrasing: *"for counting, something like: every Sunday go through each channel and count the messages that
  waited a long time for a reply — could you do that? And how long 'a long time' is, we leave open for now."*
- **A number the user merely nods at, that YOU proposed, is not yet theirs.** Someone who is still vague will nod to
  move on. Required: leave `___` at the threshold, **and** write an Open Question line saying explicitly *"this
  number came from the interviewer; the user has not decided"*. Without that line, six months later nobody can tell
  the user's numbers from the machine's.
- **Do not propose features.** If the user asks "what should we build", answer with a question about the problem.
  This step is for understanding, not designing.
- **If the user answers question 1 with a solution** ("I want to build a dashboard"), do not put it in the Goal. Ask
  back: *"what would that dashboard let you know that you do not know now?"* A BR written backwards from a solution
  is the most expensive mistake at this layer.

**The three required questions** — do not write the file until these are done:

1. What hurts right now? (tell it plainly, no polish needed)
2. Who is hurting? (you · the customer · whoever operates it · another system)
3. How do they cope today, and what does it cost? (time · number of mistakes · money — `___` if unknown)

**The four digging questions** — only once the first three have answers, and they may end in `___`:

4. If nothing is done for another six months, what happens?
5. Is there a way to get that **without building software**? (buy one? change the process? hire someone?)
6. What are you **deliberately not doing** in the first version?
7. How will you know it is done? Which number, taken from where?

Question 5 is the most skipped and the most valuable — it is the only thing that stops you building software that need
not exist. Do not rush past it because the user is excited.
Question 6 produces Out of Scope; question 7 produces Success Metrics.

**Question 5 alone may offer options** — a deliberate exception to "do not propose features". Someone who has not
thought about it cannot list non-software routes themselves, so offering nothing means dropping the question
altogether. Two constraints: only **non-software** options (change the process, do it by hand in batches, buy an
existing tool, hire someone, a shelf and a label), and offer **at least three**, so the user is not walked into one
and nodded through it.

**"I haven't thought about it" is a result for question 5, not a blank.** Write one line into `## Background`:
`**Why still build:** no reason yet — the user has weighed no non-software option`, plus an Open Question. Do not turn
that line into a sentence that sounds as if the weighing had been done. `br-check` warns while that line is missing,
and the sceptic role in `/sdd-solo:adversarial BR-###` will push straight on it.

**Writing it out:**

- Questions 1 + 3 → `## Background`. Only what the user actually said. A number the user gives is recorded with its
  source ("I counted them by hand in the inbox last week"). No source → down to Open Questions.
  **Since 5.0.0, Background in `br.md` is a TABLE OF CONTENTS, not an evidence store:** one `### heading` per point
  plus a line `→ evidence.md`, and the `**…:**` lines (such as `**Why still build:**`). The body — measurements, long
  quotes, tables — goes into `evidence.md` **next to the `br.md` of the same slice**, under a `### heading` of the same
  name. Measured at runxops: `## Background` alone was 31.8 KB across 15 evidence items, and every later reading of the
  BR had to wade through it just to learn the Goal and the Scope. Evidence is what makes a BR stand up *while it is
  being written*; after that it is a trail.
  In a new slice, just write into the two files, no tool needed. A repo **still on the 6.x layout** (a combined
  `specs/br.md`) whose `## Background` has bloated: `bash .sdd/scripts/migrate.sh --evidence BR-### --dry-run` and then
  for real — that flag only understands the 6.x tree; in the 7.0 tree `migrate.sh --layout v7` already split out an
  `evidence.md` per slice during the move.
- Questions 1 + 2 → `## Goal`, **one sentence**, in the shape "who can do what that they cannot do now".
- Question 7 → `## Success Metrics`. Numbers may freely be `___`; **the way of measuring may not be empty**. No
  analytics yet → write the hand-counting method — "count the threads in the inbox every Monday" is a valid measurement.
- Question 6 → `## Out of Scope`, and each line becomes a `-.->` branch on the Impact Map. **Every line says where it
  goes:** `→ slice ___` (which slice in `vision.md` picks it up) or `→ reopen when ___` (the condition). And before
  writing, check against `## Do not narrow` in `vision.md`: any line matching a keyword there → **ask the owner** —
  either that line comes out of Out of Scope, or the owner settles it as a deliberate narrowing and the line records
  `deliberately narrowed — owner decided YYYY-MM-DD`. Do not pick a branch yourself; `br-check` is red without that label.
- Question 5 → **always** write a `**Why still build:** ...` line into `## Background`, whatever the answer was. A
  non-software option exists and the user still chooses to build → record the reason. Not thought about → write
  *"no reason yet"* + an Open Question. That line is the only thing in a BR that can say this software was shown to
  need to exist.
- Question 4 → `## Background`, or a `CON-###` if it is a timing constraint.
- Candidate UCs → `## Related Use Cases`, **ID + name only**. Do not write UC detail here.

---

## B. Brief conversion mode

Read the file, then split it into four parts: why (the BR) · who does what (candidate UCs) · constraints (CON) ·
unclear (Open Questions).

**Step 0 applies to this mode too.** A brief is another agent's words; layer 0 is the owner's. The brief asks for
something that contradicts an item in `## Do not narrow` → **the owner wins, the brief loses**, and that line goes
down into `## Dropped from brief` with a destination.

**Before filling in Goal / In Scope: ask the user three questions in words, one per turn — required, even when the
brief already answers them (#46, #47).** Real runxops case: BR-003 was converted straight from a brief; both sceptic
roles (BR-003, BR-002) concluded *"a solution written backwards into a reason"*; two things surfaced **afterwards** —
*"the cause of work falling through = not being told"* and *"run it for myself before selling it"* — and they changed
the plan more than every technical finding put together. A brief is another agent's words; these three questions are
the words of the person paying.

1. *"What hurts, and why does it fall through?"* (the cause, not the symptom)
2. *"Build it to run for you first, or go ask customers first?"*
3. *"Once v1 is done, what do you open every day to do your work? What can you change yourself without a developer?"*

Record the answers **verbatim**, with a trail, into the file — not into something said:
- 1 → `## Background`, the line `**What pain, why it lands:** "<verbatim>" (asked in words, <date>)`; and `## Goal` is
  written from this answer, not from the brief.
- 2 → `## Background`, the line `**Run it for ourselves first or sell it:** "<verbatim>" (asked in words, <date>)`.
- 3 → `## In Scope`, as the first line `**Opened every day:** "<verbatim>"` — this **must be** in In Scope before
  anything is cut; if it contradicts the brief, the brief loses and that goes into `## Dropped from brief`.
`br-check` warns when a BR has `**Source:** brief` but Background has no `**What pain, why it lands:**` line.

**The required rules — no exceptions:**

1. **Never invent a number.** Every threshold, deadline, quota or permission the brief does not give a **source** for
   → write `___` and add a specific Open Question. Even when the brief **does** state a number: with no source it is a
   *proposal*, not a decision. Write `___ (the brief proposes 15, nobody has approved it)`.
2. **Push every feature back up a layer.** Every "build X" item must answer *which goal X serves, measured how*.
   Pushing back reaches no goal → mark it an **orphan feature** and put it into Out of Scope or an Open Question. Never
   keep it silently.
3. **A claim without evidence does not go into Background.** A brief often says "customers complain a lot about…"
   with no number. That becomes an Open Question *"where does this number come from?"*, not a fact in Background.
4. **Record what was dropped — in the FILE, not on the screen.** Every sentence or item in the brief not carried into
   the spec becomes a line `- <item> — <reason> → <destination>` in the BR's `## Dropped from brief` section, and only
   then is read back to the user. **The destination is required since 7.0** — `→ slice ___` (which slice in
   `vision.md` picks it up) · `→ reopen when ___` (the condition) · `→ moved to: <architecture.md · ADR-### · CHG-### ·
   Open Question>` for anything in the design layer. `br-check` is **red** when a line has no destination; it no longer
   only warns. Version 3.2.0 only said "print the list", so the entire product of this rule lived in speech: close the
   terminal and it is gone, and six months later nobody knows what the brief contained or why it vanished. The three
   rules above all leave a `___` or an Open Question in the file; this one must leave a trail too. See #21.

   **Dropping and deferring are two different things.** A reason of the form *"belongs to the design layer"*,
   *"belongs in an ADR"*, *"belongs to Phase 5"*, *"later"* is a **deferral**, and a deferral must record a
   DESTINATION: `→ moved to: architecture.md · ADR-### · CHG-### · Open Question`. With no destination nothing carries
   it: each UC's `design.md` is produced by `/sdd-solo:design`, and that reads the brief **only when** `brief_path` has
   been declared. The most common destination of a deferred architecture item is `specs/architecture.md` (root,
   project-wide), section `## Settled from brief`. Real case (`runxops`, #34): the line *"the whole three-layer
   architecture — belongs to the design layer"* sat still for two days while `plan.md` was written with an architecture
   **opposed to the brief**, and nobody saw it because both sides were internally consistent. A forwarding address
   nobody delivers to looks exactly like a completed handover. `br-check` is red when a deferred line has no
   `→ moved to:` (7.0).

5. **Do not write the UCs.** Only produce the IDs + names of candidate UCs.
6. **Record the source in the BR's Metadata:** the line `- **Source:** brief <path>`. That is what tells `br-check.sh`
   this BR must have a `## Dropped from brief` section.
7. **Anchor the brief — two jobs, both required.** After intake the brief becomes a **write-only** file: all three of
   the plugin's checking layers (`gate-check`, `verify`, the three adversarial roles) look only inside `specs/`. So it
   has to be brought into view by hand:

```bash
# a) declare it in .sdd/config — this puts the brief into the REQUIRED READING ORDER of every later session.
#    A repo initialised before 3.21.0 has NO brief_path= line, and `sed` on a line that does not
#    exist silently does nothing — so ask first, then pick the branch.
if grep -q '^brief_path=' .sdd/config; then
  sed -i.bak "s|^brief_path=.*|brief_path=$1|" .sdd/config && rm -f .sdd/config.bak
else
  printf 'brief_path=%s\n' "$1" >> .sdd/config
fi
grep '^brief_path=' .sdd/config        # print it, to see that it really went in
# b) anchor the brief's version in br.md — if the brief changes after intake, br-check goes red
printf '**Brief source:** %s · sha256 %s · loaded %s\n' \
  "$1" "$(shasum -a 256 "$1" | cut -c1-12)" "$(date +%F)"
```
   Paste the `**Brief source:**` line into the BR's Metadata, right under `- **Source:**`. Without (a), later sessions
   do not know the brief exists; without (b), the brief can be edited at any time with nobody knowing, and two
   documents contradict each other in silence.

**The number boundary — which numbers are forbidden and which are not.** Rule 1 forbids numbers in a **business
decision**: thresholds, deadlines, quotas, permissions. It does **not** forbid numbers in a **way of measuring**:
"time 20 consecutive table bookings" is a concrete measurement and far better than "time a few bookings". A vague
measurement makes the metric uncheckable, which loses exactly what `BR-000` is teaching. Being concrete about the
measurement is right; being concrete about a decision nobody approved is invention.

Why these rules are strict: a brief written by an LLM almost always carries plausible numbers nobody decided —
*"lock for 15 minutes after 5 failures"*, *"hold stock for 30 minutes"*. Copied straight into `specs/`, all 24 DoR gate
checks will defend those silent numbers very diligently from then on. That is exactly what `sdd-process` calls a silent
decision, except the model filled it in before the repo existed.

---

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

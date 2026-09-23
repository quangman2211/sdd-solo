---
name: verify
description: Re-read the documents with an unprimed subagent to find where the spec contradicts itself or claims something untrue. UC-### is step ⑧ — the only door of the DoR gate since 6.0.0; CHG-### is the door of the Phase 5 gate; no argument sweeps the whole specs/ tree. Use it before a gate, or when the documents just changed a lot and you need to know what still disagrees.
disable-model-invocation: true
argument-hint: "[UC-### | CHG-###] [--since <commit>] [--no-commit]"
allowed-tools: Bash Read Write Edit Grep Glob Agent
---

Reply in whatever language the user writes in; keep file names, IDs and slugs in English.

A verify pass for `$1`.

`UC-###` → **part A** (step ⑧). `CHG-###` → **part A** with the five differences in **A′**. `--since` → **A″**
(reading only what changed since the previous re-read). No argument → **part B** (the tree sweep).

**Verify never asks** (7.0.1, #53). No `AskUserQuestion`, in any part, whoever calls it. Every `F#` gets one of the
two outputs the agent can write itself — rejected with a reason, or `Undecided` with a question and a proposal —
and is then **written and committed**. Whoever decides reads `## Re-read` afterwards and answers in conversation;
applying those answers is a spec round, and re-reading it is `--since`. Why: the real runxops case where verify ran
inside a subagent session (role C / A's brief) and opened `AskUserQuestion` — nobody was there to click, the turn
hung until it timed out, and `## Re-read` was never written. Up to 7.0.0 the skill had a branch "do not ask when
nobody will answer", but an agent cannot be sure which branch it is in; a rule with no branch cannot be guessed wrong.

**Layout:** every path below is written for the 7.0 tree. A 6.x repo (no `migrate --layout v7` yet) has UCs in
`specs/contexts/<ctx>/use-cases/`, the BRs in `specs/br.md`, the RULEs in `specs/rules.md`, the entities in
`specs/contexts/<ctx>/entities.md`, and the logs and traces in `specs/internal/`. `context.sh` looks in both trees —
use it rather than picking up files yourself.

**Why this skill exists:** the writer cannot read what they just wrote — the eye reads *intent*, not *words*. Step ⑦
already answers that need, with a fresh session for the three roles. Step ⑧ needs **the same thing**, and before
3.5.0 it bought it with a night on the calendar. A night measures **time passing**, not **whether the reading
happened** — the same person, the same priming, a 30-second skim the next morning still passes the gate. From 3.5.0
to 5.2.0 the two doors lived side by side; **6.0.0 (#38) removed the overnight door** — verify is required at both
the DoR and the Phase 5 gate, because the cheaper door is the one that gets used.

---

## A. `/sdd-solo:verify UC-###` — step ⑧

1. Find the UC: `find specs -path "*/use-cases/$1-*/$1.md" -not -path '*/_template/*'` (7.0:
   `specs/<core|craft>/br-###/use-cases/`; 6.x: `specs/contexts/<ctx>/use-cases/`). Not there → stop and say so.
2. Check step ⑦ has run: the `## Adversarial pass` section must have real content. It does not → stop and tell them
   to run `/sdd-solo:adversarial $1` first. Re-reading before the review is re-reading a draft about to change.
3. **Run verify in its own subagent** (the Agent tool). This is the part that may not be shortened: a subagent
   **has none of the writing session's context**, so it is unprimed **by construction**, not because somebody said
   it was. The prompt is the content of `.sdd/prompts/verify-pass.md`, plus:
   - the output of `"${CLAUDE_PLUGIN_ROOT}/scripts/context.sh" $1 --brief` — the UC (three evidence-trail sections
     stripped), the flow, the RULE/CON/ADR it cites, the parent BR, architecture (Forbidden · Boundaries · Runs
     where), the entities and glossary. `--brief` (6.5.0) cuts each ADR to the first paragraph of Decision and drops
     Stack/Callers — verify reads behaviour; the per-source size lines at the end say which source is still
     bloating. **Plus** `$1.sequence.md` if there is one, and **the whole of `specs/rules.md` and of the
     `specs/<craft>/rules.md` of the craft the UC belongs to** (verify also looks for a rule the UC does *not*
     cite but should — that is error kind #4, and context.sh deliberately does not print uncited rules). For a UC
     in `core`, include only the root `specs/rules.md`: the core may not cite a craft's rules, so a craft rule that
     "should have been cited" there is the opposite finding — record it as an `F#`, do not feed it in as input.
   - `git log --oneline -20 -- <UC folder>` so error kind #2 can be checked (the commit says one thing, the file
     another — compare the claimed **content** against the diff, not the file list; a missing neighbouring file is
     only a warning, #42)

   **A verify round ends with the re-read commit, not with a report (#40).** Real runxops case, UC-014: the subagent
   returned 19 findings, the main agent printed *"Reporting back: 19 findings. Read them verbatim and check each one
   before writing."* and went idle — `## Re-read` still said `Run date: ___`, and it took another turn to get a
   commit. Run by an automated agent under a brief (with nobody to type the next turn), *"stopping to wait"* means
   **stopping for good**, and gate ⑨ is red although the reading did happen. Steps 4 → 5 → 6 → 7 are **one round**:
   the report coming back means going straight on to step 4 and then 5, not stopping to *"check them first"* —
   checking them **is** step 4, and the result of the check goes straight onto the `F#` line (rejected →
   `→ false positive because`). There is no "let the user see the report first" exception: to see it first, use
   `--no-commit` (step 7), and the `## Re-read` section still has to be written on this round.

   **If the spec contains a number describing real data** (row counts, ratios) the subagent must be allowed to
   **run the measuring command** — that is error kind #7, and it is the only kind that cannot be found by reading.
   If the spec has no measuring command, that absence **is itself a finding**; do not invent a command and treat it
   as checked.
4. **Check each `F#` — the main agent does it, asking nobody** (#53). Read both disagreeing places verbatim exactly
   as the subagent quoted them, then write **one** of the two outputs:
   - → `false positive because <reason>` — only when the reason is **traceable in the repo** (a spec line, an ADR, a
     commit) and the other two places do not contradict it. **Rejecting must be cheap**, one line is enough; but
     **the reason is recorded**, so the next run does not dig up the same sentence.
   - → `Undecided (waiting on the owner: <one-line question> · proposal: <ID of the place to fix>: <new wording>)` —
     everything else, obvious wording and label fixes included. The proposal is **one** concrete fix carrying an ID
     (`UC-009 Main 7` · `RULE-001` · `AC-6`), so the owner can answer with *"apply F3 F5, and for F7 …"* instead of
     reading it all again. For a question that changes the shape or a business value: the proposal says `___` with
     two directions and what each one costs — never choose for them.

   There is no third output. `→ fix the spec` and `→ Open Question` are outputs of the **applying round** after the
   owner answers (overwriting the tail of that `F#` line, then `--since`), not of the reading round.

5. Write into **`UC-###.trace.md`** — beside the UC, 8.0.0: the trail never goes in the UC body again, the body
   keeps only its `## Evidence` pointer, and the gate reads the section here — into its `## Re-read` section, **exactly this shape, because the gate reads it mechanically**:
```
## Re-read
- Run date: YYYY-MM-DD · Unprimed head: subagent
- F1 <finding> [anchor: Main 7 · RULE-003] → Undecided (waiting on the owner: <one line> · proposal: UC-009 Main 7: <new wording>)
- F2 <finding> [anchor: AC-6] → false positive because <reason>
```
   (After the applying round, F1 becomes `→ fix UC-009 Main 7`.) The gate checks that every ID after `→` exists on
   every line **except** an `→ Undecided` line — a proposal may point at an AC/RULE that does not exist yet.
   The gate requires **at least one** `F#` line carrying **both `[anchor: ...]` and an output other than `___`**.
   That is the whole anti-faking lock: faking such a line costs exactly as much as reading for real.
   (A project writing its documents in Vietnamese uses `## Đọc lại` · `Ngày chạy` · `[neo: …]` · `không phải lỗi vì`
   — the gate accepts both sides of the keyword table; write whichever language the rest of the file is in.)
6. **The reading round does not edit the spec** — nothing is chosen on this round. The owner answers the `Undecided`
   lines → the **applying round**: edit the spec per the answers, rewrite the tail of each `F#` line
   (`→ fix UC-009 Main 7` · `→ Open Question` · `→ false positive because`), then `/sdd-solo:verify $1 --since`.
   On the applying round, **SWEEP THE WHOLE TREE BEFORE COMMITTING — required, never skipped:**

```bash
# for EVERY number / decision that just changed, find the OLD value across the whole tree
grep -rn '<old value>' specs/ scripts/ *.md
```
   Any hit **outside** `## History` and **outside** a sentence shaped `<old> → <new>` means **not done yet**. The
   places most often missed (measured at #48: 14 out of 18): the root and craft `glossary.md` · the entity files the
   UC names · `$1.sequence.md` · a RULE's `Applies to` line (in both `specs/rules.md` and `specs/<craft>/rules.md`) ·
   `$1.flow.md` · the ADRs cited · the `## Related Use Cases` table in the slice's `br.md`. `gate-check.sh --pre $1`
   warns about three of those mechanically — run it before committing.

   **Sweep for the NEW value too, not only the old one.** The fixing step **creates its own errors**: changing to a
   `RULE-###` that has no heading, changing and changing back, mistyping an `AC-#`. Sweeping for the old value finds
   none of those — they are *new* values in the wrong place.

   **And the `## Re-read` section is NOT exempt.** It records the fixing, so it **drifts like everywhere else**, and
   it drifts during the very round that is doing the fixing. Real case (`runxops`): a change `RULE-006 → RULE-007`,
   then `RULE-007` turned out to have no heading so it was changed back — **the body was fixed, the `F#` line
   recording the fix was not**. The gate caught it; verify did not, because verify had already finished.
   **The place that records a fix is also a place that has to be fixed.** (`gate-check` now checks that every ID
   declared inside `## Re-read` exists — the same §7 rule as for adversarial, #12.)

   **Why this sweep lives here and not in `verify-pass.md`:** the sweep rule only means anything **after** the fix —
   before the fix there is no "old value" to sweep for. And the two verify roles run **before** the fix. Putting that
   rule in their prompt puts it into a mechanism that **cannot run it by construction** — which is not a matter of
   anyone forgetting, it is **the wrong step**.

   Real case (`runxops`): the old pair of numbers sat in **four** places — an entity file · the slice's `br.md` · a
   script's docstring · and the plugin's own prompt. **Two verify roles reading very carefully still missed the
   fourth.** What caught it was a `grep -rn` run **after** the fix. A reader cannot see a place they never thought
   existed; `grep` does not have to think.

7. Then commit **on its own, with exactly this subject** — the gate recognises it by this:
```bash
git commit --only -m "docs($1): re-read — <n> findings, <m> to fix" -- <the UC-###.md file (or proposal.md)>
```
   (A project writing in Vietnamese commits `docs($1): đọc lại — …`; the gate accepts both.)
   With `--no-commit` → **still write** `## Re-read` at step 5 (that is the round's product), only skip this commit;
   say clearly to the user that gate ⑨ **stays shut** until that commit exists and is the newest spec commit. No flag
   skips step 5.
8. Tell the user: print the **list of `Undecided` lines** — one per `F#`, with the question and the proposal — so
   they can answer in one go; `Undecided` is a valid gate output, so `/sdd-solo:gate $1` can run right now, but a
   gate passed with unanswered questions is debt the user is taking on knowingly. If this reading produced no `F#`
   line with a real output, the gate **stays shut** — since 6.0.0 there is no overnight door to fall back on. Say
   that plainly, and say what the right move is: *"found nothing"* is weak evidence (Limit 3) — widen the scope (the
   rules the UC does *not* cite, `sequence.md`, the entities, re-measured numbers) and run again, rather than
   inventing an `F#` line to get through. A `→ false positive because <reason>` line after a real reading is a valid
   output.

### A″. `/sdd-solo:verify UC-### --since [<commit>]` — re-reading only what changed (6.3.0, #49)

Real runxops case, UC-014: **six re-reads** (19 → 23 → 11 → 7 → 7 → 10 findings) because each round of fixing 1–2
behaviour places exposed 1–2 wording or label places in a neighbouring file, and since the gate requires the re-read
commit to be the newest, every wording fix dragged a **full** verify round with it (a fresh session, ~200 KB,
~10 minutes). A full re-read also rephrases old findings as "new" ones. The owner settled it: *repeat until
blocking = 0*, with the stop rule living in `verify-pass.md` (blocking = two places contradicting each other · an AC
that cannot be tested; everything else is wording debt).

Same as part A, with four differences:
1. The mark: `<commit>` if given; otherwise **the most recent re-read commit** —
   `git log -1 --format=%H --grep="^docs($1): (re-read|đọc lại)" -E -- <UC folder> specs/rules.md specs/<craft>/rules.md <the entity files the UC names>`.
   No mark at all → this is the first time, run the full part A.
2. The subagent's input **instead of** the full `context.sh`: `git diff <mark>..HEAD -- specs/` (verbatim), plus **the
   sections that were touched** in their current form (the `## …` section of the UC containing a changed line, a RULE
   with a changed line, an entity file with a changed line) and **every other place in `specs/` mentioning the same
   concept that just changed** (`grep -rn` the new value and the old value) — because error kinds #3 and #8 live
   between what changed and what did not follow. Print that scope at the top of the report. `verify-pass.md` applies
   unchanged; its *stop rule* section decides which lines are blocking.
3. Write **a new block** into `## Re-read`, without deleting the old one:
```
- Run date: YYYY-MM-DD · Unprimed head: subagent · --since <short hash>
- F12 <finding> [anchor: …] → …
```
   The `F#` numbering continues from the previous block (the gate counts every `- F#` line in the section, blocks and
   all).
4. Commit `docs($1): re-read --since <short hash> — <n> findings, <m> blocking, <k> wording debt`. The gate recognises
   the `docs($1): re-read` prefix, so this commit becomes the new mark. Since 6.3.0 the gate **passes a
   wording/label-only commit made after the re-read** (the behaviour fingerprint is unchanged:
   Main/Alt/Exceptions/Postconditions/AC · flow · RULE statements · entity mermaid); change behaviour and the gate
   goes red and prints the `--since` command with the right mark.

### A′. `/sdd-solo:verify CHG-###` — the door of the Phase 5 gate (6.0.0, #38)

Same as part A, with five differences:
1. Find it: `ls -d specs/changes/$1-*/` — it has `proposal.md` · `delta/` · `design.md`. Not there → stop and say so.
2. Step ⑦ is not required — Phase 5 has no adversarial pass.
3. The subagent's input: `proposal.md` + all of `delta/*.delta.md` + `design.md`, **plus** the output of
   `context.sh UC-###` for **each** UC the delta touches (the baseline — so a delta claiming to MODIFY/REMOVE an AC
   the baseline describes differently can be caught), the whole of `specs/rules.md` and of the
   `specs/<craft>/rules.md` of every craft the delta's UCs belong to, and `git log --oneline -20 --
   specs/changes/$1-*/`.
4. Write `## Re-read` into **`proposal.md`** (not into the baseline UC — the baseline does not change until the
   archive), in the same shape as part A step 5; the anchors point at `delta/UC-009 MODIFIED AC-3` ·
   `proposal Scope` · `UC-009 AC-3`.
5. Commit it on its own as `docs($1): re-read — <n> findings, <m> to fix`, then `/sdd-solo:change $1`.
   `change-check` §8 requires this to be the **newest** `docs($1)` commit in the change folder — editing the
   proposal or the delta afterwards means re-reading again.

---

## B. `/sdd-solo:verify` — the tree sweep

Use it when the documents just changed a lot and you need to know what still disagrees. Not tied to any gate.

1. **Pick the scope first, do not skim the whole tree.** A small tree (< ~3,000 lines) can be read whole. Larger:
   take `git diff --name-only <the previous verify>..HEAD -- specs/` plus **every file whose IDs those cite**
   (`RULE-###` → `specs/rules.md` or `specs/<craft>/rules.md`, `CON-###`/`BR-###` → that slice's `br.md`, `UC-###` →
   that UC's file, an entity name → that entity's file). Skimming the whole tree is the surest way to miss error
   kinds #3 and #4, the two most common ones.
2. Run a **subagent** with `.sdd/prompts/verify-pass.md` over that scope. For a large tree, split by layer — one
   agent for vision↔BR, one for BR↔RULE, one for UC↔AC↔flow, one for entity↔glossary — but **each agent must still
   see both sides** of the pair it is checking, otherwise it only reads half the argument.
   One extra check exists only in the 7.0 tree: **does the root `specs/*.md`, `specs/adr/` or `specs/core/` cite any
   craft's IDs** — `bash .sdd/scripts/layer-check.sh` counts it mechanically, cheaper than reading.
3. Check each `F#` as in part A step 4 — asking nobody.
4. Write the result into `notes/soat/verify-<YYYY-MM-DD>.md` (a process trace, outside `specs/`): the scope read,
   each `F#` with both sides verbatim, and its output. **Record the rejected lines too, with the reason** — that is
   what makes the next run cheaper, and the only thing left after the terminal is closed.
5. `git add notes/soat/verify-<date>.md && git commit --only -m "docs: verify pass <date> — <n> findings" --
   notes/soat/verify-<date>.md` (6.x: `specs/internal/`), then print the `Undecided` list as in part A step 8.
   Editing the spec per the answers is a separate round.

---

## Limits — tell the user, do not hide them

1. **The reason to reject must come from the person READING the findings, not the person who WROTE the spec.** Do not
   hand the subagent a list of *"context to help you reject quickly"* written by the spec's author — it will reject
   exactly the places the author believes they are not wrong, which removes the standing of the whole verify round.
2. **It produces false positives.** That is the price of reading meaning rather than counting — and the reason this
   skill is **not** a script inside the gate: a check that goes red wrongly gets learned away, and then takes the
   genuinely red lines with it.
3. **"Found nothing" is weak evidence.** Never say *"the documents are consistent"* or *"everything was checked"*.
   The correct sentence: *"this reading found nothing within the scope read"* — **with the scope listed**.
4. **It does not replace step ⑦.** The three roles ask *"what has the spec not answered"*; verify asks *"does the
   spec contradict itself"*. Running verify and skipping the adversarial pass drops the most expensive question in
   the whole process.

Do not write code. Do not edit the spec before the user has chosen.

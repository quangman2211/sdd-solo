---
name: adversarial
description: A three-role adversarial pass that reads the spec and lists the questions it does not answer. UC-### (step ⑦) uses the roles end customer / operations / abuser and asks about behaviour; BR-### (Phase 1) uses the one who pays / the one who operates it forever / the sceptic and asks about the reason for existing. It replaces the business reviewer when you work alone.
disable-model-invocation: true
argument-hint: "UC-### | BR-### [--phieu | --hoi]"
allowed-tools: Bash Read Write Edit Grep Agent AskUserQuestion
---

Reply in whatever language the user writes in; keep file names, IDs and slugs in English.

An adversarial pass for `$1`.

`$1` starting with `UC-` → **part A**. Starting with `BR-` → **part B**. Anything else → stop and ask again.

**Two modes for putting the questions — choose BEFORE running the three roles** (7.0.1, #53):

| Mode | When | Where a shape question goes |
|---|---|---|
| **ask** | the user typed the command in their own session, no flag · or `--hoi` is given | `AskUserQuestion`, one question per turn (step 5) |
| **ticket** | `--phieu` is given · or the round runs under **another agent's brief** (orchestrate: role B/C, a brief starting with `Vai:` / `Lượt`) without `--hoi` | one ticket collecting K1…Kn in the question log (step 5′), **never** `AskUserQuestion` |

Not sure which mode you are in → **ticket**. A ticket costs one extra round; a question opened in a session with
nobody in it hangs the whole round until it times out — the real runxops case (#53): adversarial ran under A's brief,
opened `AskUserQuestion`, nobody clicked, `## Adversarial pass` was never written, and A had to hand the work out
again. `--hoi` is there so A can force asking while A is sitting with the owner. Both modes use the same three roles,
the same shape/value test and the same four constraints on proposals — they differ in exactly one thing: who answers
a shape question, and when.

The question log: `notes/hoi-dap/hoi-dap.md` (the 7.0 tree) · `specs/internal/hoi-dap.md` (6.x). Missing → copy the
skeleton `${CLAUDE_PLUGIN_ROOT}/templates/skel/hoi-dap.md` (if the variable is not substituted:
`find ~/.claude/plugins -type f -name hoi-dap.md -path '*sdd-solo*skel*' | head -1`).

**The 6.x layout** (no `migrate --layout v7` yet): the BRs are in `specs/br.md` (sections `# BR-###`), the RULEs in
`specs/rules.md`, the entities in `specs/contexts/<ctx>/entities.md`, and there is no `specs/vision.md` → drop the
"Do not narrow" part, and say that you dropped it. `context.sh`, `gate-check.sh` and `br-check.sh` look in both trees.

---

## A. The UC layer — step ⑦

1. Gather the input with **one command**, do not pick up files yourself:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/context.sh" $1 --brief
```
   That output (the UC with the evidence trail stripped · the RULE/CON/ADR it cites · the parent BR · architecture ·
   the entities and glossary; `--brief` since 6.5.0: each ADR cut to the first paragraph of Decision, architecture cut
   to Forbidden · Boundaries · Runs where — the three roles ask about behaviour, not about the stack) is **all** the
   three roles get to read — hand it verbatim to each subagent at step 3. Not found →
   `find ~/.claude/plugins -type f -name context.sh -path '*sdd-solo*' | head -1`.
2. Check the preconditions with the **script**, do not judge for yourself — the four old conditions measured structure,
   so an empty template passed all of them (#11):
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/gate-check.sh" --pre $1
```
Exit ≠ 0 → **stop**, print the output verbatim, and tell the user to finish the content and run again. Do not run the
three roles on a spec that still has placeholders.
3. **Run the three roles in separate subagents** (the Agent tool, one agent per role, not using this session's context,
   so they are not primed by assumptions already made). The prompt for each agent: the content of
   `.sdd/prompts/adversarial-pass.md` in the repo, the matching role's part, plus the whole UC + the glossary (root and
   craft) + the relevant RULEs + **the entity file of every entity the UC names** (`specs/core/entities/<Name>.md` ·
   `specs/<craft>/entities/<Name>.md`, one file per entity — do not hand over the whole folder, hand over exactly the
   files the UC names). Pass the constraints verbatim: only ask, propose no code or architecture, do not edit the spec,
   at most 12 questions, ordered by consequence (money / permissions / customer data first), each question naming the
   step/E#/AC it relates to.
4. Merge the results, drop the duplicates, and write them into **`UC-###.trace.md`** — beside the UC, 8.0.0: never into the UC body, which keeps only its
   `## Evidence` pointer — into its `## Adversarial pass` section, as:
```
- Run date: YYYY-MM-DD · Fresh session: [x]
- Role end customer:
  - Q1 <question> [related: step N / E# / AC-#] → <output: ___>
- Role operations/accounting: ...
- Role abuser: ...
```
Leave the "output" column as `___` — **the user decides**, never fill it in. When the user chooses, record **the ID of
whatever was created**: `→ spec: RULE-003` · `→ spec: E4, AC-5` · `→ Open Question` · `→ Out of Scope`.
An empty `→ spec` claim cannot be checked, and `gate-check` will catch it (#12).
5. **Ask mode — put each question through `AskUserQuestion`, one question per turn** (ticket mode: step 5′, but read
   all of this step — the classification, the three things and the four constraints apply to tickets unchanged) — do
   not print 24 lines in a row and then ask "which do you want". This is the highest decision density in the whole
   process.

   **Before asking, classify with the shape/value test** (see `sdd-process`): a question that changes the *shape*
   (who the actor is · where the data comes from · who is allowed) **must be asked**; a question that changes a *value*
   (a threshold · a deadline · an enum) goes straight into an `Open Question` with an interim decision, without
   bothering anyone. Asking all 24 questions is the fastest way to make the user click through them.

   **Each question must carry three things. Missing one makes it unanswerable:**

   a. **Context = A VERBATIM QUOTE**, not a summary. A label like `[Main 7, RULE-003]` is a pointer — read what it
      points at and **paste the exact words** in. A summary is where an assumption is slipped in unseen.

      **Label vocabulary has THREE sources, not one.** Look up only some of them and the label silently loses its
      context — nothing errors, the question simply becomes a bare line again:

      | Label | Where to look it up |
      |---|---|
      | `Main N` · `Alt Na` · `E#` · `AC-#` · `SCR-###-#` · `Open Q` | the `UC-###.md` file — the numbered steps, `## Exceptions`, the `### AC-#` headings, the Screens table |
      | `RULE-###` | `specs/rules.md` (root) **and** `specs/<craft>/rules.md` — one sequence, two homes; missing one means losing the label |
      | **`CON-###`** | **the `br.md` of the slice the UC belongs to** (`specs/<core\|craft>/br-###/br.md`) — inside `## Constraints`, NOT in the UC |
      | `Background` · `Success Metrics` · `Out of Scope` · `Impact Map` | the same `br.md` |
      | an entity name | `specs/core/entities/<Name>.md` · `specs/<craft>/entities/<Name>.md` — one file per entity |

      Measured on `runxops`: 50 labels across 24 questions of one UC, 49 dereferenced; the only miss was `CON-011` —
      because it lives in `br.md`, not in the other two files. A `CON-` label usually carries the most expensive
      constraint, so missing exactly that one means missing the most important context.

      Cannot find it → **say so inside the question**: *"the label `[CON-011]` was not found in the slice's
      `br.md`"*. Do not quietly drop the label.
   b. **Every option carries what it costs.** Not "A or B" but "choosing A means E4 has to be rewritten, choosing B
      loses the ability to reconcile backwards".
   c. **`Undecided — record an Open Question` is ALWAYS a visible option**, never something the user has to type to
      escape. `___` is a valid answer at every layer of this process.

   **Four constraints on proposals — the easiest place to wreck the whole BR layer:**

   1. **The basis must be traceable in the repo, or be a command the user can re-run.** "This rule distinguishes 13
      of 13 groups on the real data, counted by `<command>`" is a basis. The model's general knowledge is **not** a
      basis — present that as *a possible direction*, never call it *a recommendation*.
   2. **No ranking, no "recommended" marker** on a question that changes a business value. Laying out the option
      space is providing information; choosing is making the decision.
   3. **A concrete value you proposed and the user merely nodded at is not yet theirs.** Write it into the spec as
      `___ (AI suggested <X>, nobody has approved it)` with an Open Question line. Only when the user says the number
      in their own words does it become a decision, and it is recorded with *"the user decided after seeing
      <the basis>"*. This is exactly the nodding trap `/sdd-solo:intake` already patched — the same trap, elsewhere.
   4. **The first three constraints live in the conversation; this one lives in the FILE.** Close the terminal and
      only the file is left. So the provenance of every number belongs in the spec, not in something said.

   For each option the user picks:
   - spec → fix it in the right place (add an E#, an AC, edit the RULE in `rules.md`, add a Screens row), then
     `## History` v+1 **in `UC-###.trace.md`** recording "after the ___ role's adversarial pass".

     **If the fix changes the ORDER of the steps — a half-done fix here is caught by no check.**
     Swap the content of two steps while keeping the numbers and every step still exists, every number is still
     there, every label still dereferences — but reading `Main Flow` from 1 downwards still produces the old order,
     which is the wrong one. Real case at `runxops`: question Q1 said *approve first, then record*; the patch swapped
     the content and kept the numbers; the half that was wrong survived a whole adversarial pass and **three gate
     runs**. The error was in the order — something only reading catches, and that is why step ⑧ *"re-read with an
     unprimed head"* exists.

     Three jobs, do all three:
     1. **Renumber** in the right order, and fix `UC-###.flow.md` to match.
     2. **Remap every label by MEANING, not by number.** After renumbering, `Main 5` may point at a completely
        different step. **A number is not an identity** — it is a position, and positions move.
     3. `## History` records **why the numbers changed**, not just "fixed". Six months later, a number that moved
        with no reason in the file makes every label untrustworthy.
   - **After every concept that just changed: grep the neighbours** (#49, #48). One concept of UC-014 at runxops was
     repeated in 3–5 places (the root and craft glossary · the entity file · the sequence · a RULE's `Applies to` ·
     the flow · an ADR); three rounds of fixing touched only the UC file → 14 of 18 verify findings were mismatches
     with a neighbouring file. Run `grep -rn '<old name/value>' specs/` **and** `grep -rn '<new name/value>' specs/`,
     fix them all in the same round, then `gate-check.sh --pre $1` — it warns about dangling phrases, entities
     missing from the glossary, and RULEs that do not acknowledge the UC.
   - Open Question → add `- [ ] <question> (interim decision: <what the user said>)`. Nothing to say yet → `___`, and
     keep the source label `[Main 7]` in the question so it can still be traced six months later.
   - Out of Scope → add it to the `br.md` of the slice the UC belongs to, each line with a destination
     (`→ slice ___` · `→ reopen when ___`). A line matching a keyword in `## Do not narrow` of `specs/vision.md` →
     **ask the owner first**, do not write it yourself: either it does not go into Out of Scope, or the owner settles
     it as `deliberately narrowed — owner decided YYYY-MM-DD`.
   No question may be left without an output.

5′. **Ticket mode** — no `AskUserQuestion`, and nobody guesses on the owner's behalf.
   - A question changing a **value** (a threshold · a deadline · an enum): as in ask mode — `→ Open Question` with the
     interim decision `___`.
   - A question changing the **shape** (the actor · the data source · permissions · the order of steps) and any
     question touching `## Do not narrow`: collect them into **one ticket** at the end of the question log, in the
     log's own shape — `### #<n> · from: spec · task: $1 · <date>`, each question as one `K#` with `Question` ·
     `Already looked up` (**verbatim**, what the label points at, as in point a) · `If chosen wrong` · `The agent
     leans towards` (each direction with what it costs — point b; no leaning on a question that changes a business
     value). Leave `Answer (R)` and `Approve` empty.
   - In the UC: the output is `→ Undecided — Open Question (ticket #<n> K#)`, and add to `## Open Questions`
     `- [ ] <question> [source label] (interim decision: ___ · ticket #<n> K#)`. Do **not** edit Main/Alt/E#/AC/RULE
     in the direction you lean — applying the ticket is a later round, reading the `For: spec` part once R or the
     owner has answered.
   - The log is **not** part of the step 6 commit: under orchestrate, A commits the log (R/B do not); running by hand,
     commit it separately as `chore(sdd): question log — ticket #<n>`. Report at the end of the round: the ticket
     number, the number of `K#`, and how many new Open Questions.
   No question may be left without an output — `Undecided — Open Question (ticket …)` is an output.
6. Finish: `git add <the UC file and the neighbouring files you edited> && git commit --only -m "docs($1): spec vN —
   after the adversarial pass" -- <exactly those files>` — name them explicitly, never `specs/`: the staging area
   belongs to the whole tree, and `git add specs/` sweeps up another role's half-finished file (P-29). This commit is
   the mark that tells `/sdd-solo:gate` the spec changed today.
7. STATE.md: `Working on: $1 · step ⑧ — waiting for the re-read with an unprimed head`. Tell the user the next step is
   **`/sdd-solo:verify $1`** — a subagent re-reads, writes `## Re-read`, and commits on its own; after that the gate
   can run. Since 6.0.0 (#38) this is the **only** route: the "shut down and re-read tomorrow" door is gone, because a
   night measures time passing rather than whether the reading happened, and the cheaper door is the one that gets
   used (#27 → #38).

---

## B. The BR layer — Phase 1

The UC-layer roles ask about **behaviour**. The BR layer needs roles that ask about **the reason for existing** —
an entirely different question, and if it is not asked here there is nowhere left to ask it.

1. Read the `br.md` of slice `$1` (`specs/<core|craft>/br-###/br.md` — find it with `ls -d specs/*/br-###/`), together
   with `specs/_intake.md` to see which question set was used, **and `specs/vision.md`** — the `## Do not narrow`
   section plus this slice's row in the `## Crafts and slices` table.

   `## Do not narrow` is **required input for all three roles**, not background information. The three roles exist to
   squeeze the BR tighter; layer 0 exists to say where it may not be squeezed. Running the three roles without giving
   them `## Do not narrow` is running exactly half the mechanism — and the missing half is the half that created
   layer 0.
2. Check the preconditions:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/br-check.sh" $1
```
Any ✗ line → **stop**, print the output, tell the user to finish the BR and run again. A `___` warning → **carry on** —
`___` is a valid state in Phase 1, and those `___` spots are exactly what the three roles will push on.
3. **Run the three roles in separate subagents** (the Agent tool, one agent per role). The prompt: the *three BR-layer
   roles* part of `.sdd/prompts/adversarial-pass.md`, plus the whole slice `br.md` **and the `## Do not narrow` section
   of `specs/vision.md`** verbatim. Same constraints as the UC layer: only ask, propose no solutions, do not edit the
   spec, at most 8 questions per role.

   - **The one who pays** — why is this worth doing **before** something else? what does doing nothing cost,
     **measurably**? where did the baseline number come from?
   - **The one who will operate it forever** — **the required first question (#47): *"once v1 is done, what do you open
     every day to do your work? what can you change yourself without a developer?"*** — the answer settles In Scope
     before the scope is cut (BR-003 at runxops was overturned because nobody asked); then: who is on the hook when it
     breaks at 2am? what in today's Out of Scope becomes a ticket next week?
   - **The sceptic** — what does the `**Why still build:**` line in Background say? If it says *"no reason yet"*,
     **start there**: has any non-software option been weighed, and was the weighing finished? Is there a way to reach
     the Goal **without building anything**? Is this really a BR, or a solution already chosen and written backwards
     into a reason?

   The third role is the most important one and does not exist at the UC layer. *"BR: build an order-tracking
   dashboard"* is not a BR — that is a solution; the real BR is in the question *why tracking is needed*. If this role
   concludes the BR is a solution written backwards then **stop, say exactly what the BR would shrink from and to, ask
   the owner, and only then rewrite** — do not record it as an Open Question and move on, and do not rewrite before
   the owner has heard what it costs. Rewriting a BR is narrowing it; the only person who may decide to narrow is the
   owner. Ticket mode: its own ticket with `K1` = *"the BR shrinks from ___ to ___, losing ___"*, every other question
   output as `Undecided`, and the step 7 commit **without** a History v+1 — then stop the round.

   **Every role must check against `## Do not narrow`.** Any question that would drop something listed there means the
   role must say out loud that it is touching layer 0, and the question goes straight to the owner at step 5 — not
   into an `Open Question` to sit there.

4. Write into the BR's `## Adversarial pass` section:
```
- Run date: YYYY-MM-DD · Fresh session: [x]
- Role the one who pays:
  - Q1 <question> → <output: ___>
- Role the one who operates it forever: ...
- Role the sceptic: ...
```
5. Ask mode: put each question through `AskUserQuestion`; ticket mode: as in part A step 5′ — **the same three things
   and four constraints as part A step 5** — the context is a verbatim quote of the BR section the label points at
   (`[Background]` · `[CON-002]` · `[Success Metrics]`), every option carries what it costs, and `Undecided` is always
   visible.
   Four valid outputs, and no "leave it":
   - → `## Background` (with the **source** of the number; no source means it is not Background)
   - → `## Open Questions` with an interim decision
   - → `## Out of Scope` + a `-.->` branch on the Impact Map, **with a destination** `→ slice ___` or
     `→ reopen when ___`
   - → a new `CON-###` in `## Constraints`

6. **"What was gained and what was lost" — before writing `## History` v+1 (in the trail file), required, never skipped.**

   Once the step 5 tickets are applied but `## History` is **not** yet written, run:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/br-scope-diff.sh" $1
```
(if the variable is not substituted: `find ~/.claude/plugins -type f -name br-scope-diff.sh -path '*sdd-solo*' | head -1`).
   It prints the `## In Scope` / `## Out of Scope` lines **added and removed** against `HEAD`.

   Then **say it back to the owner in plain words**, do not paste the diff: *"the BR shrinks from ___ to ___; it opens
   ___; it drops ___ to slice ___."* And **wait for the owner to agree** — via `AskUserQuestion`, one question, three
   options: *agree to that narrowing* · *keep the scope, reject ticket ___* · *undecided, leave it in Open Questions*.

   Why this step exists: three adversarial rounds, each narrowing the BR a little, each correctly — and together what
   is left is plainly smaller than the original intent, while **no round can see the other two**. One round's diff is
   the only thing that makes that narrowing visible before it sets. Any line touching a keyword in `## Do not narrow`
   is called out explicitly, not left inside the list.

   The owner has not agreed → **write no History, make no commit**. That is not waiting out of politeness:
   `## History` is where a version declares itself settled.

   **Ticket mode:** at step 5 you may apply no ticket that changes `## In Scope` / `## Out of Scope` /
   `## Dropped from brief` — those become `K#` in the ticket, output `Undecided`. So `br-scope-diff.sh` must be
   **empty**; any line it prints is a narrowing you just applied yourself — undo it (`git checkout -- <br.md>` and
   reapply only the parts that do not touch scope), and write no History. An empty diff → write History v+1
   *"after the adversarial pass — ticket #<n> waiting on the owner"* and go on to step 7.
7. Run `br-check.sh $1` again, then `git add <br.md and the files you edited> && git commit --only -m "docs($1): BR
   after the adversarial pass" -- <exactly those files>` (name them explicitly, never `specs/` — P-29).
8. STATE.md: `Working on: $1 · Phase 1 done`. `Next: /sdd-solo:start UC-### for the first UC in the slice's
   ## Related Use Cases`.

Do not write code. Do not create a UC folder.

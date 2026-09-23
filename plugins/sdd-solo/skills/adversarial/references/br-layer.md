# adversarial · the BR layer (Phase 1)

<!-- Read this file when `/sdd-solo:adversarial` was given a BR-###. It is the WHOLE of Phase 1: the three roles
     (the one who pays · the one who operates it forever · the sceptic), what they ask about the reason for
     existing, and the commit. See the note in uc-layer.md for why it is a separate file (8.1.0). -->

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

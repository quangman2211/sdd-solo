# adversarial · the UC layer (step ⑦)

<!-- Read this file when `/sdd-solo:adversarial` was given a UC-###. It is the WHOLE of step ⑦: the three roles,
     the shape/value test, the four constraints on a proposal, both question modes, and the commit.
     It lives beside SKILL.md instead of inside it because a run is either the UC layer or the BR layer, never
     both, and SKILL.md is loaded in full on every run (8.1.0). -->

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

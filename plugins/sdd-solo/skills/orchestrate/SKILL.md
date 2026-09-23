---
name: orchestrate
description: Coordinating several agents on one SDD-Solo repo — the eight roles A/B/C/R/V/D/T/Q, path-based boundaries from .sdd/config, the L0–L3 question log, the briefing skeletons, and the standard chain T→D→C→R→(spec‖D‖T) for a UC past the gate. Use it when the user says "run several agents", "hand work to the code/test agent", "set up the team", or when a UC is past gate + design and code and tests should run in parallel.
disable-model-invocation: true
argument-hint: "setup | UC-### | round UC-###"
allowed-tools: Bash Read Write Edit Grep Glob Agent AskUserQuestion
---

Reply in whatever language the user writes in; keep file names, IDs and slugs in English.

Coordination for `$ARGUMENTS`.

**Why this skill exists (#39):** sdd-solo was written for *one developer + one AI*. At runxops (2026-09-17, one day,
46 spec rounds, UC-014 from start to close) the owner ran **eight agents in parallel**, one role each, coordinating
through files in the repo. Every rule here was paid for (D fixed T's fake · R disagreed with D because a worktree
could not see the new spec · C escalated to the owner a design that was already settled), and up to 6.5.0 it lived
only in one repo's notes. This skill states **the roles · the files · the order**; the tool that runs them in
parallel (herdr, tmux, several windows) is the user's business — the appendix lists the traps already hit.

Whoever is reading this skill **is role A**. A does no specialist work: read results → decide the route → hand out
work → commit the logs other agents may not commit → update STATE → ask the owner on an L3.

`$ARGUMENTS` = `setup` → **§1**. `UC-###` → **§1 if setup has not run, then §4** (the standard chain).
`round UC-###` → **§4** from the current round. No argument → print the role table (§2) and ask the user what they want.

---

## 1. `setup` — once per repo

1. Read `.sdd/config`: `code_paths` · `test_paths` · `uc_test_dir` · `nghe_paths`. The role boundaries **come from
   there**, never hard-coded. Missing `uc_test_dir` → stop and tell the user to declare it (default `tests/use-cases`).
   `nghe_paths` (7.0) is the list of craft names — it decides role T's `<uctest>/<core|craft>/UC-###/` and role D's
   `src/<craft>/` area; empty in a repo still on the 6.x layout, where the boundaries fall back to
   `code_paths`/`uc_test_dir` as before.
2. The question log: `notes/hoi-dap/hoi-dap.md` (a process trace, **outside `specs/`** since 7.0). Missing → copy from
   `${CLAUDE_PLUGIN_ROOT}/templates/skel/hoi-dap.md` (if the variable is not substituted:
   `find ~/.claude/plugins -name hoi-dap.md -path '*sdd-solo*' | head -1`). Already there → leave it alone.
3. Roles (7.2): no `.sdd/roles` yet → `/sdd-solo:init --update` copies the sample set (A B R D T); read it with the
   user and adjust the write/deny areas to this repo. The `commit-msg.d/10-vai.sh` hook reads it — the default
   `vai_bat_buoc=khong` only warns; run `bash .sdd/scripts/role.sh --kiem-lich-su` (read-only, 300 commits) before
   turning on `nhanh-vai`. If the old `pre-commit.d/10-role-boundary.sh` (by branch) is still there, `git rm` it, or
   two pieces block at once. Hooks live in git, so a worktree only sees them after `merge main`.
4. (7.3) `notes/hang-doi.md` (the queue, written only by A through `queue.sh`) and `notes/uy-quyen.md` (delegation +
   named stop points) — `init --update` copies the skeletons. Read `uy-quyen.md` with the owner: **Scope** is written
   by the owner (while it is still the skeleton, A decides no L3 question), and rename the stop points to fit the
   repo. `status.sh` checks: every `STOP-<name>` in the queue must appear in the Stop points table; a Ledger row
   pointing at `#n` must have a matching line in `decisions.md`.
5. Commit `chore(sdd): orchestrate setup — hoi-dap.md + .sdd/roles + hang-doi.md + uy-quyen.md`.
6. Ask the user **two questions** with `AskUserQuestion`: (a) R's decision authority — *up to L2 (Recommended, what
   runxops settled on) · up to L1 · L0 only*; (b) a Q role (end-to-end QA) right away or not — *enable it once
   compose/deploy runs (Recommended) · enable now · none*. Record both answers at the top of `hoi-dap.md` (the
   *Default authority* line) and in `decisions.md`.

## 2. The role table — boundaries by PATH, not by "test or code"

`<code>` = `code_paths`, `<test>` = `test_paths`, `<uctest>` = `uc_test_dir` from `.sdd/config`.

| Role | May write | May not write | Ends a round with |
|---|---|---|---|
| **A · Coordinator** | `STATE.md`, `specs/decisions.md`, `notes/hoi-dap/hoi-dap.md` (committing for R), the coordination logs | code, spec | handing out work; **the only gate that asks the owner** (`AskUserQuestion`, one consequence sentence per option, always with "Delegate to R") |
| **B · Spec** | `specs/` | code, `STATE.md`, `decisions.md` | a `docs(ID)` commit + the hash + the list of remaining `___` |
| **C · Review** | `notes/soat/soat-<ID>-luot-N.md` — writing directly (runxops) or a scratchpad A then copies; **A commits**, C does not | spec/code content | the number of findings + the file path; **a fresh session each round**, reading no coordination log and no STATE, asking nobody — questions go into the file |
| **R · Arbiter** | only `notes/hoi-dap/hoi-dap.md`, **no commits** | every other file | the ticket `#n · L? · For: spec · D · T` |
| **V · Presentation** | `notes/ban-do/` notes, maps, artifacts | spec, code | a link; **decides nothing** |
| **D · Code** | `<code>/**`, migrations, `<test>/**` **except** `<uctest>/**`, deploy — in its **own worktree**, branch `code/<uc-###>` | `<uctest>/**`, `specs/` (all of it) | `feat(UC-###)` · questions → `notes/hoi-dap/hoi-D.md` (`ASK-D#` · `TEST-#`) |
| **T · Test** | `<uctest>/<core\|craft>/UC-###/**` (tests, harness, fakes, fixtures) — branch `test/<uc-###>` | `<code>/**`, `specs/` (all of it) | `test(UC-###)` · questions → `notes/hoi-dap/hoi-T.md` (`ASK-T#`) |
| **Q · QA** | `notes/soat/qa-UC-###.md`, anonymised fixtures | code, spec | a report; enable it once compose/deploy runs |

**Rules that were paid for — read them before handing out the first round:**
1. **The gate's fakes and harness belong to T.** D sees a wrong fake → **does not fix it**, writes a `TEST-#` (file,
   line, what is needed, why) into `hoi-D.md` and skips that case; T fixes it next round. Round 3's brief at runxops
   only forbade "editing T's tests" → D edited `fakes.ts` (`c0e7137`) because it read a fake as "gate implementation".
   A boundary must name **paths**.
2. **Check mechanically after each D round, do not trust the eye:** `git diff <head of T's branch> HEAD -- <uctest>`
   must be **empty**, and `git log --no-merges --format=%h -- <uctest>` must contain **no commit by D**. A Claude Code
   pane draws files changed by `git merge` exactly like files the agent edited — the owner once believed D "was still
   writing tests" because of this.
3. **D/T open a round with `git merge main`** (and merge the other role's branch if the brief says so), then read
   **exactly the ticket named**, not the whole log. D once chose against R's decision because its worktree could not
   see the new spec.
4. **The T↔D contract lives in one harness file** (T writes it from `design.md`); D "accepts it or records why not".
   `design.md` must declare the **port/use-case function signatures**, not just file names (skill `design` §3, since
   6.6.0).
5. **C tends to escalate to the owner a design that is already settled** (twice in one day). R reads the design before
   grading; C's "the owner must decide" reaches the owner **only after R confirms L3**. A does not ask directly on
   C's word.
6. **At most two writing agents at a time** in the same area; do not run two UCs from different slices in parallel if
   both write the same `glossary.md`/`rules.md` (the root one or the same craft's); do not run a large rename in
   parallel with any coding.
7. **Never handed to an agent:** setting a number/threshold/price · settling the shape of a UC · `gate`/`close` ·
   push/deploy/delete. Those are the L3 of `hoi-dap.md`, and they are A's job to ask the owner about.
8. **A subagent may not open `AskUserQuestion`** — nobody is there to click and the turn hangs until it times out
   (#53). A brief that runs `/sdd-solo:adversarial` writes **`--phieu`**: shape questions become one ticket K1…Kn at
   the end of `hoi-dap.md`, and the UC/BR records `Undecided — Open Question (ticket #n K#)`; A commits the log and
   hands it to R. Since 7.0.1 `/sdd-solo:verify` never asks — every `F#` that was not rejected becomes
   `Undecided (… · proposal: …)` and it still commits, no flag needed. A sitting with the owner and wanting to ask
   directly runs adversarial **in A's own session** with `--hoi`, not as a handed-out task.

## 3. The briefing skeletons

**Since 7.2 a work brief is generated by machine:** `bash .sdd/scripts/role.sh <role> notes/hoi-dap/phieu/NNN-*.md
[--luot N]` prints six parts (the goal · the reading pack as `file:section` through the lib · the work copied verbatim
from `For: <role>` plus every `[anchor:]` · the forbidden area from `.sdd/roles` · the checks to run + an explicitly
named commit + the `Vai:` trailer · the `KETQUA` line). It takes **a ticket file only** — all 137 hand-written briefs
at runxops were transcriptions of a ticket, and the part usually dropped was the anchor. A edits the goal sentence if
needed and sends it; over 1,500 characters → write it to a file and `prompt "$(cat file)"`. An agent ends a round with
`role.sh --ketqua <key> ket=xong neo=<hash>` **before** sending its message — the file lives in
`git-common-dir/sdd-ketqua/`, so if the message is lost the file remains (P-26); A reads `role.sh --ketqua <key>`,
not the screen. One worktree per role: `role.sh --worktree D UC-###` · `role.sh --worktree T UC-###`; **B keeps the
main checkout on `main`** (what B writes is shared truth); R and C set their markers with `role.sh R` / `role.sh C`
in their own worktrees.
The two skeletons below are there to read what those six parts say, and to use before there is a ticket (a role's
first brief).

**Role brief** (once when starting an agent, ≤ 1,500 characters):
```
Role: <D · Code for UC-###>. Branch/worktree: <code/uc-###, worktree-path>.
May write: <code_paths> migrations, notes/hoi-dap/hoi-D.md. MAY NOT write: <uc_test_dir>/** (T's), specs/ (all of it).
Decide no business question: the spec is missing a number/enum/permission → STOP, write ASK-D# into
notes/hoi-dap/hoi-D.md, do not guess, do not use AskUserQuestion, do not message another agent. Do not run
/sdd-solo:*. Commit <type>(UC-###), do not push.
End of every round: a short report (commit · check counts · new ASK/TEST) then STOP.
There is NO work yet. Read <design.md, tasks.md> and answer with exactly one line: "D ready".
```

**Work brief** (each round) — ten items; missing one and the round drifts:
```
Round <D-6> · branch <code/uc-014> · worktree <path>.
Old rules in one line: <may write / may not write / commit style / no push / where questions go>.
Step 0: git merge main [and git merge test/uc-014].
Read: <file:section> — EXACTLY ticket #<n>, the "For: D" part; read no other ticket. (point at it, do not copy it)
Work, in order (L0 first): 1. <K1 …> 2. <K2 …>
Checks that must run: <npm test …> — print the pass/fail counts, do not just say "green".
Boundary check at the end of the round: git diff --stat <head of T's branch>..HEAD -- <uc_test_dir> must be empty.
Commit: <feat(UC-014): …>, split by block. Do not push.
Final report ≤ 10 lines: commit · check counts · new ASK-D#/TEST-# · what was not done. Long output → write a file and return the path.
When done, STOP.
```
Write the brief into a scratchpad file first and only then send it — a brief over ~1,500 characters is pasted as a
block by some tools and never sent (see the appendix).

**Code review brief for C** (after each D round, a fresh session): the diff `git -C <worktree> diff <base>..<head>`;
five questions: (1) trace the work → AC → test → code; (2) the right layer, domain / use-cases / adapters; (3) silent
defaults and the places D marked "GUESS"; (4) state transitions follow the entity file
(`specs/<core|craft>/entities/<Name>.md`), and no forbidden column (CON) slipped through; (5) code that quietly
diverged from `design.md`; (6) does `src/core` import `src/<craft>` — `layer-check.sh` counts that for you.
Every finding **in the ticket shape** (`Question · Already looked up · If chosen wrong · The agent leans towards`) so
R can grade it without translating it again. Write into C's and R's prompts: **which measurements may already be
stale**, because T is editing in parallel.

## 4. The standard chain for a UC past the gate

Entry conditions: `.sdd/gate/UC-###.ok` · a `design.md` that passes `design-check` · `tasks.md`. Missing → stop and
name the command (`/sdd-solo:gate`, `/sdd-solo:design`). Do not stand up D before those exist — that is `CLAUDE.md`'s
rule, not A's.

```
T round 1  — RED tests from the ACs (one file per AC in <uctest>/<core|craft>/UC-###/), harness + fakes from the design; branch test/uc-###
D round 1  — the groundwork blocks (the tasks "tied to no AC"), then merge test/uc-### one AC at a time and make them green; branch code/uc-###
C review   — a fresh session, the diff of D's round, the five questions of §3 → notes/soat/soat-UC-###-luot-N.md (C writes it, A commits)
R          — one ticket collecting K1…Kn: the level of each K, For: spec · D · T, the order to apply; A commits the log
spec ‖ D ‖ T — the three roles apply AT THE SAME TIME, each reading exactly its own "For:" part
… repeat: D round n → C review → R → spec ‖ D ‖ T … until both suites are green on the real code and C has no K left at L0/L1
C full review — a fresh session, the whole branch, measuring a migration into an empty DB too (green numbers on an already-migrated cluster prove nothing)
D runs the five self-review questions (.sdd/checklists/self-review.md) — three of the four items became work at runxops, do not skip it
merge code/uc-### → main (A or the owner) → /sdd-solo:close (the owner, never an agent)
clean the lanes  — bash .sdd/scripts/role.sh --don UC-### : removes the role worktrees of this UC, prunes, deletes its
                   <role>.nhanh branches. It never forces: a worktree with uncommitted files or an unmerged branch is
                   KEPT and named, which is the one report you want here. Run it right after close — measured at
                   runxops on 2026-09-24, skipping it left 4 workspaces and 18 code/ · test/ branches of UC-016…030
                   behind, and the owner found them, not a check. `--dry-run` first if you want to see the list.
```
One `C → R → spec ‖ D ‖ T` loop was roughly 35–45 minutes at runxops. The last three roles always go out together
because they only need the ticket's text, not each other.

**The queue (7.3):** `queue.sh add <key> <lane> <role> --can "<earlier key>"` · `queue.sh next` prints what can go out
right now (every Need is done, the lane has room) — A asks the machine, not its memory · `queue.sh take <key>` when
handing it out · `queue.sh done <key>` only with a KETQUA `ket=xong` + anchor · `queue.sh stop <key> <stop name>` with
a name from `uy-quyen.md` · `queue.sh board` is the assignment board (an overdue item only raises a `suspected-dead` flag
for A to look at; it never changes state by itself). Agents do not write the board; a secondary worktree reads the
`main` copy. Every round of A's ends with **either a background wait command or a named stop point** — there is no
third state.
**The addressed question log:** D/T open a question with `phieu.sh hoi D "<question>"` (four boxes: source · blocking ·
doing while waiting · spec work when answered); A answers in the `Answer (A/R)` box + `target:` (design.md ·
decisions.md) and **does not edit the question**; the body of a UC only reopens when an AC changes —
`hoi-check.sh D` is red when the gate is open and a target points into the UC body.

**After every round, A does exactly four things:** (1) read the branch's `git log` and the agent's final report block
(do not trust a screen reading for long output); (2) check the boundary mechanically (§2 rule 2); (3) commit the logs
the agent may not commit (`hoi-dap.md`, the review file) — `chore(sdd): hoi-dap #n` or `docs(UC-###): review round N`;
(4) one line in `STATE.md`: which round is running, which ticket is waiting for Approve.

**The ticket flow:** a new ticket takes its number with `bash .sdd/scripts/phieu.sh new "<task>" <role>` (an atomic
lock shared by every worktree, the placeholder row committed immediately — P-21, four collisions in one day when
numbers were allocated by hand); it is closed with `phieu.sh close <n>` (counting F#/K# in the file, requiring a
KETQUA from each role — P-33). An agent writes `ASK-<role>#` into `notes/hoi-dap/hoi-<role>.md` (inside its own
worktree) and STOPS → A reads the worktree and hands it to R: *"ticket #n: grade L0–L3, check the spec/ADR/design,
write For: per role and the order to apply; write only hoi-dap.md, do not commit"* → L0–L2: A hands each role its
`For:` part · L3: A asks the owner with `AskUserQuestion` (2–4 options, one consequence sentence each, with
"Undecided") → A writes `decisions.md`/the spec before D starts the next round. An agent repeating an already-answered
question → the next round's brief says *"read the ticket's Answer section before asking again"*.

**Using this in a plugin repo / a small repo:** three roles are enough — A (this session), D (fixing by group of work,
in a worktree), C (a fresh session, reviewing D's diff against the work itself and against everything else that
speaks about it). R folds into A because the questions are usually L1.

## 5. Limits — tell the user

1. This skill **cannot measure** whether an agent followed its brief; what can be measured is the githook
   `commit-msg.d/10-vai.sh` (the role boundary from `.sdd/roles`, the `Vai:` trailer in `git log`), the KETQUA files,
   and the two `git diff`/`git log` commands in §2 rule 2. The rest is A's discipline.
2. When an agent compacts its own context between rounds, `wait` still works but it may have forgotten its role rules
   → a work brief **restates the old rules in one line** every round, not only at startup.
3. It does not replace `/sdd-solo:verify` or the three adversarial roles: C reviews **code**; verify reviews **the
   spec**. Two different jobs.

---

## Appendix — the herdr traps, only if you run herdr

The project runs **herdr** → read `references/herdr-traps.md` (full path
`${CLAUDE_PLUGIN_ROOT}/skills/orchestrate/references/herdr-traps.md`; if the variable is not substituted,
`find ~/.claude/plugins -type f -name herdr-traps.md -path '*sdd-solo*' | head -1`).

It does not → skip it, and do not go looking. herdr is **not a dependency** of sdd-solo: no step of the standard
chain above needs it, and the file records traps we hit with one runner at one version. Another runner has other
traps, and reading ours would only teach you to look for the wrong ones.

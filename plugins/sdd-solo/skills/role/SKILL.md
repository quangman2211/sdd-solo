---
name: role
description: Agent team roles (7.2) — set a worktree's role marker, create a worktree for a role, clean the lanes of a finished UC, print a six-part brief from a ticket (applying for a role that commits, answering for one that does not), write a KETQUA. Use it when the coordinator hands work to the spec/arbiter/code/test agent, when an agent session needs to know which role it is, or after a UC closes.
disable-model-invocation: true
argument-hint: "<role> | <role> <ticket file> [--luot N] | --xem | --worktree <role> [UC-###] | --don UC-### [--dry-run] | --ketqua <key> ket=… neo=…"
allowed-tools: Bash Read
---

Reply in whatever language the user writes in; keep file names, IDs and slugs in English.

Run `role.sh` with `$ARGUMENTS`:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/role.sh" $ARGUMENTS
```
(if `${CLAUDE_PLUGIN_ROOT}` is not substituted: `find ~/.claude/plugins -type f -name role.sh -path '*sdd-solo*' | head -1`;
in a project that has run `init --update`, `.sdd/scripts/role.sh` is a copy that runs without the plugin).

The mechanism is in the plugin, the policy is in the repo's `.sdd/roles` (which roles · where each writes · where each may not · branch · whether it commits). No `.sdd/roles` yet → tell the user to run `/sdd-solo:init --update` and then edit the sample set (A coordinator · B spec · R arbiter · D code · T test).

| Command | What it does | What to tell the user |
|---|---|---|
| `<role>` | writes the role marker for **this worktree** (`.git[/worktrees/<name>]/sdd-role`, never in git, not tied to the branch) and prints the contract | what this role may write and may not; the `commit-msg.d/10-vai.sh` hook only warns while `vai_bat_buoc=khong` |
| `--xem` | the current role: `$SDD_ROLE` → the worktree marker → the branch pattern | if none can be inferred, nothing is being enforced |
| `--worktree <role> [UC-###]` | creates the worktree `../<repo>-<role>[-uc-###]` on the branch from `<V>.nhanh` and sets the marker | **the spec role keeps the main checkout on `main`** — what B writes is shared truth, and from a separate worktree the other roles read a stale `main` until the merge; the hooks inside a worktree are the copy from when it was created, so open each round with `git merge main` |
| `--don UC-###` | the reverse of `--worktree`: removes that UC's role worktrees, `worktree prune`, deletes its `<V>.nhanh` branches | **it never forces.** A worktree with uncommitted or untracked files, and a branch that is not merged, are KEPT and named — a lane you cannot delete is a lane with something in it. Run it right after `/sdd-solo:close` (orchestrate §4): measured at runxops on 2026-09-24, skipping it left 4 workspaces and 18 `code/` · `test/` branches of UC-016…030 behind. `--dry-run` lists without touching. It does not close panes — whoever opened the pane closes it |
| `<role> <ticket file>` | prints the **six-part brief**: goal · reading pack as `file:section` · the work copied verbatim from `For: <role>` + the anchor · the forbidden area · the checks to run and how to commit · the KETQUA line | it takes **a ticket file only**, never free text — the anchor exists only in the ticket. **A role with `<V>.commit=khong` gets the ANSWERING brief instead** (8.2.0): grade each K at L0–L3 · look the source up · write the `Answer (R):` box and one `For:` line per role · do not commit (A does) · `KETQUA neo=<the ticket file>`. It switches on `commit=khong`, not on the letter R, because the role names are the repo's policy. Longer than 1,500 characters → write it to a file and use `prompt "$(cat file)"`. Edit the goal sentence if needed, then send |
| `--ketqua <key> ket=xong neo=<hash>` | writes one KETQUA line into `$(git rev-parse --git-common-dir)/sdd-ketqua/<key>.txt` — shared by every worktree, outside git | the agent calls this **before** sending its message back; `ket=xong` requires a real `neo`, `ket=chan` requires `hoi=`. When the message is lost, the file is still there (P-26) |
| `--kiem-lich-su [range]` | read-only: runs the write-area rules over history and counts commits no role was allowed to make | run it **before** turning on `vai_bat_buoc`, to find out whether the boundary is real or theatre |

Rules for this skill: never edit `.sdd/roles` for the user; never hand work to a role from free text; never propose writing code.
A spec/arbiter/code/test role running under a brief: hitting something the spec does not say → `bash .sdd/scripts/phieu.sh new "<task>" <role>` and then **stop**, never `AskUserQuestion`.

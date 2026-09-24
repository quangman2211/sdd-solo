---
name: queue
description: The coordinator's work queue (7.3) — notes/hang-doi.md in git, machine-readable; add · next (what can be handed out right now) · take · done (only with a KETQUA + anchor, or a closed ticket) · stop <name> · board. Use it when the coordinator hands out work, asks "what can go out next", or wants the board.
disable-model-invocation: true
argument-hint: "add <key> <lane> <role> [--can \"k1 k2\"] | next | take <key> [who] | done <key> [--theo-phieu #n] | stop <key> <name> | board | list"
allowed-tools: Bash Read
---

Reply in whatever language the user writes in; keep file names, IDs and slugs in English.

Run `queue.sh` with `$ARGUMENTS`:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/queue.sh" $ARGUMENTS
```
(if the variable is not substituted: `find ~/.claude/plugins -type f -name queue.sh -path '*sdd-solo*' | head -1`; inside a project: `.sdd/scripts/queue.sh`).

- `giu [role]` (8.6.0) — read-only, runs in any worktree: the active items that role still holds, one per line as `<key>|<last ket=>`. The `Stop` hook asks exactly this.
- **Only the coordinator, in the main checkout, writes** — `add|take|done|stop` refuse to run in a secondary worktree. Agents do not write the board; an agent writes a KETQUA (`role.sh --ketqua`), and `done` reads it and checks the anchor before writing the row. Every write is one `--only` commit.
- `next` = every `Needs` is `done` and the lane has room (the `## Lanes` table, Capacity column). Ask the machine, not your memory.
- `done <key> --theo-phieu #n` — for a job that ended `ket=chan hoi=#n` and was settled BY THE TICKET, with no work
  left to redo (8.4.0, P-50): `done` wanted a fresh `ket=xong` and `stop` wanted a stop name, so there was no way
  to close one. It is a second SHAPE of evidence, not an exemption — ticket #n must carry the `Applied:` stamp
  `phieu.sh close` writes onto the FILE, and close only writes it after counting F#/K# there and finding a KETQUA
  from every role in `For:`. The ticket file becomes the anchor.
- `done` on the last open item of a UC prints what that UC's lane still holds (`role.sh --don --dry-run`, which removes nothing) and the command to clean it for real. It only looks — deleting a lane deletes the only copy of somebody's work (8.6.0).
- `done` with no KETQUA `ket=xong` + anchor → red. `done` with an empty Anchor is red on `board`. Elapsed time is not evidence: an `active` item past its deadline (90 minutes by default, `--qua-han N`) only raises a `suspected-dead` flag for the coordinator to go and look at.
- `stop <key> <name>` → `STOP-<name>`; the name must exist in `notes/uy-quyen.md ## Stop points`, and `status.sh` checks it.
- A work key is `[a-z0-9][a-z0-9._-]{1,39}` — it is also the KETQUA file name. Suggested shape: `<role>-<id>-p<ticket>[-l<round>]`, which is what `role.sh` prints in part 6 of a brief.

Do not decide the order of work for the coordinator; do not change a state because time passed.

# Queue — the coordinator's running board

<!-- The coordinator's file (role A), kept in git, read by machine with .sdd/scripts/queue.sh. Agents do
     NOT write this file — an agent writes a KETQUA (role.sh --ketqua); `queue.sh done` reads the KETQUA,
     checks the anchor, and only then writes the row. A secondary worktree only reads, through
     `git show main:notes/hang-doi.md`, so it never reads its own branch's stale copy (queue.sh does this).
     State is a closed set: waiting · active · done · dropped · STOP-<name>  (names declared in
     notes/uy-quyen.md ## Stop points).
     `done` with an empty Anchor column is red — elapsed time is not evidence. Needs: several keys
     separated by spaces. -->

## Lanes
| Lane | Capacity | Write area |
|---|---|---|
| spec | 1 | specs/** |
| code | 2 | src/** tests/** |
| do | 1 | notes/do/** |

## Work
| Key | Lane | Role | Needs | State | Anchor | Note |
|---|---|---|---|---|---|---|

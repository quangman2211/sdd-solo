# commit-msg.d/ — the repo's own rules (#50)

Every **executable** file (`chmod +x`) in this folder runs after the checks in `.sdd/hooks/commit-msg`, in name
order, receiving the message file path as `$1`. A non-zero exit blocks the commit. `.example` and `README.md` do not
run. The plugin **never touches** your files here on `init --update` — it only refreshes `README.md`, the `.example`
files, and **`10-vai.sh`** (which belongs to the plugin).

The parent hook exports: `SDD_ROOT` · `SDD_STAGED` · `SDD_CODE_PATHS` · `SDD_TEST_PATHS` · `SDD_UC_TEST_DIR` ·
`SDD_MSG` (the first line).

`10-vai.sh` (7.2) — the **role** boundary from `.sdd/roles`: it calls `.sdd/scripts/role.sh --commit <msg>`. The role
is inferred from `$SDD_ROLE` → a `Vai: <V>` trailer in the message → the worktree marker (`role.sh <role>`) → the
branch pattern. With no `.sdd/roles` it stays silent; `vai_bat_buoc=khong` (the default) only warns, `nhanh-vai`/`moi`
block. The hook appends a `Vai: <V>` trailer whenever it can infer one, so `git log --grep '^Vai: '` can measure who
wrote what. Version 7.1 blocked by branch in `pre-commit.d/10-role-boundary.sh` — delete it if it is still there.

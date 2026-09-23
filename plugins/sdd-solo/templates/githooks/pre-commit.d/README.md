# pre-commit.d/ — the repo's own rules (#50)

Every **executable** file (`chmod +x`) in this folder runs after the checks in `.sdd/hooks/pre-commit`, in name
order. A non-zero exit blocks the commit. `.example` and `README.md` do not run. The plugin **never touches** your
files here on `init --update` — it only refreshes `README.md` and the `.example` files.

The parent hook exports, for child scripts: `SDD_ROOT` · `SDD_STAGED` (the staged files, one per line) ·
`SDD_CODE_PATHS` · `SDD_TEST_PATHS` · `SDD_UC_TEST_DIR` (read from `.sdd/config`).

Hooks live in git, so **each worktree runs its own branch's copy of the hook**: a new rule added on `main` only takes
effect in another branch after that branch does `merge main`. Real case: the hook was edited on `main`, a test commit
in worktree `code/uc-014` went through unblocked and had to be `reset --hard`.

**Testing a `.d` rule from a worktree:** the parent hook looks for `.d/` under that worktree's own
`git rev-parse --show-toplevel`, so `git -c core.hooksPath=<main repo>/.sdd/hooks commit` in a worktree still does
**not** run the `.d` rules (the worktree's `.d` folder has no files yet) — and the commit slips through. Two correct
ways: `merge main` into the worktree first, or call the script directly with the environment:
`SDD_STAGED="$(git diff --cached --name-only)" SDD_ROOT=$(git rev-parse --show-toplevel)
bash .sdd/scripts/role.sh --staged`.

Shipped skeleton: `20-layer-boundary` (7.0: the root and core cite no craft, `src/core` does not import
`src/<craft>` — it looks only at staged files and calls `.sdd/scripts/layer-check.sh --staged`).

The **role** boundary has lived in `commit-msg.d/10-vai.sh` since 7.2; the old `10-role-boundary.sh` (by branch) —
delete it if it is still there.

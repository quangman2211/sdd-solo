#!/usr/bin/env bash
# The ROLE boundary (7.2) — run from commit-msg because only here can both the message (the `Vai: <V>` trailer) and the staged files be read.
# The role is inferred in this order: $SDD_ROLE → the `Vai: <V>` trailer → the worktree marker (role.sh <role>) → the branch pattern <V>.nhanh.
# No .sdd/roles → silence. vai_bat_buoc=khong (the default) → a reminder only. A merge commit → skipped.
# It replaces pre-commit.d/10-role-boundary.sh (blocking by branch, up to 7.1): DELETE that one if it is still there, or two pieces block at once.
RS="$SDD_ROOT/.sdd/scripts/role.sh"
[ -f "$RS" ] || { [ -f "$SDD_ROOT/.sdd/roles" ] && echo "! role.sh is not in .sdd/scripts/ yet — run /sdd-solo:init --update" >&2; exit 0; }
bash "$RS" --commit "$1"

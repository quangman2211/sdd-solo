#!/usr/bin/env bash
# deps-check.sh — the external dependencies of SDD-Solo.
#
# Since 4.0.0 this list is almost empty, and that is deliberate: the process runs the whole way round
# on its own. The MANDATORY dependencies are `git`, `bash` and `node` (>= 18).
#
# Why node since 7.6.0: seven scripts read/edit structured files (mermaid, markdown tables, the brief,
# the evidence trail, the context pack, the migration). Up to 7.5.0 that part was python embedded in
# heredocs — 1,185 lines of python inside 4,953 lines of bash, two languages for one plugin, and the
# second language was NOT the language of the project using it. Python is gone, bash stays: where there
# is a fallback (mermaid, reading JSON) it still runs without node; where a file is EDITED
# (context · pass · migrate), `need_node` stops with a message.
#
# Why Spec Kit left the mandatory column — three measurements, not a preference:
#   ① `speckit-specify/SKILL.md` tells the agent IN PROSE: the specs live under `specs/`, the next
#      number is taken by scanning the directories currently in `specs/`, then
#      `mkdir -p specs/<NNN>-<slug>`. It and we share one directory with two ID systems
#      (`001-` vs `UC-###`), neither side aware of the other.
#   ② `/speckit-plan` reads exactly two things: FEATURE_SPEC + `.specify/memory/constitution.md`.
#      In a real repo, FEATURE_SPEC is a thin file holding only IDs while constitution.md is still all
#      placeholders. The step that decides the architecture runs on two empty inputs — that is #34.
#   ③ Four repos on one machine had 10 / 24 / 25 / 35 speckit-* commands. Putting someone else command
#      name into a hard rule means the rule breaks on their release schedule.
#
# Spec Kit IS still worth installing and reading — it is a good design reference, updated often. It is
# only that no repo may break when it changes.
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"

echo "=== Dependencies ==="

# ── mandatory ───────────────────────────────────────────────────────────
command -v git >/dev/null 2>&1 && ok "git" || bad "git — not there; the githooks and every count need it"
[ -d "$ROOT/.git" ] && ok "the repo is git init-ed" || bad "not git init-ed — the githooks cannot be attached"
if command -v node >/dev/null 2>&1; then
  NV="$(node -p 'process.versions.node' 2>/dev/null)"
  if [ "$(printf '%s\n' "${NV%%.*}")" -ge 18 ] 2>/dev/null; then ok "node $NV"
  else bad "node $NV — needs >= 18 (the mermaid parser, the markdown tables and migrate all run on it)"; fi
else
  bad "node — not there; >= 18 is needed for gate-check (mermaid), context.sh, pass.sh close, migrate.sh"
fi

# ── optional: one line each, never red ──────────────────────────────────
if [ -d "$ROOT/.specify" ]; then
  info "Spec Kit — .specify/ is present. Optional, NOT part of the 14 steps since 4.0.0."
  # Only mention it when the two trees really do share a directory — speaking when there is nothing to
  # clean up teaches people to ignore this line.
  if find "$ROOT/specs" -maxdepth 1 -type d -name '[0-9][0-9][0-9]-*' 2>/dev/null | grep -q .; then
    warn "specs/ holds both the Spec Kit tree (the 00N-* directories) and the sdd-solo tree"
    info "→ bash .sdd/scripts/migrate.sh --dry-run   (moves it to .speckit/work/, keeping the git history)"
  fi
else
  info "Spec Kit — not installed. Not needed for the 14 steps; install it if you want to read it as a design reference."
fi

find "$HOME/.claude/plugins/cache" -maxdepth 2 -type d -name 'aiup-core' 2>/dev/null | grep -q . \
  && info "AIUP — installed. Not used for steps ② ③ ④: its four commands write into a docs/ tree, and /use-case-spec collides with the ID system (#29)." \
  || info "AIUP — not installed, and not needed."

[ -d "/Applications/Camunda Modeler.app" ] \
  && info "Camunda Modeler — present (optional: the DMN engine, opening an old .bpmn)" \
  || info "Camunda Modeler — absent, and not needed: step ④ draws mermaid in UC-###.flow.md"

info "Claude Design — cannot be checked by a script; needed for Phase 0 and step ⑤"

echo
if [ "$FAIL" -gt 0 ]; then echo "$FAIL mandatory dependencies missing."; exit 1; fi
echo "All dependencies present."

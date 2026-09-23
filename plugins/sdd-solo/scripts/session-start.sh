#!/usr/bin/env bash
# SessionStart hook: read STATE.md and put it into the context. Prints nothing if the repo does not use sdd-solo.
ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
[ -f "$ROOT/STATE.md" ] || exit 0
STATE="$(cat "$ROOT/STATE.md")"
VER="$(cat "$ROOT/.sdd/version" 2>/dev/null || echo '?')"
GATES="$(ls "$ROOT/.sdd/gate" 2>/dev/null | grep -E '\.ok$' | sed 's/\.ok$//' | tr '\n' ' ')"
# This hook runs FROM the plugin directory the session actually loaded — the only place that can
# know it. Record it for version-check to read; without it, slot ④ is blind.
HD="$(cd "$(dirname "$0")" && pwd)"; . "$HD/lib.sh"
SV="$(jver "$(dirname "$HD")/.claude-plugin/plugin.json" version)"
if [ -n "$SV" ]; then
  SF="$(sess_file)"; mkdir -p "$(dirname "$SF")" && echo "$SV" > "$SF"
  find "$(dirname "$SF")" -name 'session-*' -mtime +7 -delete 2>/dev/null
fi
# a version mismatch: compared locally only. No network call in a hook — a hook has a 10s timeout.
VC="$("$(cd "$(dirname "$0")" && pwd)/version-check.sh" --brief 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g; s/^ *//' | tr '\n' '; ')"
# With no BR yet, every piece of advice about a UC is in the wrong place — say so in the first sentence.
BRW=""
# 7.0: through lib (br_untouched) — 6.x measures specs/br.md, 7.0 measures every specs/*/br-###/br.md.
if br_untouched "$ROOT"; then
  BRW=" STATE: NO BR YET — the BR is still the template, so this repo is in Phase 1 and not at any UC. The first thing to tell the user: type /sdd-solo:intake (it asks 7 questions and writes the BR for them). DO NOT talk about UCs, do not suggest writing code, and do not suggest the AIUP /requirements because it skips the BR layer. Ignore the sentence below about restating which UC we are at."
fi
# The source brief: if there is one, it MUST enter the context — this is the only place in the whole
# process that looks outside specs/. With a sha-mismatch warning: a brief changed after it was loaded
# means two documents may be contradicting each other with nobody comparing them (#34).
BFW=""
BP="$(brief_path "$ROOT")"
if [ -n "$BP" ] && [ -f "$ROOT/$BP" ]; then
  BSHA="$(sha "$ROOT/$BP" | cut -c1-12)"
  BREC="$(brief_rec_sha "$ROOT")"
  BFW=" SOURCE BRIEF: $BP — specs/br.md was converted from this file. READ IT before writing a plan, choosing an architecture, or deciding anything about the stack / where it runs / who calls it; the items dropped from the BR as 'belonging to the design layer' are in there, and their destination is $(arch_file "$ROOT" | sed "s#$ROOT/##") — no mechanism carries them there by itself."
  if [ -n "$BREC" ] && [ "$BREC" != "$BSHA" ]; then
    BFW="$BFW WARNING: the brief changed since intake (sha $BREC → $BSHA) — br.md and the brief may be contradicting each other; compare them before trusting either."
  fi
fi
# 7.3 — a session with a ROLE MARKER (role.sh <role>, or SDD_ROLE) gets the ROLE CONTRACT + the work assigned to it instead
# of the paragraph written for a person at a keyboard. The hook runs again on every /clear ("one session per piece of work"),
# so a freshly cleared session knows who it is, what it may write and which item it holds. The coordinator role (no branch pattern, a name containing "coordinator") still gets STATE + the assignment board.
RV="$(role_current "$ROOT")"
if [ -n "$RV" ] && [ -n "$(roles_file "$ROOT")" ] && role_known "$RV" "$ROOT"; then
  RN="$(role_name "$RV" "$ROOT")"
  QB=""; [ -x "$HD/queue.sh" ] && [ -f "$ROOT/notes/hang-doi.md" ] && QB="$(bash "$HD/queue.sh" list 2>/dev/null | grep -E "^\| *[a-z0-9][a-z0-9._-]* *\|" | awk -F'|' -v v="$RV" -v re="^($(kw q_active)|$(kw q_wait))\$" '{a=$4; b=$6; gsub(/^ +| +$/,"",a); gsub(/^ +| +$/,"",b)} a==v && b ~ re' | cut -c1-160 | tr '\n' ';')"
  KQ=""; for kf in "$(ketqua_dir "$ROOT")"/$(printf '%s' "$RV" | tr 'A-Z' 'a-z')-*.txt; do [ -f "$kf" ] && KQ="$KQ $(basename "$kf" .txt)=$(tail -1 "$kf" | grep -oE 'ket=[a-z]+' | cut -d= -f2)"; done
  LAG=""; MB="$(git -C "$ROOT" show-ref --verify --quiet refs/heads/main && echo main || echo master)"
  if [ "$(cd "$ROOT" && git rev-parse --git-dir)" != "$(cd "$ROOT" && git rev-parse --git-common-dir)" ]; then
    NB="$(git -C "$ROOT" rev-list --count "HEAD..$MB" 2>/dev/null)"; LAG=" A secondary worktree, $MB is ${NB:-?} commits ahead — open the round with: git merge $MB (the hooks, the gate markers and .sdd/version here are this branch copies)."
    MG="$(git -C "$ROOT" ls-tree --name-only "$MB:.sdd/gate/" 2>/dev/null | sed 's/\.ok$//' | while read -r g; do [ -f "$ROOT/.sdd/gate/$g.ok" ] || printf '%s ' "$g"; done)"
    [ -n "$MG" ] && LAG="$LAG Gate markers $MB has that this branch does not: $MG"
  fi
  if printf '%s' "$RN" | grep -qiE "$(kw coordinator)"; then ISA=1; else ISA=0; fi
  CTX="[sdd-solo v$VER] This session is ROLE $RV · $RN (the role marker is per worktree). May write: $(role_paths "$RV" "$ROOT"). MAY NOT write: $(role_deny "$RV" "$ROOT"). Commit: $(role_may_commit "$RV" "$ROOT" && printf '<type>(ID) listing the files by name (git commit --only -- <file>), the hook adds the trailer Vai: %s' "$RV" || printf 'NO — the coordinator commits instead'). Checks before committing: $(role_checks "$RV" "$ROOT"). Rules: do EXACTLY the work in the brief, read exactly the reading pack, do not read the coordination log; if you hit something the spec does not state (a number · an enum · a permission · a shape) → bash .sdd/scripts/phieu.sh new \"<task>\" $RV (or phieu.sh hoi $RV \"<question>\") and then STOP — no AskUserQuestion, no guessing, no messaging another agent; no push. Ending a round: bash .sdd/scripts/role.sh --ketqua <key> ket=xong neo=<hash> BEFORE reporting, then report in ≤ 10 lines opening with that KETQUA line.${LAG} Work assigned to this role (notes/hang-doi.md): ${QB:-no rows}. KETQUA written so far:${KQ:- none}.${VC:+ WARNING, version mismatch: $VC}"
  if [ "$ISA" = 1 ]; then
    CTX="$CTX

=== Assignment board (queue.sh board) ===
$( [ -x "$HD/queue.sh" ] && bash "$HD/queue.sh" board 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' )

=== STATE.md ===
$STATE"
  fi
  if command -v node >/dev/null 2>&1; then node "$HD/js/util.mjs" hookjson "$CTX"
  else printf '%s\n' "$CTX"; fi
  exit 0
fi
CTX="[sdd-solo v$VER] This repo runs the SDD-Solo process.${BRW}${BFW} The first thing to do in this session: restate to the user which UC and which step they are at (per the STATE.md below) and the suggested next command. Hard rules: do not write code for a UC with no .sdd/gate/UC-###.ok marker, and do not write code for a UC with no design.md in its directory — tell the user to run /sdd-solo:gate and then /sdd-solo:design first. If choosing a stack / a place to run / a library that $(arch_file "$ROOT" | sed "s#$ROOT/##") does not state, STOP and ask. On a business decision the spec does not state, STOP and ask, do not pick a default. UCs through the gate: ${GATES:-none yet}.${VC:+ WARNING, version mismatch — tell the user in the first sentence: $VC}

=== STATE.md ===
$STATE"
if command -v node >/dev/null 2>&1; then
  node "$HD/js/util.mjs" hookjson "$CTX"
else
  printf '%s\n' "$CTX"
fi

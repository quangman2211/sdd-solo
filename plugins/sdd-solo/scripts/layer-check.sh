#!/usr/bin/env bash
# layer-check.sh [--staged] [--file <path> ...] — the core/craft boundary rule (7.0, plan §3).
#
#   The core does not know a craft; a craft knows the core. Concretely, and measurably:
#   ① the root specs/*.md · specs/adr/ · specs/core/**  MUST NOT quote a craft ID: a RULE/ADR/UC/BR living in
#      specs/<craft>/ → RED. An entity name from specs/<craft>/entities/ (Channel, Product…) → only a WARNING:
#      a technical constitution and a root ADR mentioning an entity name is ordinary; too much red turns the
#      hook into noise and people switch it off (settled with the runxops peer 2026-09-18).
#   ② src/core/**  MUST NOT import from src/<craft>/ (a relative path `../<craft>/`, an absolute `src/<craft>/`,
#      or an alias `@/<craft>/`).
#   Except: specs/vision.md (its Crafts and slices table naming a craft BR is its job) · specs/decisions.md (one
#   ledger for the whole project) · specs/traceability.md (generated) · *.trace.md · evidence.md · files under notes/ ·
#   and in every file, the evidence sections `## History` · `## Adversarial pass` · `## Re-read` (7.0.1).
#
# By default it scans the whole repo → printing every spot, exit 1 if there is one. `--staged` only looks at the
# staged files (used by the pre-commit.d/20-layer-boundary githook — blocking only NEW violations, not demanding
# that a freshly migrated repo be clean at once). `--file` looks at exactly the named files (gate-check/design-check
# call it for a core UC, as a warning only). A 6.x repo (no crafts) → nothing to check, exit 0.
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"
MODE=all; FILES=""
PREV=""
for a in "$@"; do
  case "$PREV" in --file) FILES="$FILES $a"; PREV=""; continue;; esac
  case "$a" in --staged) MODE=staged;; --file) MODE=files; PREV="$a";; *) [ "$MODE" = files ] && FILES="$FILES $a";; esac
done
[ "$(layout "$ROOT")" = v7 ] || { info "the repo is not on the 7.0 layout — there is no craft whose boundary to check"; exit 0; }
NGHE="$(nghe_list "$ROOT")"
[ -n "$NGHE" ] || { info "there is no craft yet (nghe_paths empty, no specs/<craft>/) — nothing to check"; exit 0; }
NRE="$(printf '%s' "$NGHE" | tr -s ' ' '|')"

# ── the craft IDs: collected from the specs/<craft>/ tree ────────────────
NIDS="$(for n in $NGHE; do
  [ -f "$ROOT/specs/$n/rules.md" ] && grep -oE '^## RULE-[0-9]+' "$ROOT/specs/$n/rules.md" | awk '{print $2}'
  ls "$ROOT/specs/$n/adr/"ADR-[0-9]*.md 2>/dev/null | xargs -n1 basename 2>/dev/null | grep -oE '^ADR-[0-9]+'
  ls -d "$ROOT/specs/$n"/br-[0-9]*/ 2>/dev/null | sed -E 's#.*/br-([0-9]+)/$#BR-\1#'
  ls -d "$ROOT/specs/$n"/br-[0-9]*/use-cases/UC-[0-9]*/ 2>/dev/null | sed -E 's#.*/(UC-[0-9]+)-[^/]*/$#\1#'
done | sort -u)"
# 7.4 (P-24): a CON-### lives in the slice br.md (`- **CON-001 Technical:**`) — in a craft slice the CON belongs to the
# craft. Minus the numbers that also exist at the root/core (CONs are numbered per BR so collisions are normal, and a
# collision cannot be attributed to anyone, so it is skipped).
NCON="$(for n in $NGHE; do cat /dev/null "$ROOT/specs/$n"/br-[0-9]*/br.md 2>/dev/null | grep -oE '\*\*CON-[0-9]+' | tr -d '*'; done | sort -u)"
CCON="$(cat /dev/null "$ROOT"/specs/core/br-[0-9]*/br.md "$ROOT/specs/br.md" 2>/dev/null | awk '/^# BR-000:/{s=1;next} /^# BR-/{s=0} !s' | grep -oE '\*\*CON-[0-9]+' | tr -d '*' | sort -u)"   # skip the BR-000 sample: the template CON-001..003 belong to nobody
NCON="$(printf '%s\n' "$CCON" | awk 'NR==FNR{a[$0];next} NF && !($0 in a)' - <(printf '%s\n' "$NCON"))"
NIDS="$(printf '%s\n%s\n' "$NIDS" "$NCON" | awk 'NF' | sort -u)"
NENT="$(for n in $NGHE; do
  ls "$ROOT/specs/$n/entities/"*.md 2>/dev/null | xargs -n1 basename 2>/dev/null | sed 's/\.md$//' | grep -vE '^(README|_.*)$'
done | sort -u)"
IDRE="$(printf '%s\n' "$NIDS" | awk 'NF' | tr '\n' '|' | sed 's/|$//')"
# entity names are matched whole-word and case-sensitively (`Order`, `Listing`)
ENRE="$(printf '%s\n' "$NENT" | awk 'NF' | tr '\n' '|' | sed 's/|$//')"

# ── the list of files to look at ──────────────────────────────────────────
is_root_spec() { # 0 if the file is in the "root + core" area (where ① applies)
  case "$1" in
    specs/vision.md|specs/decisions.md|specs/traceability.md) return 1;;
    *.trace.md|*/evidence.md|notes/*) return 1;;
    specs/adr/*|specs/core/*) return 0;;
    specs/*/*) return 1;;
    specs/*.md) return 0;;
  esac
  return 1
}
is_core_src() { case "$1" in src/core/*) return 0;; esac; return 1; }
case "$MODE" in
  staged) LIST="${SDD_STAGED:-$(git -C "$ROOT" diff --cached --name-only --diff-filter=d)}";;
  files)  LIST="$(for f in $FILES; do printf '%s\n' "${f#$ROOT/}"; done)";;
  *)      LIST="$( { find "$ROOT/specs" -maxdepth 1 -name '*.md'; find "$ROOT/specs/adr" "$ROOT/specs/core" -type f -name '*.md' 2>/dev/null
                     find "$ROOT/src/core" -type f 2>/dev/null; } | sed "s#^$ROOT/##")";;
esac
HITS=0; ENTW=0
for f in $LIST; do
  [ -f "$ROOT/$f" ] || continue
  if is_root_spec "$f"; then
    # drop <!-- --> blocks and lines inside ``` — an example quoted in the guidance text is not a real quotation.
    # 7.0.1 (R ticket #71, P-13): drop the EVIDENCE sections too — `## History` · `## Adversarial pass` · `## Re-read`,
    # up to the next `## ` heading. The ledger rule forbids editing a History line, so a root glossary/ADR whose old
    # History mentions a craft RULE would go red every time anyone touched the file — the same class as *.trace.md /
    # evidence.md, already exempted by file. A dropped line is printed as a blank line so the printed line numbers still match the file.
    BODY="$(strip_markup < "$ROOT/$f" | awk -v TR="$(kwh trace)[[:space:]]*$" '
      $0 ~ TR { v=1; print ""; next }
      /^## / { v=0 }
      /^```/ { c=!c; print ""; next }
      (c || v) { print ""; next }
      { print }')"
    H=""; [ -n "$IDRE" ] && H="$(printf '%s\n' "$BODY" | grep -nwE "($IDRE)" | head -5)"
    if [ -n "$H" ]; then
      HITS=$((HITS+1))
      bad "$f quotes a craft ID ($(printf '%s\n' "$H" | grep -owE "($IDRE)" | sort -u | tr '\n' ' ' | sed 's/ $//')) — the root and the core do not know a craft"
      printf '%s\n' "$H" | cut -c1-100 | sed 's/^/      /'
    fi
    E=""; [ -n "$ENRE" ] && E="$(printf '%s\n' "$BODY" | grep -nwE "($ENRE)" | head -3)"
    if [ -n "$E" ]; then
      ENTW=$((ENTW+1))
      warn "$f mentions a craft entity name ($(printf '%s\n' "$E" | grep -owE "($ENRE)" | sort -u | tr '\n' ' ' | sed 's/ $//')) — usually fine, but an entity every craft needs belongs in specs/core/entities/"
    fi
  fi
  if is_core_src "$f"; then
    H="$(grep -nE "(import|require|from)[^\n]*['\"](\.\./)+($NRE)/|['\"](src|@|~)/($NRE)/" "$ROOT/$f" | head -5)"
    if [ -n "$H" ]; then
      HITS=$((HITS+1))
      bad "$f imports from src/<craft> — src/core may not know a craft ($NGHE)"
      printf '%s\n' "$H" | cut -c1-100 | sed 's/^/      /'
    fi
  fi
done
if [ "$HITS" -eq 0 ]; then
  ok "the core/craft boundary: nowhere in the root/core quotes a craft ID ($(printf '%s\n' "$NIDS" | grep -c .) craft IDs, $(printf '%s\n' "$NENT" | grep -c .) craft entities, $(printf '%s\n' "$LIST" | grep -c .) files looked at${ENTW:+; $ENTW files mention a craft entity name — a warning})"
  exit 0
fi
info "the fix: whatever the craft needs and the core needs too goes up to the root/core (a project-wide RULE, a shared entity); everything else means that line belongs in specs/<craft>/"
exit 1

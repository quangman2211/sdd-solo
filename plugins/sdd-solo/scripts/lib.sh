#!/usr/bin/env bash
# Shared functions for the sdd-solo scripts. bash 3.2 compatible (macOS).
ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
bad()  { printf '  \033[31m✗\033[0m %s\n' "$1"; FAIL=$((FAIL+1)); _reg_next; }
# bad_at <file:line> <message> — the same, with WHERE. A finding that does not say where costs the reader a
# second search through a file they already believed was right.
bad_at() { printf '  \033[31m✗\033[0m %s\n' "$2"; printf '      → %s\n' "$1"; FAIL=$((FAIL+1)); _reg_next; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; WARN=$((WARN+1)); }
info() { printf '  – %s\n' "$1"; }
FAIL=0; WARN=0
# 8.5.0 — a red check must say WHICH STEP TO GO BACK TO, not only how many errors there are.
#
# Up to 8.4.2 every check ended with `NOT THROUGH — 5 errors, 3 warnings. Fix them and run again.` and left the
# reader to work out, from 48 possible messages, which of the 14 steps had actually failed. Measured at runxops as
# a recurring complaint from the coordinator: the gate says WHAT is wrong, never WHERE to go next.
#
# Borrowed from GitHub Spec Kit, which does this well: its `analyze` ends with explicit command suggestions
# ("Run /speckit.specify with refinement", "Manually edit tasks.md to add coverage for ...") — templates/commands/
# analyze.md:198 of v1.0.11. Only the REPORTING is borrowed: Spec Kit enforces nothing but file existence, and its
# analyze leaves no trace on disk, which is the failure this repo diagnosed at #29.
#
# The mechanism is per SECTION, not per message: a check calls `step` once at the top of each numbered section,
# and every `bad` inside that section registers it. Rewriting 142 messages would have been the expensive way to
# get the same line, and each rewrite is a chance to change a message a githook or §9 matches on.
SDD_STEP=""; SDD_NEXT=""
step() { SDD_STEP="$1"; }
_reg_next() {
  [ -n "$SDD_STEP" ] || return 0
  printf '%s' "$SDD_NEXT" | grep -qxF "$SDD_STEP" && return 0
  SDD_NEXT="$SDD_NEXT$SDD_STEP
"
}
# nexts — print the steps that actually went red, in the order the sections run, each at most once.
nexts() {
  [ -n "$SDD_NEXT" ] || return 0
  echo "Next, in this order:"
  printf '%s' "$SDD_NEXT" | sed 's/^/  /'
}

project_root() {
  if [ -n "$CLAUDE_PROJECT_DIR" ]; then echo "$CLAUDE_PROJECT_DIR"; return; fi
  git rev-parse --show-toplevel 2>/dev/null || pwd
}

# ── 7.0 (#55): the core|craft × br-### axis — ONE place every script looks paths up ───
# Up to 6.6.x, 11 scripts ran their own `find`/`grep` straight at `specs/contexts/<ctx>/…`,
# `specs/br.md`, `specs/internal/…`. Changing the tree meant changing 11 places, and a miss
# was silent. Since 7.0 every path goes through the functions below; each one tries the 7.0
# layout FIRST and falls back to 6.x, so an unmigrated repo runs exactly as before (measured
# with an output snapshot).
# Layout 7.0 (plan 2026-09-18, T2 T3):
#   specs/vision.md · glossary.md · rules.md · architecture.md · decisions.md · adr/   ← project-wide
#   specs/core/entities/<Entity>.md · specs/core/br-###/{br.md,evidence.md,use-cases/}  ← the core
#   specs/<craft>/{glossary.md,rules.md,adr/,entities/,br-###/…}                         ← each craft
# Layout 6.x: specs/br.md · specs/contexts/<ctx>/{entities.md,use-cases.md,use-cases/} · specs/internal/…

# layout <root> → v7 | v6. Told apart by the presence of vision.md or a br-###/ directory.
layout() {
  [ -f "$1/specs/vision.md" ] && { printf 'v7'; return; }
  ls -d "$1"/specs/*/br-[0-9]*/ >/dev/null 2>&1 && { printf 'v7'; return; }
  printf 'v6'
}
find_vision() { [ -f "$1/specs/vision.md" ] && printf '%s' "$1/specs/vision.md"; }

# find_uc UC-002 <root> → the path of UC-002.md (empty if absent). 7.0 first, then 6.x.
find_uc() {
  local id="$1" root="$2" f
  f="$(find "$root/specs" -type f -path "*/br-*/use-cases/${id}-*/${id}.md" -not -path '*/specs/changes/*' 2>/dev/null | head -1)"
  [ -z "$f" ] && f="$(find "$root/specs/contexts" -type f -path "*/use-cases/${id}-*/${id}.md" 2>/dev/null | head -1)"
  printf '%s' "$f"
}
# all_uc_files <root> → every UC-###.md file (minus .flow/.sequence/.trace), 7.0 and 6.x, sorted
all_uc_files() {
  { find "$1/specs" -type f -path '*/br-*/use-cases/UC-*/UC-*.md' -not -path '*/specs/changes/*' 2>/dev/null
    find "$1/specs/contexts" -type f -path '*/use-cases/UC-*/UC-*.md' 2>/dev/null; } \
  | grep -vE '\.(flow|sequence|trace)\.md$' | sort -u
}
# owner_of <path-to-UC.md> → `core` | the craft name (7.0) | the context name (6.x). Replaces ctx_of.
# It is also the sub-directory of uc_test_dir: tests/use-cases/<owner>/UC-###/.
owner_of() {
  case "$1" in
    */specs/contexts/*) printf '%s' "$1" | sed -E 's#.*/specs/contexts/([^/]+)/.*#\1#';;
    *) printf '%s' "$1" | sed -E 's#.*/specs/([^/]+)/.*#\1#';;
  esac
}
ctx_of() { owner_of "$1"; }   # the old name — kept for the .sdd/scripts/ copy of a repo that has not updated
# br_of <path-to-UC.md> → the BR-### of the slice holding the UC (7.0: from the directory name br-###; 6.x: from Metadata)
br_of() {
  case "$1" in
    */br-[0-9]*/use-cases/*) printf '%s' "$1" | sed -E 's#.*/br-([0-9]+)/use-cases/.*#BR-\1#';;
    *) grep -oE "($(kw relbr)):\*\* *BR-[0-9]+" "$1" 2>/dev/null | grep -oE 'BR-[0-9]+' | head -1;;
  esac
}
# br_dir BR-003 <root> → the slice directory (7.0), empty on 6.x
br_dir() { ls -d "$2"/specs/*/br-"${1#BR-}"/ 2>/dev/null | head -1 | sed 's#/$##'; }
# br_file BR-003 <root> → the file containing `# BR-003:` — 7.0: <br_dir>/br.md · 6.x: specs/br.md
br_file() { local d; d="$(br_dir "$1" "$2")"; if [ -n "$d" ]; then printf '%s/br.md' "$d"; else printf '%s/specs/br.md' "$2"; fi; }
# br_files <root> → every br.md (7.0) or specs/br.md (6.x)
br_files() {
  if [ "$(layout "$1")" = v7 ]; then ls "$1"/specs/*/br-[0-9]*/br.md 2>/dev/null | sort
  else [ -f "$1/specs/br.md" ] && printf '%s\n' "$1/specs/br.md"; fi
}
# br_text <root> → every BR concatenated (lets a scan catch a CON number reused across two BRs)
br_text() { for f in $(br_files "$1"); do cat "$f"; printf '\n'; done; }
# br_body BR-001 <root> — the body of one BR (without the `# BR-###:` line), empty if absent
br_body() { br_text "$2" | awk -v h="# $1:" 'index($0,h)==1{f=1;next} f&&/^# BR-/{exit} f{print}'; }
# br_title BR-001 <root> → the `# BR-###: …` line
br_title() { br_text "$2" | grep -E "^# $1:" | head -1; }
# br_ids <root> — every BR present in the repo
br_ids() { br_text "$1" | grep -oE '^# BR-[0-9]+' | awk '{print $2}' | awk '!a[$0]++'; }
# owner_of_br BR-003 <root> → core | craft (7.0); empty on 6.x
owner_of_br() { local d; d="$(br_dir "$1" "$2")"; [ -n "$d" ] && basename "$(dirname "$d")"; }
# evidence_file BR-003 <root> → 7.0: <br_dir>/evidence.md · 6.x: specs/br.evidence.md
evidence_file() { local d; d="$(br_dir "$1" "$2")"; if [ -n "$d" ]; then printf '%s/evidence.md' "$d"; else printf '%s/specs/br.evidence.md' "$2"; fi; }
# br_untouched <root> — 0 if there is no real BR yet (only the sample plus an empty skeleton)
br_untouched() {
  if [ "$(layout "$1")" = v7 ]; then
    ! br_text "$1" | grep -E '^# BR-[0-9]+: *[^ <]' | grep -vqE '^# BR-000'
  else grep -qE "$(kw ph_brname)" "$1/specs/br.md" 2>/dev/null; fi
}
# uc_table_file UC-### <root> → the file holding the table | UC-### | … | Status |: 7.0 = the slice's br.md,
# 6.x = the context's use-cases.md (#44)
uc_table_file() {
  local f b t; f="$(find_uc "$1" "$2")"
  if [ -z "$f" ]; then
    # 7.0.1 (#51): a UC with only a table row and no file yet (planned then dropped) → find the table holding that row
    for t in $(br_files "$2") $(ls "$2"/specs/contexts/*/use-cases.md 2>/dev/null); do
      grep -qE "^\| *$1 *\|" "$t" && { printf '%s' "$t"; return 0; }
    done
    return 0
  fi
  case "$f" in
    */specs/contexts/*) printf '%s/specs/contexts/%s/use-cases.md' "$2" "$(owner_of "$f")";;
    *) b="$(br_of "$f")"; [ -n "$b" ] && br_file "$b" "$2";;
  esac
}

# rules_files <root> → specs/rules.md + specs/<craft>/rules.md (whichever exist)
rules_files() {
  { [ -f "$1/specs/rules.md" ] && printf '%s\n' "$1/specs/rules.md"
    ls "$1"/specs/*/rules.md 2>/dev/null | grep -vE '/specs/(contexts|internal|changes)/'; } | awk 'NF&&!a[$0]++'
}
# rule_file RULE-### <root> → the file with the heading `## RULE-###` (empty if absent)
rule_file() { for f in $(rules_files "$2"); do grep -qE "^## $1\b" "$f" && { printf '%s' "$f"; return; }; done; }
# rules_text <root> → every rules.md concatenated
rules_text() { for f in $(rules_files "$1"); do cat "$f"; printf '\n'; done; }
# adr_dirs <root> → the ADR directories that exist: specs/adr · specs/<craft>/adr · specs/internal/adr · docs/adr
adr_dirs() {
  { [ -d "$1/specs/adr" ] && printf '%s\n' "$1/specs/adr"
    ls -d "$1"/specs/*/adr 2>/dev/null | grep -vE '/specs/(contexts|changes)/'
    [ -d "$1/docs/adr" ] && printf '%s\n' "$1/docs/adr"; } | awk 'NF&&!a[$0]++'
}
# adr_file ADR-### <root> → the ADR file (empty if absent); skips the `_*` templates
adr_file() { for d in $(adr_dirs "$2"); do f="$(ls "$d/$1"* 2>/dev/null | grep -v '/_' | head -1)"; [ -n "$f" ] && { printf '%s' "$f"; return; }; done; }
# arch_file · decisions_file · glossary_file <root> → the 7.0 path if it exists, else the 6.x path
# (returns a path even when the file does not exist, so a "missing <path>" message points at the right place)
arch_file()      { if [ -f "$1/specs/architecture.md" ] || [ "$(layout "$1")" = v7 ]; then printf '%s/specs/architecture.md' "$1"; else printf '%s/specs/internal/architecture.md' "$1"; fi; }
decisions_file() { if [ -f "$1/specs/decisions.md" ] || [ "$(layout "$1")" = v7 ]; then printf '%s/specs/decisions.md' "$1"; else printf '%s/specs/internal/decisions.md' "$1"; fi; }
glossary_file()  { printf '%s/specs/glossary.md' "$1"; }
# nghe_glossary · nghe_rules <owner> <root> → the craft's own file (empty if absent / if core)
nghe_glossary() { [ "$1" != core ] && [ -f "$2/specs/$1/glossary.md" ] && printf '%s/specs/%s/glossary.md' "$2" "$1"; }
nghe_rules()    { [ "$1" != core ] && [ -f "$2/specs/$1/rules.md" ] && printf '%s/specs/%s/rules.md' "$2" "$1"; }
# nghe_list <root> → the craft names: nghe_paths= in .sdd/config, else probe the directories under specs/
nghe_list() {
  local v; v="$(cfg_get nghe_paths "$1" "")"
  [ -n "$v" ] && { printf '%s' "$v"; return; }
  for d in "$1"/specs/*/; do
    d="$(basename "$d")"
    case "$d" in core|adr|changes|contexts|internal|_*) continue;; esac
    { ls -d "$1/specs/$d"/br-[0-9]*/ >/dev/null 2>&1 || [ -f "$1/specs/$d/glossary.md" ] || [ -d "$1/specs/$d/entities" ]; } && printf '%s ' "$d"
  done | sed 's/ *$//'
}
# entity_files <path-to-UC.md> <root> → the entity files this UC may use:
#   7.0: specs/core/entities/*.md + specs/<owner>/entities/*.md (minus README, _*) · 6.x: the context's entities.md
entity_files() {
  local o; o="$(owner_of "$1")"
  case "$1" in
    */specs/contexts/*) [ -f "$2/specs/contexts/$o/entities.md" ] && printf '%s\n' "$2/specs/contexts/$o/entities.md";;
    *) { ls "$2"/specs/core/entities/*.md 2>/dev/null
         [ "$o" != core ] && ls "$2/specs/$o/entities/"*.md 2>/dev/null; } | grep -vE '/(README|_[^/]*)\.md$';;
  esac
}
# entity_cited <path-to-UC.md> <root> → among entity_files, the ones whose entity name appears in the
# binding part of the UC (7.0); 6.x → entities.md itself (one file holding every entity of the context)
entity_cited() {
  local live; live="$(awk -v re="^## ($(kw trace))" '$0 ~ re {t=1;next} /^## /{t=0} !t' "$1")"
  for f in $(entity_files "$1" "$2"); do
    case "$f" in */specs/contexts/*) printf '%s\n' "$f"; continue;; esac
    n="$(basename "$f" .md)"
    printf '%s' "$live" | grep -qE "(^|[^A-Za-z0-9_])$n([^A-Za-z0-9_]|$)" && printf '%s\n' "$f"
  done
}
# entity_names <path-to-UC.md> <root> → the entity names found in entity_files (7.0: the file name; 6.x: `class X` / `## X`)
entity_names() {
  for f in $(entity_files "$1" "$2"); do
    case "$f" in
      */specs/contexts/*) grep -oE '^[[:space:]]*class [A-Za-z][A-Za-z0-9_]*|^## [A-Z][A-Za-z0-9_]*' "$f" | awk '{print $NF}' | grep -vxE 'Domain|History|Entity[AB]?';;
      *) basename "$f" .md;;
    esac
  done | sort -u
}
# glossary_files <owner> <root> → specs/glossary.md + specs/<craft>/glossary.md (whichever exist)
glossary_files() {
  { [ -f "$2/specs/glossary.md" ] && printf '%s\n' "$2/specs/glossary.md"
    nghe_glossary "$1" "$2"; } | awk 'NF'
}
# id_exists <ID> <root> → 0 if the ID is real. The commit-msg githook copies this logic (it runs bare bash) — same path list.
id_exists() {
  case "$1" in
    UC-*)   [ -n "$(find_uc "$1" "$2")" ];;
    CHG-*)  ls -d "$2/specs/changes/$1-"* >/dev/null 2>&1 || ls -d "$2/changes/$1-"* >/dev/null 2>&1;;
    RULE-*) [ -n "$(rule_file "$1" "$2")" ];;
    BR-*)   br_text "$2" | grep -qE "^#{1,2} $1\b";;
    ADR-*)  [ -n "$(adr_file "$1" "$2")" ];;
    # A CON-### lives in the ## Constraints of a BR: `- **CON-001 Technical:** …` (4.1.0)
    CON-*)  br_text "$2" | grep -qE "^-? *\*\*$1\b";;
    *) return 1;;
  esac
}

# ── Documentation keywords: bilingual (7.7.0) ────────────────────────────
# The table is scripts/kw.tsv (name · kind · Vietnamese · English) — bash and node read THE SAME file,
# nothing is passed through an environment variable. The full reasoning is at the top of kw.tsv.
#   kw  <name> → '<vi>|<en>'  the alternation body for READING (accepts either language)
#   kwh <name> → '^## (…)'    the section-heading pattern
#   kwl <name> → '\*\*(…):\*\*' the bold-label pattern
#   kw_w <name> [root] → ONE side for WRITING, per the project's doc_lang (default vi — a running
#                        repo does not change one byte; scaffold writes doc_lang=en for a NEW project)
# A name that is not in the table → printed to stderr and returns 1. Never let it return empty: an empty
# pattern matches everything, and a falsely green gate is the most expensive kind of breakage in this repo.
# KW_TSV is computed AT CALL TIME, not at assignment: SDD_LIBDIR is set at the end of lib.sh, so an
# early assignment would yield "/kw.tsv".
_kw_tsv() { printf "%s/kw.tsv" "${SDD_LIBDIR:-$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)}"; }
_kw_col() {
  KW_TSV="$(_kw_tsv)"
  awk -F'\t' -v n="$1" -v c="$2" '$1 == n { print $c; found=1; exit } END { exit !found }' "$KW_TSV" 2>/dev/null
}
kw() {
  _kw_vi="$(_kw_col "$1" 3)" || { printf 'lib.sh kw(): no keyword "%s" in kw.tsv\n' "$1" >&2; return 1; }
  _kw_en="$(_kw_col "$1" 4)"
  # drop the duplicate side: a multi-form group can have the same element in both columns (History), do not list it twice
  printf '%s|%s\n' "$_kw_vi" "$_kw_en" | tr '|' '\n' | awk '!seen[$0]++' | paste -sd'|' -
}
kwh() { printf '^## (%s)' "$(kw "$1")"; }
kwl() { printf '\\*\\*(%s):\\*\\*' "$(kw "$1")"; }
# doc_lang <root> → vi | en. The language scripts WRITE documents in. Default vi: every running repo
# keeps its behaviour; scaffold writes doc_lang=en when it creates a NEW .sdd/config.
doc_lang() { _dl="$(cfg_get doc_lang "${1:-$(project_root)}" vi)"; case "$_dl" in en) echo en;; *) echo vi;; esac; }
kw_w() {
  _kww="$(_kw_col "$1" "$( [ "$(doc_lang "${2:-}")" = en ] && echo 4 || echo 3 )")" \
    || { printf 'lib.sh kw_w(): no keyword "%s" in kw.tsv\n' "$1" >&2; return 1; }
  printf '%s\n' "$_kww"
}
# kw_pairs — the table for the test suite (tests/kwswap.mjs): one line `name<TAB>vi<TAB>en`, comments dropped.
kw_pairs() { grep -v '^#' "$(_kw_tsv)" 2>/dev/null | awk -F'\t' 'NF>=4'; }

# slug_of <path> → the part after UC-###-
slug_of() { basename "$(dirname "$1")" | sed -E 's/^UC-[0-9]+-//'; }
# ── the UC table (#44) ───────────────────────────────────────────────────
# Two places state a UC's status: the **Status:** line inside the UC file, and the Status column
# of the table `| UC-### | Name | Actor | BR-### | Status |`. On 6.x the table lives in
# specs/contexts/<ctx>/use-cases.md; on 7.0 in `## Related Use Cases` of the slice's br.md.
# uc_table_file (above) returns the right file for both — pass.sh/status.sh only go through it (#51).
# uc_table_status UC-### <root> → the Status cell of the UC's table row (empty if there is no row/table)
uc_table_status() {
  _t="$(uc_table_file "$1" "$2")"; [ -n "$_t" ] && [ -f "$_t" ] || return 0
  awk -F'|' -v id="$1" 'NF>=3 && $2 ~ ("^[ ]*" id "[ ]*$") { s=$(NF-1); gsub(/^[ ]+|[ ]+$/,"",s); print s; exit }' "$_t"
}
# uc_table_set UC-### <status> <root> → write the Status cell; 0 if there was a row to write, 1 if not
uc_table_set() {
  _t="$(uc_table_file "$1" "$3")"; [ -n "$_t" ] && [ -f "$_t" ] || return 1
  [ -n "$(uc_table_status "$1" "$3")" ] || return 1
  awk -F'|' -v OFS='|' -v id="$1" -v st="$2" '
    NF>=3 && $2 ~ ("^[ ]*" id "[ ]*$") { $(NF-1) = " " st " " } { print }' "$_t" > "$_t.tmp" && mv "$_t.tmp" "$_t"
}

# find_chg CHG-001 <root> → the change directory (empty if absent). 2.0.0 moved
# changes/ → specs/changes/; both are accepted for an unmigrated repo.
find_chg() {
  local d
  d="$(ls -d "$2/specs/changes/$1-"* 2>/dev/null | head -1)"
  [ -z "$d" ] && d="$(ls -d "$2/changes/$1-"* 2>/dev/null | head -1)"
  printf '%s' "$d"
}

# ── 7.5 — mermaid through a parser, not through grep (P-32) ──────────────
# mmd <--lint|--edges|--nodes|--states|--kinds> <file…> — prints the output of js/mermaid.mjs.
# mmd_ok → 0 when it can run (node present + js/mermaid.mjs next to lib.sh). When it cannot, EVERY caller
# must fall back to the previous release's grep path: a check that cannot run must never become a red check.
SDD_LIBDIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
mmd_ok() { command -v node >/dev/null 2>&1 && [ -f "$SDD_LIBDIR/js/mermaid.mjs" ]; }
mmd() { local m="$1"; shift; mmd_ok || return 0; bash "$SDD_LIBDIR/mermaid.sh" "$m" "$@"; }
# mmd_lint <file…> — prints the error lines through bad(), returns 1 if there were any. Skips missing files.
mmd_lint() {
  local f ff="" out
  for f in "$@"; do [ -f "$f" ] && ff="$ff $f"; done
  [ -n "$ff" ] || return 0
  mmd_ok || return 0
  out="$(mmd --lint $ff)" || true
  [ -n "$out" ] || return 0
  printf '%s\n' "$out" | while IFS= read -r l; do
    printf '  \033[31m✗\033[0m %s\n' "$(printf '%s' "$l" | sed "s#^$ROOT/##" | cut -c1-200)"
  done
  return 1
}

sha() { if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | cut -d' ' -f1; else sha256sum "$1" | cut -d' ' -f1; fi; }
today() { date +%Y-%m-%d; }

# 6.0.0 (#38): the verify door is shared by the DoR gate (the UC file) and the Phase 5 gate (proposal.md).
# rr_lines <file> → the F# lines in ## Re-read; rr_count (stdin) → how many lines carry
# BOTH an [anchor: ...] AND an outcome other than ___. That is the whole anti-faking latch: making up
# such a line costs exactly as much as actually reading.
# ── the evidence trail lives beside the UC, not inside it (8.0.0) ───────
# Up to 7.8 the trail — `## Adversarial pass` · `## Re-read` · `## History` — sat in the UC body and only moved
# into UC-###.trace.md when the UC CLOSED. Measured on the runxops copy: 56% of 2.33 MB of UC bodies is trail,
# and the worst single file is 455 KB of which 72% is trail. A closed UC is not the expensive case — an OPEN one
# is, because that is the file every working session loads. From 8.0.0 the trail is written to UC-###.trace.md
# from its first line and the UC body keeps one `## Evidence` pointer.
#
# trace_of <UC file> → the side file next to it.
# ev_body <keyword> <UC file> → that evidence section's body: from the side file when the section is there,
# from the UC body otherwise. The fallback is not politeness. Every repo written before 8.0.0 has the trail in
# the body, and a check that quietly stopped looking there would turn "the evidence is missing" into a RED gate
# on work that was actually done — the gate would be lying, which is the one failure this plugin cannot have.
# `migrate --trace` moves a repo across; until it runs, both places read.
trace_of() { case "$1" in *.md) printf '%s\n' "${1%.md}.trace.md";; *) printf '%s\n' "$1.trace.md";; esac; }
ev_body() {
  _evre="$(kwh "$1")"; _evo=""
  # The BODY WINS when it still has the section, and that order is the whole compatibility guarantee. A repo
  # written before 8.0.0 keeps its live trail in the body and often ALSO has a UC-###.trace.md left by an older
  # `pass.sh close` — reading the side file first made the gate answer from the archive instead of from the live
  # section, and the verdict moved on UCs nobody had touched (measured: +28 ✓ on one UC of the runxops copy).
  # Reading the body first means a repo that has not migrated cannot notice 8.0.0 at all; only a body with the
  # section GONE — which is what `migrate --trace` and the 8.0.0 templates produce — falls through to the side file.
  # The heading must match EXACTLY — `## Re-read`, not `## Re-read — 2026-09-17`. A trail file accumulates
  # ARCHIVE blocks under dated headings (that is what `pass.sh close` has written since 5.0.0), and a prefix match
  # folds the archive into the live section: measured on the runxops copy, gate-check §7 then walked every
  # `→ spec` ID twice and one UC went from 38 ✓ to 65 ✓ purely from having been closed once. The live trail is the
  # undated section; a dated one is a thing already put away, and it was invisible to the gate before 8.0.0 too.
  _evx="$_evre[[:space:]]*\$"
  _evo="$(awk -v re="$_evx" '$0 ~ re {f=1;next} /^## /{f=0} f' "$2" 2>/dev/null)"
  if [ -n "$(printf '%s' "$_evo" | tr -d '[:space:]')" ]; then printf '%s\n' "$_evo"; return 0; fi
  _evt="$(trace_of "$2")"
  [ -f "$_evt" ] && awk -v re="$_evx" '$0 ~ re {f=1;next} /^## /{f=0} f' "$_evt" 2>/dev/null
}
# uc_text <UC file> → the UC body PLUS its trail, for the checks that scan for quoted IDs. Moving the trail out
# must not change WHAT is checked, only where it is stored: before 8.0.0 a RULE named in an adversarial anchor
# was inside the file the ID scan read, so it still has to be. Measured: without this, six UCs of the runxops
# copy silently stopped checking between 1 and 5 RULE IDs the moment the trail moved.
uc_text() { cat "$1" 2>/dev/null; ev_body adversarial "$1"; ev_body reread "$1"; ev_body history "$1"; }
rr_lines() { ev_body reread "$1" | grep -E '^- F[0-9]+ '; }
# rr_rounds <UC file> → how many re-read ROUNDS the trail records (one `- Run date:` line per round).
# 8.0.0 uses it for the ceiling; see rr_max in .sdd/config and gate-check §8.
rr_rounds() { ev_body reread "$1" | grep -cE "^- *($(kw rundate))[[:space:]]*:" 2>/dev/null || true; }
# rr_max <root> → the ceiling on re-read rounds, 0 = no ceiling. Default 3, and it applies to repos that never
# wrote the line: measured on runxops, rounds and unresolved findings rise together — 13 rounds / 105 Undecided
# (UC-024), 13 / 74 (UC-029), 12 / 71 (UC-026) — while every UC that stopped at one round has none. A ceiling
# nobody is under is not a ceiling, so the default is the number, not "off".
# 8.5.0: the default drops from 3 to 2. Measured on runxops across 18 UCs and 1,048 findings: a UC that ran ONE
# round resolved 79% of them at 1.0 KB of trail per resolved finding; a UC that ran FOUR OR MORE resolved 34% at
# 3.5 KB — three times the findings, less than half the resolution rate, ten times the leftover. UC-024 ran 13
# rounds for 109 findings, 0 resolved, 63 KB. Another round is not an answer to the previous round.
rr_max() { _rm="$(cfg_get rr_max "${1:-$(project_root)}" 2)"; case "$_rm" in ''|*[!0-9]*) _rm=2;; esac; printf '%s\n' "$_rm"; }
rr_count() {
  # 7.7.0: `[anchor: …]` is bilingual too — `nb` is a pattern, not a literal, because an English spec's F# line
  # writes `[anchor: …]`. This is one of only two doors that open the Phase 5 gate; hard-coding `neo` here means
  # an English spec that really was re-read still goes red with "not re-read" — a falsely red gate no other check sees.
  # The brackets are written `[[]` and `[]]`, NOT `\[` `\]`: `awk -v` processes the STRING's escapes before the
  # pattern reaches the regex engine, so `\\]` arrives as `\]` and the pattern misses silently (measured: the
  # Vietnamese side went from green to red "not re-read"). Inside a bracket there is no escape left to swallow.
  awk -v lb="^[[:space:]]*($(kw output))[[:space:]]*:" \
      -v nb="[[]($(kw anchor)):[^]]*[^] [:space:]][]]" '
    $0 ~ nb && /→/ {
      i = index($0, "→"); o = substr($0, i + 3)
      # Strip the label first and only then ask whether anything is left: keeping it means the
      # arrow + outcome + ___ string is still non-empty thanks to the two label words themselves, so a line
      # that decided nothing opens the door too. That is the cheapest faking case there is.
      # Put NO single quote inside this awk block — it terminates the shell string.
      sub(lb, "", o)
      gsub(/[_[:space:]]/, "", o)
      if (o != "") n++
    } END { print n + 0 }'
}
# 7.4 (P-20): rr_undecided (stdin) → how many F# lines have "→ Undecided" as their outcome. It is still a valid
# gate outcome (7.0.1 #53: verify does not ask, and opening the gate with an unanswered question is a debt the owner
# takes on knowingly) — but the gate must SAY the number, or "11 findings with an anchor + an outcome" looks exactly
# the same whether nothing was decided or everything was (CHG-002 at runxops: 11 tails had to be changed to "Decided"
# by hand before a reader could tell).
# 8.1.1 (P-46): it counts the LIVE TAIL, through the same reduction as rr_tail below — not the whole line.
# The re-read ledger is append-only, so a finding that HAS been settled keeps its old "→ Undecided" in the body
# and carries the answer as a further tail: `→ Undecided (waiting on the owner) → **fixed in v4**`. Grepping the
# whole line calls that Undecided forever, and at the ceiling of 8.0.0 that is a RED GATE WITH NO WAY OUT — the
# only move left is to rewrite the old words, which the ledger forbids. Measured at runxops: UC-031 had 13 F#
# lines, 11 already answered, live-tail count 2, and the gate printed "13 Undecided, ceiling reached". 7.4 (P-37)
# already settled this for the ID scan; rr_undecided was the one place left reading the dead text.
rr_undecided() {
  awk -v re="($(kw undecided))" '{
    t = $0
    gsub(/`[^`]*`/, "", t)
    while (match(t, /\([^()]*\)/)) t = substr(t, 1, RSTART - 1) substr(t, RSTART + RLENGTH)
    n = 0; while ((i = index(t, "→")) > 0) { t = substr(t, i + 3); n++ }
    if (n && t ~ re) u++
  } END { print u + 0 }'
}
# rr_tail (stdin, one line) → the LIVE TAIL of an F# line: the text after the LAST arrow, once every `…` and (…) (nested) is dropped.
# An F# body often quotes the gate error or the old tail inside code ticks / parentheses — "`✗ re-read faked → E4 …`" (UC-027 F74 at runxops),
# "(→ old Undecided …)" (P-37) — and the arrow inside those is not the line's outcome. No arrow → print empty.
rr_tail() {
  awk '{
    t = $0
    gsub(/`[^`]*`/, "", t)
    while (match(t, /\([^()]*\)/)) t = substr(t, 1, RSTART - 1) substr(t, RSTART + RLENGTH)
    n = 0; while ((i = index(t, "→")) > 0) { t = substr(t, i + 3); n++ }
    if (n) print t
  }'
}

# ── version ─────────────────────────────────────────────────────────────
CLAUDE_PLUGINS_DIR="$HOME/.claude/plugins"
# need_node <task name> — the three scripts that READ/EDIT files through js/ (context · pass · migrate) have no fallback.
# Without node, stop with a message; do not let the shell print `node: command not found` and exit 127 in silence.
need_node() {
  command -v node >/dev/null 2>&1 && return 0
  bad "Node.js (>= 18) is required to run ${1:-this script} — install node and run again"
  exit 127
}
# nodejs <util command> … — call js/util.mjs; silent when the machine has no node (every caller has a fallback)
nodejs() { command -v node >/dev/null 2>&1 || return 1; node "$SDD_LIBDIR/js/util.mjs" "$@" 2>/dev/null; }
# jver <file.json> <dotted.path> — read a version, falling back to grep when node is absent
jver() {
  local v; v="$(nodejs json "$1" "$2")"
  if [ -n "$v" ]; then printf '%s\n' "$v"
  else grep -oE '"version" *: *"[^"]+"' "$1" 2>/dev/null | head -1 | sed -E 's/.*"([^"]+)"$/\1/'; fi
}
# vcmp a b → -1 if a<b, 0 if equal, 1 if a>b. An odd string ('-', '?') counts as 0.0.0
vcmp() { awk -v a="$1" -v b="$2" 'BEGIN{na=split(a,x,".");nb=split(b,y,".");
  for(i=1;i<=3;i++){va=(i<=na?x[i]+0:0);vb=(i<=nb?y[i]+0:0);
  if(va<vb){print "-1";exit}if(va>vb){print "1";exit}}print "0"}'; }
# mkt_field <marketplace name> <dotted.path> — read known_marketplaces.json
mkt_field() { nodejs mkt "$1" "$2"; }
# mkt_of <plugin_root> → the marketplace name inferred from cache/<mkt>/<plugin>/<ver>, empty when running --plugin-dir
mkt_of() { echo "$1" | sed -nE 's#.*/plugins/cache/([^/]+)/[^/]+/[^/]+$#\1#p'; }
# installed_ver <plugin name> → the version installed on disk (installed_plugins.json)
installed_ver() { nodejs installed "$1" version; }
# installed_path <plugin name> → the directory of the installed version
installed_path() { nodejs installed "$1" path; }
# The version the Claude Code SESSION actually loaded. Only the SessionStart hook can know it
# (it runs from the loaded plugin's directory), so the hook records it for whoever needs it.
# CLAUDE_PLUGIN_ROOT is NOT an env var — it is a token Claude Code substitutes in
# hooks.json and SKILL.md, so a script launched from bash cannot read it.
sess_file() { echo "${XDG_CACHE_HOME:-$HOME/.cache}/sdd-solo/session-${1:-${CLAUDE_CODE_SESSION_ID:-none}}"; }
sess_ver()  { cat "$(sess_file)" 2>/dev/null; }
# is_semver <string> → 0 if it has the form X.Y.Z. A loose glob like [0-9]*.[0-9]* LETS
# "1.4.0<junk>" THROUGH, so do not use one; this is the strict check, anchored at both ends.
is_semver() { printf '%s' "$1" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; }
# clean_ver <string> → itself if it is semver, otherwise '-'. Use it before every comparison
# so a decision never runs on a value that cannot be trusted.
clean_ver() { if is_semver "$1"; then printf '%s' "$1"; else printf '%s' '-'; fi; }
# dump_bad <label> <string> — print the bytes so it can be traced next time, instead of guessing
dump_bad() { warn "$1 is not a valid version string — bytes:"; printf '%s' "$2" | od -c | head -3 | sed 's/^/      /'; }

# ── .sdd/config — the project's code/test paths ─────────────────────────
# The format is deliberately simple (key=value, lists separated by spaces)
# so a githook can parse it in plain shell without this lib.sh.
CFG_DEFAULT_CODE="src"; CFG_DEFAULT_TEST="tests"; CFG_DEFAULT_UCTEST="tests/use-cases"
# tool_paths: REAL code that belongs to no UC and cannot — a script that measures
# data, a one-off conversion script, a repo utility. Default EMPTY: a repo that has
# not declared it behaves exactly as before (#31). Exempt from IDs at the githook,
# not counted in the trace-ratio denominator. Why it is needed: rule 5b REQUIRES that
# "a number describing real data carries the command that measured it" — so the plugin
# is ASKING for this kind of code to be written — and then the hook refuses to commit it
# without an ID attached. Both rules are right; put side by side they leave a gap.
CFG_DEFAULT_TOOL=""
cfg_get() { # cfg_get <key> <root> [default]
  V="$(sed -n "s/^$1=//p" "$2/.sdd/config" 2>/dev/null | tail -1 | sed 's/[[:space:]]*$//')"
  [ -n "$V" ] && printf '%s' "$V" || printf '%s' "$3"
}
code_paths()  { cfg_get code_paths  "$1" "$CFG_DEFAULT_CODE"; }
test_paths()  { cfg_get test_paths  "$1" "$CFG_DEFAULT_TEST"; }
uc_test_dir() { cfg_get uc_test_dir "$1" "$CFG_DEFAULT_UCTEST"; }
tool_paths()  { cfg_get tool_paths  "$1" "$CFG_DEFAULT_TOOL"; }
# brief_path: the source file a BR was converted from (#34). It is recorded in the config so it
# is part of the MANDATORY READING ORDER — without this line the brief becomes a write-only file
# right after intake: `gate-check` measures inside specs/, `verify` reads inside specs/, and the
# three adversarial roles are deliberately blind to it. Three layers of checking, none looking outside specs/.
brief_path()  { cfg_get brief_path  "$1" ""; }
# brief_sha <root> → the short sha of the current brief, empty when there is no file
brief_sha() { _b="$(brief_path "$1")"; [ -n "$_b" ] && [ -f "$1/$_b" ] || return 1
              sha "$1/$_b" 2>/dev/null | cut -c1-12; }
# brief_rec_sha <root> → the sha br.md DECLARES on its '**Brief source:**' line, empty if not declared.
# It lives in one place because the two callers (br-check, session-start) must extract the same
# number; the first version of session-start wrote '[^\n]*' — which in grep's ERE means
# "any character but \ and n", so any path containing an 'n' missed, and a miss is silent.
# 7.0: several br.md → take the line with the LATEST `loaded YYYY-MM-DD` (runxops' old BR-001 declares an old sha while
# BR-003 declares the new one; taking the first line in file order goes falsely red with "the brief changed"). No date → the first line, as before.
brief_rec_sha() { br_text "$1" | grep -oE "$(kwl briefsource).*sha256 [0-9a-f]{12}([^0-9a-f].*)?\$" \
                  | awk -v ld="($(kw loaded)) [0-9]{4}-[0-9]{2}-[0-9]{2}" '{d=""; if (match($0,ld)) d=substr($0,RSTART+RLENGTH-10,10); print d "\t" $0}' \
                  | sort | tail -1 | grep -oE 'sha256 [0-9a-f]{12}' | cut -c8-; }
# ── REAL content or still a template ─────────────────────────────────────
# ONE single copy. Up to 4.0.0 this function was copied verbatim into br-check.sh and
# change-check.sh — two identical copies, so one round of fixing hit only half of them, and
# the session reporting the bug still assumed it lived in lib.sh because "surely a thing used
# in two places is shared".
nonempty() { printf '%s' "$1" | grep -qvE '^[[:space:]]*$'; }

# strip_markup — remove the things that LOOK like a placeholder but are valid syntax,
# before going to look for a real placeholder. List them EXPLICITLY, do not widen the regex
# into "drop every short <...>": loosening here trades a false red for a missed real red.
#   ① a <!-- ... --> block (including one spanning several lines)
#   ② HTML tags that really occur in the templates: <b> <br/> ...
#   ③ autolink markdown <https://...>
strip_markup() {
  awk '
    BEGIN { incmt = 0 }
    {
      line = $0; out = ""
      while (length(line) > 0) {
        if (incmt) {
          k = index(line, "-->")
          if (k == 0) { line = ""; break }
          line = substr(line, k + 3); incmt = 0
        } else {
          k = index(line, "<!--")
          if (k == 0) { out = out line; line = ""; break }
          out = out substr(line, 1, k - 1)
          line = substr(line, k + 4); incmt = 1
        }
      }
      print out
    }' \
  | sed -E 's#</?(br|b|i|u|em|strong|code|sub|sup|kbd|small)[[:space:]]*/?>##g; s#<[a-z]+://[^ >]*>##g'
}

# filled <text> — has REAL content: not empty, no placeholder left, not just the
# template's rows of "...".
filled() {
  nonempty "$1" || return 1
  # A placeholder can SPAN SEVERAL LINES: '<Why ...' opens on this line and '...>' closes
  # on the next. The single-line regex '<[^>]+>' matches neither, so an empty section passes
  # as if it had content. Both the opening half and the closing half must be caught.
  #
  # The CLOSING half must have a REAL character immediately before '>'. The version up to 4.0.0
  # used '>[[:space:]]*$', so a line holding only '>' — that is, AN EMPTY LINE INSIDE A BLOCKQUOTE,
  # valid markdown and used all the time — counted as a placeholder's closing half.
  # Measured consequence at runxops: a '## Background' 427 lines long, without a single '<...>',
  # still went red. And it guarded exactly the section holding every MEASUREMENT of the BR layer —
  # the check protecting the most number-dense place was the first one to be disabled.
  # Exclude '-' and '=' before '>' as well: that is a mermaid arrow ('A -->'), not a
  # placeholder's closing half.
  printf '%s\n' "$1" | strip_markup \
    | grep -qE '<[^>]+>|^[[:space:]]*<|[^[:space:]>=-]>[[:space:]]*$' && return 1
  printf '%s' "$1" | grep -vE '^[[:space:]]*$' \
    | grep -qvE '^[[:space:]]*([-*][[:space:]]*)?\.\.\.[[:space:]]*$' || return 1
  return 0
}

# paths_re "src app" → ^(src|app)/  — for grep -E over git paths
paths_re() { printf '^(%s)/' "$(printf '%s' "$1" | tr -s ' ' '|' | sed 's/|$//')"; }
# detect_paths <root> → guess code_paths from the directories present. Does NOT accept specs/
# (sdd-solo's own) as a test directory.
detect_paths() {
  C=""; for d in src app lib cmd internal pkg apps packages source; do
    [ -d "$1/$d" ] && C="$C $d"; done
  T=""; for d in tests test __tests__ spec; do [ -d "$1/$d" ] && T="$T $d"; done
  printf '%s|%s' "$(printf '%s' "$C" | sed 's/^ *//')" "$(printf '%s' "$T" | sed 's/^ *//')"
}
# has_code_path <root> → 0 if at least one code_path exists
has_code_path() { for d in $(code_paths "$1"); do [ -d "$1/$d" ] && return 0; done; return 1; }
# repo_has_code <root> → 0 if the repo has source files outside the process directories.
# Used to tell "the config is wrong" apart from "the repo has not a line of code yet".
# tool_paths does NOT count as "product code" here (#33). Without excluding it,
# `trace-ratio` prints "the repo has source files but no commit touches src tests →
# fix code_paths" on a repo that just declared tool_paths EXACTLY as 3.19.0 told it to.
# A false red, and one notch worse than silence because it pushes people to drop tool_paths
# or to stuff scripts into code_paths — walking straight back into the #31 trap just removed.
repo_has_code() {
  _t="$(tool_paths "$1")"
  _re='^(specs|\.sdd|docs|changes|checklists|prompts|\.githooks)/'
  [ -n "$_t" ] && _re="$_re|^($(printf '%s' "$_t" | tr -s ' ' '|' | sed 's/^|//; s/|$//'))/"
  git -C "$1" ls-files 2>/dev/null \
    | grep -vE "$_re" \
    | grep -qE '\.(js|ts|tsx|jsx|py|go|rb|java|cs|kt|swift|rs|php|c|cc|cpp|h|hpp|sh|sql|vue|svelte)$'
}
# plugin_script <name> — find a script that ONLY the plugin has (scaffold.sh, session-start.sh).
# The .sdd/scripts/ copy deliberately does not hold them, so a script running from the copy must
# look over at the real plugin instead of deriving a path next to itself. Prints empty if not found.
# Xem #10.
plugin_script() {
  # 1) next to me (running from the plugin itself)
  [ -x "$2/scripts/$1" ] && { printf '%s' "$2/scripts/$1"; return; }
  # 2) the INSTALLED version per installed_plugins.json — do not grab an old cached one
  IP="$(installed_path sdd-solo)"
  [ -n "$IP" ] && [ -x "$IP/scripts/$1" ] && { printf '%s' "$IP/scripts/$1"; return; }
  # 3) only as a last resort, scan the cache and take the highest version
  find "$HOME/.claude/plugins/cache" -type f -name "$1" -path '*sdd-solo*' 2>/dev/null \
    | sort -t/ -k7 -V | tail -1
}

# ── 7.2 · the agent team: roles · a per-worktree role marker · atomic locks · KETQUA ───────────────
# .sdd/roles: key=value like .sdd/config (a bare-bash githook can read it), lists separated by spaces.
#   vai=A B R D T · <V>.ten · <V>.ghi · <V>.cam · <V>.nhanh · <V>.commit=co|khong · <V>.kiem
#   vai_bat_buoc=khong|nhanh-vai|moi — khong (the default): the hook only warns, it does not block.
# No file → every function returns empty and behaviour is identical to 7.1. A write area accepts @code_paths
# @test_paths @uc_test_dir @tool_paths, expanded from .sdd/config, so paths are not copied in two places.
roles_file() { [ -f "$1/.sdd/roles" ] && printf '%s' "$1/.sdd/roles"; }
role_get() { # role_get <key> <root> [default]
  local v; v="$(sed -n "s/^$1=//p" "$2/.sdd/roles" 2>/dev/null | tail -1 | sed 's/[[:space:]]*$//')"
  if [ -n "$v" ]; then printf '%s' "$v"; else printf '%s' "$3"; fi
}
role_list()     { role_get vai "$1" ""; }
role_name()     { role_get "$1.ten" "$2" "$1"; }
role_branch()   { role_get "$1.nhanh" "$2" ""; }
role_checks()   { role_get "$1.kiem" "$2" ""; }
role_required() { role_get vai_bat_buoc "$1" khong; }
role_may_commit() { [ "$(role_get "$1.commit" "$2" co)" != khong ]; }
# role_sign <role> <root> -> the passes this role may SIGN (`<V>.ky=gate close`), empty when it may sign none.
# role_sign_declared <root> -> true when ANY role declares a `.ky` line. Signing authority is opt-in in BOTH
# directions (8.4.0, P-52): a repo that declares nothing keeps exactly the behaviour it had, marker or no marker.
# The moment one `.ky` line exists the repo has said "signing is a declared authority", and a session whose role
# is known but not listed is refused. Delegating a signature to an agent is the OWNER decision, never the agent
# own: keep `.sdd/roles` OUT of the coordinator write area, or the delegation is self-granted and means nothing.
role_sign()   { role_get "$1.ky" "$2" ""; }
role_sign_declared() { _rsd="$(roles_file "$1")"; [ -n "$_rsd" ] && grep -qE "^[A-Za-z0-9_-]+\.ky=[[:space:]]*[^[:space:]]" "$_rsd"; }
role_known()    { local v; for v in $(role_list "$2"); do [ "$v" = "$1" ] && return 0; done; return 1; }
# A pattern like `specs/**` passed through an unquoted `for x in $1` → the shell expands it into real file names
# (measured: `specs/**` became 11 paths). Turn globbing off while iterating (set -f) and restore it afterwards.
_noglob_on()  { case $- in *f*) _NG=1;; *) _NG=0; set -f;; esac; }
_noglob_off() { [ "${_NG:-1}" = 0 ] && set +f; }
_role_expand() { # expand @code_paths … from .sdd/config
  local x out=""
  _noglob_on
  for x in $1; do
    case "$x" in
      @code_paths)  out="$out $(code_paths "$2")";;
      @test_paths)  out="$out $(test_paths "$2")";;
      @uc_test_dir) out="$out $(uc_test_dir "$2")";;
      @tool_paths)  out="$out $(tool_paths "$2")";;
      *) out="$out $x";;
    esac
  done
  _noglob_off
  printf '%s' "$out" | sed 's/^ *//'
}
role_paths() { _role_expand "$(role_get "$1.ghi" "$2" "")" "$2"; }
role_deny()  { _role_expand "$(role_get "$1.cam" "$2" "")" "$2"; }
# glob_re <pattern> → an ERE anchored at both ends. Only two characters: ** = any depth · * = within one segment.
# Without a * it matches the exact path or everything under that directory. Avoids `case` so it can run inside $( ) (bash 3.2).
glob_re() {
  local p="${1%/}" r
  r="$(printf '%s' "$p" | sed -e 's/\./\\./g' -e 's/+/\\+/g' -e 's/?/\\?/g' -e 's/(/\\(/g' -e 's/)/\\)/g' -e 's/{/\\{/g' -e 's/}/\\}/g' -e 's/|/\\|/g' -e 's/\$/\\$/g' \
        -e 's#\*\*/#__DSS__#g' -e 's#\*\*#__DS__#g' -e 's#\*#[^/]*#g' -e 's#__DSS__#(.*/)?#g' -e 's#__DS__#.*#g')"
  if printf '%s' "$p" | grep -q '\*'; then printf '^%s$' "$r"; else printf '^%s(/.*)?$' "$r"; fi
}
# path_in <path> "<pattern …>" → 0 if it matches one pattern
path_in() { local m r=1; _noglob_on; for m in $2; do printf '%s' "$1" | grep -qE "$(glob_re "$m")" && { r=0; break; }; done; _noglob_off; return $r; }
# role_allows <role> <path> <root> → 0 if the role may write there. A deny beats a grant.
role_allows() { path_in "$2" "$(role_deny "$1" "$3")" && return 1; path_in "$2" "$(role_paths "$1" "$3")"; }
# role_of_path <path> <root> → the roles allowed to write there (so the blocking message can say "this is T's")
role_of_path() { local v out=""; for v in $(role_list "$2"); do role_allows "$v" "$1" "$2" && out="$out $v"; done; printf '%s' "$out" | sed 's/^ *//'; }
# role_marker_file <root> → the role-marker file PRIVATE to this worktree: .git/sdd-role in the main
# checkout, .git/worktrees/<name>/sdd-role in a secondary one. Not in git, not tied to a branch (measured on runxops, 7.2).
role_marker_file() { local m; m="$(cd "$1" && git rev-parse --git-path sdd-role 2>/dev/null)"; [ -n "$m" ] || return 1; case "$m" in /*) ;; *) m="$1/$m";; esac; printf '%s' "$m"; }
# role_current <root> → the session's role: SDD_ROLE → the worktree marker → the branch pattern <V>.nhanh; empty if it cannot be inferred
# kq_field <field> <KETQUA line> — the value of ONE field, reading the FIRST occurrence only.
# role.sh writes the fields in a fixed order (key ket neo kiem hoi con vai luc) and only `kiem=` may carry spaces,
# so the first `<field>=` on the line is always the field and anything later is text quoted inside kiem=.
# 8.6.0 (P-58): there were two readers of this one line and they disagreed. `queue.sh done` used
# `grep -oE 'ket=[a-z]+'`, which prints EVERY match — a kiem= quoting another role's `ket=xong` made KET two lines
# and `[ "$KET" = xong ]` false; `queue.sh board` read the same line with a `*ket=xong*` glob and said xong. One
# job, two answers, at the door that marks work finished (runxops, KETQUA b-032-ap-232, 20:31). There is one
# reader now, and every caller goes through it.
kq_field() {
  printf '%s' "$2" | grep -oE "(^|[[:space:]])$1=[^[:space:]]*" | head -1 | sed -E "s/^[[:space:]]*$1=//"
}

# role_norm <string> — the role name is the FIRST token.
# 8.6.0: a coordinator opening a pane with SDD_ROLE="C soi opus" (role · job · model) means the role C. Up to 8.5.0
# the name was taken verbatim, so the commit hook said "the role 'C soi opus' is not in .sdd/roles" on every commit
# in a shared prose-lane worktree while the commit itself went through — a message that is wrong in both directions.
role_norm() { printf '%s' "$1" | awk '{print $1}'; }

role_current() {
  local v m br p
  [ -n "$SDD_ROLE" ] && { role_norm "$SDD_ROLE"; return; }
  m="$(role_marker_file "$1")"; [ -n "$m" ] && [ -f "$m" ] && { role_norm "$(head -1 "$m")"; return; }
  br="$(git -C "$1" symbolic-ref --quiet --short HEAD 2>/dev/null)"
  for v in $(role_list "$1"); do
    p="$(role_branch "$v" "$1")"; [ -n "$p" ] || continue
    printf '%s' "$br" | grep -qE "$(glob_re "$p")" && { printf '%s' "$v"; return; }
  done
}
# git_common <root> → the git directory SHARED by every worktree (the main checkout's .git). Locks and KETQUA go here:
# .sdd/ is inside the working tree, so each worktree has its own copy — a lock there is invisible to exactly what it must block.
git_common() { local d; d="$(cd "$1" && git rev-parse --git-common-dir 2>/dev/null)"; case "$d" in /*) ;; *) d="$1/$d";; esac; printf '%s' "$d"; }
lock_dir()   { printf '%s/sdd-lock' "$(git_common "$1")"; }
# is_main_wt <root> → true in the MAIN checkout, false in a secondary worktree (7.3 queue.sh, 8.3.0 phieu.sh).
# Anything shared and hand-merged — the queue board, the ticket index — is written by the main checkout only:
# two worktrees writing one table is a merge conflict every round, and the coordinator pays it by hand (P-49).
is_main_wt() { [ "$(cd "${1:-.}" && git rev-parse --git-dir 2>/dev/null)" = "$(cd "${1:-.}" && git rev-parse --git-common-dir 2>/dev/null)" ]; }
ketqua_dir() { printf '%s/sdd-ketqua' "$(git_common "$1")"; }
# lock_take <name> <root> — an atomic mkdir (POSIX). Waits up to 10 s; a lock older than 2 minutes counts as orphaned and is removed.
lock_take() {
  local d i=0; mkdir -p "$(lock_dir "$2")"; d="$(lock_dir "$2")/$1"
  while ! mkdir "$d" 2>/dev/null; do
    i=$((i+1))
    if [ "$i" -gt 100 ]; then
      [ -n "$(find "$d" -maxdepth 0 -mmin +2 2>/dev/null)" ] && { rm -rf "$d"; i=0; continue; }
      return 1
    fi
    sleep 0.1
  done
  printf '%s\n' "$$" > "$d/pid"
}
lock_drop() { rm -rf "$(lock_dir "$2")/$1"; }
# plugin_file <path relative to the plugin> — like plugin_script but for templates (templates/skel/…)
plugin_file() {
  local p="$1" root="$2" ip
  [ -f "$root/$p" ] && { printf '%s' "$root/$p"; return; }
  ip="$(installed_path sdd-solo)"; [ -n "$ip" ] && [ -f "$ip/$p" ] && { printf '%s' "$ip/$p"; return; }
  find "$HOME/.claude/plugins/cache" -type f -path "*sdd-solo*/$p" 2>/dev/null | sort -t/ -k7 -V | tail -1
}
# hoi_dap_file <root> → the question log: 7.0 notes/hoi-dap/hoi-dap.md · 6.x specs/internal/hoi-dap.md (a path even when the file is absent)
hoi_dap_file() {
  if [ -f "$1/notes/hoi-dap/hoi-dap.md" ] || [ ! -f "$1/specs/internal/hoi-dap.md" ]; then printf '%s/notes/hoi-dap/hoi-dap.md' "$1"
  else printf '%s/specs/internal/hoi-dap.md' "$1"; fi
}

# ── 7.4 — the behavioural fingerprint of a UC at a revision (#49; shared by gate-check §9 · close-check P-10) ─────
# Areas: main alt exc post ac (sections of the UC) · flow (the .flow.md file) · rules (the quoted RULE statements, minus Applies to)
# · entities (the mermaid blocks of the entities the UC names). Paths are looked up PER REVISION: a UC may have moved
# directory (git mv, a 6.x → 7.0 migration) between the two marks; compare content, not paths (P-31).
fp_tree()   { git -C "$1" ls-tree -r --name-only "$2" 2>/dev/null; }
fp_layout() { fp_tree "$1" "$2" | grep -qE '^specs/vision\.md$|^specs/[^/]+/br-[0-9]+/' && printf v7 || printf v6; }
fp_uc()     { fp_tree "$1" "$3" | grep -E "/use-cases/$2-[^/]*/$2$4\.md\$" | head -1; }   # <root> <id> <rev> <suffix: "" | .flow>
fp_rules()  { fp_tree "$1" "$2" | grep -E '^specs/rules\.md$|^specs/[^/]+/rules\.md$' | grep -vE '^specs/(contexts|internal|changes)/'; }
fp_entities() { # <root> <id> <rev> <efs at HEAD> — 6.x: the context's entities.md; 7.0: the same file names as entity_cited at HEAD
  local u o e n
  u="$(fp_uc "$1" "$2" "$3" "")"; [ -n "$u" ] || return 0
  if [ "$(fp_layout "$1" "$3")" = v6 ]; then printf '%s\n' "$u" | sed -E 's#(specs/contexts/[^/]+)/.*#\1/entities.md#'
  else o="$(printf '%s' "$u" | sed -E 's#^specs/([^/]+)/.*#\1#')"
       for e in $4; do n="$(basename "$e")"; fp_tree "$1" "$3" | grep -E "^specs/(core|$o)/entities/$n\$"; done; fi
}
spec_fp() { # spec_fp <root> <id> <rev> <area> [efs]
  local root="$1" id="$2" rev="$3" z="$4" efs="$5" uc h f rl r p
  uc="$(git -C "$root" show "$rev:$(fp_uc "$root" "$id" "$rev" "")" 2>/dev/null)"
  case "$z" in
    main|alt|exc|post|ac)
      case "$z" in main) h="## Main Flow";; alt) h="## Alternative Flows";; exc) h="## Exceptions";; post) h="## Postconditions";; ac) h="## Acceptance Criteria";; esac
      printf '%s\n' "$uc" | awk -v h="$h" 'index($0,h)==1{f=1;next} f&&/^## /{f=0} f';;
    flow) f="$(fp_uc "$root" "$id" "$rev" ".flow")"; [ -n "$f" ] && git -C "$root" show "$rev:$f" 2>/dev/null;;
    rules)
      rl="$(for p in $(fp_rules "$root" "$rev"); do git -C "$root" show "$rev:$p" 2>/dev/null; printf '\n'; done)"
      # 8.0.0: which RULEs the fingerprint covers is read from the UC body AND its trail file at that revision.
      # The set must not depend on WHERE the trail is stored, or the commit that moves it looks like a change of
      # behaviour: measured on the runxops copy, migrating an implemented UC made §9 say "the spec changed
      # BEHAVIOUR after the UC was closed — areas: rules" on a commit that moved bytes and edited nothing.
      p="$(fp_uc "$root" "$id" "$rev" ".trace")"
      [ -n "$p" ] && uc="$uc
$(git -C "$root" show "$rev:$p" 2>/dev/null)"
      for r in $(printf '%s' "$uc" | grep -oE 'RULE-[0-9]+' | sort -u); do
        printf '%s\n' "$rl" | awk -v h="## $r" 'index($0,h)==1{f=1;print;next} f&&/^## /{f=0} f' | grep -vE "$(kw appliesto)"
      done;;
    entities) for p in $(fp_entities "$root" "$id" "$rev" "$efs"); do git -C "$root" show "$rev:$p" 2>/dev/null | sed -n '/^```mermaid/,/^```/p'; done;;
  esac
}
# fp_changed <root> <id> <rev1> <rev2> [efs] → prints the areas that differ (space separated, with a leading space);
# set FP_SKIP=entities when the two marks use different layouts (6.x one file per context · 7.0 one per entity — concatenating is not comparable).
fp_changed() {
  local z out=""; FP_SKIP=""
  for z in main alt exc post ac flow rules entities; do
    if [ "$z" = entities ] && [ "$(fp_layout "$1" "$3")" != "$(fp_layout "$1" "$4")" ]; then FP_SKIP=entities; continue; fi
    [ "$(spec_fp "$1" "$2" "$3" "$z" "$5")" = "$(spec_fp "$1" "$2" "$4" "$z" "$5")" ] || out="$out $z"
  done
  printf '%s' "$out"
}

# ── 7.7 — the WRITE language for every node command of the plugin ────────
# Set in ONE place at the end of lib.sh instead of exported by each script that calls node. Forgetting one
# place means that file writes Vietnamese in a repo declaring `doc_lang=en`, and NO check goes red — the READ
# direction accepts both sides, so the miss stays silent until a human reads the file. A script needing a
# different root (context.sh) exports its own override after sourcing lib; the `:-` here keeps a value already set in the environment.
export SDD_DOC_LANG="${SDD_DOC_LANG:-$(doc_lang 2>/dev/null || echo vi)}"

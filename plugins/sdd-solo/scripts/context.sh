#!/usr/bin/env bash
# context.sh UC-### [--why] — ONE command printing exactly enough context for a UC.
#
# Why this file exists. Up to 4.2.0, /sdd-solo:design told the agent in prose to read 13 file names, and
# no check could measure whether it had. An instruction to read 13 files is an instruction that fails by
# probability — and fails silently, because the design that comes out still reads smoothly, it is only
# missing one source (#34: design.md contradicted the brief for two days with nobody seeing it).
# Measured at runxops: understanding UC-009 meant opening 15 files / 6 directories / 210 KB ≈ 53k tokens,
# of which more than 60% was evidence trail (adversarial, re-read, history, evidence) and not in force.
#
# This script collects EXACTLY what is in force and EXACTLY the IDs this UC quotes:
#   the UC (minus the 3 evidence sections) · the flow · the quoted RULEs · the quoted CONs · the quoted ADRs
#   · the parent BR sections (without Background) · architecture (4 sections) · the entities/glossary it names
#   · the brief line for the agent to read separately (outside specs/, rule #34 unchanged).
# It prints, it writes no file. The last line measures the KB — the agent and the human both see the price.
#
# --why: prints only the RULEs · CONs · ADRs · ## Forbidden — answering "what decided this feature" for a
# maintainer, on one screen. This is the other half of decisions.sh: decisions.sh goes from time down to a
# decision; --why goes from a UC up to the decisions.
#
# --brief (6.5.0, the rest of #43, delegated by the owner): the version for the ⑦/⑧ subagents — they read BEHAVIOUR
# and CONSTRAINTS, not "built with what". It differs from the full version in two places: an ADR prints only the first
# paragraph of ## Decision + the sub-section names (a pointer, not the body); architecture prints only ## Forbidden ·
# ## Boundaries · ## Runs where (dropping Stack and Callers). Measured on runxops UC-014: 9 ADR Decisions were 53 KB,
# the first paragraphs ~21 KB; architecture 45 → ~22 KB. The RULEs are NOT cut (a contradiction hides in the prose of a
# rule), and the glossary is not filtered by the terms the UC names (measured: dropping 24 entries saved no KB). Step ⑩ design reads the full version.
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"
ID=""; WHY=0; BRIEF=0
for a in "$@"; do case "$a" in --why) WHY=1;; --brief) BRIEF=1;; UC-[0-9]*|BR-[0-9]*) ID="$a";; esac; done
[ -z "$ID" ] && { echo "Usage: context.sh <UC-###|BR-###> [--why | --brief]" >&2; exit 2; }
# 7.4 (P-23): BR-### — the context of a SLICE: the decision sections of the BR (without Background), the slice row in
# vision.md, the RULEs/ADRs the BR quotes, architecture, the entities/glossary the BR names. The same js/context.mjs and
# the same evidence-cutting rule; only the subject is br.md instead of UC-###.md. 6.x: specs/br.md holds several BRs — take only this ID section.
case "$ID" in
  BR-*)
    F="$(br_file "$ID" "$ROOT")"
    { [ -f "$F" ] && [ -n "$(br_title "$ID" "$ROOT")" ]; } || { printf '  \033[31m✗\033[0m cannot find %s in %s\n' "$ID" "${F#$ROOT/}" >&2; exit 1; }
    CTX="$(owner_of_br "$ID" "$ROOT")";;
  *)
    F="$(find_uc "$ID" "$ROOT")"
    [ -z "$F" ] && { printf '  \033[31m✗\033[0m cannot find the file for %s\n' "$ID" >&2; exit 1; }
    CTX="$(owner_of "$F")";;
esac
DIR="$(dirname "$F")"
BP="$(brief_path "$ROOT")"; BS=""; [ -n "$BP" ] && BS="$(brief_sha "$ROOT" 2>/dev/null)"
# 7.0 (#55): every source path is looked up in lib.sh and passed into js/context.mjs through the environment, one file
# per line — it does not know the layout itself. 6.x: rules.md · br.md · internal/{adr,architecture.md} ·
# contexts/<ctx>/entities.md; 7.0: the root + craft rules.md · the slice br.md · adr/ · architecture.md ·
# the entities/<Name>.md the UC names (entity_cited). OTHERS = the OTHER context/craft names, to cut them from the glossary.
export SDD_RULES="$(rules_files "$ROOT")" SDD_BRS="$(br_files "$ROOT")" SDD_ADRS="$(adr_dirs "$ROOT")"
export SDD_ARCH="$(arch_file "$ROOT")" SDD_ENTS="$(entity_cited "$F" "$ROOT")" SDD_GLOS="$(glossary_files "$CTX" "$ROOT")"
if [ "$(layout "$ROOT")" = v7 ]; then OTHERS="$(nghe_list "$ROOT" | tr ' ' '\n' | grep -vx "${CTX:-core}")"
else OTHERS="$(ls -d "$ROOT"/specs/contexts/*/ 2>/dev/null | xargs -n1 basename | grep -v '^_' | grep -vx "$CTX")"; fi
export SDD_OTHERS="$OTHERS"
export SDD_DOC_LANG="$(doc_lang "$ROOT")"   # 7.7.0: the WRITE language; the js keyword table reads kw.tsv directly

need_node "context.sh"
node "$HERE/js/context.mjs" "$ROOT" "$F" "$ID" "$CTX" "$WHY" "$BP" "$BS" "$BRIEF"

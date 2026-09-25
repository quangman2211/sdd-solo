#!/usr/bin/env bash
# adopt.sh [--count] — what of this repo predates sdd-solo, and how much of it is still unspecified.
#
# BLOCKS NOTHING. Always exits 0. This is a WORKLIST, not a gate — the same contract as uc-steps.sh
# and numbers.sh. There is no --import, no --as-built, and nothing here writes a UC file or a gate
# marker: a behaviour becomes a UC by walking steps 1-9, because the steps that would be skipped are
# the steps that find the defects.
#
# --count prints the two dashboard lines. Each declares its own denominator (#30), because mixing
# "what the hook still waves through" with "what the process has taken in" is exactly the error
# metrics.sh had to split apart once already.
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/lib.sh"
ROOT="$(project_root)"
MODE="${1:-}"

AF="$(adopt_from "$ROOT")"
if [ -z "$AF" ]; then
  info "this repo declares no adoption baseline (adopt_from in .sdd/config is empty) — nothing to adopt."
  info "That is normal for a repo that had no code when sdd-solo arrived."
  exit 0
fi
if ! adopt_ok "$ROOT"; then
  if [ "$(git -C "$ROOT" rev-parse --is-shallow-repository 2>/dev/null)" = true ]; then
    bad "this is a shallow clone, so the adoption baseline cannot be read — clone with full history to count."
  else
    bad "$(printf 'adopt_from=%s is not a commit this repo holds — the baseline is unreadable.' "$AF")"
  fi
  info "While it cannot be read, the githook exempts nothing and every code commit needs an ID."
  exit 0
fi

WHEN="$(git -C "$ROOT" log -1 --format=%ad --date=short "$AF" 2>/dev/null)"
TREE="$(git -C "$ROOT" ls-tree -r --name-only "$AF" 2>/dev/null | grep -c .)"
FILES="$(adopt_files "$ROOT")"
NF_="$(printf '%s\n' "$FILES" | grep -c .)"
PEND="$(adopt_pending "$ROOT")"
NP="$(printf '%s\n' "$PEND" | grep -c .)"
DECL="$(adopt_declared "$ROOT")"
ND=0
[ -n "$FILES" ] && [ -n "$DECL" ] && ND="$(printf '%s\n' "$FILES" | grep -xF "$DECL" 2>/dev/null | grep -c .)"

count_lines() {
  printf 'Adoption (baseline %s · %s · %s files in that tree; %s still under code_paths/test_paths minus tool_paths)\n' \
    "$(printf '%.7s' "$AF")" "${WHEN:-?}" "$TREE" "$NF_"
  printf '  Baseline files no commit carrying an ID has ever touched: %s/%s\n' "$NP" "$NF_"
  printf '  Baseline files a UC through the gate lists in %s:  %s/%s\n' "$(kw_w existingcode "$ROOT")" "$ND" "$NF_"
}

if [ "$MODE" = "--count" ]; then count_lines; exit 0; fi

count_lines
echo
if [ "$NP" = 0 ]; then
  ok "every baseline file has been through a commit carrying an ID — the exemption set is empty."
  info "adopt_from stays in .sdd/config for good: removing it is indistinguishable from tampering,"
  info "and a zero you can see is a zero you can trust."
  exit 0
fi
echo "Still exempt at the githook, grouped by directory — these are what /sdd-solo:adopt turns into BR/UC candidates:"
printf '%s\n' "$PEND" | grep . | awk -F/ '{ d = (NF>1 ? $1 : "."); for (i=2;i<NF;i++) d = d "/" $i; print d "\t" $0 }' \
  | sort | awk -F'\t' '
      $1 != last { if (last != "") print ""; printf "  %s/\n", $1; last = $1 }
      { printf "    %s\n", $2 }'
echo
info "Each of these is code with no UC YET — it stays in the trace-ratio denominator, unlike tool_paths."
info "Next: /sdd-solo:intake for the BR layer if it is not written, then /sdd-solo:adopt to group these."
exit 0

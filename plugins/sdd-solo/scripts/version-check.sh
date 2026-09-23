#!/usr/bin/env bash
# version-check.sh [--remote] [--brief]
# Compares the version chain and names exactly the command to run for each mismatch:
#   GitHub ─①─▶ the downloaded marketplace ─②─▶ the installed version ─③─▶ the project .sdd/
#                                            └────④─▶ the open Claude Code session
# No command can fix slot ④ — only opening a new session can.
# --remote: also asks GitHub (at most 3s, remembered for 24h). Without the flag it is purely local.
# --brief : prints only the mismatch lines. Used by the SessionStart hook.
# --no-cache: skip the 24h cache and ask GitHub now.
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
PLUGIN="${SDD_PLUGIN:-$(dirname "$HERE")}"; ROOT="$(project_root)"
CACHE_D="${XDG_CACHE_HOME:-$HOME/.cache}/sdd-solo"; CACHE="$CACHE_D/remote-check"
TTL=86400   # 24h

REMOTE=0; BRIEF=0; NOCACHE=0
for a in "$@"; do
  [ "$a" = "--remote" ] && REMOTE=1
  [ "$a" = "--brief" ] && BRIEF=1
  [ "$a" = "--no-cache" ] && { NOCACHE=1; REMOTE=1; }
done

PNAME="$(jver "$PLUGIN/.claude-plugin/plugin.json" name 2>/dev/null || echo sdd-solo)"
MKTNAME="$(mkt_of "$PLUGIN")"
DEV=0; [ -z "$MKTNAME" ] && { MKTNAME="$PNAME"; DEV=1; }   # running from --plugin-dir

# ── the five links ──────────────────────────────────────────────────────
PROJ="$(cat "$ROOT/.sdd/version" 2>/dev/null || echo '-')"
INST="$(installed_ver "$PNAME")"
[ -z "$INST" ] && INST="$(jver "$PLUGIN/.claude-plugin/plugin.json" version)"
[ -z "$INST" ] && INST='-'
MKTLOC="$(mkt_field "$MKTNAME" installLocation)"
MKT='-'; [ -f "$MKTLOC/.claude-plugin/marketplace.json" ] && MKT="$(jver "$MKTLOC/.claude-plugin/marketplace.json" plugins.0.version)"
SESS="$(sess_ver)"; [ -z "$SESS" ] && SESS='-'
SRC="$(mkt_field "$MKTNAME" source.repo)"
# Do not let an odd value reach vcmp: it splits on "." then adds 0, so "1.4.0<junk>"
# still comes out as 1.4.0 and a decision is made on data that cannot be trusted.
PROJ="$(clean_ver "$PROJ")"; INST="$(clean_ver "$INST")"; MKT="$(clean_ver "$MKT")"; SESS="$(clean_ver "$SESS")"

REM='-'
if [ "$REMOTE" = "1" ] && [ -n "$SRC" ]; then
  NOW="$(date +%s)"
  if [ "$NOCACHE" = "0" ] && [ -f "$CACHE" ]; then
    CT="$(awk '{print $1}' "$CACHE" 2>/dev/null)"; CV="$(awk '{print $2}' "$CACHE" 2>/dev/null)"
    # A cache still in date is NOT enough: if the local version already exceeds the number in the cache,
    # the cache is certainly stale (the author bumped several times in one sitting) → ask again.
    if [ -n "$CT" ] && [ $((NOW - CT)) -lt "$TTL" ] && [ "$(vcmp "$CV" "$MKT")" != "-1" ]; then
      REM="$CV"
    fi
  fi
  if [ "$REM" = '-' ]; then
    R="$(curl -fsS --max-time 3 "https://raw.githubusercontent.com/$SRC/main/.claude-plugin/marketplace.json" 2>/dev/null \
         | grep -oE '"version" *: *"[^"]+"' | head -1 | sed -E 's/.*"([^"]+)"$/\1/')"
    if is_semver "$R"; then REM="$R"; mkdir -p "$CACHE_D" && echo "$NOW $R" > "$CACHE"
    else REM='?'; fi   # no network: stay quiet, do not call it a mismatch
  fi
fi

# ── the table: the version first, the label after — printf pads by byte, so an accented label shifts the column
if [ "$BRIEF" = "0" ]; then
  echo "=== Version ==="
  printf '  %-8s %s\n' "$PROJ" "the project .sdd/"
  printf '  %-8s %s\n' "$INST" "the installed version"
  printf '  %-8s %s\n' "$MKT"  "the downloaded marketplace"
  if [ "$SESS" = '-' ]; then
    printf '  %-8s %s\n' "?" "this running session (unknown — the hook has not recorded it, or this runs outside Claude Code)"
  else
    printf '  %-8s %s\n' "$SESS" "this running session"
  fi
  [ "$REMOTE" = "1" ] && printf '  %-8s %s\n' "$REM" "GitHub${SRC:+ ($SRC)}"
  echo
fi

sev() { # a major mismatch is ✗, everything else is !
  if [ "$(echo "$1" | cut -d. -f1)" != "$(echo "$2" | cut -d. -f1)" ]; then bad "$3"; else warn "$3"; fi
}
[ "$(vcmp "$PROJ" "$INST")" = "-1" ] && \
  sev "$PROJ" "$INST" "③ the project is older than the installed version ($PROJ < $INST) → /sdd-solo:init --update"
[ "$(vcmp "$INST" "$MKT")" = "-1" ] && \
  sev "$INST" "$MKT" "② the installed version is older than the downloaded one ($INST < $MKT) → /plugin update $PNAME"
if [ "$REMOTE" = "1" ] && [ "$REM" != '-' ] && [ "$REM" != '?' ]; then
  C1="$(vcmp "$MKT" "$REM")"
  [ "$C1" = "-1" ] && sev "$MKT" "$REM" "① there is a newer version on GitHub ($MKT < $REM) → /plugin marketplace update $MKTNAME"
  # The other direction means something too: local newer than GitHub = there is an unpushed release.
  # Staying quiet here is exactly the kind of silent failure this whole file exists to prevent.
  [ "$C1" = "1" ] && warn "① local ($MKT) is newer than GitHub ($REM) — there is an unpushed release"
fi
# ④ is only visible because the hook recorded it; no command fixes it, a new session must be opened
[ "$SESS" != '-' ] && [ "$(vcmp "$SESS" "$INST")" = "-1" ] && \
  sev "$SESS" "$INST" "④ this session still runs $SESS while $INST is installed → OPEN A NEW SESSION (no command can fix it)"

[ "$(vcmp "$PROJ" "$INST")" = "1" ] && [ "$PROJ" != '-' ] && [ "$INST" != '-' ] && \
  warn ".sdd/ ($PROJ) is newer than the installed version ($INST) — the repo was init-ed with a dev build, or the plugin was downgraded"
[ "$DEV" = "1" ] && [ "$BRIEF" = "0" ] && info "the script is running from --plugin-dir, not from the installed version"

if [ "$((FAIL+WARN))" -eq 0 ]; then
  [ "$BRIEF" = "0" ] && ok "no mismatch"
  exit 0
fi
exit 1

#!/usr/bin/env bash
# update.sh — run the whole update chain in the right order, only the slots that are out of step.
#   ① claude plugin marketplace update   ② claude plugin update   ③ scaffold --update
# A new version does NOT apply to an open session — exactly like Claude Code, a new session is needed.
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
PLUGIN="${SDD_PLUGIN:-$(dirname "$HERE")}"; ROOT="$(project_root)"
PNAME="$(jver "$PLUGIN/.claude-plugin/plugin.json" name 2>/dev/null || echo sdd-solo)"
MKTNAME="$(mkt_of "$PLUGIN")"

if [ -z "$MKTNAME" ]; then
  warn "the plugin is running from --plugin-dir, not from the marketplace-installed version"
  info "skipping ① ②, running only ③ scaffold --update"
else
  # ① marketplace clone ← GitHub
  echo "① refreshing the marketplace…"
  OUT="$(claude plugin marketplace update "$MKTNAME" </dev/null 2>&1)"; RC=$?
  echo "$OUT" | sed 's/^/    /'
  [ "$RC" -eq 0 ] && ok "marketplace $MKTNAME" \
                  || bad "could not refresh the marketplace — no network? Continuing with the downloaded version."
  # ② the installed version ← the marketplace clone
  MKTLOC="$(mkt_field "$MKTNAME" installLocation)"
  MJ="$MKTLOC/.claude-plugin/marketplace.json"
  MKT='-'
  if [ -f "$MJ" ]; then
    MKT="$(jver "$MJ" plugins.0.version)"
    # ① has just written the clone. Retry once if what comes back is not a version.
    is_semver "$MKT" || { sleep 0.3; MKT="$(jver "$MJ" plugins.0.version)"; }
  fi
  CUR="$(clean_ver "$(jver "$PLUGIN/.claude-plugin/plugin.json" version)")"
  if ! is_semver "$MKT"; then
    # Do not guess, do not decide on a value that cannot be trusted — see slot ④ at 1.4.0.
    dump_bad "② the marketplace version" "$MKT"
    bad "② skipped because the marketplace version could not be read → do it by hand: claude plugin update $PNAME@$MKTNAME"
    MKT='-'
  elif [ "$(vcmp "$CUR" "$MKT")" = "-1" ]; then
    # MUST use printf, not echo. The bash 3.2 on macOS swallows a whole variable expansion
    # when it sits immediately before a multi-byte character:
    #   bash -c 'M=1.6.1; echo "→ $M…"'   →  loses "1.6.1" and the first byte of "…"
    # It only breaks under a UTF-8 locale, which is the real environment of every user. See #6.
    printf '② installing %s %s → %s…\n' "$PNAME" "$CUR" "$MKT"
    OUT="$(claude plugin update "$PNAME@$MKTNAME" </dev/null 2>&1)"; RC=$?
    echo "$OUT" | sed 's/^/    /'
    [ "$RC" -eq 0 ] && ok "installed $MKT" || bad "the install did not finish — do it by hand: claude plugin update $PNAME@$MKTNAME"
  else
    ok "② the installed version is already the newest ($CUR)"
  fi
fi

# ③ the project .sdd/ ← the scaffold of the NEWEST version, not of the running one
NEW="$(installed_path "$PNAME")"
[ -n "$NEW" ] && [ -x "$NEW/scripts/scaffold.sh" ] || NEW="$PLUGIN"
echo "③ updating the project .sdd/ and templates (scaffold from $(jver "$NEW/.claude-plugin/plugin.json" version))…"
"$NEW/scripts/scaffold.sh" "$NEW" "$ROOT" --update 2>&1 | sed 's/^/    /'

# the version of the open session comes from where the SessionStart hook recorded it — NOT inferred from
# this script path, because this script is invoked through bash so its path is the new version.
SESS="$(sess_ver)"
INSTALLED="$(jver "$NEW/.claude-plugin/plugin.json" version)"
echo
echo "=== Sau khi update ==="
printf '  %-8s %s\n' "$INSTALLED" "the installed version"
printf '  %-8s %s\n' "$(cat "$ROOT/.sdd/version" 2>/dev/null || echo '-')" "the project .sdd/"
printf '  %-8s %s\n' "${SESS:-?}"  "this running session${SESS:+}"
echo
if [ -z "$SESS" ]; then
  echo "Which version this session loaded is unknown (the hook has not recorded it). Open a new session to be sure."
elif [ "$(vcmp "$SESS" "$INSTALLED")" = "-1" ]; then
  echo "OPEN A NEW SESSION to load $INSTALLED — this one is still running $SESS."
  echo "Same as Claude Code: a new version does not apply to an open session."
else
  ok "this session already runs the newest version"
fi

# 8.0.0: the one migration this release needs, named here because nothing else will name it. Only speak when
# there is something to move — a repo already on the new shape must not be told to run a migration.
if [ -n "$(all_uc_files "$ROOT")" ]; then
  OLDSHAPE=0
  for u in $(all_uc_files "$ROOT"); do
    grep -qE "$(kwh adversarial)|$(kwh reread)|^## History" "$u" 2>/dev/null && { OLDSHAPE=1; break; }
  done
  if [ "$OLDSHAPE" = 1 ]; then
    echo
    warn "8.0.0: the evidence trail (## Adversarial pass · ## Re-read · ## History) belongs beside the UC now, in"
    info "UC-###.trace.md, not in the UC body. Your UCs still carry it in the body — the gate reads it there and"
    info "nothing is broken, so this is not urgent, but it is what 8.0.0 is for. Measured on a real repo: 2.33 MB"
    info "of UC bodies became 1.01 MB, with nothing lost and the same gate verdict on every UC."
    info "  bash .sdd/scripts/migrate.sh --trace --dry-run   # see what would move, touches nothing"
    info "  bash .sdd/scripts/migrate.sh --trace             # move it, then read the diff and commit"
    info "Run it as often as you like: it decides per file from the file's own content and changes nothing twice."
  fi
fi

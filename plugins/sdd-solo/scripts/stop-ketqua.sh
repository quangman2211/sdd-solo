#!/usr/bin/env bash
# stop-ketqua.sh — the Stop hook for a role pane (8.6.0, P-59).
#
# When a role ends its turn while still holding a job that has no terminal KETQUA, this blocks ONCE and prints the
# exact `role.sh --ketqua …` line to write. On the second attempt (stop_hook_active) it says so on stderr and lets go.
#
# Why it exists: the two-channel result of 7.2 (a file first, the message second) is there because a report that
# lives only in a message is a report that is gone when the message is — four subagent reports lost in one afternoon
# (P-26), and eight jobs marked done by nothing but the clock at 22:16 on 22/09. The file half only helps if it gets
# written, and the moment it is most often skipped is the moment the turn ends. That moment is here.
#
# Why once and not always: a hook that can never be got past stops the work instead of the mistake. It blocks once,
# says exactly what to type, then gets out of the way — the same shape as every other rule here, which reports a
# state and leaves the judgement with whoever can see the work.
#
# It is SILENT unless all of these hold: the repo declares .sdd/roles · a role can be inferred · the queue says that
# role holds an active item · that item has no KETQUA with a terminal ket=. Any doubt and it exits 0 without a word:
# a hook that fires on a guess is worse than no hook, and this one runs in every session the plugin is installed in.
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/lib.sh" 2>/dev/null || exit 0

IN="$(cat 2>/dev/null)"
AGAIN="$(printf '%s' "$IN" | tr -d '\n' | sed -nE 's/.*"stop_hook_active"[[:space:]]*:[[:space:]]*(true|false).*/\1/p')"

ROOT="$(project_root 2>/dev/null)" || exit 0
[ -n "$ROOT" ] || exit 0
[ -n "$(roles_file "$ROOT")" ] || exit 0
V="$(role_current "$ROOT")"; [ -n "$V" ] || exit 0
role_known "$V" "$ROOT" || exit 0

# `xong` · `chan` · `do` are the terminal values role.sh --ketqua accepts; anything else (including no KETQUA at all)
# means the job has not been reported on.
[ -f "$ROOT/notes/hang-doi.md" ] || exit 0
# `NF == 2` is not decoration: queue.sh reports its own errors on stdout, and a line like "there is no
# notes/hang-doi.md" has no bar in it, so without this the hook would block on the text of an error message.
# Only a real `<key>|<ket>` line counts.
OPEN="$(bash "$HERE/queue.sh" giu "$V" 2>/dev/null | awk -F'|' 'NF == 2 && $1 ~ /^[a-z0-9][a-z0-9._-]*$/ && $2 != "xong" && $2 != "chan" && $2 != "do" {print $1}')"
[ -n "$OPEN" ] || exit 0

if [ "$AGAIN" = true ]; then
  printf 'sdd-solo: ending the turn with no KETQUA for: %s\n' "$(printf '%s' "$OPEN" | tr '\n' ' ')" >&2
  printf 'sdd-solo: the coordinator will see these as suspected-dead, not as done.\n' >&2
  exit 0
fi

R="Role $V is ending the turn while still holding: $(printf '%s' "$OPEN" | tr '\n' ' ')"
R="$R"$'\n'"None of these has a KETQUA with a terminal ket=, so nothing outside this pane knows how the job went. Time passing is not evidence: the coordinator will read them as suspected-dead, not as done."
R="$R"$'\n'"Write one line per item, then end the turn again:"
for k in $OPEN; do
  R="$R"$'\n'"  bash .sdd/scripts/role.sh --ketqua $k ket=xong neo=<hash|.sdd/gate/UC-###.ok|path> kiem=<check:result>"
done
R="$R"$'\n'"ket=chan needs hoi=<ticket number> instead of an anchor; ket=do is for a job that failed. Send the same line back to the coordinator as the first line of the message."
R="$R"$'\n'"If the job genuinely is not finished and you are stopping on purpose, end the turn again and this will let go."

# JSON by hand: no node here on purpose — a hook that needs a runtime is a hook that fails silently on the machine
# that does not have it.
printf '{"decision":"block","reason":"%s"}\n' \
  "$(printf '%s' "$R" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed 's/\\n$//')"
exit 0

#!/usr/bin/env bash
# .github/check-manifest.sh — the release chain, checked on every push and PR.
#
# CLAUDE.md names version drift the most expensive silent failure this repo has: Claude Code caches a
# plugin by a directory NAMED after the version, so pushing without a bump makes `/plugin update` load
# nothing at all, with no error anywhere. A human is the only thing standing between that and a release
# today. This job is that human, mechanised.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAIL=0
bad()  { printf '  \033[31m✗\033[0m %s\n' "$1"; FAIL=$((FAIL+1)); }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }

jver() { grep -oE '"version" *: *"[^"]+"' "$1" | head -1 | sed -E 's/.*"([^"]+)"$/\1/'; }
PV="$(jver "$ROOT/plugins/sdd-solo/.claude-plugin/plugin.json")"
MV="$(jver "$ROOT/.claude-plugin/marketplace.json")"

[ -n "$PV" ] || bad "plugin.json has no version"
[ -n "$MV" ] || bad "marketplace.json has no version"
if [ -n "$PV" ] && [ -n "$MV" ]; then
  if [ "$PV" = "$MV" ]; then ok "version matches in both manifests: $PV"
  else bad "$(printf 'plugin.json says %s, marketplace.json says %s — they must be identical' "$PV" "$MV")"; fi
fi

# Every release gets exactly one CHANGELOG entry — that file IS this plugin's ## History.
if [ -n "$PV" ]; then
  if grep -qE "^## ${PV//./\\.}( |$)" "$ROOT/CHANGELOG.md"; then ok "CHANGELOG has an entry for $PV"
  else bad "$(printf 'CHANGELOG.md has no "## %s" heading — every release gets one entry' "$PV")"; fi
fi

# The source path the marketplace advertises has to exist, or the plugin resolves to nothing.
SRC="$(grep -oE '"source" *: *"[^"]+"' "$ROOT/.claude-plugin/marketplace.json" | head -1 | sed -E 's/.*"([^"]+)"$/\1/')"
if [ -n "$SRC" ]; then
  if [ -d "$ROOT/${SRC#./}" ]; then ok "$(printf 'marketplace source resolves: %s' "$SRC")"
  else bad "$(printf 'marketplace source %s does not exist' "$SRC")"; fi
fi

# A plugin that does not parse is a plugin nobody can install. `claude` is not on a CI runner, so this
# is a shape check, not a substitute for `claude plugin validate` — which stays a step the author runs.
for f in "$ROOT/.claude-plugin/marketplace.json" "$ROOT/plugins/sdd-solo/.claude-plugin/plugin.json"; do
  if command -v node >/dev/null 2>&1; then
    node -e 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"))' "$f" 2>/dev/null \
      && ok "valid JSON: ${f#$ROOT/}" || bad "invalid JSON: ${f#$ROOT/}"
  else warn "no node — JSON not parsed"; fi
done

# Every command skill must be reachable: a skill directory with no SKILL.md is a command that silently
# does not exist, and nothing else in this repo would notice.
for d in "$ROOT"/plugins/sdd-solo/skills/*/; do
  [ -f "$d/SKILL.md" ] || bad "$(printf '%s has no SKILL.md' "${d#$ROOT/}")"
done
ok "$(ls -d "$ROOT"/plugins/sdd-solo/skills/*/ | wc -l | tr -d ' ') skills each have a SKILL.md"

echo
[ "$FAIL" = 0 ] && { echo "manifest chain OK"; exit 0; } || { echo "$FAIL problem(s) in the release chain"; exit 1; }

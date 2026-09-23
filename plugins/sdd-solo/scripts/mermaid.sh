#!/usr/bin/env bash
# mermaid.sh <--lint|--edges|--nodes|--states|--kinds> <file...> — the bash wrapper around js/mermaid.mjs (7.5.0, P-32;
# moved from python to node at 7.6.0).
#
# Without node it stays silent and exits 0: every caller has the previous release grep fallback, and a check that
# CANNOT RUN must never be turned into a check that is RED.
#
# SDD_MERMAID_REAL=1 → for --lint, ask the PROJECT own mermaid library directly (it needs mermaid + jsdom in
# node_modules) instead of the imitating parser. If the project does not have it, js/mermaid-real.mjs exits 3 and we fall back to the parser.
HERE="$(cd "$(dirname "$0")" && pwd)"
command -v node >/dev/null 2>&1 || exit 0
[ -f "$HERE/js/mermaid.mjs" ] || exit 0
if [ "${SDD_MERMAID_REAL:-0}" = 1 ] && [ "$1" = --lint ]; then
  shift
  SDD_ROOT="${SDD_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}" \
    node "$HERE/js/mermaid-real.mjs" "$@"
  rc=$?
  [ "$rc" != 3 ] && exit $rc
  set -- --lint "$@"
fi
exec node "$HERE/js/mermaid.mjs" "$@"

#!/usr/bin/env bash
# mermaid.sh <--lint|--edges|--nodes|--states|--kinds> <file...> — vỏ bash của js/mermaid.mjs (7.5.0, P-32;
# chuyển từ python sang node ở 7.6.0).
#
# Không có node thì im lặng và exit 0: mọi chỗ gọi đều có đường lùi grep của bản trước, và một phép kiểm
# KHÔNG CHẠY ĐƯỢC không bao giờ được biến thành một phép kiểm ĐỎ.
#
# SDD_MERMAID_REAL=1 → với --lint, hỏi thẳng thư viện mermaid của DỰ ÁN (cần mermaid + jsdom trong
# node_modules) thay vì parser bắt chước. Dự án chưa có thì js/mermaid-real.mjs thoát 3 và ta rơi về parser.
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

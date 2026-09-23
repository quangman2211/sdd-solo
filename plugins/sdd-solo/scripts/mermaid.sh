#!/usr/bin/env bash
# mermaid.sh <--lint|--edges|--nodes|--states|--kinds> <file...> — vỏ bash của mermaid.py (7.5.0, P-32).
# Không có python3 thì im lặng và exit 0: mọi chỗ gọi đều có đường lùi grep của bản trước, và một phép
# kiểm KHÔNG CHẠY ĐƯỢC không bao giờ được biến thành một phép kiểm ĐỎ.
HERE="$(cd "$(dirname "$0")" && pwd)"
command -v python3 >/dev/null 2>&1 || exit 0
[ -f "$HERE/mermaid.py" ] || exit 0
exec python3 "$HERE/mermaid.py" "$@"

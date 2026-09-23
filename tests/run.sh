#!/usr/bin/env bash
# tests/run.sh [chuỗi lọc] — chạy bộ test của plugin. exit 1 khi có FAIL.
#   bash tests/run.sh            mọi ca
#   bash tests/run.sh p18        ca có tên chứa p18
#   SDD_TEST_KEEP=1              giữ thư mục làm việc để xem
# Bốn kết quả: PASS · FAIL (hồi quy, exit 1) · XFAIL (lỗi còn mở, chờ) · XPASS (lỗi đã hết — đổi ca sang chk).
T="$(cd "$(dirname "$0")" && pwd)"; P="$(cd "$T/../plugins/sdd-solo" && pwd)"
W="${SDD_TEST_WORK:-$(mktemp -d "${TMPDIR:-/tmp}/sdd-test.XXXXXX")}"; RES="$W/results.tsv"; : > "$RES"
export T P W RES
. "$T/lib.sh"
echo "plugin: $P ($(grep -oE '"version": *"[^"]+"' "$P/.claude-plugin/plugin.json" | head -1 | sed -E 's/.*"([^"]+)"$/\1/'))"
echo "work:   $W"
mkbase
N=0
for c in "$T"/cases/*.sh; do
  n="$(basename "$c" .sh)"
  [ -n "$1" ] && case "$n" in *"$1"*) ;; *) continue;; esac
  N=$((N+1)); echo "── $n"
  ( CASE="$n"; . "$c" ) || _res FAIL "ca thoát sớm (exit $?)" 
done
echo
PASS=$(grep -c '^PASS' "$RES"); FAIL=$(grep -c '^FAIL' "$RES"); XF=$(grep -c '^XFAIL' "$RES"); XP=$(grep -c '^XPASS' "$RES")
echo "$N ca · PASS $PASS · FAIL $FAIL · XFAIL $XF (lỗi còn mở) · XPASS $XP (lỗi đã hết — đổi sang chk)"
[ "$FAIL" -gt 0 ] && { echo; grep '^FAIL' "$RES" | cut -f2,3 | sed 's/^/  ✗ /'; }
[ "$XP" -gt 0 ] && { echo; grep '^XPASS' "$RES" | cut -f2,3 | sed 's/^/  ↑ /'; }
[ -n "$SDD_TEST_KEEP" ] || rm -rf "$W"
[ "$FAIL" -eq 0 ]

# Kịch bản gốc 1.0.0: githook chặn code trước cổng, chặn trộn spec+code, cho qua sau cổng
nr hooks
mkdir -p src; printf 'x\n' > src/a.js
cmv "feat(UC-001): code trước cổng"; R=$?
chk "commit-msg chặn feat(UC-001) khi chưa có marker (exit $R)" '[ $R != 0 ] && grep -q "chưa qua cổng DoR" "$W/hookerr.txt"'
git reset -q
cmv "docs: không ID"; R=$?
chk "commit-msg chặn commit đụng code không có ID (exit $R)" '[ $R != 0 ] && grep -q "phải có ID" "$W/hookerr.txt"'
git reset -q; rm -f src/a.js
S pass.sh gate UC-001
chk "pass.sh gate exit 0 (được $R)" '[ $R = 0 ] && [ -f .sdd/gate/UC-001.ok ]'
printf 'x\n' > src/a.js; app "$UC1" "- v3 (2026-01-07, anh): sửa"
cmv "feat(UC-001): trộn"; R=$?
chk "pre-commit chặn trộn spec + code (exit $R)" '[ $R != 0 ] && grep -q "trộn spec" "$W/hookerr.txt"'
git reset -q; git checkout -q -- "$UC1"
cmv "feat(UC-001): code sau cổng"; R=$?
chk "feat(UC-001) qua sau cổng (exit $R)" '[ $R = 0 ]'

# P-42: commit merge có xung đột chở cả spec (UC khác) lẫn code từ main → pre-commit chặn "trộn spec và code"
nr p42
S pass.sh gate UC-001
printf 'a\n' > STATE.md; cm "chore(sdd): state a" 2026-01-06
git checkout -q -b code/uc-001
mkdir -p src; printf 'x\n' > src/a.js; printf 'b\n' > STATE.md
cm "feat(UC-001): code" 2026-01-07
git checkout -q master
app "$UC1" "- v3 (2026-01-08, anh): sửa"; printf 'c\n' > STATE.md; mkdir -p src; printf 'y\n' > src/b.js
cm "docs(UC-001): spec" 2026-01-08
git checkout -q code/uc-001
git merge -q master >/dev/null 2>&1; MR=$?
chk "merge có xung đột (git merge exit $MR)" '[ $MR != 0 ] && [ -f "$(git rev-parse --git-path MERGE_HEAD)" ]'
printf 'bc\n' > STATE.md; git add STATE.md
git commit -q -m "Merge master vào code/uc-001" 2>"$W/hookerr.txt"; R=$?
chk "P-42 · pre-commit cho qua commit merge chở spec + code của main (được exit $R)" '[ $R = 0 ]'

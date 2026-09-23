# 7.2: dấu vai theo worktree + hook commit-msg.d/10-vai.sh — nhắc khi khong, chặn khi nhanh-vai, suy vai từ env/đuôi/dấu/nhánh
nr vai
chk "hook 10-vai.sh được cài và thực thi" '[ -x .sdd/hooks/commit-msg.d/10-vai.sh ] && [ ! -e .sdd/hooks/pre-commit.d/10-role-boundary.sh.example ]'
S role.sh B
chk "role.sh B ghi dấu vào .git/sdd-role, in hợp đồng" '[ "$(cat .git/sdd-role)" = B ] && has "được ghi: specs/**"'
S role.sh --xem
chk "--xem suy vai B từ dấu" 'has "Vai B · spec"'
S pass.sh gate UC-001
# B (spec) commit code → vai_bat_buoc=khong: chỉ nhắc, cho qua, có đuôi Vai:
mkdir -p src; printf 'x\n' > src/b.js
cmv "feat(UC-001): B lấn sang code"; R=$?
chk "khong: B ghi src → cho qua (exit $R), nhắc 'chỗ này của vai D'" '[ $R = 0 ] && grep -q "chỗ này của vai D" "$W/hookerr.txt"'
chk "hook thêm đuôi Vai: B vào message" 'git log -1 --format=%B | grep -q "^Vai: B$"'
# bật chặn
rep .sdd/roles 'vai_bat_buoc=khong' 'vai_bat_buoc=nhanh-vai'
cm "chore(sdd): bật vai_bat_buoc"
printf 'y\n' > src/c.js
cmv "feat(UC-001): B lấn lần hai"; R=$?
chk "nhanh-vai: B ghi src → CHẶN (exit $R)" '[ $R != 0 ] && grep -q "chặn (vai_bat_buoc=nhanh-vai)" "$W/hookerr.txt"'
git reset -q; rm -f src/c.js
app "$UC1" "- v3 (2026-01-09, anh): B sửa spec"
cmv "docs(UC-001): B sửa spec"; R=$?
chk "nhanh-vai: B ghi specs/ → qua (exit $R)" '[ $R = 0 ]'
# đuôi Vai: trong message thắng dấu worktree
printf 'z\n' > src/d.js
git add -A; git commit -q -m "feat(UC-001): D qua đuôi" -m "Vai: D" 2>"$W/hookerr.txt"; R=$?
chk "đuôi 'Vai: D' trong message → suy vai D, src qua (exit $R)" '[ $R = 0 ]'
# SDD_ROLE thắng tất cả
printf 'w\n' > src/e.js; git add -A
SDD_ROLE=T git commit -q -m "feat(UC-001): T qua env" 2>"$W/hookerr.txt"; R=$?
chk "SDD_ROLE=T → src bị chặn, thông điệp nói của vai D (exit $R)" '[ $R != 0 ] && grep -q "chỗ này của vai D" "$W/hookerr.txt"'
git reset -q; rm -f src/e.js
# R không được commit
rm .git/sdd-role; S role.sh R
mkdir -p notes/hoi-dap; printf '# Hỏi đáp\n' > notes/hoi-dap/hoi-dap.md
cmv "chore(sdd): R thử commit"; R=$?
chk "R.commit=khong → chặn (exit $R)" '[ $R != 0 ] && grep -q "không được commit" "$W/hookerr.txt"'
git reset -q; git checkout -q -- . 2>/dev/null; git clean -qfd notes 2>/dev/null
# worktree riêng cho D: dấu riêng, nhánh theo mẫu, checkout chính vẫn giữ dấu R
S role.sh --worktree D UC-001
chk "--worktree D UC-001 dựng ../vai-d-uc-001 nhánh code/uc-001 (exit $R)" '[ $R = 0 ] && [ -d "$W/vai-d-uc-001" ] && [ "$(git -C "$W/vai-d-uc-001" symbolic-ref --short HEAD)" = code/uc-001 ]'
chk "dấu vai của worktree phụ nằm ở .git/worktrees/*/sdd-role = D, checkout chính vẫn R" '[ "$(cat "$(cd "$W/vai-d-uc-001" && git rev-parse --git-path sdd-role)")" = D ] && [ "$(cat .git/sdd-role)" = R ]'
( cd "$W/vai-d-uc-001" && mkdir -p src && printf 'q\n' > src/f.js && git add -A && git commit -q -m "feat(UC-001): D trong worktree" 2>"$W/hookerr.txt" ); R=$?
chk "D commit src trong worktree riêng → qua (exit $R)" '[ $R = 0 ]'
( cd "$W/vai-d-uc-001" && mkdir -p tests/use-cases && printf 'q\n' > tests/use-cases/x.test.js && git add -A && git commit -q -m "feat(UC-001): D lấn test cổng" 2>"$W/hookerr.txt" ); R=$?
chk "D ghi uc_test_dir trong worktree → chặn, nói của vai T (exit $R)" '[ $R != 0 ] && grep -q "chỗ này của vai T" "$W/hookerr.txt"'
# không có .sdd/roles → im lặng, hành vi cũ
git rm -q --cached .sdd/roles 2>/dev/null; rm -f .sdd/roles; rm -f .git/sdd-role
printf 'v\n' > src/g.js
cmv "feat(UC-001): không roles"; R=$?
chk "không có .sdd/roles → hook im lặng, qua (exit $R)" '[ $R = 0 ] && ! grep -q "vai" "$W/hookerr.txt"'

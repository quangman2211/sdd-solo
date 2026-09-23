# P-49 (8.3.0): phieu.sh new ở worktree phụ ghi dòng mục lục lên NHÁNH của vai, trong khi A/R sửa cùng
# bảng trên main → mỗi lượt merge một xung đột ở hoi-dap.md, gộp tay (runxops cb380e3a, lượt 2+3 UC-031).
# Chữa như queue.sh đã chữa: CHỈ CHECKOUT CHÍNH ghi bảng; bảng là thứ SINH RA từ file phiếu.
nr gom
HD=notes/hoi-dap/hoi-dap.md
S phieu.sh new "UC-001 gửi trùng" soi
chk "checkout chính: vẫn ghi dòng mục lục như cũ (exit $R)" '[ $R = 0 ] && grep -q "| #1 |" "$HD"'
# ── worktree phụ ──
S role.sh --worktree D UC-001
WD="$W/gom-d-uc-001"
git -C "$WD" merge -q main 2>/dev/null
( cd "$WD" && CLAUDE_PROJECT_DIR="$WD" bash "$P/scripts/phieu.sh" new "UC-001 kho rỗng" code >/dev/null 2>&1 )
chk "worktree phụ: TẠO file phiếu" '[ -n "$(ls "$WD"/notes/hoi-dap/phieu/002-* 2>/dev/null)" ]'
chk "worktree phụ: KHÔNG đụng mục lục — đó là cả phép chữa" '! grep -q "| #2 |" "$WD/$HD"'
chk "vẫn commit file để giữ số (P-21 không được yếu đi)" \
  'git -C "$WD" log -1 --format=%s | grep -q "phiếu #2"'
# số tiếp theo ở main vẫn không trùng, vì max_n đọc git log --all
S phieu.sh new "UC-001 việc khác" soi
chk "main cấp số tiếp theo là #3, không trùng #2 của worktree (exit $R)" \
  '[ $R = 0 ] && [ -n "$(ls notes/hoi-dap/phieu/003-* 2>/dev/null)" ]'
# ── merge: đây là phép đo thật — 8.2.0 xung đột ở đúng dòng này ──
# A cũng sửa cột Trạng thái của phiếu trước trên main, sát dòng mới nối thêm — nguyên văn ca runxops
node -e 'const f=require("fs"),p=process.argv[1];f.writeFileSync(p,f.readFileSync(p,"utf8").replace(/^(\| \*#1 \|[^\n]*)$/m,x=>x))' "$HD" 2>/dev/null
MO="$(git merge --no-ff -m "chore(sdd): merge code/uc-001" code/uc-001 2>&1)"; RM=$?
chk "merge nhánh vai KHÔNG còn xung đột ở hỏi-đáp (P-49) (exit $RM)" \
  '[ $RM = 0 ] && ! printf "%s\n" "$MO" | grep -q CONFLICT'
S phieu.sh muc-luc
chk "soát thấy file #2 chưa có dòng (exit $R)" '[ $R = 1 ] && has "files with no index row"'
S phieu.sh muc-luc --gom
chk "--gom dựng lại đủ ba dòng từ file phiếu (exit $R)" \
  '[ $R = 0 ] && grep -q "| #1 |" "$HD" && grep -q "| #2 |" "$HD" && grep -q "| #3 |" "$HD"'
chk "--gom giữ nguyên phần văn phía trên bảng" 'grep -q "^## Bốn mức" "$HD" || grep -q "Four levels" "$HD"'
S phieu.sh muc-luc
chk "soát lại: khớp hết" '[ $R = 0 ] && has "the index and the files match"'
# ── trạng thái SUY từ file, không sửa tay ──
chk "phiếu chưa điền ô Trả lời → mở" 'grep -E "^\| *#2 \|" "$HD" | grep -q "mở"'
F2="$(ls notes/hoi-dap/phieu/002-*.md)"
node -e 'const f=require("fs"),p=process.argv[1];f.writeFileSync(p,f.readFileSync(p,"utf8").replace("**Trả lời (R):** <level L0–L3> · <the answer>","**Trả lời (R):** L1 · dùng kho rỗng làm mặc định"))' "$F2"
S phieu.sh muc-luc --gom
chk "điền ô Trả lời → trạng thái tự thành 'đã trả lời', không ai sửa bảng" \
  'grep -E "^\| *#2 \|" "$HD" | grep -q "đã trả lời"'
# ── worktree phụ không được gom ──
( cd "$WD" && CLAUDE_PROJECT_DIR="$WD" bash "$P/scripts/phieu.sh" muc-luc --gom >"$W/g.out" 2>&1 ); RG=$?
chk "worktree phụ: --gom bị từ chối, nói rõ vì sao (exit $RG)" \
  '[ $RG != 0 ] && grep -q "MAIN checkout" "$W/g.out"'

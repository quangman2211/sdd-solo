# P-16: UC đã implemented, commit docs(UC-###) ngoài vân tay sau commit đóng → §9 vẫn so với lần đọc lại cũ.
# Hai hình: (a) ## Đọc lại chưa nén (đóng bằng bản trước 7.4) → đỏ "spec đổi HÀNH VI"; (b) đã nén → đỏ "chưa đọc lại".
# 7.4: mốc so của UC implemented là commit đóng; đổi hành vi sau đó là việc của Phase 5.
# 8.4.0: `pass.sh close` giờ chạy close-check trước và TỪ CHỐI khi đỏ — sửa một AC sau cổng rồi đóng
# chính là thứ §9 vẫn luôn nói là sai, tới 8.3.0 pass.sh mới bỏ qua. Trạng thái mà ca này cần đo chỉ có ở
# repo đóng bằng bản CŨ, nên dựng thẳng ở đây thay vì đi qua cổng. Đây là giàn giáo của bộ test, không phải
# một cửa thoát của plugin: plugin không có cờ bỏ qua, và sẽ không có.
close_cu() {
  node -e 'const f=require("fs"),p=process.argv[1];f.writeFileSync(p,f.readFileSync(p,"utf8").replace(/(\*\*Status:\*\* *)(draft|reviewed)/,"$1implemented"))' "$UC1"
  node "$P/scripts/js/pass.mjs" trace "$UC1" "$UCD/UC-001.trace.md" UC-001 2026-01-12 >/dev/null 2>&1 || true
  [ -f "$UCD/UC-001.trace.md" ] && git add "$UCD/UC-001.trace.md"
  git add "$UC1" && GIT_AUTHOR_DATE=2026-01-12T10:00:00 GIT_COMMITTER_DATE=2026-01-12T10:00:00 \
    git -c core.hooksPath=/dev/null commit -q -m "docs(UC-001): implemented — traceability"
}
nr p16
S pass.sh gate UC-001
rep "$UC1" 'Then:  một tin báo được gửi' 'Then:  đúng một tin báo được gửi'
cm "docs(UC-001): áp chữ AC-1 sau cổng" 2026-01-10
code_uc1
close_cu
rep "$UC1" '- **Rules:** RULE-001' '- **Rules:** RULE-001 · **Upstream UC:** -'
cm "docs(UC-001): sửa Dependencies" 2026-01-13
S gate-check.sh UC-001
chk "đỏ status implemented (đúng luật)" 'has "status is already implemented"'
chk "P-16 · (b) đã nén: không đỏ §9 'chưa đọc lại' trên UC implemented" '! has "not re-read with an unanchored mind"'
nr p16a
ins_after "$UC1" "- F1 Main 2" "- F2 x [neo: Screens] → không phải lỗi vì commit <hash> đã bỏ"
cm "docs(UC-001): đọc lại — F2" 2026-01-06
S pass.sh gate UC-001
rep "$UC1" 'Then:  một tin báo được gửi' 'Then:  đúng một tin báo được gửi'
cm "docs(UC-001): áp chữ AC-1 sau cổng" 2026-01-10
code_uc1
close_cu
chk "(a) ## Đọc lại đã nén dù thân có <hash> (P-40)" '! grep -q "^- F1 " "$UC1"'
# UC đóng bằng bản trước 7.4 còn nguyên F# trong ## Đọc lại — dựng lại hình đó bằng tay
ins_after "$UC1" "phát hiện · " "- F1 Main 2 nói gửi theo RULE-001 [neo: Main 2 · RULE-001] → không phải lỗi vì đã có Open Question"
rep "$UC1" '- **Rules:** RULE-001' '- **Rules:** RULE-001 · **Upstream UC:** -'
cm "docs(UC-001): sửa Dependencies" 2026-01-13
S gate-check.sh UC-001
chk "P-16 · (a) chưa nén: không đỏ 'spec đổi HÀNH VI' vì vùng đổi nằm trước commit đóng" '! has "changed BEHAVIOUR"'
# đổi AC SAU khi đóng thì cổng phải chỉ sang Phase 5, không chỉ sang verify
rep "$UC1" 'Then:  đúng một tin báo được gửi' 'Then:  hai tin báo được gửi'
cm "docs(UC-001): đảo AC-1 sau đóng" 2026-01-14
S gate-check.sh UC-001
chk "AC đổi sau commit đóng → cổng nói 'sau khi đóng UC' + Phase 5" 'has "after the UC was closed" && has "Phase 5"'

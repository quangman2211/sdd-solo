# 8.11.0 — con số phải CHẠM ĐƯỢC 0, và mỗi dòng khai mẫu số của nó.
#
# CLAUDE.md đã đo một lần rằng chỉ ĐẾM là một lỗ hổng: tới 7.8 `→ Chưa quyết` chỉ được đếm và kết quả
# là 13 vòng / 105 tồn trên UC-024; cái chữa không phải counter tốt hơn mà là `rr_max`, một cái đỏ.
# Và `metrics.sh` tự đặt bar cho mình: dòng đáng theo dõi là dòng CÓ THỂ về đích. Nên mẫu số ở đây là
# file mốc CÒN LẠI, và dòng một chính là tập hook tha — bảng đếm và cổng không được nói ngược nhau.
mkbrown adopt3
S adopt.sh --count
chk "adopt --count chạy được (exit $R)" '[ $R = 0 ]'
chk "dòng 1 đếm đúng 3 file mốc" 'hasE "ever touched: 3/3"'
chk "dòng 2 bắt đầu từ 0" 'hasE "Existing code:  ?0/3"'
chk "không có phần trăm ở đâu cả — kho này đếm bằng số nguyên trần" '! has "%"'
chk "mỗi dòng khai mẫu số của nó" 'hasE "[0-9]+/[0-9]+" && has "files in that tree"'

# một commit mang ID kéo dòng 1 xuống — đây là việc THẬT làm số xuống, không phải một công tắc
mkdir -p specs; app specs/s.md "# spec"
cm "docs(UC-001): spec reviewed" 2026-01-03
mkdir -p .sdd/gate; git rev-parse HEAD > .sdd/gate/UC-001.ok
cm "chore(sdd): marker" 2026-01-03
app app/a.js "const x = 1;"
cmv "feat(UC-001): a.js"
S adopt.sh --count
chk "sau một commit mang ID: 3/3 → 2/3" 'hasE "ever touched: 2/3"'

# xoá file cũng là một câu trả lời hợp lệ cho "hãy spec nó" — mẫu số phải xuống theo
git rm -q app/b.js; cm "chore(sdd): bo file khong dung nua" 2026-01-04
S adopt.sh --count
chk "xoá một file mốc: mẫu số xuống còn 2" 'hasE "ever touched: 1/2"'

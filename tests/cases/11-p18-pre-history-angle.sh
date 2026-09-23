# P-18 / P-39a: `<...>` trong ## History (sổ chỉ-thêm) bị --pre đếm là "chưa điền"
nr p18
app "$UC1" "- v3 (2026-01-07, anh): ghi lại cảnh báo id node dạng E<số> của cổng"
S gate-check.sh --pre UC-001
xfail P-18 "--pre không đếm <...> trong ## History (được exit $R)" '[ $R = 0 ]'

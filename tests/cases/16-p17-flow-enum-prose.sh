# P-17: cảnh báo "id node dạng E<số>" bắt cả văn xuôi ngoài khối mermaid của flow.md
nr p17
app "$FL1" "Ghi chú: X1 bỏ E1 (chỉ tới được E1 từ T2)."
cm "docs(UC-001): đọc lại — ghi chú flow" 2026-01-06
S gate-check.sh UC-001
chk "P-17 · không cảnh báo id node E<số> cho chữ ngoài khối mermaid" '! has "id node dạng E<số>"'

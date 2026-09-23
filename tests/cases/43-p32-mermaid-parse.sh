# P-32: gate-check đếm nhãn mermaid bằng grep, không parse — 10/21 sơ đồ runxops vỡ khi render mà cổng vẫn xanh.
# Ground truth đo bằng chính mermaid (mermaid.parse qua jsdom, 88 khối của runxops): 17 khối vỡ, cả 17 do
# ';' trong lời (sequence · state · class) hoặc '( ) [ ] { } |' trong nhãn node flowchart chưa bọc nháy kép.
nr p32
# ① nhãn node flowchart chưa bọc nháy, có ngoặc → mermaid vỡ
rep "$FL1" 'S([Order new])' 'S([Order new (theo RULE-001)])'
S mermaid.sh --lint "$FL1"
chk "P-32 · lint bắt ngoặc trong nhãn node chưa bọc nháy (exit $R)" '[ $R = 1 ] && has "UC-001.flow.md"'
rep "$FL1" 'S([Order new (theo RULE-001)])' 'S(["Order new (theo RULE-001)"])'
S mermaid.sh --lint "$FL1"
chk "P-32 · bọc nháy kép thì qua (exit $R)" '[ $R = 0 ]'
# ② dấu ; trong lời sequence → mermaid cắt câu, chữ sau mất
printf '# UC-001 — Sequence\n```mermaid\nsequenceDiagram\n  A->>B: gửi tin; chờ trả lời\n```\n' > "$UCD/UC-001.sequence.md"
S mermaid.sh --lint "$UCD/UC-001.sequence.md"
chk "P-32 · lint bắt ';' trong lời sequence (exit $R)" '[ $R = 1 ] && has "sequence"'
# ③ cổng đọc nhãn cạnh qua parser, không grep: nhãn trong nháy kép của node không còn giả mạo được nhãn cạnh
S mermaid.sh --edges "$FL1"
chk "P-32 · --edges in đúng nhãn cạnh" '[ "$(printf "%s\n" "$O" | grep -c .)" = 1 ] && has "E1 gửi hỏng"'
S mermaid.sh --nodes "$FL1"
chk "P-32 · --nodes in id + hình + nhãn" 'hasE "^S[[:space:]]+stadium[[:space:]]+Order new \(theo RULE-001\)$" && hasE "^T1[[:space:]]+rect"'
# ④ cổng đầy đủ đỏ khi sơ đồ vỡ — sơ đồ không render được thì không ai đọc lại được nó
rep "$FL1" 'T1[Hiển thị SCR-001-1]' 'T1[Hiển thị SCR-001-1 (màn chính)]'
cm "docs(UC-001): đọc lại — sửa flow" 2026-01-06
S gate-check.sh UC-001
chk "P-32 · cổng đỏ khi flow.md không parse được (exit $R)" '[ $R = 1 ] && has "mermaid"'
# ⑤ nhãn trong nháy kép của node không giả mạo được nhãn cạnh (#17 bằng parser)
nr p32b
rep "$FL1" 'X1([E1: thử lại])' 'X1(["E1 | E2 đều thử lại"])'
S mermaid.sh --edges "$FL1"
chk "P-32 · --edges không nhặt chữ trong nhãn node" '[ "$(printf "%s\n" "$O" | grep -c .)" = 1 ]'
S mermaid.sh --lint "$FL1"
chk "P-32 · | trong nhãn đã bọc nháy kép là hợp lệ (exit $R)" '[ $R = 0 ]'
# ⑥ dấu ; trong nhãn stateDiagram của entity: mermaid mất TRẮNG nhãn cả sơ đồ → cổng phải đỏ
nr p32c
rep specs/orders/entities/Order.md '[*] --> new : UC-001 báo đơn' '[*] --> new : UC-001 báo đơn (console; seed tay)'
cm "docs(UC-001): đọc lại — sửa entity" 2026-01-06
S gate-check.sh UC-001
chk "P-32 · cổng đỏ khi ; làm mất nhãn state diagram (exit $R)" '[ $R = 1 ] && hasE "mất khi render|không render được"'
# ⑦ không có python3 thì mọi thứ im lặng, hành vi như 7.4
nr p32d
mkdir -p "$W/nopy" && printf '#!/bin/sh\nexit 127\n' > "$W/nopy/python3" && chmod +x "$W/nopy/python3"
O="$(PATH="$W/nopy:$PATH" bash "$P/scripts/gate-check.sh" UC-001 2>&1 | clean)"; R=$?
chk "P-32 · không có python3: cổng vẫn qua, không đỏ oan (exit $R)" '[ $R = 0 ]'
# ⑧ bản sao .sdd/scripts/ của dự án phải có parser, kẻo cổng chạy ở CI rơi về grep im lặng
nr p32e
chk "P-32 · scaffold chép mermaid.py + mermaid.sh sang .sdd/scripts/" '[ -f .sdd/scripts/mermaid.py ] && [ -x .sdd/scripts/mermaid.sh ]'

# diagrams/

Chỉ diagram **cấp context** nằm ở đây (context map, domain model). Sơ đồ luồng của từng use case nằm trong thư mục UC: `use-cases/UC-###-slug/UC-###.flow.md`.

- `UC-###.flow.md` — mermaid `flowchart`, trong thư mục UC. Là text: gõ bằng bàn phím, `git diff` đọc được, VS Code và GitHub render sẵn.
- `RULE-###.dmn` — DMN nếu muốn chạy rule bằng engine (tuỳ chọn; bảng trong `rules.md` là bản chính). Đây là lý do duy nhất còn cần Camunda Modeler.
- `UC-###.bpmn` — đường cũ, vẫn được cổng DoR chấp nhận. Không đếm được E# bằng máy vì là XML nén; sửa được thì chuyển sang `.flow.md`.

Đối chiếu bắt buộc trước cổng DoR:
- Số `subgraph` = số actor, khi UC có từ hai actor trở lên.
- Mỗi Alternative Flow = một nhánh của `D#{...}`, điều kiện ghi trên mũi tên.
- Mỗi Exception `E#` = một mũi tên có nhãn `|E# ...|` dẫn tới node kết `X#([E#: ...])`.
- Mỗi Postcondition = một node kết `P#([...])`.

Dòng `E#` được `/sdd-solo:gate` kiểm bằng máy, **cả hai chiều**: E# khai trong UC mà sơ đồ không có nhánh → đỏ; nhãn E# trong sơ đồ mà UC không có Exception đó → cũng đỏ. Hai dòng còn lại là văn xuôi tự do nên chỉ có anh kiểm.

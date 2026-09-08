# diagrams/

- `UC-###.bpmn` — BPMN 2.0 chuẩn, vẽ ở Camunda Modeler.
- `UC-###.bpmn.svg` — export để đọc không cần tool.
- `RULE-###.dmn` — DMN nếu muốn chạy rule bằng engine (tuỳ chọn; bảng trong rules.md là bản chính).

Đối chiếu bắt buộc trước cổng DoR:
- Số lane = số actor trong UC.
- Mỗi Alternative Flow = một nhánh của exclusive gateway, điều kiện ghi trên mũi tên.
- Mỗi Exception E# = một error boundary event → end event có tên.
- Mỗi Postcondition = một end event có tên.

# Phân loại feedback (Phase 4)

Mọi feedback rơi vào đúng một dòng. Spec trước, code sau.

| Loại | Dấu hiệu | Đích đến | Commit |
|---|---|---|---|
| Đã Out of Scope | có trong Out of Scope / hàng "sau" của Story Map | ghi vào BR Open Questions hoặc nâng lên Story Map | docs(BR-###) |
| Spec thiếu | không E#/AC nào nói tới | thêm AC/E#, flow, SCR, History → regen | docs(UC-###) rồi feat(UC-###) |
| Bug | AC nói rõ, code làm khác | test AC đỏ trước, rồi sửa | fix(UC-###) |
| Rule sai | AC đúng như viết nhưng sai thực tế | sửa rules.md, AC cũ deprecated, AC mới | docs(RULE-###) |
| UX | hành vi đúng, khách vẫn không làm được | sửa SCR, cập nhật ## Screens | docs(UC-###) |

Ranh giới bug / spec thiếu: "QR hết hạn thì hiện lỗi" là exception; "app crash khi QR hết hạn" là bug.

---
name: state
description: Cập nhật STATE.md cuối buổi — đang làm UC nào bước nào, quyết định gần nhất, câu hỏi treo, việc tiếp theo, bỏ dở vì. Thay standup cho một người. Dùng khi user nói "cập nhật STATE", "xong buổi", "đóng máy".
argument-hint: "[ghi chú ngắn]"
allowed-tools: Bash Read Edit
---

Viết lại `STATE.md` (root repo) theo đúng 5 dòng. Nguồn: STATE cũ, `git log -5 --format='%s'`, `.sdd/gate/`, UC đang mở trong session này, `$ARGUMENTS`.

```
Đang làm:            UC-### · bước N — <một cụm>
Quyết định gần nhất: <một câu> (→ ADR-### | docs/decisions.md)
Câu hỏi treo:        <một câu> (quyết định tạm: ___)  | không có
Việc tiếp theo:      <lệnh hoặc việc cụ thể đầu tiên của buổi sau>
Bỏ dở vì:            <lý do thật, kể cả "hết pin">
```

Quy tắc: không dài hơn 5 dòng chính (mục Retro nếu có giữ nguyên). "Việc tiếp theo" phải là thứ bắt đầu được trong 5 phút. Không commit STATE riêng — nó đi cùng commit tiếp theo, hoặc `chore(sdd): state` nếu user yêu cầu.

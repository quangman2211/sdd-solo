---
name: update
description: Cập nhật sdd-solo trọn chuỗi trong một lệnh — làm mới marketplace, cài bản mới, rồi cập nhật .sdd/ và template của dự án. Dùng khi hook hoặc /sdd-solo:status báo lệch version.
disable-model-invocation: true
argument-hint: ""
allowed-tools: Bash
---

Chạy:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/update.sh"
```
Nếu `${CLAUDE_PLUGIN_ROOT}` không được thay: `find ~/.claude/plugins -type f -name update.sh -path '*sdd-solo*' | head -1`.

In nguyên output. Script tự bỏ qua khe nào đã đúng, nên đừng chạy lại từng lệnh con.

Sau đó:
- Mục `=== Sau khi update ===` mà dòng "phiên NÀY vẫn đang chạy" thấp hơn "bản đã cài" → **nói user mở session mới**. Bản mới không áp vào phiên đang mở, y như Claude Code tự update chính nó. Đừng hứa là đã có hiệu lực.
- Có file `.new` trong phần ③ → liệt kê, nói user tự merge. Không tự ghi đè.
- Lên **major** (1.x → 2.x) thì `init --update` không di chuyển được file đã có: đọc CHANGELOG của bản đó và nói user chạy script migrate nếu có.
- Script không sửa spec và không commit gì. Thay đổi trong `.sdd/` và template là việc của user commit — nhắc `chore(sdd): update sdd-solo <ver>`.

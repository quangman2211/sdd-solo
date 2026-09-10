---
name: init
description: Cài quy trình SDD-Solo vào repo hiện tại (scaffold specs/ .sdd/ STATE.md, khối CLAUDE.md, git hooks), hoặc cập nhật lên bản plugin mới mà không ghi đè file đã sửa tay. --update chỉ làm mới .sdd/ và template; --plugin làm trọn chuỗi marketplace → plugin đã cài → .sdd/ trong một lệnh.
disable-model-invocation: true
argument-hint: "[--update] [--plugin]"
allowed-tools: Bash Read
---

Cài hoặc cập nhật sdd-solo trong repo hiện tại.

`$ARGUMENTS` có `--plugin` → **chế độ B** (trọn chuỗi). Còn lại → **chế độ A** (scaffold).

---

## A. `/sdd-solo:init` · `/sdd-solo:init --update`

1. Xác định root repo: `git rev-parse --show-toplevel` (không phải git repo → hỏi user có muốn
   `git init` không; hook cần git).
2. Chạy scaffold — nó chỉ hiểu `--update`, đừng truyền cờ nào khác vào:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/scaffold.sh" "${CLAUDE_PLUGIN_ROOT}" "$(git rev-parse --show-toplevel)" --update
```
   (bỏ `--update` nếu đây là lần cài đầu). Nếu `${CLAUDE_PLUGIN_ROOT}` không được thay, tìm plugin:
   `find ~/.claude/plugins -type f -name scaffold.sh -path '*sdd-solo*' | head -1`, rồi dùng thư
   mục cha của `scripts/`.
3. In nguyên output cho user (các dòng ✓ / !).
4. Kiểm phụ thuộc, in nguyên output:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/deps-check.sh"
```
   Từ 4.0.0 danh sách này gần như rỗng — bắt buộc chỉ còn `git` và repo đã `git init`. Spec Kit,
   AIUP, Camunda đều là **tuỳ chọn** và script chỉ nói một dòng về chúng. Exit ≠ 0 nghĩa là thiếu
   một thứ thật sự bắt buộc; đọc lại dòng ✗ cho user.
5. Output có cảnh báo *"specs/ đang chứa cả cây của Spec Kit"* → nói user chạy
   `bash .sdd/scripts/migrate.sh --dry-run` xem trước, rồi chạy thật. **Đừng tự chạy** — nó dời file.
6. `specs/br.md` còn nguyên template (có chuỗi `<Tên business requirement>`) → nói bước tiếp là
   **`/sdd-solo:intake`**. Đừng đề xuất viết code, đừng đề xuất công cụ ngoài.
7. Có file `.new` trong output → liệt kê và nói user tự merge; không tự ghi đè.

---

## B. `/sdd-solo:init --plugin`

Dùng khi hook SessionStart hoặc `/sdd-solo:status` báo lệch version. Chạy:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/update.sh"
```
(không thay được biến: `find ~/.claude/plugins -type f -name update.sh -path '*sdd-solo*' | head -1`).

In nguyên output. Script tự bỏ qua khe nào đã đúng, nên đừng chạy lại từng lệnh con.

Sau đó:
- Mục `=== Sau khi update ===` mà dòng *"phiên NÀY vẫn đang chạy"* thấp hơn *"bản đã cài"* →
  **nói user mở session mới**. Bản mới không áp vào phiên đang mở, y như Claude Code tự update
  chính nó. Đừng hứa là đã có hiệu lực.
- Có file `.new` trong phần ③ → liệt kê, nói user tự merge. Không tự ghi đè.
- Lên **major** (3.x → 4.x) thì scaffold không di chuyển được file đã có: đọc CHANGELOG của bản đó,
  và với 4.0.0 thì nói user chạy `bash .sdd/scripts/migrate.sh --dry-run`.
- Script không sửa spec và không commit gì. Thay đổi trong `.sdd/` và template là việc của user
  commit — nhắc `chore(sdd): update sdd-solo <ver>`.

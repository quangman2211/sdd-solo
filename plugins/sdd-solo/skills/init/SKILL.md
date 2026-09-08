---
name: init
description: Cài quy trình SDD-Solo vào repo hiện tại (scaffold specs/ .sdd/ STATE.md, khối CLAUDE.md, spec-template mỏng cho Spec Kit, git hooks) hoặc cập nhật lên bản plugin mới mà không ghi đè file đã sửa tay. --with-deps cài luôn Spec Kit và AIUP.
disable-model-invocation: true
argument-hint: "[--update] [--with-deps]"
allowed-tools: Bash Read
---

Chạy scaffold của plugin vào repo hiện tại.

1. Xác định root repo: `git rev-parse --show-toplevel` (nếu không phải git repo, hỏi user có muốn `git init` không — hook cần git).
2. Chạy scaffold. **Bỏ `--with-deps` ra khỏi tham số truyền cho scaffold** — nó chỉ hiểu `--update`:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/scaffold.sh" "${CLAUDE_PLUGIN_ROOT}" "$(git rev-parse --show-toplevel)" $ARGUMENTS
```
Nếu biến `${CLAUDE_PLUGIN_ROOT}` không được thay, tìm plugin: `find ~/.claude/plugins -type f -name scaffold.sh -path '*sdd-solo*' | head -1` và dùng thư mục cha của `scripts/`.
3. In nguyên output của script cho user (các dòng ✓ / ! ).
4. Kiểm phụ thuộc — **không tự cài trừ khi user gõ `--with-deps`**:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/deps-check.sh"            # mặc định: chỉ kiểm, in lệnh
"${CLAUDE_PLUGIN_ROOT}/scripts/deps-check.sh" --fix      # chỉ khi $ARGUMENTS có --with-deps
```
In nguyên output. Script tự lo thứ tự bắt buộc (`specify init` trước, rồi scaffold `--update` để thay spec-template) và tự kiểm lại sau khi cài, nên đừng đoán hộ nó.
   - Exit ≠ 0 và user **không** gõ `--with-deps`: đọc lại các dòng ✗ cho user, nói rõ họ có thể chạy `/sdd-solo:init --with-deps` để cài giúp. Không tự chạy.
   - `--fix` không cài được lệnh `specify` (cần `uv`) — chỗ đó vẫn là việc của user.
   - AIUP vừa cài xong thì lệnh `/requirements` chưa có trong session hiện tại; nhắc user mở session mới.
5. Nếu `specs/br.md` còn nguyên template (có chuỗi `<Tên business requirement>`): nói bước tiếp là **`/sdd-solo:intake`** — nó hỏi bảy câu rồi tự viết BR. Đừng đề xuất `/requirements` ở đây: AIUP đọc `docs/vision.md` mà không skill nào tạo ra file đó, và nó nhảy thẳng vào "hệ thống làm gì", bỏ qua tầng "vì sao làm". Đừng đề xuất viết code.
6. Nếu có file `.new` trong output: liệt kê và nói user tự merge; không tự ghi đè.

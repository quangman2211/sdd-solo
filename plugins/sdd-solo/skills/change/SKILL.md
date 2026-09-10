---
name: change
description: Phase 5 — cổng cho một CHG-### đổi hành vi đã giao (proposal, design, delta ADDED/MODIFIED/REMOVED khớp baseline, UC bị đụng phải implemented). Đỏ thì không được sửa code; xanh thì đặt status applying, ghi marker .sdd/gate/CHG-###.ok và commit.
disable-model-invocation: true
argument-hint: "CHG-###"
allowed-tools: Bash Read
---

Cổng Phase 5 cho `$1`.

Phase 5 chỉ dành cho thay đổi làm **một AC cũ không còn đúng** trên UC đã `implemented`. Thêm AC mới mà không phá AC cũ thì vẫn là Phase 3: sửa thẳng UC, `## History` v+1, xong. Nếu user mở change cho việc thuộc Phase 3, nói ngay và đừng chạy tiếp.

1. Chưa có thư mục change thì tạo trước — copy `${CLAUDE_PLUGIN_ROOT}/templates/skel/change/` (không thay được biến: `find ~/.claude/plugins -type d -name skel -path '*sdd-solo*' | head -1`) thành `specs/changes/$1-<slug>/`, điền cùng user, commit `docs($1): ...`. Không tự bịa Why/Scope/delta thay user.
2. Chạy và in nguyên output:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/change-check.sh" $1
```
(nếu `${CLAUDE_PLUGIN_ROOT}` không được thay: `find ~/.claude/plugins -type f -name change-check.sh -path '*sdd-solo*' | head -1`).
3. Exit ≠ 0 → **KHÔNG QUA CỔNG**. Với mỗi dòng ✗ nói cần sửa gì, ở file nào. Ba loại ✗ hay gặp và ý nghĩa thật của chúng:
   - *"UC đang draft, chưa implemented"* → đây là Phase 3, đóng change lại.
   - *"không delta nào MODIFIED/REMOVED"* → cũng là Phase 3.
   - *"REMOVED AC-# nhưng baseline không có"* → delta đang nói về một baseline khác với baseline thật; đọc lại UC trước khi sửa delta.
   Không tự sửa spec thay user (trừ khi user bảo). Không viết code. Dừng ở đây.
4. Exit 0 → chạy:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/pass.sh" change $1
```
Script đặt `Status: applying`, ghi `.sdd/gate/$1.ok`, commit `docs($1): change reviewed — qua cổng Phase 5`. Không có marker này thì githook chặn mọi commit code gắn `($1)`.
5. STATE.md: `Đang làm: $1 · qua cổng Phase 5 — đang applying`. `Việc tiếp theo: test cho AC mới (đỏ trước) → sửa domain → test AC cũ được giữ vẫn xanh`.
6. Nhắc user: AC bị `REMOVED` **không bị xoá** khỏi baseline lúc archive — đánh dấu `deprecated` kèm ngày. Và việc cuối của `tasks.md` là archive: merge delta vào `specs/`, `## History` của UC v+1, commit `chore($1): archive`.

Không có cờ bỏ qua.

---
name: gate
description: Bước ⑨ — cổng Definition of Ready cho một UC, kiểm cơ học (AC vs E#, Screens, RULE tồn tại, BPMN, adversarial pass, commit docs đã qua một đêm). Đỏ thì không được chạy Spec Kit; xanh thì đặt status reviewed, ghi marker .sdd/gate/UC-###.ok và commit.
disable-model-invocation: true
argument-hint: "UC-###"
allowed-tools: Bash Read
---

Cổng DoR cho `$1`.

1. Chạy và in nguyên output:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/gate-check.sh" $1
```
(nếu `${CLAUDE_PLUGIN_ROOT}` không được thay: `find ~/.claude/plugins -type f -name gate-check.sh -path '*sdd-solo*' | head -1`).
2. Exit ≠ 0 → **KHÔNG QUA CỔNG**. Với mỗi dòng ✗, nói user cần sửa gì và ở file nào. Không tự sửa spec thay user (trừ khi user bảo). Không chạy `/specify`, `/plan`. Dừng ở đây.
3. Exit 0 → chạy:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/gate-pass.sh" $1
```
Script đặt `Status: reviewed`, ghi `.sdd/gate/$1.ok`, commit `docs($1): spec reviewed — qua cổng DoR`.
4. STATE.md: `Đang làm: $1 · bước ⑨ xong — sẵn sàng /specify`. `Việc tiếp theo: /specify (file mỏng trích ID) → /plan, đọc plan trước khi /tasks`.
5. Nhắc user ba chỗ cần soi khi đọc plan: RULE được kiểm trước khi tạo record chưa; logic RULE nằm ở domain hay adapter; chuyển trạng thái có đúng state diagram.

Không có cờ bỏ qua. Muốn vượt cổng thì phải sửa spec cho đủ.

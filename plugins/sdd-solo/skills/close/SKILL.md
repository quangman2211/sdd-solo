---
name: close
description: Bước ⑭ — Definition of Done cho một UC — mỗi AC có test đúng tên, docs đứng trước feat trong git log, soi số literal (rule ngầm), History có dòng; xanh thì status implemented, ghi traceability và commit.
disable-model-invocation: true
argument-hint: "UC-###"
allowed-tools: Bash Read Edit
---

Đóng `$1`.

1. Chạy self-review 5 câu cùng user trước (từ `checklists/self-review.md`), đặc biệt câu 5 *"AI quyết hay mình quyết?"* — nếu có quyết định kỹ thuật đáng nhớ, append một dòng vào `docs/decisions.md` theo format trong file.
2. Chạy và in output:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/close-check.sh" $1
```
3. Exit ≠ 0 → liệt kê việc còn thiếu (test thiếu, thứ tự commit sai, chưa qua gate). Dừng.
4. Có cảnh báo "số literal cần soi" → đi qua từng dòng với user: mỗi số phải trích RULE/CON hoặc user giải thích; số nào là rule nghiệp vụ mà spec chưa có → dừng, thêm RULE, commit `docs(...)`, rồi mới đóng.
5. Exit 0 → chạy:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/close-pass.sh" $1
```
6. Nếu spec có đổi trong lúc code mà `## History` chưa ghi → thêm dòng v+1 trước khi pass.
7. Gợi ý UC tiếp theo từ `specs/contexts/<ctx>/use-cases.md` (status draft đầu tiên) và nhắc `/sdd-solo:state`.

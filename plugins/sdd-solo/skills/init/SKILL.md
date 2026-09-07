---
name: init
description: Cài quy trình SDD-Solo vào repo hiện tại (scaffold specs/ docs/ changes/ STATE.md, khối CLAUDE.md, spec-template mỏng cho Spec Kit, git hooks) hoặc cập nhật lên bản plugin mới mà không ghi đè file đã sửa tay.
disable-model-invocation: true
argument-hint: "[--update]"
allowed-tools: Bash Read
---

Chạy scaffold của plugin vào repo hiện tại.

1. Xác định root repo: `git rev-parse --show-toplevel` (nếu không phải git repo, hỏi user có muốn `git init` không — hook cần git).
2. Chạy:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/scaffold.sh" "${CLAUDE_PLUGIN_ROOT}" "$(git rev-parse --show-toplevel)" $ARGUMENTS
```
Nếu biến `${CLAUDE_PLUGIN_ROOT}` không được thay, tìm plugin: `find ~/.claude/plugins -type f -name scaffold.sh -path '*sdd-solo*' | head -1` và dùng thư mục cha của `scripts/`.
3. In nguyên output của script cho user (các dòng ✓ / ! ).
4. Kiểm và nhắc, không tự cài:
   - Spec Kit: `ls .specify` — chưa có → nhắc `specify init --here` rồi chạy lại `/sdd-solo:init --update` để thay spec-template.
   - AIUP: nhắc `/plugin marketplace add ai-unified-process/marketplace` và `/plugin install aiup-core` nếu user chưa có `/requirements`.
   - Camunda Modeler cho BPMN/DMN; Claude Design cho Design System ở Phase 0.
5. Nếu là repo mới (chưa có `specs/br.md` nội dung): nói bước tiếp là Phase 1 — `/requirements` hoặc tự viết BR; đừng đề xuất viết code.
6. Nếu có file `.new` trong output: liệt kê và nói user tự merge; không tự ghi đè.

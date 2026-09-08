#!/usr/bin/env bash
# Hook SessionStart: đọc STATE.md và đưa vào context. Không in gì nếu repo không dùng sdd-solo.
ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
[ -f "$ROOT/STATE.md" ] || exit 0
STATE="$(cat "$ROOT/STATE.md")"
VER="$(cat "$ROOT/.sdd/version" 2>/dev/null || echo '?')"
GATES="$(ls "$ROOT/.sdd/gate" 2>/dev/null | grep -E '\.ok$' | sed 's/\.ok$//' | tr '\n' ' ')"
CTX="[sdd-solo v$VER] Repo này chạy quy trình SDD-Solo. Việc đầu tiên trong session: nói lại cho user đang ở UC nào, bước nào (theo STATE.md dưới đây) và lệnh gợi ý tiếp theo. Quy tắc cứng: không chạy /speckit-specify, /speckit-plan, /speckit-tasks, /speckit-implement cho UC chưa có marker .sdd/gate/UC-###.ok — bảo user chạy /sdd-solo:gate trước. Gặp quyết định nghiệp vụ spec chưa nói thì DỪNG và hỏi, không chọn mặc định. UC đã qua cổng: ${GATES:-chưa có}.

=== STATE.md ===
$STATE"
if command -v python3 >/dev/null 2>&1; then
  python3 - "$CTX" <<'PY'
import json,sys
print(json.dumps({"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":sys.argv[1]}},ensure_ascii=False))
PY
else
  printf '%s\n' "$CTX"
fi

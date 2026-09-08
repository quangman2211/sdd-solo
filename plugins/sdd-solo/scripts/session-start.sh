#!/usr/bin/env bash
# Hook SessionStart: đọc STATE.md và đưa vào context. Không in gì nếu repo không dùng sdd-solo.
ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
[ -f "$ROOT/STATE.md" ] || exit 0
STATE="$(cat "$ROOT/STATE.md")"
VER="$(cat "$ROOT/.sdd/version" 2>/dev/null || echo '?')"
GATES="$(ls "$ROOT/.sdd/gate" 2>/dev/null | grep -E '\.ok$' | sed 's/\.ok$//' | tr '\n' ' ')"
# Hook này chạy TỪ thư mục plugin mà phiên thật sự nạp — chỗ duy nhất biết
# được điều đó. Ghi lại để version-check đọc; không có nó thì khe ④ mù.
HD="$(cd "$(dirname "$0")" && pwd)"; . "$HD/lib.sh"
SV="$(jver "$(dirname "$HD")/.claude-plugin/plugin.json" version)"
if [ -n "$SV" ]; then
  SF="$(sess_file)"; mkdir -p "$(dirname "$SF")" && echo "$SV" > "$SF"
  find "$(dirname "$SF")" -name 'session-*' -mtime +7 -delete 2>/dev/null
fi
# lệch version: chỉ so cục bộ. Không gọi mạng ở hook — hook có timeout 10s.
VC="$("$(cd "$(dirname "$0")" && pwd)/version-check.sh" --brief 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g; s/^ *//' | tr '\n' '; ')"
CTX="[sdd-solo v$VER] Repo này chạy quy trình SDD-Solo. Việc đầu tiên trong session: nói lại cho user đang ở UC nào, bước nào (theo STATE.md dưới đây) và lệnh gợi ý tiếp theo. Quy tắc cứng: không chạy /speckit-specify, /speckit-plan, /speckit-tasks, /speckit-implement cho UC chưa có marker .sdd/gate/UC-###.ok — bảo user chạy /sdd-solo:gate trước. Gặp quyết định nghiệp vụ spec chưa nói thì DỪNG và hỏi, không chọn mặc định. UC đã qua cổng: ${GATES:-chưa có}.${VC:+ CẢNH BÁO lệch version — nói cho user ngay ở câu đầu: $VC}

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

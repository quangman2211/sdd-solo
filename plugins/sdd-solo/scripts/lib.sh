#!/usr/bin/env bash
# Hàm dùng chung cho script sdd-solo. Tương thích bash 3.2 (macOS).
ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
bad()  { printf '  \033[31m✗\033[0m %s\n' "$1"; FAIL=$((FAIL+1)); }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; WARN=$((WARN+1)); }
info() { printf '  – %s\n' "$1"; }
FAIL=0; WARN=0

project_root() {
  if [ -n "$CLAUDE_PROJECT_DIR" ]; then echo "$CLAUDE_PROJECT_DIR"; return; fi
  git rev-parse --show-toplevel 2>/dev/null || pwd
}

# find_uc UC-002 → in ra đường dẫn file UC-002.md (rỗng nếu không có)
find_uc() {
  local id="$1" root="$2"
  find "$root/specs/contexts" -type f -path "*/use-cases/${id}-*/${id}.md" 2>/dev/null | head -1
}
# ctx_of <path-to-UC.md> → tên context
ctx_of() { echo "$1" | sed -E 's#.*/specs/contexts/([^/]+)/.*#\1#'; }
# slug_of <path> → phần sau UC-###-
slug_of() { basename "$(dirname "$1")" | sed -E 's/^UC-[0-9]+-//'; }

sha() { if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | cut -d' ' -f1; else sha256sum "$1" | cut -d' ' -f1; fi; }
today() { date +%Y-%m-%d; }

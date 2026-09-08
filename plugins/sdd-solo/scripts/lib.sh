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

# ── version ─────────────────────────────────────────────────────────────
CLAUDE_PLUGINS_DIR="$HOME/.claude/plugins"
# jver <file.json> <đường.dẫn> — đọc version, fallback grep nếu không có python3
jver() {
  python3 -c 'import json,sys
d=json.load(open(sys.argv[1]))
for k in sys.argv[2].split("."):
    d = d[int(k)] if isinstance(d,list) else d[k]
print(d)' "$1" "$2" 2>/dev/null \
  || grep -oE '"version" *: *"[^"]+"' "$1" 2>/dev/null | head -1 | sed -E 's/.*"([^"]+)"$/\1/'
}
# vcmp a b → -1 nếu a<b, 0 bằng, 1 nếu a>b. Chuỗi lạ ('-', '?') coi như 0.0.0
vcmp() { awk -v a="$1" -v b="$2" 'BEGIN{na=split(a,x,".");nb=split(b,y,".");
  for(i=1;i<=3;i++){va=(i<=na?x[i]+0:0);vb=(i<=nb?y[i]+0:0);
  if(va<vb){print "-1";exit}if(va>vb){print "1";exit}}print "0"}'; }
# mkt_field <tên marketplace> <đường.dẫn> — đọc known_marketplaces.json
mkt_field() { python3 -c 'import json,sys
d=json.load(open(sys.argv[1])).get(sys.argv[2],{})
for k in sys.argv[3].split("."): d = d.get(k,{}) if isinstance(d,dict) else ""
print(d if isinstance(d,str) else "")' "$CLAUDE_PLUGINS_DIR/known_marketplaces.json" "$1" "$2" 2>/dev/null; }
# mkt_of <plugin_root> → tên marketplace suy từ cache/<mkt>/<plugin>/<ver>, rỗng nếu chạy --plugin-dir
mkt_of() { echo "$1" | sed -nE 's#.*/plugins/cache/([^/]+)/[^/]+/[^/]+$#\1#p'; }

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
# installed_ver <tên plugin> → version đang cài trên đĩa (installed_plugins.json)
installed_ver() { python3 -c 'import json,sys,os
p=os.path.expanduser("~/.claude/plugins/installed_plugins.json")
try: d=json.load(open(p))["plugins"]
except Exception: sys.exit(0)
for k,v in d.items():
    if k.split("@")[0]==sys.argv[1] and v: print(v[-1].get("version","")); break' "$1" 2>/dev/null; }
# installed_path <tên plugin> → thư mục bản đang cài
installed_path() { python3 -c 'import json,sys,os
p=os.path.expanduser("~/.claude/plugins/installed_plugins.json")
try: d=json.load(open(p))["plugins"]
except Exception: sys.exit(0)
for k,v in d.items():
    if k.split("@")[0]==sys.argv[1] and v: print(v[-1].get("installPath","")); break' "$1" 2>/dev/null; }
# Bản mà PHIÊN Claude Code đang mở thật sự nạp. Chỉ hook SessionStart biết được
# (nó chạy từ thư mục plugin đã nạp), nên hook ghi lại, ai cần thì đọc.
# CLAUDE_PLUGIN_ROOT KHÔNG phải env var — nó là token Claude Code thay trong
# hooks.json và SKILL.md, nên script gọi từ bash không đọc được.
sess_file() { echo "${XDG_CACHE_HOME:-$HOME/.cache}/sdd-solo/session-${1:-${CLAUDE_CODE_SESSION_ID:-none}}"; }
sess_ver()  { cat "$(sess_file)" 2>/dev/null; }
# is_semver <chuỗi> → 0 nếu đúng dạng X.Y.Z. Glob lỏng kiểu [0-9]*.[0-9]* CHO QUA
# "1.4.0<rác>" nên đừng dùng; đây là kiểm chặt, neo hai đầu.
is_semver() { printf '%s' "$1" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; }
# clean_ver <chuỗi> → chính nó nếu là semver, ngược lại '-'. Dùng trước mọi so sánh
# để quyết định không bao giờ chạy trên giá trị không tin được.
clean_ver() { if is_semver "$1"; then printf '%s' "$1"; else printf '%s' '-'; fi; }
# dump_bad <nhãn> <chuỗi> — in bytes để lần sau còn lần ra, thay vì đoán
dump_bad() { warn "$1 không đúng dạng version — bytes:"; printf '%s' "$2" | od -c | head -3 | sed 's/^/      /'; }

# ── .sdd/config — đường dẫn code/test của dự án ─────────────────────────
# Định dạng cố tình đơn giản (key=giá trị, danh sách cách nhau bằng dấu cách)
# để githook parse được bằng shell thuần, không cần lib.sh này.
CFG_DEFAULT_CODE="src"; CFG_DEFAULT_TEST="tests"; CFG_DEFAULT_UCTEST="tests/use-cases"
cfg_get() { # cfg_get <key> <root> [mặc định]
  V="$(sed -n "s/^$1=//p" "$2/.sdd/config" 2>/dev/null | tail -1 | sed 's/[[:space:]]*$//')"
  [ -n "$V" ] && printf '%s' "$V" || printf '%s' "$3"
}
code_paths()  { cfg_get code_paths  "$1" "$CFG_DEFAULT_CODE"; }
test_paths()  { cfg_get test_paths  "$1" "$CFG_DEFAULT_TEST"; }
uc_test_dir() { cfg_get uc_test_dir "$1" "$CFG_DEFAULT_UCTEST"; }
# paths_re "src app" → ^(src|app)/  — dùng cho grep -E trên đường dẫn git
paths_re() { printf '^(%s)/' "$(printf '%s' "$1" | tr -s ' ' '|' | sed 's/|$//')"; }
# detect_paths <root> → đoán code_paths từ thư mục đang có. KHÔNG nhận specs/
# (của sdd-solo) làm thư mục test.
detect_paths() {
  C=""; for d in src app lib cmd internal pkg apps packages source; do
    [ -d "$1/$d" ] && C="$C $d"; done
  T=""; for d in tests test __tests__ spec; do [ -d "$1/$d" ] && T="$T $d"; done
  printf '%s|%s' "$(printf '%s' "$C" | sed 's/^ *//')" "$(printf '%s' "$T" | sed 's/^ *//')"
}
# has_code_path <root> → 0 nếu có ít nhất một code_path tồn tại
has_code_path() { for d in $(code_paths "$1"); do [ -d "$1/$d" ] && return 0; done; return 1; }
# repo_has_code <root> → 0 nếu repo có file nguồn ngoài các thư mục của quy trình.
# Dùng để phân biệt "config sai" với "repo chưa viết code dòng nào".
repo_has_code() {
  git -C "$1" ls-files 2>/dev/null \
    | grep -vE '^(specs|\.sdd|docs|changes|checklists|prompts|\.githooks)/' \
    | grep -qE '\.(js|ts|tsx|jsx|py|go|rb|java|cs|kt|swift|rs|php|c|cc|cpp|h|hpp|sh|sql|vue|svelte)$'
}

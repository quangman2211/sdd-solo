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

# ── 7.0 (#55): trục core|nghề × br-### — MỘT chỗ tra đường dẫn cho mọi script ───
# Tới 6.6.x có 11 script tự `find`/`grep` thẳng vào `specs/contexts/<ctx>/…`,
# `specs/br.md`, `specs/internal/…`. Đổi cây thì đổi 11 chỗ và hụt im lặng. Từ 7.0
# mọi đường dẫn đi qua các hàm dưới đây; mỗi hàm tra bố cục 7.0 TRƯỚC rồi rơi về
# bố cục 6.x, nên repo chưa migrate vẫn chạy y như cũ (đo bằng snapshot output).
#
# Bố cục 7.0 (plan 2026-09-18, T2 T3):
#   specs/vision.md · glossary.md · rules.md · architecture.md · decisions.md · adr/   ← xuyên suốt
#   specs/core/entities/<Entity>.md · specs/core/br-###/{br.md,evidence.md,use-cases/}  ← lõi
#   specs/<nghề>/{glossary.md,rules.md,adr/,entities/,br-###/…}                          ← mỗi nghề
# Bố cục 6.x: specs/br.md · specs/contexts/<ctx>/{entities.md,use-cases.md,use-cases/} · specs/internal/…

# layout <root> → v7 | v6. Nhận diện bằng sự có mặt của vision.md hoặc thư mục br-###/.
layout() {
  [ -f "$1/specs/vision.md" ] && { printf 'v7'; return; }
  ls -d "$1"/specs/*/br-[0-9]*/ >/dev/null 2>&1 && { printf 'v7'; return; }
  printf 'v6'
}
find_vision() { [ -f "$1/specs/vision.md" ] && printf '%s' "$1/specs/vision.md"; }

# find_uc UC-002 <root> → đường dẫn file UC-002.md (rỗng nếu không có). 7.0 trước, 6.x sau.
find_uc() {
  local id="$1" root="$2" f
  f="$(find "$root/specs" -type f -path "*/br-*/use-cases/${id}-*/${id}.md" -not -path '*/specs/changes/*' 2>/dev/null | head -1)"
  [ -z "$f" ] && f="$(find "$root/specs/contexts" -type f -path "*/use-cases/${id}-*/${id}.md" 2>/dev/null | head -1)"
  printf '%s' "$f"
}
# all_uc_files <root> → mọi file UC-###.md (bỏ .flow/.sequence/.trace), 7.0 lẫn 6.x, sort
all_uc_files() {
  { find "$1/specs" -type f -path '*/br-*/use-cases/UC-*/UC-*.md' -not -path '*/specs/changes/*' 2>/dev/null
    find "$1/specs/contexts" -type f -path '*/use-cases/UC-*/UC-*.md' 2>/dev/null; } \
  | grep -vE '\.(flow|sequence|trace)\.md$' | sort -u
}
# owner_of <path-to-UC.md> → `core` | tên nghề (7.0) | tên context (6.x). Thay ctx_of.
# Đây cũng là thư mục con của uc_test_dir: tests/use-cases/<owner>/UC-###/.
owner_of() {
  case "$1" in
    */specs/contexts/*) printf '%s' "$1" | sed -E 's#.*/specs/contexts/([^/]+)/.*#\1#';;
    *) printf '%s' "$1" | sed -E 's#.*/specs/([^/]+)/.*#\1#';;
  esac
}
ctx_of() { owner_of "$1"; }   # tên cũ — giữ cho bản sao .sdd/scripts/ của repo chưa update
# br_of <path-to-UC.md> → BR-### của lát chứa UC (7.0: từ tên thư mục br-###; 6.x: từ Metadata)
br_of() {
  case "$1" in
    */br-[0-9]*/use-cases/*) printf '%s' "$1" | sed -E 's#.*/br-([0-9]+)/use-cases/.*#BR-\1#';;
    *) grep -oE 'Liên quan tới BR:\*\* *BR-[0-9]+' "$1" 2>/dev/null | grep -oE 'BR-[0-9]+' | head -1;;
  esac
}
# br_dir BR-003 <root> → thư mục lát (7.0), rỗng ở 6.x
br_dir() { ls -d "$2"/specs/*/br-"${1#BR-}"/ 2>/dev/null | head -1 | sed 's#/$##'; }
# br_file BR-003 <root> → file chứa `# BR-003:` — 7.0: <br_dir>/br.md · 6.x: specs/br.md
br_file() { local d; d="$(br_dir "$1" "$2")"; if [ -n "$d" ]; then printf '%s/br.md' "$d"; else printf '%s/specs/br.md' "$2"; fi; }
# br_files <root> → mọi file br.md (7.0) hoặc specs/br.md (6.x)
br_files() {
  if [ "$(layout "$1")" = v7 ]; then ls "$1"/specs/*/br-[0-9]*/br.md 2>/dev/null | sort
  else [ -f "$1/specs/br.md" ] && printf '%s\n' "$1/specs/br.md"; fi
}
# br_text <root> → nội dung mọi BR nối lại (cho phép quét CON trùng số giữa hai BR)
br_text() { for f in $(br_files "$1"); do cat "$f"; printf '\n'; done; }
# br_body BR-001 <root> — nội dung một mục BR (không gồm dòng `# BR-###:`), rỗng nếu không có
br_body() { br_text "$2" | awk -v h="# $1:" 'index($0,h)==1{f=1;next} f&&/^# BR-/{exit} f{print}'; }
# br_title BR-001 <root> → dòng `# BR-###: …`
br_title() { br_text "$2" | grep -E "^# $1:" | head -1; }
# br_ids <root> — mọi BR có trong repo
br_ids() { br_text "$1" | grep -oE '^# BR-[0-9]+' | awk '{print $2}' | awk '!a[$0]++'; }
# owner_of_br BR-003 <root> → core | nghề (7.0); rỗng ở 6.x
owner_of_br() { local d; d="$(br_dir "$1" "$2")"; [ -n "$d" ] && basename "$(dirname "$d")"; }
# evidence_file BR-003 <root> → 7.0: <br_dir>/evidence.md · 6.x: specs/br.evidence.md
evidence_file() { local d; d="$(br_dir "$1" "$2")"; if [ -n "$d" ]; then printf '%s/evidence.md' "$d"; else printf '%s/specs/br.evidence.md' "$2"; fi; }
# br_untouched <root> — 0 nếu chưa có BR thật nào (chỉ còn mẫu + khung trống)
br_untouched() {
  if [ "$(layout "$1")" = v7 ]; then
    ! br_text "$1" | grep -E '^# BR-[0-9]+: *[^ <]' | grep -vqE '^# BR-000'
  else grep -q '<Tên business requirement>' "$1/specs/br.md" 2>/dev/null; fi
}
# uc_table_file UC-### <root> → file có bảng | UC-### | … | Status |: 7.0 = br.md của lát,
# 6.x = use-cases.md của context (#44)
uc_table_file() {
  local f b t; f="$(find_uc "$1" "$2")"
  if [ -z "$f" ]; then
    # 7.0.1 (#51): UC chỉ có dòng trong bảng, chưa từng có file (UC dự kiến rồi bỏ) → tìm bảng có dòng đó
    for t in $(br_files "$2") $(ls "$2"/specs/contexts/*/use-cases.md 2>/dev/null); do
      grep -qE "^\| *$1 *\|" "$t" && { printf '%s' "$t"; return 0; }
    done
    return 0
  fi
  case "$f" in
    */specs/contexts/*) printf '%s/specs/contexts/%s/use-cases.md' "$2" "$(owner_of "$f")";;
    *) b="$(br_of "$f")"; [ -n "$b" ] && br_file "$b" "$2";;
  esac
}

# rules_files <root> → specs/rules.md + specs/<nghề>/rules.md (có file nào in file đó)
rules_files() {
  { [ -f "$1/specs/rules.md" ] && printf '%s\n' "$1/specs/rules.md"
    ls "$1"/specs/*/rules.md 2>/dev/null | grep -vE '/specs/(contexts|internal|changes)/'; } | awk 'NF&&!a[$0]++'
}
# rule_file RULE-### <root> → file có heading `## RULE-###` (rỗng nếu không có)
rule_file() { for f in $(rules_files "$2"); do grep -qE "^## $1\b" "$f" && { printf '%s' "$f"; return; }; done; }
# rules_text <root> → mọi rules.md nối lại
rules_text() { for f in $(rules_files "$1"); do cat "$f"; printf '\n'; done; }
# adr_dirs <root> → thư mục ADR đang có: specs/adr · specs/<nghề>/adr · specs/internal/adr · docs/adr
adr_dirs() {
  { [ -d "$1/specs/adr" ] && printf '%s\n' "$1/specs/adr"
    ls -d "$1"/specs/*/adr 2>/dev/null | grep -vE '/specs/(contexts|changes)/'
    [ -d "$1/docs/adr" ] && printf '%s\n' "$1/docs/adr"; } | awk 'NF&&!a[$0]++'
}
# adr_file ADR-### <root> → file ADR (rỗng nếu không có); bỏ khuôn `_*`
adr_file() { for d in $(adr_dirs "$2"); do f="$(ls "$d/$1"* 2>/dev/null | grep -v '/_' | head -1)"; [ -n "$f" ] && { printf '%s' "$f"; return; }; done; }
# arch_file · decisions_file · glossary_file <root> → đường 7.0 nếu có, không thì đường 6.x
# (trả đường dù file chưa tồn tại, để thông điệp "thiếu <đường>" chỉ đúng chỗ)
arch_file()      { if [ -f "$1/specs/architecture.md" ] || [ "$(layout "$1")" = v7 ]; then printf '%s/specs/architecture.md' "$1"; else printf '%s/specs/internal/architecture.md' "$1"; fi; }
decisions_file() { if [ -f "$1/specs/decisions.md" ] || [ "$(layout "$1")" = v7 ]; then printf '%s/specs/decisions.md' "$1"; else printf '%s/specs/internal/decisions.md' "$1"; fi; }
glossary_file()  { printf '%s/specs/glossary.md' "$1"; }
# nghe_glossary · nghe_rules <owner> <root> → file riêng của nghề (rỗng nếu không có / là core)
nghe_glossary() { [ "$1" != core ] && [ -f "$2/specs/$1/glossary.md" ] && printf '%s/specs/%s/glossary.md' "$2" "$1"; }
nghe_rules()    { [ "$1" != core ] && [ -f "$2/specs/$1/rules.md" ] && printf '%s/specs/%s/rules.md' "$2" "$1"; }
# nghe_list <root> → tên các nghề: .sdd/config nghe_paths=, không có thì dò thư mục dưới specs/
nghe_list() {
  local v; v="$(cfg_get nghe_paths "$1" "")"
  [ -n "$v" ] && { printf '%s' "$v"; return; }
  for d in "$1"/specs/*/; do
    d="$(basename "$d")"
    case "$d" in core|adr|changes|contexts|internal|_*) continue;; esac
    { ls -d "$1/specs/$d"/br-[0-9]*/ >/dev/null 2>&1 || [ -f "$1/specs/$d/glossary.md" ] || [ -d "$1/specs/$d/entities" ]; } && printf '%s ' "$d"
  done | sed 's/ *$//'
}
# entity_files <path-to-UC.md> <root> → file entity UC này được phép dùng:
#   7.0: specs/core/entities/*.md + specs/<owner>/entities/*.md (bỏ README, _*) · 6.x: entities.md của context
entity_files() {
  local o; o="$(owner_of "$1")"
  case "$1" in
    */specs/contexts/*) [ -f "$2/specs/contexts/$o/entities.md" ] && printf '%s\n' "$2/specs/contexts/$o/entities.md";;
    *) { ls "$2"/specs/core/entities/*.md 2>/dev/null
         [ "$o" != core ] && ls "$2/specs/$o/entities/"*.md 2>/dev/null; } | grep -vE '/(README|_[^/]*)\.md$';;
  esac
}
# entity_cited <path-to-UC.md> <root> → trong entity_files, file nào tên entity xuất hiện trong
# phần hiệu lực của UC (7.0); 6.x → chính entities.md (một file chứa mọi entity của context)
entity_cited() {
  local live; live="$(awk '/^## (Adversarial pass|Đọc lại|History)/{t=1;next} /^## /{t=0} !t' "$1")"
  for f in $(entity_files "$1" "$2"); do
    case "$f" in */specs/contexts/*) printf '%s\n' "$f"; continue;; esac
    n="$(basename "$f" .md)"
    printf '%s' "$live" | grep -qE "(^|[^A-Za-z0-9_])$n([^A-Za-z0-9_]|$)" && printf '%s\n' "$f"
  done
}
# entity_names <path-to-UC.md> <root> → tên entity có trong entity_files (7.0: tên file; 6.x: `class X` / `## X`)
entity_names() {
  for f in $(entity_files "$1" "$2"); do
    case "$f" in
      */specs/contexts/*) grep -oE '^[[:space:]]*class [A-Za-z][A-Za-z0-9_]*|^## [A-Z][A-Za-z0-9_]*' "$f" | awk '{print $NF}' | grep -vxE 'Domain|History|Entity[AB]?';;
      *) basename "$f" .md;;
    esac
  done | sort -u
}
# glossary_files <owner> <root> → specs/glossary.md + specs/<nghề>/glossary.md (file nào có)
glossary_files() {
  { [ -f "$2/specs/glossary.md" ] && printf '%s\n' "$2/specs/glossary.md"
    nghe_glossary "$1" "$2"; } | awk 'NF'
}
# id_exists <ID> <root> → 0 nếu ID có thật. Githook commit-msg chép logic (chạy bash trần) — cùng danh sách đường dẫn.
id_exists() {
  case "$1" in
    UC-*)   [ -n "$(find_uc "$1" "$2")" ];;
    CHG-*)  ls -d "$2/specs/changes/$1-"* >/dev/null 2>&1 || ls -d "$2/changes/$1-"* >/dev/null 2>&1;;
    RULE-*) [ -n "$(rule_file "$1" "$2")" ];;
    BR-*)   br_text "$2" | grep -qE "^#{1,2} $1\b";;
    ADR-*)  [ -n "$(adr_file "$1" "$2")" ];;
    # CON-### nằm trong ## Constraints của một BR: `- **CON-001 Technical:** …` (4.1.0)
    CON-*)  br_text "$2" | grep -qE "^-? *\*\*$1\b";;
    *) return 1;;
  esac
}

# slug_of <path> → phần sau UC-###-
slug_of() { basename "$(dirname "$1")" | sed -E 's/^UC-[0-9]+-//'; }
# ── bảng UC (#44) ────────────────────────────────────────────────────────
# Hai chỗ nói trạng thái của một UC: dòng **Status:** trong file UC và cột Status
# của bảng `| UC-### | Tên | Actor | BR-### | Status |`. 6.x bảng ở
# specs/contexts/<ctx>/use-cases.md; 7.0 ở `## Related Use Cases` của br.md lát.
# uc_table_file (trên) trả đúng file cho cả hai — pass.sh/status.sh chỉ đi qua đó (#51).
# uc_table_status UC-### <root> → ô Status của dòng UC trong bảng (rỗng nếu không có dòng/bảng)
uc_table_status() {
  _t="$(uc_table_file "$1" "$2")"; [ -n "$_t" ] && [ -f "$_t" ] || return 0
  awk -F'|' -v id="$1" 'NF>=3 && $2 ~ ("^[ ]*" id "[ ]*$") { s=$(NF-1); gsub(/^[ ]+|[ ]+$/,"",s); print s; exit }' "$_t"
}
# uc_table_set UC-### <status> <root> → ghi ô Status; 0 nếu có dòng để ghi, 1 nếu không
uc_table_set() {
  _t="$(uc_table_file "$1" "$3")"; [ -n "$_t" ] && [ -f "$_t" ] || return 1
  [ -n "$(uc_table_status "$1" "$3")" ] || return 1
  awk -F'|' -v OFS='|' -v id="$1" -v st="$2" '
    NF>=3 && $2 ~ ("^[ ]*" id "[ ]*$") { $(NF-1) = " " st " " } { print }' "$_t" > "$_t.tmp" && mv "$_t.tmp" "$_t"
}

# find_chg CHG-001 <root> → thư mục change (rỗng nếu không có). 2.0.0 dời
# changes/ → specs/changes/; nhận cả hai cho repo chưa migrate.
find_chg() {
  local d
  d="$(ls -d "$2/specs/changes/$1-"* 2>/dev/null | head -1)"
  [ -z "$d" ] && d="$(ls -d "$2/changes/$1-"* 2>/dev/null | head -1)"
  printf '%s' "$d"
}

# ── 7.5 — mermaid qua parser, không qua grep (P-32) ───────────────────────
# mmd <--lint|--edges|--nodes|--states|--kinds> <file…> — in đầu ra của mermaid.py.
# mmd_ok → 0 khi chạy được (có python3 + mermaid.py cạnh lib.sh). Không chạy được thì MỌI chỗ gọi
# phải rơi về đường grep của bản trước: một phép kiểm không chạy được không bao giờ thành một phép kiểm đỏ.
SDD_LIBDIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
mmd_ok() { command -v python3 >/dev/null 2>&1 && [ -f "$SDD_LIBDIR/mermaid.py" ]; }
mmd() { local m="$1"; shift; mmd_ok || return 0; python3 "$SDD_LIBDIR/mermaid.py" "$m" "$@"; }
# mmd_lint <file…> — in các dòng lỗi qua bad(), trả 1 nếu có. Bỏ file không tồn tại.
mmd_lint() {
  local f ff="" out
  for f in "$@"; do [ -f "$f" ] && ff="$ff $f"; done
  [ -n "$ff" ] || return 0
  mmd_ok || return 0
  out="$(mmd --lint $ff)" || true
  [ -n "$out" ] || return 0
  printf '%s\n' "$out" | while IFS= read -r l; do
    printf '  \033[31m✗\033[0m %s\n' "$(printf '%s' "$l" | sed "s#^$ROOT/##" | cut -c1-200)"
  done
  return 1
}

sha() { if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | cut -d' ' -f1; else sha256sum "$1" | cut -d' ' -f1; fi; }
today() { date +%Y-%m-%d; }

# 6.0.0 (#38): cửa verify dùng chung cho cổng DoR (file UC) và cổng Phase 5 (proposal.md).
# rr_lines <file> → các dòng F# trong ## Đọc lại; rr_count (stdin) → bao nhiêu dòng có
# CẢ [neo: ...] LẪN đầu ra khác ___. Đó là toàn bộ chốt chống khai gian: bịa một dòng
# như vậy tốn đúng bằng đọc thật.
rr_lines() { sed -n '/^## Đọc lại/,/^## /p' "$1" 2>/dev/null | grep -E '^- F[0-9]+ '; }
rr_count() {
  awk '
    /\[neo:[^]]*[^] [:space:]]\]/ && /→/ {
      i = index($0, "→"); o = substr($0, i + 3)
      # Bóc nhãn trước rồi mới hỏi còn gì không: nếu giữ lại thì chuỗi
      # mũi-tên + dau ra + ___ vẫn khác rỗng nhờ chính hai chữ nhãn, nên một
      # dòng chưa quyết gì cũng mở được cửa. Đây là ca khai gian rẻ nhất.
      # KHÔNG đặt dấu nháy đơn trong khối awk này — nó đóng chuỗi của shell.
      sub(/^[[:space:]]*đầu ra[[:space:]]*:/, "", o)
      gsub(/[_[:space:]]/, "", o)
      if (o != "") n++
    } END { print n + 0 }'
}
# 7.4 (P-20): rr_undecided (stdin) → bao nhiêu dòng F# có đầu ra là "→ Chưa quyết". Vẫn là đầu ra hợp lệ của cổng
# (7.0.1 #53: verify không hỏi, cổng mở với câu chưa trả lời là nợ chủ dự án tự nhận) — nhưng cổng phải NÓI RA con số,
# không thì "11 phát hiện có neo + đầu ra" ở trạng thái chưa quyết gì và ở trạng thái đã quyết hết xanh y hệt nhau
# (CHG-002 runxops: phải đổi tay 11 đuôi thành "Đã quyết" người đọc mới biết).
rr_undecided() { grep -c '→ *Chưa quyết' 2>/dev/null || true; }
# rr_tail (stdin, một dòng) → ĐUÔI SỐNG của dòng F#: chữ sau mũi tên CUỐI, sau khi bỏ mọi `…` và (…) (lồng nhau).
# Thân F# hay chép nguyên lỗi cổng hay đuôi cũ vào nháy mã / ngoặc — "`✗ đọc lại khai → E4 …`" (UC-027 F74 runxops),
# "(→ Chưa quyết cũ …)" (P-37) — mũi tên trong đó không phải đầu ra của dòng. Không có mũi tên → in rỗng.
rr_tail() {
  awk '{
    t = $0
    gsub(/`[^`]*`/, "", t)
    while (match(t, /\([^()]*\)/)) t = substr(t, 1, RSTART - 1) substr(t, RSTART + RLENGTH)
    n = 0; while ((i = index(t, "→")) > 0) { t = substr(t, i + 3); n++ }
    if (n) print t
  }'
}

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
# tool_paths: code THẬT nhưng KHÔNG thuộc UC nào và không thể thuộc — script đo
# dữ liệu, script chuyển đổi một lần, tiện ích của repo. Mặc định RỖNG: repo chưa
# khai thì hành xử y như trước (#31). Miễn ID ở githook, không tính vào mẫu số
# trace-ratio. Vì sao cần: luật 5b BẮT "số mô tả dữ liệu thật phải kèm lệnh đo ra
# nó" — tức plugin đang YÊU CẦU viết loại code này — rồi hook không cho commit nó
# nếu không gắn một ID. Hai luật đều đúng, đặt cạnh nhau thì hở.
CFG_DEFAULT_TOOL=""
cfg_get() { # cfg_get <key> <root> [mặc định]
  V="$(sed -n "s/^$1=//p" "$2/.sdd/config" 2>/dev/null | tail -1 | sed 's/[[:space:]]*$//')"
  [ -n "$V" ] && printf '%s' "$V" || printf '%s' "$3"
}
code_paths()  { cfg_get code_paths  "$1" "$CFG_DEFAULT_CODE"; }
test_paths()  { cfg_get test_paths  "$1" "$CFG_DEFAULT_TEST"; }
uc_test_dir() { cfg_get uc_test_dir "$1" "$CFG_DEFAULT_UCTEST"; }
tool_paths()  { cfg_get tool_paths  "$1" "$CFG_DEFAULT_TOOL"; }
# brief_path: file nguồn mà BR được chuyển ra từ đó (#34). Ghi vào config để nó
# nằm trong THỨ TỰ ĐỌC BẮT BUỘC — không có dòng này thì brief thành file chỉ-ghi
# ngay sau intake: `gate-check` đo trong specs/, `verify` đọc trong specs/, ba
# vai adversarial cố ý mù với nó. Ba lớp kiểm, không lớp nào nhìn ra ngoài specs/.
brief_path()  { cfg_get brief_path  "$1" ""; }
# brief_sha <root> → sha ngắn của brief hiện tại, rỗng nếu không có file
brief_sha() { _b="$(brief_path "$1")"; [ -n "$_b" ] && [ -f "$1/$_b" ] || return 1
              sha "$1/$_b" 2>/dev/null | cut -c1-12; }
# brief_rec_sha <root> → sha mà br.md KHAI ở dòng '**Nguồn brief:**', rỗng nếu chưa khai.
# Ở chung một chỗ vì hai nơi dùng nó (br-check, session-start) phải rút cùng một
# con số; bản đầu của session-start viết '[^\n]*' — trong ERE của grep đó là
# "mọi ký tự trừ \ và n", nên đường dẫn nào có chữ 'n' là hụt, và hụt thì im.
# 7.0: nhiều br.md → lấy dòng có `nạp YYYY-MM-DD` MUỘN NHẤT (BR-001 cũ của runxops khai sha cũ, BR-003 khai sha
# mới; lấy dòng đầu theo thứ tự file thì đỏ oan "brief đã đổi"). Không có ngày thì dòng đầu như cũ.
brief_rec_sha() { br_text "$1" | grep -oE '\*\*Nguồn brief:\*\*.*sha256 [0-9a-f]{12}([^0-9a-f].*)?$' \
                  | awk '{d=""; if (match($0,/nạp [0-9]{4}-[0-9]{2}-[0-9]{2}/)) d=substr($0,RSTART+4,10); print d "\t" $0}' \
                  | sort | tail -1 | grep -oE 'sha256 [0-9a-f]{12}' | cut -c8-; }
# ── nội dung THẬT hay còn là template ───────────────────────────────────
# Một bản DUY NHẤT. Tới 4.0.0 hàm này được chép nguyên vào br-check.sh và
# change-check.sh — hai bản y hệt nhau, nên một lượt vá chỉ trúng một nửa, và
# phiên báo lỗi còn tưởng nó nằm ở lib.sh vì "chắc thứ dùng hai nơi thì ở chung".
nonempty() { printf '%s' "$1" | grep -qvE '^[[:space:]]*$'; }

# strip_markup — bỏ những thứ TRÔNG như placeholder nhưng là cú pháp hợp lệ,
# trước khi đi tìm placeholder thật. Liệt kê ĐÍCH DANH, không nới regex thành
# "bỏ mọi <...> ngắn": nới tay ở đây là đổi đỏ oan lấy hụt đỏ thật.
#   ① khối <!-- ... --> (kể cả trải nhiều dòng)
#   ② thẻ HTML có thật trong template: <b> <br/> ...
#   ③ autolink markdown <https://...>
strip_markup() {
  awk '
    BEGIN { incmt = 0 }
    {
      line = $0; out = ""
      while (length(line) > 0) {
        if (incmt) {
          k = index(line, "-->")
          if (k == 0) { line = ""; break }
          line = substr(line, k + 3); incmt = 0
        } else {
          k = index(line, "<!--")
          if (k == 0) { out = out line; line = ""; break }
          out = out substr(line, 1, k - 1)
          line = substr(line, k + 4); incmt = 1
        }
      }
      print out
    }' \
  | sed -E 's#</?(br|b|i|u|em|strong|code|sub|sup|kbd|small)[[:space:]]*/?>##g; s#<[a-z]+://[^ >]*>##g'
}

# filled <text> — có nội dung THẬT: không rỗng, không còn placeholder, không
# phải toàn dòng "..." của template.
filled() {
  nonempty "$1" || return 1
  # Placeholder có thể TRẢI NHIỀU DÒNG: '<Vì sao ...' mở ở dòng này, '...>' đóng
  # ở dòng sau. Regex một dòng '<[^>]+>' không khớp cái nào, nên mục rỗng đi qua
  # như có nội dung. Phải bắt cả nửa mở lẫn nửa đóng.
  #
  # Nửa ĐÓNG phải có ký tự THẬT ngay trước '>'. Bản tới 4.0.0 dùng '>[[:space:]]*$'
  # nên một dòng chỉ có '>' — tức DÒNG TRỐNG BÊN TRONG BLOCKQUOTE, cú pháp
  # markdown hợp lệ và dùng thường xuyên — bị tính là nửa đóng của placeholder.
  # Hệ quả đo được ở runxops: '## Background' dài 427 dòng, không một '<...>'
  # nào, vẫn đỏ. Và nó gác đúng mục chứa toàn bộ SỐ ĐO của tầng BR — phép kiểm
  # bảo vệ chỗ nhiều số nhất lại là phép kiểm bị vô hiệu hoá đầu tiên.
  # Loại '-' và '=' trước '>' nữa: đó là mũi tên mermaid ('A -->'), không phải
  # nửa đóng của placeholder.
  printf '%s\n' "$1" | strip_markup \
    | grep -qE '<[^>]+>|^[[:space:]]*<|[^[:space:]>=-]>[[:space:]]*$' && return 1
  printf '%s' "$1" | grep -vE '^[[:space:]]*$' \
    | grep -qvE '^[[:space:]]*([-*][[:space:]]*)?\.\.\.[[:space:]]*$' || return 1
  return 0
}

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
# tool_paths KHÔNG tính là "code sản phẩm" ở đây (#33). Không loại nó ra thì
# `trace-ratio` in "repo có file nguồn nhưng không commit nào đụng src tests →
# sửa code_paths" trên một repo vừa khai tool_paths ĐÚNG như 3.19.0 bảo. Đỏ oan,
# và tệ hơn im lặng một bậc vì nó hướng người ta gỡ tool_paths hoặc nhét scripts
# vào code_paths — quay ngược đúng cái bẫy #31 vừa gỡ.
repo_has_code() {
  _t="$(tool_paths "$1")"
  _re='^(specs|\.sdd|docs|changes|checklists|prompts|\.githooks)/'
  [ -n "$_t" ] && _re="$_re|^($(printf '%s' "$_t" | tr -s ' ' '|' | sed 's/^|//; s/|$//'))/"
  git -C "$1" ls-files 2>/dev/null \
    | grep -vE "$_re" \
    | grep -qE '\.(js|ts|tsx|jsx|py|go|rb|java|cs|kt|swift|rs|php|c|cc|cpp|h|hpp|sh|sql|vue|svelte)$'
}
# plugin_script <tên> — tìm script CHỈ có ở plugin (scaffold.sh, session-start.sh).
# Bản sao ở .sdd/scripts/ cố ý không chứa chúng, nên script chạy từ bản sao phải
# tìm sang plugin thật thay vì suy đường dẫn cạnh mình. In rỗng nếu không thấy.
# Xem #10.
plugin_script() {
  # 1) cạnh mình (đang chạy từ chính plugin)
  [ -x "$2/scripts/$1" ] && { printf '%s' "$2/scripts/$1"; return; }
  # 2) bản ĐANG CÀI theo installed_plugins.json — không vơ bừa bản cũ trong cache
  IP="$(installed_path sdd-solo)"
  [ -n "$IP" ] && [ -x "$IP/scripts/$1" ] && { printf '%s' "$IP/scripts/$1"; return; }
  # 3) cùng lắm mới quét cache, lấy version cao nhất
  find "$HOME/.claude/plugins/cache" -type f -name "$1" -path '*sdd-solo*' 2>/dev/null \
    | sort -t/ -k7 -V | tail -1
}

# ── 7.2 · đội agent: vai · dấu vai theo worktree · khoá nguyên tử · KETQUA ────────────────────────
# .sdd/roles: khoá=giá trị như .sdd/config (githook bash trần đọc được), danh sách cách nhau bằng dấu cách.
#   vai=A B R D T · <V>.ten · <V>.ghi · <V>.cam · <V>.nhanh · <V>.commit=co|khong · <V>.kiem
#   vai_bat_buoc=khong|nhanh-vai|moi — khong (mặc định): hook chỉ nhắc, không chặn.
# Không có file → mọi hàm trả rỗng, hành vi y hệt 7.1. Vùng ghi nhận @code_paths @test_paths @uc_test_dir
# @tool_paths nở từ .sdd/config, để đường dẫn không chép hai nơi.
roles_file() { [ -f "$1/.sdd/roles" ] && printf '%s' "$1/.sdd/roles"; }
role_get() { # role_get <khoá> <root> [mặc định]
  local v; v="$(sed -n "s/^$1=//p" "$2/.sdd/roles" 2>/dev/null | tail -1 | sed 's/[[:space:]]*$//')"
  if [ -n "$v" ]; then printf '%s' "$v"; else printf '%s' "$3"; fi
}
role_list()     { role_get vai "$1" ""; }
role_name()     { role_get "$1.ten" "$2" "$1"; }
role_branch()   { role_get "$1.nhanh" "$2" ""; }
role_checks()   { role_get "$1.kiem" "$2" ""; }
role_required() { role_get vai_bat_buoc "$1" khong; }
role_may_commit() { [ "$(role_get "$1.commit" "$2" co)" != khong ]; }
role_known()    { local v; for v in $(role_list "$2"); do [ "$v" = "$1" ] && return 0; done; return 1; }
# Mẫu như `specs/**` đi qua `for x in $1` KHÔNG quote → shell nở thành tên file thật (đo: `specs/**` thành 11 đường).
# Tắt glob trong lúc duyệt (set -f) rồi trả lại như cũ.
_noglob_on()  { case $- in *f*) _NG=1;; *) _NG=0; set -f;; esac; }
_noglob_off() { [ "${_NG:-1}" = 0 ] && set +f; }
_role_expand() { # nở @code_paths … từ .sdd/config
  local x out=""
  _noglob_on
  for x in $1; do
    case "$x" in
      @code_paths)  out="$out $(code_paths "$2")";;
      @test_paths)  out="$out $(test_paths "$2")";;
      @uc_test_dir) out="$out $(uc_test_dir "$2")";;
      @tool_paths)  out="$out $(tool_paths "$2")";;
      *) out="$out $x";;
    esac
  done
  _noglob_off
  printf '%s' "$out" | sed 's/^ *//'
}
role_paths() { _role_expand "$(role_get "$1.ghi" "$2" "")" "$2"; }
role_deny()  { _role_expand "$(role_get "$1.cam" "$2" "")" "$2"; }
# glob_re <mẫu> → ERE neo hai đầu. Chỉ hai ký tự: ** = mọi độ sâu · * = trong một đoạn. Không có * thì khớp
# đúng đường dẫn hoặc mọi thứ dưới thư mục đó. Không dùng case, để gọi được trong $( ) (bash 3.2).
glob_re() {
  local p="${1%/}" r
  r="$(printf '%s' "$p" | sed -e 's/\./\\./g' -e 's/+/\\+/g' -e 's/?/\\?/g' -e 's/(/\\(/g' -e 's/)/\\)/g' -e 's/{/\\{/g' -e 's/}/\\}/g' -e 's/|/\\|/g' -e 's/\$/\\$/g' \
        -e 's#\*\*/#__DSS__#g' -e 's#\*\*#__DS__#g' -e 's#\*#[^/]*#g' -e 's#__DSS__#(.*/)?#g' -e 's#__DS__#.*#g')"
  if printf '%s' "$p" | grep -q '\*'; then printf '^%s$' "$r"; else printf '^%s(/.*)?$' "$r"; fi
}
# path_in <đường dẫn> "<mẫu …>" → 0 nếu khớp một mẫu
path_in() { local m r=1; _noglob_on; for m in $2; do printf '%s' "$1" | grep -qE "$(glob_re "$m")" && { r=0; break; }; done; _noglob_off; return $r; }
# role_allows <vai> <đường dẫn> <root> → 0 nếu vai được ghi. Cấm thắng được ghi.
role_allows() { path_in "$2" "$(role_deny "$1" "$3")" && return 1; path_in "$2" "$(role_paths "$1" "$3")"; }
# role_of_path <đường dẫn> <root> → các vai được ghi chỗ đó (để thông điệp chặn nói "chỗ này của T")
role_of_path() { local v out=""; for v in $(role_list "$2"); do role_allows "$v" "$1" "$2" && out="$out $v"; done; printf '%s' "$out" | sed 's/^ *//'; }
# role_marker_file <root> → file dấu vai RIÊNG worktree này: .git/sdd-role ở checkout chính,
# .git/worktrees/<tên>/sdd-role ở worktree phụ. Không vào git, không theo nhánh (đo trên runxops, 7.2).
role_marker_file() { local m; m="$(cd "$1" && git rev-parse --git-path sdd-role 2>/dev/null)"; [ -n "$m" ] || return 1; case "$m" in /*) ;; *) m="$1/$m";; esac; printf '%s' "$m"; }
# role_current <root> → vai của phiên: SDD_ROLE → dấu worktree → mẫu nhánh <V>.nhanh; rỗng nếu không suy được
role_current() {
  local v m br p
  [ -n "$SDD_ROLE" ] && { printf '%s' "$SDD_ROLE"; return; }
  m="$(role_marker_file "$1")"; [ -n "$m" ] && [ -f "$m" ] && { head -1 "$m" | tr -d '[:space:]'; return; }
  br="$(git -C "$1" symbolic-ref --quiet --short HEAD 2>/dev/null)"
  for v in $(role_list "$1"); do
    p="$(role_branch "$v" "$1")"; [ -n "$p" ] || continue
    printf '%s' "$br" | grep -qE "$(glob_re "$p")" && { printf '%s' "$v"; return; }
  done
}
# git_common <root> → thư mục git CHUNG mọi worktree (.git của checkout chính). Khoá và KETQUA đặt ở đây:
# .sdd/ nằm trong cây làm việc nên mỗi worktree một bản — khoá ở đó vô hình với đúng đối tượng nó phải chặn.
git_common() { local d; d="$(cd "$1" && git rev-parse --git-common-dir 2>/dev/null)"; case "$d" in /*) ;; *) d="$1/$d";; esac; printf '%s' "$d"; }
lock_dir()   { printf '%s/sdd-lock' "$(git_common "$1")"; }
ketqua_dir() { printf '%s/sdd-ketqua' "$(git_common "$1")"; }
# lock_take <tên> <root> — mkdir nguyên tử (POSIX). Chờ tới 10 s; khoá quá 2 phút coi là mồ côi và gỡ.
lock_take() {
  local d i=0; mkdir -p "$(lock_dir "$2")"; d="$(lock_dir "$2")/$1"
  while ! mkdir "$d" 2>/dev/null; do
    i=$((i+1))
    if [ "$i" -gt 100 ]; then
      [ -n "$(find "$d" -maxdepth 0 -mmin +2 2>/dev/null)" ] && { rm -rf "$d"; i=0; continue; }
      return 1
    fi
    sleep 0.1
  done
  printf '%s\n' "$$" > "$d/pid"
}
lock_drop() { rm -rf "$(lock_dir "$2")/$1"; }
# plugin_file <đường dẫn tương đối trong plugin> — như plugin_script nhưng cho khuôn (templates/skel/…)
plugin_file() {
  local p="$1" root="$2" ip
  [ -f "$root/$p" ] && { printf '%s' "$root/$p"; return; }
  ip="$(installed_path sdd-solo)"; [ -n "$ip" ] && [ -f "$ip/$p" ] && { printf '%s' "$ip/$p"; return; }
  find "$HOME/.claude/plugins/cache" -type f -path "*sdd-solo*/$p" 2>/dev/null | sort -t/ -k7 -V | tail -1
}
# hoi_dap_file <root> → sổ hỏi đáp: 7.0 notes/hoi-dap/hoi-dap.md · 6.x specs/internal/hoi-dap.md (đường dù chưa có file)
hoi_dap_file() {
  if [ -f "$1/notes/hoi-dap/hoi-dap.md" ] || [ ! -f "$1/specs/internal/hoi-dap.md" ]; then printf '%s/notes/hoi-dap/hoi-dap.md' "$1"
  else printf '%s/specs/internal/hoi-dap.md' "$1"; fi
}

# ── 7.4 — vân tay hành vi của UC ở một revision (#49; dùng chung gate-check §9 · close-check P-10) ──────────
# Vùng: main alt exc post ac (mục của UC) · flow (file .flow.md) · rules (phát biểu RULE được trích, bỏ Áp dụng cho)
# · entities (khối mermaid của entity UC nhắc). Đường dẫn tra THEO REVISION: UC có thể đã dời thư mục (git mv,
# migrate 6.x → 7.0) giữa hai mốc; so nội dung, không so đường dẫn (P-31).
fp_tree()   { git -C "$1" ls-tree -r --name-only "$2" 2>/dev/null; }
fp_layout() { fp_tree "$1" "$2" | grep -qE '^specs/vision\.md$|^specs/[^/]+/br-[0-9]+/' && printf v7 || printf v6; }
fp_uc()     { fp_tree "$1" "$3" | grep -E "/use-cases/$2-[^/]*/$2$4\.md\$" | head -1; }   # <root> <id> <rev> <đuôi: "" | .flow>
fp_rules()  { fp_tree "$1" "$2" | grep -E '^specs/rules\.md$|^specs/[^/]+/rules\.md$' | grep -vE '^specs/(contexts|internal|changes)/'; }
fp_entities() { # <root> <id> <rev> <efs ở HEAD> — 6.x: entities.md của context; 7.0: cùng tên file với entity_cited ở HEAD
  local u o e n
  u="$(fp_uc "$1" "$2" "$3" "")"; [ -n "$u" ] || return 0
  if [ "$(fp_layout "$1" "$3")" = v6 ]; then printf '%s\n' "$u" | sed -E 's#(specs/contexts/[^/]+)/.*#\1/entities.md#'
  else o="$(printf '%s' "$u" | sed -E 's#^specs/([^/]+)/.*#\1#')"
       for e in $4; do n="$(basename "$e")"; fp_tree "$1" "$3" | grep -E "^specs/(core|$o)/entities/$n\$"; done; fi
}
spec_fp() { # spec_fp <root> <id> <rev> <vùng> [efs]
  local root="$1" id="$2" rev="$3" z="$4" efs="$5" uc h f rl r p
  uc="$(git -C "$root" show "$rev:$(fp_uc "$root" "$id" "$rev" "")" 2>/dev/null)"
  case "$z" in
    main|alt|exc|post|ac)
      case "$z" in main) h="## Main Flow";; alt) h="## Alternative Flows";; exc) h="## Exceptions";; post) h="## Postconditions";; ac) h="## Acceptance Criteria";; esac
      printf '%s\n' "$uc" | awk -v h="$h" 'index($0,h)==1{f=1;next} f&&/^## /{f=0} f';;
    flow) f="$(fp_uc "$root" "$id" "$rev" ".flow")"; [ -n "$f" ] && git -C "$root" show "$rev:$f" 2>/dev/null;;
    rules)
      rl="$(for p in $(fp_rules "$root" "$rev"); do git -C "$root" show "$rev:$p" 2>/dev/null; printf '\n'; done)"
      for r in $(printf '%s' "$uc" | grep -oE 'RULE-[0-9]+' | sort -u); do
        printf '%s\n' "$rl" | awk -v h="## $r" 'index($0,h)==1{f=1;print;next} f&&/^## /{f=0} f' | grep -v 'Áp dụng cho'
      done;;
    entities) for p in $(fp_entities "$root" "$id" "$rev" "$efs"); do git -C "$root" show "$rev:$p" 2>/dev/null | sed -n '/^```mermaid/,/^```/p'; done;;
  esac
}
# fp_changed <root> <id> <rev1> <rev2> [efs] → in các vùng khác nhau (cách nhau dấu cách, có dấu cách đầu);
# đặt FP_SKIP=entities khi hai mốc khác bố cục (6.x một file/context · 7.0 một file/entity — nối lại không so được).
fp_changed() {
  local z out=""; FP_SKIP=""
  for z in main alt exc post ac flow rules entities; do
    if [ "$z" = entities ] && [ "$(fp_layout "$1" "$3")" != "$(fp_layout "$1" "$4")" ]; then FP_SKIP=entities; continue; fi
    [ "$(spec_fp "$1" "$2" "$3" "$z" "$5")" = "$(spec_fp "$1" "$2" "$4" "$z" "$5")" ] || out="$out $z"
  done
  printf '%s' "$out"
}

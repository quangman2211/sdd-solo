#!/usr/bin/env bash
# version-check.sh [--remote] [--brief]
# So chuỗi version và chỉ đúng lệnh cần chạy cho từng chỗ lệch:
#   GitHub ─①─▶ marketplace đã tải ─②─▶ bản đã cài ─③─▶ .sdd/ dự án
#                                            └────④─▶ phiên Claude Code đang mở
# Khe ④ không lệnh nào sửa được — chỉ mở session mới.
# --remote: hỏi thêm GitHub (tối đa 3s, nhớ 24h). Không có cờ thì thuần cục bộ.
# --brief : chỉ in dòng lệch. Dùng cho hook SessionStart.
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
PLUGIN="${SDD_PLUGIN:-$(dirname "$HERE")}"; ROOT="$(project_root)"
CACHE_D="${XDG_CACHE_HOME:-$HOME/.cache}/sdd-solo"; CACHE="$CACHE_D/remote-check"
TTL=86400   # 24h

REMOTE=0; BRIEF=0
for a in "$@"; do
  [ "$a" = "--remote" ] && REMOTE=1
  [ "$a" = "--brief" ] && BRIEF=1
done

PNAME="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["name"])' "$PLUGIN/.claude-plugin/plugin.json" 2>/dev/null || echo sdd-solo)"
MKTNAME="$(mkt_of "$PLUGIN")"
DEV=0; [ -z "$MKTNAME" ] && { MKTNAME="$PNAME"; DEV=1; }   # chạy bằng --plugin-dir

# ── năm mắt xích ────────────────────────────────────────────────────────
PROJ="$(cat "$ROOT/.sdd/version" 2>/dev/null || echo '-')"
INST="$(installed_ver "$PNAME")"
[ -z "$INST" ] && INST="$(jver "$PLUGIN/.claude-plugin/plugin.json" version)"
[ -z "$INST" ] && INST='-'
MKTLOC="$(mkt_field "$MKTNAME" installLocation)"
MKT='-'; [ -f "$MKTLOC/.claude-plugin/marketplace.json" ] && MKT="$(jver "$MKTLOC/.claude-plugin/marketplace.json" plugins.0.version)"
SESS="$(sess_ver)"; [ -z "$SESS" ] && SESS='-'
SRC="$(mkt_field "$MKTNAME" source.repo)"
# Không để giá trị lạ lọt vào vcmp: nó tách theo "." rồi +0 nên "1.4.0<rác>"
# vẫn ra 1.4.0 và quyết định trên dữ liệu không tin được.
PROJ="$(clean_ver "$PROJ")"; INST="$(clean_ver "$INST")"; MKT="$(clean_ver "$MKT")"; SESS="$(clean_ver "$SESS")"

REM='-'
if [ "$REMOTE" = "1" ] && [ -n "$SRC" ]; then
  NOW="$(date +%s)"
  if [ -f "$CACHE" ]; then
    CT="$(awk '{print $1}' "$CACHE" 2>/dev/null)"; CV="$(awk '{print $2}' "$CACHE" 2>/dev/null)"
    [ -n "$CT" ] && [ $((NOW - CT)) -lt "$TTL" ] && REM="$CV"
  fi
  if [ "$REM" = '-' ]; then
    R="$(curl -fsS --max-time 3 "https://raw.githubusercontent.com/$SRC/main/.claude-plugin/marketplace.json" 2>/dev/null \
         | grep -oE '"version" *: *"[^"]+"' | head -1 | sed -E 's/.*"([^"]+)"$/\1/')"
    if is_semver "$R"; then REM="$R"; mkdir -p "$CACHE_D" && echo "$NOW $R" > "$CACHE"
    else REM='?'; fi   # mất mạng: im, không coi là lệch
  fi
fi

# ── bảng: version trước, nhãn sau — printf đệm theo byte nên nhãn có dấu sẽ lệch cột
if [ "$BRIEF" = "0" ]; then
  echo "=== Version ==="
  printf '  %-8s %s\n' "$PROJ" "dự án .sdd/"
  printf '  %-8s %s\n' "$INST" "bản đã cài"
  printf '  %-8s %s\n' "$MKT"  "marketplace đã tải về"
  if [ "$SESS" = '-' ]; then
    printf '  %-8s %s\n' "?" "phiên này đang chạy (không biết — hook chưa ghi, hoặc chạy ngoài Claude Code)"
  else
    printf '  %-8s %s\n' "$SESS" "phiên này đang chạy"
  fi
  [ "$REMOTE" = "1" ] && printf '  %-8s %s\n' "$REM" "GitHub${SRC:+ ($SRC)}"
  echo
fi

sev() { # major lệch thì ✗, còn lại !
  if [ "$(echo "$1" | cut -d. -f1)" != "$(echo "$2" | cut -d. -f1)" ]; then bad "$3"; else warn "$3"; fi
}
[ "$(vcmp "$PROJ" "$INST")" = "-1" ] && \
  sev "$PROJ" "$INST" "③ dự án cũ hơn bản đã cài ($PROJ < $INST) → /sdd-solo:init --update"
[ "$(vcmp "$INST" "$MKT")" = "-1" ] && \
  sev "$INST" "$MKT" "② bản đã cài cũ hơn bản đã tải ($INST < $MKT) → /plugin update $PNAME"
[ "$REMOTE" = "1" ] && [ "$REM" != '-' ] && [ "$REM" != '?' ] && [ "$(vcmp "$MKT" "$REM")" = "-1" ] && \
  sev "$MKT" "$REM" "① có bản mới trên GitHub ($MKT < $REM) → /plugin marketplace update $MKTNAME"
# ④ chỉ thấy được nhờ hook ghi lại; không lệnh nào sửa, phải mở session mới
[ "$SESS" != '-' ] && [ "$(vcmp "$SESS" "$INST")" = "-1" ] && \
  sev "$SESS" "$INST" "④ phiên này vẫn chạy $SESS trong khi đã cài $INST → MỞ SESSION MỚI (không lệnh nào sửa được)"

[ "$(vcmp "$PROJ" "$INST")" = "1" ] && [ "$PROJ" != '-' ] && [ "$INST" != '-' ] && \
  warn ".sdd/ ($PROJ) mới hơn bản đã cài ($INST) — repo init bằng bản dev, hoặc plugin bị hạ cấp"
[ "$DEV" = "1" ] && [ "$BRIEF" = "0" ] && info "script đang chạy từ --plugin-dir, không phải bản cài"

if [ "$((FAIL+WARN))" -eq 0 ]; then
  [ "$BRIEF" = "0" ] && ok "không lệch"
  exit 0
fi
exit 1

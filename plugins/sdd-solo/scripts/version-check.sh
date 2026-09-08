#!/usr/bin/env bash
# version-check.sh [--remote] [--brief]
# So chuỗi version và chỉ đúng lệnh cần chạy cho từng chỗ lệch:
#   GitHub ──①──▶ marketplace clone ──②──▶ plugin đã cài ──③──▶ .sdd/ của dự án
# --remote: hỏi thêm GitHub (tối đa 3s, nhớ 24h). Không có cờ thì thuần cục bộ, không đụng mạng.
# --brief : chỉ in dòng lệch, không in bảng. Dùng cho hook SessionStart.
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
PLUGIN="${SDD_PLUGIN:-$(dirname "$HERE")}"; ROOT="$(project_root)"
CFG="$HOME/.claude/plugins"
CACHE_D="${XDG_CACHE_HOME:-$HOME/.cache}/sdd-solo"; CACHE="$CACHE_D/remote-check"
TTL=86400   # 24h

REMOTE=0; BRIEF=0
for a in "$@"; do
  [ "$a" = "--remote" ] && REMOTE=1
  [ "$a" = "--brief" ] && BRIEF=1
done

# ── bốn mắt xích ────────────────────────────────────────────────────────
PROJ="$(cat "$ROOT/.sdd/version" 2>/dev/null || echo '-')"
RUN="$(jver "$PLUGIN/.claude-plugin/plugin.json" version)"; [ -z "$RUN" ] && RUN='-'
MKTNAME="$(mkt_of "$PLUGIN")"
DEV=0; [ -z "$MKTNAME" ] && { MKTNAME="sdd-solo"; DEV=1; }   # chạy bằng --plugin-dir
MKTLOC="$(mkt_field "$MKTNAME" installLocation)"
MKT='-'; [ -n "$MKTLOC" ] && [ -f "$MKTLOC/.claude-plugin/marketplace.json" ] && \
  MKT="$(jver "$MKTLOC/.claude-plugin/marketplace.json" plugins.0.version)"
SRC="$(mkt_field "$MKTNAME" source.repo)"

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
    if [ -n "$R" ]; then
      REM="$R"; mkdir -p "$CACHE_D" && echo "$NOW $R" > "$CACHE"
    else
      REM='?'   # không có mạng: im, không coi là lệch
    fi
  fi
fi

# ── bảng: version đứng trước để cột không lệch vì dấu tiếng Việt ────────
if [ "$BRIEF" = "0" ]; then
  echo "=== Version ==="
  printf '  %-8s %s\n' "$PROJ" "dự án .sdd/"
  printf '  %-8s %s\n' "$RUN"  "plugin đang chạy${DEV:+}"
  printf '  %-8s %s\n' "$MKT"  "marketplace đã tải về"
  [ "$REMOTE" = "1" ] && printf '  %-8s %s\n' "$REM" "GitHub${SRC:+ ($SRC)}"
  echo
fi

sev() { # sev <a> <b> <thông điệp> — major lệch thì ✗, còn lại !
  if [ "$(echo "$1" | cut -d. -f1)" != "$(echo "$2" | cut -d. -f1)" ]; then bad "$3"; else warn "$3"; fi
}
[ "$(vcmp "$PROJ" "$RUN")" = "-1" ] && \
  sev "$PROJ" "$RUN" "③ dự án cũ hơn plugin ($PROJ < $RUN) → /sdd-solo:init --update"
[ "$(vcmp "$RUN" "$MKT")" = "-1" ] && \
  sev "$RUN" "$MKT" "② plugin cũ hơn bản đã tải ($RUN < $MKT) → /plugin update sdd-solo"
[ "$REMOTE" = "1" ] && [ "$REM" != '-' ] && [ "$REM" != '?' ] && [ "$(vcmp "$MKT" "$REM")" = "-1" ] && \
  sev "$MKT" "$REM" "① có bản mới trên GitHub ($MKT < $REM) → /plugin marketplace update sdd-solo"

# dự án mới hơn plugin: init bằng bản dev, hoặc plugin bị hạ cấp
[ "$(vcmp "$PROJ" "$RUN")" = "1" ] && [ "$PROJ" != '-' ] && [ "$RUN" != '-' ] && \
  warn ".sdd/ ($PROJ) mới hơn plugin đang chạy ($RUN) — repo init bằng bản dev, hoặc plugin bị hạ cấp"
[ "$DEV" = "1" ] && [ "$BRIEF" = "0" ] && info "plugin đang chạy từ --plugin-dir, không phải bản cài"

if [ "$((FAIL+WARN))" -eq 0 ]; then
  [ "$BRIEF" = "0" ] && ok "không lệch"
  exit 0
fi
exit 1

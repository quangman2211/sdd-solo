#!/usr/bin/env bash
# update.sh — chạy trọn chuỗi update theo đúng thứ tự, chỉ những khe đang lệch.
#   ① claude plugin marketplace update   ② claude plugin update   ③ scaffold --update
# Bản mới KHÔNG áp vào phiên đang mở — giống hệt Claude Code, phải mở session mới.
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
PLUGIN="${SDD_PLUGIN:-$(dirname "$HERE")}"; ROOT="$(project_root)"
PNAME="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["name"])' "$PLUGIN/.claude-plugin/plugin.json" 2>/dev/null || echo sdd-solo)"
MKTNAME="$(mkt_of "$PLUGIN")"

if [ -z "$MKTNAME" ]; then
  warn "plugin đang chạy từ --plugin-dir, không phải bản cài qua marketplace"
  info "bỏ qua ① ②, chỉ chạy ③ scaffold --update"
else
  # ① marketplace clone ← GitHub
  echo "① làm mới marketplace…"
  OUT="$(claude plugin marketplace update "$MKTNAME" </dev/null 2>&1)"; RC=$?
  echo "$OUT" | sed 's/^/    /'
  [ "$RC" -eq 0 ] && ok "marketplace $MKTNAME" \
                  || bad "không làm mới được marketplace — mất mạng? Chạy tiếp bằng bản đã tải."
  # ② bản cài ← marketplace clone
  MKTLOC="$(mkt_field "$MKTNAME" installLocation)"
  MJ="$MKTLOC/.claude-plugin/marketplace.json"
  MKT='-'
  if [ -f "$MJ" ]; then
    MKT="$(jver "$MJ" plugins.0.version)"
    # ① vừa ghi lại clone xong. Thử lại một nhịp nếu đọc ra thứ không phải version.
    is_semver "$MKT" || { sleep 0.3; MKT="$(jver "$MJ" plugins.0.version)"; }
  fi
  CUR="$(clean_ver "$(jver "$PLUGIN/.claude-plugin/plugin.json" version)")"
  if ! is_semver "$MKT"; then
    # Không đoán, không quyết định trên giá trị không tin được — xem khe ④ ở 1.4.0.
    dump_bad "② version của marketplace" "$MKT"
    bad "② bỏ qua vì không đọc được version marketplace → làm tay: claude plugin update $PNAME@$MKTNAME"
    MKT='-'
  elif [ "$(vcmp "$CUR" "$MKT")" = "-1" ]; then
    echo "② cài $PNAME $CUR → $MKT…"
    OUT="$(claude plugin update "$PNAME@$MKTNAME" </dev/null 2>&1)"; RC=$?
    echo "$OUT" | sed 's/^/    /'
    [ "$RC" -eq 0 ] && ok "đã cài $MKT" || bad "cài không xong — làm tay: claude plugin update $PNAME@$MKTNAME"
  else
    ok "② bản cài đã là mới nhất ($CUR)"
  fi
fi

# ③ .sdd/ của dự án ← scaffold của bản MỚI NHẤT, không phải bản đang chạy
NEW="$(python3 -c '
import json,sys,os
p=os.path.expanduser("~/.claude/plugins/installed_plugins.json")
d=json.load(open(p))["plugins"]
for k,v in d.items():
    if k.split("@")[0]==sys.argv[1] and v:
        print(v[-1].get("installPath",""));break
' "$PNAME" 2>/dev/null)"
[ -n "$NEW" ] && [ -x "$NEW/scripts/scaffold.sh" ] || NEW="$PLUGIN"
echo "③ cập nhật .sdd/ và template của dự án (scaffold từ $(jver "$NEW/.claude-plugin/plugin.json" version))…"
"$NEW/scripts/scaffold.sh" "$NEW" "$ROOT" --update 2>&1 | sed 's/^/    /'

# version phiên đang mở lấy từ chỗ hook SessionStart ghi lại — KHÔNG suy từ
# đường dẫn script, vì script này gọi qua bash nên đường dẫn là bản mới.
SESS="$(sess_ver)"
INSTALLED="$(jver "$NEW/.claude-plugin/plugin.json" version)"
echo
echo "=== Sau khi update ==="
printf '  %-8s %s\n' "$INSTALLED" "bản đã cài"
printf '  %-8s %s\n' "$(cat "$ROOT/.sdd/version" 2>/dev/null || echo '-')" "dự án .sdd/"
printf '  %-8s %s\n' "${SESS:-?}"  "phiên này đang chạy${SESS:+}"
echo
if [ -z "$SESS" ]; then
  echo "Không biết phiên này đang nạp bản nào (hook chưa ghi). Cứ mở session mới cho chắc."
elif [ "$(vcmp "$SESS" "$INSTALLED")" = "-1" ]; then
  echo "MỞ SESSION MỚI để nạp $INSTALLED — phiên này vẫn đang chạy $SESS."
  echo "Giống Claude Code: bản mới không áp vào phiên đang mở."
else
  ok "phiên này đã chạy bản mới nhất"
fi

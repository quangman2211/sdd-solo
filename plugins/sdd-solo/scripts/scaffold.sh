#!/usr/bin/env bash
# scaffold.sh <plugin_root> <project_root> [--update]
# Copy templates/project vào repo. Ghi manifest sha để lần update chỉ ghi đè file chưa sửa tay.
set -e
PLUGIN="$1"; ROOT="$2"; MODE="${3:-}"
. "$PLUGIN/scripts/lib.sh"
VER="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["version"])' "$PLUGIN/.claude-plugin/plugin.json" 2>/dev/null || grep -oE '"version": *"[^"]+"' "$PLUGIN/.claude-plugin/plugin.json" | head -1 | sed -E 's/.*"([^"]+)"$/\1/')"
# Chiều ngược: plugin CŨ chạy trên repo MỚI. Bản 1.x scaffold vào repo 2.x sẽ
# dựng lại cả cây 1.x (checklists/ prompts/ .githooks/) cạnh cây 2.x — rồi lần
# migrate sau lại thấy "hai cây cùng tồn tại". Chặn hạ cấp ngay từ đây.
# || true là BẮT BUỘC: dưới set -e, một command substitution thất bại ở vế
# phải của phép gán làm thoát ngay. Repo trắng chưa có .sdd/version — chính
# scaffold mới là thứ tạo ra nó — nên 2.0.3 chặn sạch /sdd-solo:init trên
# repo trắng, exit 1, không một dòng output. Xem #14.
PV="$(cat "$ROOT/.sdd/version" 2>/dev/null || true)"
if [ -n "$PV" ] && [ "$(vcmp "$PV" "$VER")" = "1" ]; then
  bad "dự án ở $PV, plugin đang chạy là $VER — không hạ cấp bố cục dự án"
  info "cập nhật plugin rồi chạy lại: /plugin marketplace update sdd-solo → /plugin update sdd-solo"
  exit 1
fi
# Repo đã cài sdd-solo mà còn dấu vết bố cục 1.x → PHẢI migrate trước.
# Chạy scaffold trước migrate là dựng sẵn toàn bộ cây đích bằng template rỗng,
# rồi migrate thấy đích đã có nên bỏ qua hết — nội dung thật kẹt ở chỗ cũ, mọi
# file nhân đôi, không một dòng lỗi nào. Xem #8.
if [ -f "$ROOT/.sdd/version" ]; then
  OLD1X=""
  for m in checklists/definition-of-ready.md prompts/adversarial-pass.md \
           specs/contexts/_template changes/_template .githooks/commit-msg .gitmessage; do
    [ -e "$ROOT/$m" ] && OLD1X="$OLD1X $m"
  done
  if [ -n "$OLD1X" ]; then
    bad "repo còn bố cục 1.x:$OLD1X"
    info "chạy MIGRATE TRƯỚC, init sau — ngược lại là nội dung thật kẹt ở chỗ cũ:"
    info "  bố cục 1.x không còn script chuyển đổi từ 4.0.0 — xem README mục 'Bố cục 1.x'"
    info "  rồi mới /sdd-solo:init --update"
    exit 1
  fi
fi
MAN="$ROOT/.sdd/manifest"; mkdir -p "$ROOT/.sdd/gate"; touch "$MAN"
TPL="$PLUGIN/templates/project"
COPIED=0; KEPT=0; NEW=0
echo "sdd-solo $VER → $ROOT ${MODE}"
cd "$TPL"
find . -type f | sed 's#^\./##' | sort | while read -r rel; do
  src="$TPL/$rel"; dst="$ROOT/$rel"; tsha="$(sha "$src")"
  mkdir -p "$(dirname "$dst")"
  esc="$(printf '%s' "$rel" | sed 's/[.[\*^$/]/\\&/g')"
  line="$(grep -E "^$esc " "$MAN" | tail -1)"
  rec_inst="$(echo "$line" | awk '{print $2}')"; rec_tpl="$(echo "$line" | awk '{print $3}')"
  if [ ! -f "$dst" ]; then
    cp "$src" "$dst"; echo "$rel $(sha "$dst") $tsha" >> "$MAN"; ok "tạo  $rel"
  elif [ "$rec_tpl" = "$tsha" ]; then
    : # template không đổi kể từ lần cài → không đụng
  else
    cur="$(sha "$dst")"
    if [ -z "$rec_inst" ] || [ "$rec_inst" = "$cur" ]; then
      cp "$src" "$dst"; echo "$rel $(sha "$dst") $tsha" >> "$MAN"; ok "cập nhật $rel"
    else
      cp "$src" "$dst.new"; echo "$rel $rec_inst $tsha" >> "$MAN"; warn "giữ  $rel — anh đã sửa; bản mới ở $rel.new (tự merge rồi xoá .new)"
    fi
  fi
done
# CLAUDE.md: khối giữa marker
CL="$ROOT/CLAUDE.md"; B='<!-- sdd-solo:begin -->'; E='<!-- sdd-solo:end -->'
BLOCK="$(cat "$PLUGIN/templates/CLAUDE.md.tmpl")"
if [ -f "$CL" ] && grep -q "$B" "$CL"; then
  python3 - "$CL" "$B" "$E" "$BLOCK" <<'PY'
import sys,re
p,b,e,block=sys.argv[1:5]; s=open(p,encoding='utf-8').read()
s=re.sub(re.escape(b)+r'.*?'+re.escape(e), b+'\n'+block+'\n'+e, s, flags=re.S)
open(p,'w',encoding='utf-8').write(s)
PY
  ok "CLAUDE.md — thay khối sdd-solo"
else
  { [ -f "$CL" ] && printf '\n'; printf '%s\n%s\n%s\n' "$B" "$BLOCK" "$E"; } >> "$CL"; ok "CLAUDE.md — thêm khối sdd-solo"
fi
# 4.0.0: KHÔNG còn vá .specify/templates/spec-template.md. Bản mỏng ấy tồn tại
# chỉ để /speckit-plan có chỗ đọc — một miếng đệm không sinh thông tin mới (#35).
# Và nó buộc một thứ tự init mà đảo lại là hỏng im lặng: `specify init --force`
# chạy SAU thì ghi đè bản mỏng, không báo gì. Bước ⑩ giờ là /sdd-solo:design.
# git hooks
if [ -d "$ROOT/.git" ]; then
  mkdir -p "$ROOT/.sdd/hooks"; cp "$PLUGIN/templates/githooks/"* "$ROOT/.sdd/hooks/"; chmod +x "$ROOT/.sdd/hooks/"*
  git -C "$ROOT" config core.hooksPath .sdd/hooks
  [ -f "$ROOT/.sdd/gitmessage" ] && git -C "$ROOT" config commit.template .sdd/gitmessage
  ok "git hooks: commit-msg, pre-commit (core.hooksPath=.sdd/hooks)"
else
  warn "chưa có .git — git init rồi chạy lại để cài hook"
fi
# .sdd/config — sinh một lần, dò từ repo. KHÔNG nằm trong templates/project nên
# init --update không bao giờ ghi đè: đây là nội dung của dự án, không phải hành vi.
if [ ! -f "$ROOT/.sdd/config" ]; then
  D="$(detect_paths "$ROOT")"; DC="${D%%|*}"; DT="${D##*|}"
  [ -z "$DC" ] && DC="$CFG_DEFAULT_CODE"; [ -z "$DT" ] && DT="$CFG_DEFAULT_TEST"
  UCT="$(printf '%s' "$DT" | awk '{print $1}')/use-cases"
  {
    echo "# sdd-solo — đường dẫn code/test của repo này."
    echo "# Githook và script kiểm đều đọc file này. Sai đường dẫn thì hook chặn hụt"
    echo "# trong im lặng, nên /sdd-solo:status có kiểm lại giúp."
    echo "# Danh sách cách nhau bằng dấu cách. Sửa tay thoải mái, init --update không đụng."
    echo "code_paths=$DC"
    echo "test_paths=$DT"
    echo "uc_test_dir=$UCT"
    echo "# tool_paths: code THẬT không thuộc UC nào và không thể thuộc — script đo"
    echo "# dữ liệu, script chuyển đổi một lần, tiện ích của repo. Được miễn ID ở"
    echo "# githook và không tính vào mẫu số trace-ratio. Để trống là hành xử như cũ."
    echo "tool_paths="
    echo "# brief_path: file brief nguồn mà specs/br.md được chuyển ra từ đó."
    echo "# /sdd-solo:intake ghi dòng này. Nó đưa brief vào THỨ TỰ ĐỌC BẮT BUỘC —"
    echo "# không có nó thì brief thành file chỉ-ghi ngay sau intake (#34)."
    echo "brief_path="
  } > "$ROOT/.sdd/config"
  ok ".sdd/config — code_paths=$DC · test_paths=$DT (dò từ repo; sửa nếu sai)"
  # tests/ · __tests__/ · spec/ là ba quy ước khác hẳn nhau. Đoán trượt thì
  # ac-coverage mù mà không ai biết, nên nói ngay thay vì ghi lặng.
  [ -d "$ROOT/$(printf '%s' "$DT" | awk '{print $1}')" ] || \
    warn ".sdd/config: uc_test_dir=$UCT là ĐOÁN — thư mục test chưa tồn tại. Sửa cho khớp quy ước của repo (tests/ · __tests__/ · spec/)."
else
  info ".sdd/config đã có — code_paths=$(code_paths "$ROOT")"
fi
if ! has_code_path "$ROOT"; then
  if repo_has_code "$ROOT"; then
    bad ".sdd/config: không thư mục nào trong code_paths=$(code_paths "$ROOT") tồn tại, mà repo đã có file nguồn → githook đang chặn hụt. Sửa .sdd/config."
  else
    info "chưa có thư mục code nào — bình thường với repo mới; nhớ sửa .sdd/config khi đặt code"
  fi
fi
# 2.0.0: chép script kiểm vào dự án để cổng DoR chạy được ngoài máy đã cài
# plugin (CI, người clone repo). Đổi lại: bản sao có thể trôi version — .sdd/version
# so với version plugin, lệch thì session-start và status cảnh báo.
mkdir -p "$ROOT/.sdd/scripts"
KEEP="lib.sh br-check.sh gate-check.sh change-check.sh close-check.sh design-check.sh pass.sh status.sh metrics.sh version-check.sh deps-check.sh migrate.sh uc-steps.sh"
for f in $KEEP; do
  [ -f "$PLUGIN/scripts/$f" ] && cp "$PLUGIN/scripts/$f" "$ROOT/.sdd/scripts/$f"
done
chmod +x "$ROOT/.sdd/scripts/"*.sh 2>/dev/null
ok ".sdd/scripts/ — bản sao $VER, chạy được không cần plugin (CI dùng .sdd/scripts/gate-check.sh)"

# Dọn script bản cũ đã gộp/bỏ. Chép file mới mà KHÔNG dọn file cũ thì repo nâng
# cấp xong vẫn còn nguyên ĐƯỜNG CŨ chạy được: `gate-pass.sh` vẫn đóng dấu cổng
# được, đứng song song `pass.sh gate`; `uc-ready.sh` vẫn đo bốn thứ mà
# `gate-check.sh --pre` đang đo. Gộp trong plugin để hai phép đo khỏi trôi khỏi
# nhau, rồi để lại cả hai bản trong dự án, là không gộp gì cả.
#
# LIỆT KÊ ĐÍCH DANH những tên plugin TỪNG phát hành — không xoá theo luật "mọi
# .sh không nằm trong danh sách chép". Người dùng có thể đã để script của họ ở
# đây; một phép dọn theo luật chung thì có thể xoá nhầm, một danh sách đích danh
# thì không thể.
RETIRED="ac-coverage.sh trace-ratio.sh gate-pass.sh close-pass.sh change-pass.sh uc-ready.sh migrate-1to2.sh"
RM=""
for f in $RETIRED; do
  # chốt an toàn: không bao giờ xoá thứ bản NÀY đang phát hành
  case " $KEEP " in *" $f "*) continue;; esac
  [ -f "$ROOT/.sdd/scripts/$f" ] && { rm -f "$ROOT/.sdd/scripts/$f"; RM="$RM $f"; }
done
[ -n "$RM" ] && ok ".sdd/scripts/ — dọn bản cũ đã gộp:$RM"
echo "$VER" > "$ROOT/.sdd/version"
echo; echo "Xong. Commit: git add -A && git commit -m \"chore(sdd): init sdd-solo $VER\""
# Dòng này là câu chỉ đường ĐẦU TIÊN user đọc, trước khi biết bất cứ thứ gì khác.
# Tới 3.2.0 nó vẫn nói "/requirements (AIUP) hoặc tự viết specs/br.md" — mà
# /requirements đọc vision.md (không ai tạo), còn "tự viết br.md" chính là chỗ
# người ta đứng lại. Xem #20.
echo "BƯỚC TIẾP — Phase 1: gõ /sdd-solo:intake"
echo "  Nó hỏi 7 câu (khổ gì · ai khổ · tốn gì · ...) rồi tự viết specs/br.md."
echo "  Đang cầm sẵn brief của agent khác: /sdd-solo:intake duong/dan/brief.md"
echo "  Muốn tự viết: đọc BR-000 mẫu trong specs/br.md, hoặc specs/_intake.md để tự hỏi mình."

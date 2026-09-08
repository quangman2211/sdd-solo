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
    info "  bash \"$PLUGIN/scripts/migrate-1to2.sh\" --dry-run   # xem trước"
    info "  bash \"$PLUGIN/scripts/migrate-1to2.sh\"             # làm thật"
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
# Spec Kit template mỏng
if [ -d "$ROOT/.specify/templates" ]; then
  T="$ROOT/.specify/templates/spec-template.md"
  [ -f "$T" ] && ! grep -q 'sdd-solo' "$T" && cp "$T" "$T.bak"
  cp "$PLUGIN/templates/speckit/spec-template.md" "$T"; ok ".specify/templates/spec-template.md — bản mỏng trích ID (bản cũ .bak)"
else
  warn "chưa có .specify/ — chạy 'specify init --here --force --non-interactive --integration claude' TRƯỚC, rồi /sdd-solo:init --update để thay spec-template"
fi
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
for f in lib.sh gate-check.sh gate-pass.sh change-check.sh change-pass.sh close-check.sh close-pass.sh status.sh trace-ratio.sh ac-coverage.sh version-check.sh deps-check.sh migrate-1to2.sh uc-ready.sh; do
  [ -f "$PLUGIN/scripts/$f" ] && cp "$PLUGIN/scripts/$f" "$ROOT/.sdd/scripts/$f"
done
chmod +x "$ROOT/.sdd/scripts/"*.sh 2>/dev/null
ok ".sdd/scripts/ — bản sao $VER, chạy được không cần plugin (CI dùng .sdd/scripts/gate-check.sh)"
echo "$VER" > "$ROOT/.sdd/version"
echo; echo "Xong. Commit: git add -A && git commit -m \"chore(sdd): init sdd-solo $VER\""; echo "Bước tiếp: đọc specs/README.md · viết STATE.md · /requirements (AIUP) hoặc tự viết specs/br.md"

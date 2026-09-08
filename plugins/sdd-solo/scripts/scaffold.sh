#!/usr/bin/env bash
# scaffold.sh <plugin_root> <project_root> [--update]
# Copy templates/project vào repo. Ghi manifest sha để lần update chỉ ghi đè file chưa sửa tay.
set -e
PLUGIN="$1"; ROOT="$2"; MODE="${3:-}"
. "$PLUGIN/scripts/lib.sh"
VER="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["version"])' "$PLUGIN/.claude-plugin/plugin.json" 2>/dev/null || grep -oE '"version": *"[^"]+"' "$PLUGIN/.claude-plugin/plugin.json" | head -1 | sed -E 's/.*"([^"]+)"$/\1/')"
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
  mkdir -p "$ROOT/.githooks"; cp "$PLUGIN/templates/githooks/"* "$ROOT/.githooks/"; chmod +x "$ROOT/.githooks/"*
  git -C "$ROOT" config core.hooksPath .githooks
  [ -f "$ROOT/.gitmessage" ] && git -C "$ROOT" config commit.template .gitmessage
  ok "git hooks: commit-msg, pre-commit (core.hooksPath=.githooks)"
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
echo "$VER" > "$ROOT/.sdd/version"
echo; echo "Xong. Commit: git add -A && git commit -m \"chore(sdd): init sdd-solo $VER\""; echo "Bước tiếp: đọc specs/README.md · viết STATE.md · /requirements (AIUP) hoặc tự viết specs/br.md"

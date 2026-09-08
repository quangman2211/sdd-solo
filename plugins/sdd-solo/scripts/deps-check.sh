#!/usr/bin/env bash
# deps-check.sh [--fix]
# Kiểm phụ thuộc ngoài của SDD-Solo (Spec Kit, AIUP, Camunda).
# Mặc định chỉ kiểm và in lệnh copy-paste. --fix thì cài luôn theo đúng thứ tự.
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
PLUGIN="$(dirname "$HERE")"; ROOT="$(project_root)"
FIX=0; [ "$1" = "--fix" ] && FIX=1
DID_FIX=0

SPECIFY_INIT="specify init --here --force --non-interactive --integration claude"
SPECIFY_TOOL="uv tool install specify-cli --from git+https://github.com/github/spec-kit.git"
AIUP_URL="https://github.com/AI-Unified-Process/marketplace.git"
AIUP_MKT="ai-unified-process-marketplace"

echo "=== Phụ thuộc ==="

# ── Spec Kit ────────────────────────────────────────────────────────────
NEED_SCAFFOLD=0
if ! command -v specify >/dev/null 2>&1; then
  bad "Spec Kit — chưa có lệnh 'specify'"
  info "→ $SPECIFY_TOOL"
  info "  (cần uv: https://docs.astral.sh/uv/ — không tự cài hộ)"
elif [ ! -d "$ROOT/.specify" ]; then
  bad "Spec Kit — có lệnh 'specify' nhưng repo chưa init"
  info "→ $SPECIFY_INIT"
  info "  rồi /sdd-solo:init --update   (thứ tự này bắt buộc)"
  if [ "$FIX" = "1" ]; then
    echo; info "--fix: đang chạy specify init…"
    DID_FIX=1
    if (cd "$ROOT" && $SPECIFY_INIT); then ok "đã init Spec Kit"; NEED_SCAFFOLD=1
    else bad "specify init lỗi — làm tay theo lệnh trên"; fi
  fi
else
  ok "Spec Kit — .specify/ có"
  if [ -f "$ROOT/.specify/templates/spec-template.md" ] && \
     grep -q 'sdd-solo' "$ROOT/.specify/templates/spec-template.md" 2>/dev/null; then
    ok "spec-template — đã là bản mỏng trích ID"
  else
    bad "spec-template — vẫn là bản gốc Spec Kit, chưa thay"
    info "→ /sdd-solo:init --update"
    info "  (dấu hiệu đã chạy specify init SAU /sdd-solo:init — init không nhắc lại nữa)"
    [ "$FIX" = "1" ] && NEED_SCAFFOLD=1
  fi
fi

# lệnh /speckit-* có thật trong repo chưa
if [ -d "$ROOT/.claude/skills" ]; then
  MISS=""
  for c in specify plan tasks implement; do
    [ -d "$ROOT/.claude/skills/speckit-$c" ] || MISS="$MISS /speckit-$c"
  done
  [ -z "$MISS" ] && ok "lệnh /speckit-specify /speckit-plan /speckit-tasks /speckit-implement" \
                 || warn "thiếu lệnh:$MISS — chạy lại '$SPECIFY_INIT'"
fi

# ── AIUP ────────────────────────────────────────────────────────────────
if find "$HOME/.claude/plugins/cache" -maxdepth 2 -type d -name 'aiup-core' 2>/dev/null | grep -q .; then
  ok "AIUP — aiup-core đã cài"
else
  bad "AIUP — chưa có aiup-core (cho /requirements /entity-model /use-case-diagram /use-case-spec)"
  info "→ /plugin marketplace add $AIUP_URL"
  info "→ /plugin install aiup-core@$AIUP_MKT"
  info "  dùng URL https đầy đủ; dạng owner/repo rơi sang SSH → Permission denied (publickey)"
  if [ "$FIX" = "1" ]; then
    echo; info "--fix: đang cài AIUP…"; DID_FIX=1
    claude plugin marketplace add "$AIUP_URL" 2>&1 | sed 's/^/      /'
    claude plugin install "aiup-core@$AIUP_MKT" -y 2>&1 | sed 's/^/      /'
    find "$HOME/.claude/plugins/cache" -maxdepth 2 -type d -name 'aiup-core' 2>/dev/null | grep -q . \
      && ok "đã cài aiup-core — mở session mới để thấy lệnh" \
      || bad "cài AIUP không xong — làm tay bằng hai lệnh trên"
  fi
fi

# ── Camunda ─────────────────────────────────────────────────────────────
if [ -d "/Applications/Camunda Modeler.app" ]; then
  ok "Camunda Modeler — có (bước ④ vẽ BPMN)"
else
  warn "Camunda Modeler — không thấy ở /Applications (chỉ kiểm được trên macOS)"
  info "→ https://camunda.com/download/modeler/ · cần cho bước ④ BPMN và DMN"
fi
info "Claude Design — không kiểm được bằng script; cần cho Phase 0 và bước ⑤"

# ── cài lại spec-template nếu vừa init Spec Kit ──────────────────────────
if [ "$NEED_SCAFFOLD" = "1" ]; then
  echo; info "--fix: chạy lại scaffold --update để thay spec-template…"
  "$PLUGIN/scripts/scaffold.sh" "$PLUGIN" "$ROOT" --update 2>&1 | sed 's/^/      /'
fi

# đã đụng tay vào máy thì kiểm lại từ đầu, đừng tin sổ sách
if [ "$FIX" = "1" ] && [ "$DID_FIX" = "1" ]; then
  echo; echo "=== Kiểm lại sau khi cài ==="
  exec "$0"
fi

echo
if [ "$FAIL" -gt 0 ]; then
  echo "Thiếu $FAIL phụ thuộc."
  [ "$FIX" = "1" ] && echo "--fix không cài được hết — làm tay theo lệnh ở trên." \
                   || echo "Chạy lệnh ở trên, hoặc /sdd-solo:init --with-deps để cài giúp."
  exit 1
fi
echo "Đủ phụ thuộc."

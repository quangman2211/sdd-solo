#!/usr/bin/env bash
# pass.sh <gate|close|change> <ID> — chạy SAU khi phép kiểm tương ứng exit 0.
#
# Gộp từ gate-pass.sh + close-pass.sh + change-pass.sh (4.0.0). Ba script cũ
# cùng một hình: đổi Status, ghi dấu vết, commit riêng. Giữ NGUYÊN từng câu chữ
# commit message và từng dòng in ra — githook và `gate-check` §9 nhận diện commit
# bằng tiêu đề, nên đổi một ký tự ở đây là mở một lỗ im lặng ở chỗ khác.
#
# Vì sao mode tường minh chứ không đoán theo tiền tố ID: `UC-###` đi qua HAI pass
# khác nhau (⑨ gate và ⑭ close). Tiền tố không phân biệt được hai cái đó, và một
# script tự đoán sai giữa "reviewed" với "implemented" thì hỏng im lặng.
set -e
MODE="${1:-}"; ID="${2:-}"
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
case "$MODE" in
  gate|close|change|deprecate) ;;
  *) echo "Dùng: pass.sh <gate|close|change|deprecate> <ID>" >&2; exit 2;;
esac
[ -z "$ID" ] && { echo "Dùng: pass.sh $MODE <ID>" >&2; exit 2; }
ROOT="$(project_root)"

# marker + commit marker — chung cho gate và change
mark() {
  mkdir -p "$ROOT/.sdd/gate"
  git -C "$ROOT" rev-parse HEAD > "$ROOT/.sdd/gate/$1.ok"
  git -C "$ROOT" add ".sdd/gate/$1.ok" \
    && git -C "$ROOT" commit -q --only -m "chore(sdd): gate marker $1" -- ".sdd/gate/$1.ok" || true
}

case "$MODE" in

gate)
  F="$(find_uc "$ID" "$ROOT")"; [ -z "$F" ] && exit 1
  sed -i.bak -E 's/(\*\*Status:\*\* *)draft/\1reviewed/' "$F" && rm -f "$F.bak"
  sed -i.bak -E "s/(\*\*Last updated:\*\* *).*/\1$(today)/" "$F" && rm -f "$F.bak"
  # #44: bảng use-cases.md của context nói cùng một trạng thái, cùng một commit.
  T="$(uc_table_file "$ID" "$ROOT")"; TF=""
  if uc_table_set "$ID" reviewed "$ROOT"; then TF="$T"; else
    printf '  ! bảng %s không có dòng %s — thêm dòng cho /sdd-solo:state gợi đúng UC tiếp theo\n' "${T#$ROOT/}" "$ID"; fi
  git -C "$ROOT" commit -q --only -m "docs($ID): spec reviewed — qua cổng DoR" -- "$F" $TF || true
  mark "$ID"
  printf 'QUA CỔNG. Status -> reviewed · marker .sdd/gate/%s.ok · đã commit.\n' "$ID"
  printf 'Bước tiếp: /sdd-solo:design %s — thiết kế trước khi viết dòng code đầu tiên.\n' "$ID"
  ;;

close)
  F="$(find_uc "$ID" "$ROOT")"; [ -z "$F" ] && exit 1
  CTX="$(ctx_of "$F")"
  sed -i.bak -E 's/(\*\*Status:\*\* *)(draft|reviewed)/\1implemented/' "$F" && rm -f "$F.bak"
  # 5.0.0 — dấu vết rời khỏi file đang hiệu lực. Đo ở runxops: UC-009.md 56 KB thì
  # ## Adversarial pass 11,0 + ## Đọc lại 11,3 + ## History 6,3 = 28,6 KB, và không ai
  # đọc lại ba mục đó sau khi UC đóng — chúng là giấy nháp của một bài toán đã giải.
  # Trong đội, biên bản rà soát là bằng chứng cho người thứ hai; làm một mình thì
  # không có người thứ hai. Nhưng KHÔNG XOÁ: thân dời sang UC-###.trace.md cùng thư
  # mục (git giữ, tranh chấp thì mở), tại chỗ để lại MỘT dòng có số đếm bằng máy.
  # Nén ở ⑭ chứ không ở ⑨: lúc UC còn mở, F# là danh sách việc và cổng đọc nó bằng
  # máy. Idempotent — dòng tóm tắt đã có đuôi "→ UC-###.trace.md" thì không nén lại.
  TRACE="$(dirname "$F")/$ID.trace.md"
  python3 - "$F" "$TRACE" "$ID" "$(today)" <<'PY'
import sys, re, io
f, tr, ID, today = sys.argv[1:5]
s = io.open(f, encoding='utf-8').read()
def section(name):
    return re.search(r'(?ms)^## ' + re.escape(name) + r'[ \t]*\n(.*?)(?=^## |\Z)', s)
moved = []
def replace(name, summary):
    global s
    m = section(name)
    if not m: return
    body = m.group(1)
    if ('→ ' + ID + '.trace.md') in body: return          # đã nén
    if not body.strip(): return                              # rỗng — không có gì để dời
    # Còn là KHUÔN (YYYY-MM-DD, <...>) thì không phải dấu vết — không dời. Bắt được
    # vì chạy close trên một UC khuôn trống: nó "dời 3 mục" toàn placeholder.
    if re.search(r'YYYY-MM-DD|<[^>\n]+>', body): return
    moved.append((name, body.rstrip('\n') + '\n'))
    s = s[:m.start(1)] + summary + '\n\n' + s[m.end(1):]
def date_in(body):
    m = re.search(r'Ngày chạy:\s*(\d{4}-\d{2}-\d{2})', body)
    return m.group(1) if m else today
m = section('Adversarial pass')
if m and 'Ngày chạy' in m.group(1):
    b = m.group(1); n = len(re.findall(r'(?m)^\s*-\s*Q\d+\b', b))
    replace('Adversarial pass', f'- Ngày chạy: {date_in(b)} · 3 vai · {n} câu, đã áp hết → {ID}.trace.md')
m = section('Đọc lại')
if m and re.search(r'(?m)^- F\d+ ', m.group(1)):
    b = m.group(1); n = len(re.findall(r'(?m)^- F\d+ ', b))
    k = len(re.findall(r'(?m)^- F\d+ .*không phải lỗi', b))
    replace('Đọc lại', f'- Ngày chạy: {date_in(b)} · {n} phát hiện · {k} dương tính giả · đã áp hết → {ID}.trace.md')
m = section('History')
if m and re.search(r'(?m)^- v\d+ ', m.group(1)):
    vs = [int(x) for x in re.findall(r'(?m)^- v(\d+) ', m.group(1))]
    replace('History', f'- v{max(vs)+1} ({today}): implemented · lịch sử đầy đủ → {ID}.trace.md')
m = section('Open Questions')
if m:
    b = m.group(1)
    closed = re.findall(r'(?m)^[ \t]*[-*] \[x\].*\n?', b, flags=re.I)
    if closed:
        moved.append(('Open Questions (đã đóng)', ''.join(closed)))
        nb = re.sub(r'(?m)^[ \t]*[-*] \[x\].*\n?', '', b, flags=re.I)
        s = s[:m.start(1)] + nb + s[m.end(1):]
if moved:
    head = ''
    try: old = io.open(tr, encoding='utf-8').read()
    except FileNotFoundError:
        old = ''
        head = (f'# {ID} — dấu vết\n\n'
                f'<!-- Sinh bởi pass.sh close ngày {today}. Đây là GIẤY NHÁP của {ID}: adversarial, đọc lại,\n'
                f'     history, câu hỏi đã đóng. Không phải file đọc thường — mở khi cần tra vì sao một\n'
                f'     dòng trong {ID}.md ra như thế. context.sh và decisions.sh không đọc file này. -->\n')
    out = old + head
    for h, b in moved:
        out += f'\n## {h} — {today}\n{b}'
    io.open(tr, 'w', encoding='utf-8').write(out)
    io.open(f, 'w', encoding='utf-8').write(s)
    print(f'  dời {len(moved)} mục sang {ID}.trace.md')
PY
  BR="$(grep -oE 'BR-[0-9]+' "$F" | head -1)"
  RULES="$(grep -oE 'RULE-[0-9]+' "$F" | sort -u | tr '\n' ' ')"
  ADRS="$(grep -oE 'ADR-[0-9]+' "$F" | sort -u | tr '\n' ' ')"
  TR="$ROOT/specs/traceability.md"
  for n in $(grep -oE '^### AC-[0-9]+' "$F" | grep -oE '[0-9]+'); do
    SCRS="$(sed -n '/^## Screens/,/^## /p' "$F" | grep -oE 'SCR-[0-9]+-[0-9]+' | sort -u | tr '\n' ' ')"
    echo "| $BR | $ID | AC-$n | $RULES | $SCRS | tests/use-cases/$CTX/$ID/AC-$n.test.* | $ADRS | implemented |" >> "$TR"
  done
  # #44: bảng use-cases.md — ca thật runxops UC-014: file UC implemented, bảng vẫn draft,
  # /sdd-solo:state gợi UC tiếp theo sai, phải sửa tay một commit riêng (cfbead4).
  T="$(uc_table_file "$ID" "$ROOT")"; TF=""
  if uc_table_set "$ID" implemented "$ROOT"; then TF="$T"; else
    printf '  ! bảng %s không có dòng %s — thêm dòng cho /sdd-solo:state gợi đúng UC tiếp theo\n' "${T#$ROOT/}" "$ID"; fi
  [ -f "$TRACE" ] && git -C "$ROOT" add "$TRACE"
  git -C "$ROOT" commit -q --only -m "docs($ID): implemented — traceability" -- "$F" "$TR" $TF $( [ -f "$TRACE" ] && printf '%s' "$TRACE" ) || true
  echo "ĐÃ ĐÓNG $ID. Status → implemented${TF:+ (file UC + bảng use-cases.md)} · traceability +$(grep -cE '^### AC-' "$F") dòng · commit xong."
  echo "Nhớ: cập nhật STATE.md (/sdd-solo:state) trước khi đóng máy."
  ;;

deprecate)
  # #45: bỏ UC cho tử tế — năm việc rời nhau (Status · History · marker · bảng · decisions) thì
  # một việc luôn bị bỏ sót. Ca thật runxops: UC-009/UC-012 deprecated bằng tay, marker cổng còn
  # nguyên (githook vẫn cho feat(UC-009)), History/decisions ghi tay, STATE ghi nợ nhiều ngày.
  F="$(find_uc "$ID" "$ROOT")"; [ -z "$F" ] && exit 1
  shift 2; BY="-"; REASON=""
  while [ $# -gt 0 ]; do case "$1" in --by) BY="${2:--}"; shift 2;; *) REASON="$REASON $1"; shift;; esac; done
  REASON="$(printf '%s' "$REASON" | sed 's/^ *//')"
  [ -z "$REASON" ] && { echo "Dùng: pass.sh deprecate UC-### [--by UC-###] <lý do>" >&2; exit 2; }
  case "$BY" in UC-[0-9]*|-) ;; *) echo "--by phải là UC-### hoặc -" >&2; exit 2;; esac
  sed -i.bak -E 's/(\*\*Status:\*\* *)(draft|reviewed|implemented)/\1deprecated/' "$F" && rm -f "$F.bak"
  sed -i.bak -E "s/(\*\*Last updated:\*\* *).*/\1$(today)/" "$F" && rm -f "$F.bak"
  python3 - "$F" "$(today)" "$REASON" "$BY" <<'PY'
import sys, re, io
f, today, reason, by = sys.argv[1:5]
s = io.open(f, encoding='utf-8').read()
vs = [int(x) for x in re.findall(r'(?m)^- v(\d+) ', s)]
line = f'- v{max(vs, default=0)+1} ({today}, anh): deprecated — {reason}' + (f' · thay bằng {by}' if by != '-' else ' · không có UC thay thế')
m = re.search(r'(?ms)^## History[ \t]*\n(.*?)(?=^## |\Z)', s)
if m:
    body = m.group(1).rstrip('\n')
    s = s[:m.start(1)] + body + '\n' + line + '\n' + ('\n' if m.end(1) < len(s) else '') + s[m.end(1):]
else:
    s = s.rstrip('\n') + '\n\n## History\n' + line + '\n'
io.open(f, 'w', encoding='utf-8').write(s)
PY
  T="$(uc_table_file "$ID" "$ROOT")"; TF=""
  if uc_table_set "$ID" deprecated "$ROOT"; then TF="$T"; else
    printf '  ! bảng %s không có dòng %s\n' "${T#$ROOT/}" "$ID"; fi
  MK="$ROOT/.sdd/gate/$ID.ok"; MKF=""
  if [ -f "$MK" ]; then
    git -C "$ROOT" rm -q --cached ".sdd/gate/$ID.ok" 2>/dev/null || true
    rm -f "$MK"; MKF=".sdd/gate/$ID.ok"
  fi
  DEC="$ROOT/specs/internal/decisions.md"; DF=""
  if [ -f "$DEC" ]; then
    printf -- '- %s — Bỏ %s (%s). Loại: giữ %s. Chi tiết: %s\n' "$(today)" "$ID" "$REASON" "$ID" "$( [ "$BY" = "-" ] && printf 'không có UC thay thế' || printf '%s' "$BY" )" >> "$DEC"
    DF="$DEC"
  fi
  git -C "$ROOT" commit -q --only -m "docs($ID): deprecated — $REASON" -- "$F" $TF $DF $MKF || true
  printf 'ĐÃ BỎ %s. Status -> deprecated · History v+1 · marker cổng %s · bảng use-cases.md %s · decisions.md %s · đã commit.\n' \
    "$ID" "$( [ -n "$MKF" ] && printf 'đã gỡ' || printf 'không có' )" "$( [ -n "$TF" ] && printf 'đã sửa' || printf 'không có dòng' )" "$( [ -n "$DF" ] && printf '+1 dòng' || printf 'không có file' )"
  [ "$BY" != "-" ] && printf 'Thay bằng %s — chưa có thư mục thì /sdd-solo:start %s.\n' "$BY" "$BY"
  echo "Nhớ: ## Related Use Cases của BR cha và STATE.md còn trỏ $ID thì sửa tay (/sdd-solo:state)."
  ;;

change)
  D="$(find_chg "$ID" "$ROOT")"; [ -z "$D" ] && exit 1
  P="$D/proposal.md"
  python3 - "$P" "$(today)" <<'PY'
import sys,re
p,d=sys.argv[1],sys.argv[2]; s=open(p,encoding='utf-8').read()
s=re.sub(r'(?m)^(## Status\n+)[a-z]+\s*$', r'\1applying', s)
s=re.sub(r'(?m)^(## History\n)', r'\1', s)
if '## History' in s and f'{d}: designed -> applying' not in s:
    s=s.rstrip('\n')+f'\n- {d}: designed -> applying (qua cổng Phase 5)\n'
open(p,'w',encoding='utf-8').write(s)
PY
  git -C "$ROOT" commit -q --only -m "docs($ID): change reviewed — qua cổng Phase 5" -- "$P" || true
  mark "$ID"
  printf 'QUA CỔNG PHASE 5. Status -> applying · marker .sdd/gate/%s.ok · đã commit.\n' "$ID"
  echo "Bước tiếp: viết test cho AC mới (đỏ trước) rồi sửa code. Commit code gắn ($ID)."
  echo "Xong hết thì merge delta vào specs/, History UC v+1, và chore($ID): archive."
  ;;

esac

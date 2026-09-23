#!/usr/bin/env bash
# Hook SessionStart: đọc STATE.md và đưa vào context. Không in gì nếu repo không dùng sdd-solo.
ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
[ -f "$ROOT/STATE.md" ] || exit 0
STATE="$(cat "$ROOT/STATE.md")"
VER="$(cat "$ROOT/.sdd/version" 2>/dev/null || echo '?')"
GATES="$(ls "$ROOT/.sdd/gate" 2>/dev/null | grep -E '\.ok$' | sed 's/\.ok$//' | tr '\n' ' ')"
# Hook này chạy TỪ thư mục plugin mà phiên thật sự nạp — chỗ duy nhất biết
# được điều đó. Ghi lại để version-check đọc; không có nó thì khe ④ mù.
HD="$(cd "$(dirname "$0")" && pwd)"; . "$HD/lib.sh"
SV="$(jver "$(dirname "$HD")/.claude-plugin/plugin.json" version)"
if [ -n "$SV" ]; then
  SF="$(sess_file)"; mkdir -p "$(dirname "$SF")" && echo "$SV" > "$SF"
  find "$(dirname "$SF")" -name 'session-*' -mtime +7 -delete 2>/dev/null
fi
# lệch version: chỉ so cục bộ. Không gọi mạng ở hook — hook có timeout 10s.
VC="$("$(cd "$(dirname "$0")" && pwd)/version-check.sh" --brief 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g; s/^ *//' | tr '\n' '; ')"
# Chưa có BR thì mọi lời khuyên về UC đều sai chỗ — nói thẳng ngay câu đầu.
BRW=""
# 7.0: qua lib (br_untouched) — 6.x đo specs/br.md, 7.0 đo mọi specs/*/br-###/br.md.
if br_untouched "$ROOT"; then
  BRW=" TRẠNG THÁI: CHƯA CÓ BR — BR còn nguyên template, nên repo này đang ở Phase 1 chứ không ở UC nào cả. Câu đầu tiên nói với user: gõ /sdd-solo:intake (hỏi 7 câu rồi viết BR giúp). ĐỪNG nói về UC, đừng đề xuất viết code, và đừng đề xuất /requirements của AIUP vì nó bỏ qua tầng BR. Bỏ qua câu 'nói lại đang ở UC nào' bên dưới."
fi
# Brief nguồn: nếu có, nó PHẢI vào context — đây là chỗ duy nhất trong cả quy
# trình nhìn ra ngoài specs/. Kèm cảnh báo lệch sha: brief đổi sau khi nạp nghĩa
# là hai tài liệu có thể đang nói ngược nhau mà không ai đối chiếu (#34).
BFW=""
BP="$(brief_path "$ROOT")"
if [ -n "$BP" ] && [ -f "$ROOT/$BP" ]; then
  BSHA="$(sha "$ROOT/$BP" | cut -c1-12)"
  BREC="$(brief_rec_sha "$ROOT")"
  BFW=" BRIEF NGUỒN: $BP — specs/br.md được chuyển ra từ file này. ĐỌC NÓ trước khi viết plan, chọn kiến trúc, hay quyết bất cứ gì về ngăn xếp/nơi chạy/ai gọi; những mục bị loại khỏi BR vì 'thuộc tầng thiết kế' nằm trong đó, và đích của chúng là $(arch_file "$ROOT" | sed "s#$ROOT/##") — không cơ chế nào tự mang chúng tới đó."
  if [ -n "$BREC" ] && [ "$BREC" != "$BSHA" ]; then
    BFW="$BFW CẢNH BÁO: brief đã đổi kể từ lần intake (sha $BREC → $BSHA) — br.md và brief có thể đang nói ngược nhau; đối chiếu trước khi tin bên nào."
  fi
fi
# 7.3 — phiên có DẤU VAI (role.sh <vai>, hay SDD_ROLE) thì bơm HỢP ĐỒNG VAI + việc đang giao thay cho đoạn văn viết cho
# một người ngồi gõ. Hook chạy lại mỗi /clear ("mỗi việc một phiên"), nên phiên vừa xoá tự biết mình là ai, được ghi gì,
# đang giữ việc nào. Vai điều phối (không có mẫu nhánh, tên chứa "điều phối") vẫn nhận STATE + bảng giao việc.
RV="$(role_current "$ROOT")"
if [ -n "$RV" ] && [ -n "$(roles_file "$ROOT")" ] && role_known "$RV" "$ROOT"; then
  RN="$(role_name "$RV" "$ROOT")"
  QB=""; [ -x "$HD/queue.sh" ] && [ -f "$ROOT/notes/hang-doi.md" ] && QB="$(bash "$HD/queue.sh" list 2>/dev/null | grep -E "^\| *[a-z0-9][a-z0-9._-]* *\|" | awk -F'|' -v v="$RV" '{a=$4; b=$6; gsub(/^ +| +$/,"",a); gsub(/^ +| +$/,"",b)} a==v && (b=="đang" || b=="chờ")' | cut -c1-160 | tr '\n' ';')"
  KQ=""; for kf in "$(ketqua_dir "$ROOT")"/$(printf '%s' "$RV" | tr 'A-Z' 'a-z')-*.txt; do [ -f "$kf" ] && KQ="$KQ $(basename "$kf" .txt)=$(tail -1 "$kf" | grep -oE 'ket=[a-z]+' | cut -d= -f2)"; done
  LAG=""; MB="$(git -C "$ROOT" show-ref --verify --quiet refs/heads/main && echo main || echo master)"
  if [ "$(cd "$ROOT" && git rev-parse --git-dir)" != "$(cd "$ROOT" && git rev-parse --git-common-dir)" ]; then
    NB="$(git -C "$ROOT" rev-list --count "HEAD..$MB" 2>/dev/null)"; LAG=" Worktree phụ, sau $MB ${NB:-?} commit — mở lượt bằng: git merge $MB (hook, marker cổng, .sdd/version ở đây là bản của nhánh này)."
    MG="$(git -C "$ROOT" ls-tree --name-only "$MB:.sdd/gate/" 2>/dev/null | sed 's/\.ok$//' | while read -r g; do [ -f "$ROOT/.sdd/gate/$g.ok" ] || printf '%s ' "$g"; done)"
    [ -n "$MG" ] && LAG="$LAG Marker cổng $MB có mà nhánh này chưa: $MG"
  fi
  case "$RN" in *"điều phối"*) ISA=1;; *) ISA=0;; esac
  CTX="[sdd-solo v$VER] Phiên này là VAI $RV · $RN (dấu vai theo worktree). Được ghi: $(role_paths "$RV" "$ROOT"). KHÔNG ghi: $(role_deny "$RV" "$ROOT"). Commit: $(role_may_commit "$RV" "$ROOT" && printf '<type>(ID) kê đích danh file (git commit --only -- <file>), hook thêm đuôi Vai: %s' "$RV" || printf 'KHÔNG — điều phối commit thay'). Kiểm trước commit: $(role_checks "$RV" "$ROOT"). Luật: làm ĐÚNG việc trong lời giao, đọc đúng gói đọc, không đọc sổ điều phối; gặp điều spec chưa nói (số · enum · quyền · hình dạng) → bash .sdd/scripts/phieu.sh new \"<việc>\" $RV (hoặc phieu.sh hoi $RV \"<câu>\") rồi DỪNG — không AskUserQuestion, không đoán, không nhắn agent khác; không push. Kết lượt: bash .sdd/scripts/role.sh --ketqua <khoá> ket=xong neo=<hash> TRƯỚC khi báo, rồi báo ≤ 10 dòng mở đầu bằng chính dòng KETQUA.${LAG} Việc đang giao cho vai này (notes/hang-doi.md): ${QB:-không có dòng nào}. KETQUA đã ghi:${KQ:- chưa có}.${VC:+ CẢNH BÁO lệch version: $VC}"
  if [ "$ISA" = 1 ]; then
    CTX="$CTX

=== Bảng giao việc (queue.sh board) ===
$( [ -x "$HD/queue.sh" ] && bash "$HD/queue.sh" board 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' )

=== STATE.md ===
$STATE"
  fi
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$CTX" <<'PY2'
import json,sys
print(json.dumps({"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":sys.argv[1]}},ensure_ascii=False))
PY2
  else printf '%s\n' "$CTX"; fi
  exit 0
fi
CTX="[sdd-solo v$VER] Repo này chạy quy trình SDD-Solo.${BRW}${BFW} Việc đầu tiên trong session: nói lại cho user đang ở UC nào, bước nào (theo STATE.md dưới đây) và lệnh gợi ý tiếp theo. Quy tắc cứng: không viết code cho UC chưa có marker .sdd/gate/UC-###.ok, và không viết code cho UC chưa có design.md trong thư mục của nó — bảo user chạy /sdd-solo:gate rồi /sdd-solo:design trước. Chọn ngăn xếp/nơi chạy/thư viện mà $(arch_file "$ROOT" | sed "s#$ROOT/##") chưa nói thì DỪNG và hỏi. Gặp quyết định nghiệp vụ spec chưa nói thì DỪNG và hỏi, không chọn mặc định. UC đã qua cổng: ${GATES:-chưa có}.${VC:+ CẢNH BÁO lệch version — nói cho user ngay ở câu đầu: $VC}

=== STATE.md ===
$STATE"
if command -v python3 >/dev/null 2>&1; then
  python3 - "$CTX" <<'PY'
import json,sys
print(json.dumps({"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":sys.argv[1]}},ensure_ascii=False))
PY
else
  printf '%s\n' "$CTX"
fi

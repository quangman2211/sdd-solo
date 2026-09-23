#!/usr/bin/env bash
# scaffold.sh <plugin_root> <project_root> [--update]
# Copy templates/project vào repo. Ghi manifest sha để lần update chỉ ghi đè file chưa sửa tay.
set -e
PLUGIN="$1"; ROOT="$2"; MODE="${3:-}"
# Gọi tay thiếu tham số vị trí thì `source` một đường rỗng đổ "invalid option" — không ai đoán được.
if [ -z "$PLUGIN" ] || [ -z "$ROOT" ] || [ ! -f "$PLUGIN/scripts/lib.sh" ]; then
  echo "Dùng: scaffold.sh <thư mục plugin> <thư mục dự án> [--update]" >&2
  echo "  ví dụ: bash ~/.claude/plugins/cache/sdd-solo/sdd-solo/<ver>/scripts/scaffold.sh <thư mục plugin đó> \"\$(git rev-parse --show-toplevel)\" --update" >&2
  exit 2
fi
. "$PLUGIN/scripts/lib.sh"
VER="$(node "$PLUGIN/scripts/js/util.mjs" json "$PLUGIN/.claude-plugin/plugin.json" version 2>/dev/null || true)"
[ -z "$VER" ] && VER="$(grep -oE '"version": *"[^"]+"' "$PLUGIN/.claude-plugin/plugin.json" | head -1 | sed -E 's/.*"([^"]+)"$/\1/')"
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
# 7.0: repo 6.x CÓ NỘI DUNG (specs/contexts/ có UC, hoặc specs/br.md có BR thật) mà chưa migrate → chặn, cùng
# lý do với #8 ở trên: scaffold sẽ dựng specs/core/br-000/ + vision.md cạnh cây cũ, rồi `layout` thấy vision.md
# mà tưởng là 7.0 — hai cây cùng lúc, không dòng đỏ nào. Repo 6.x còn nguyên khuôn (chưa BR, chưa UC) thì
# cứ scaffold: khuôn cũ có sha khớp manifest sẽ được dọn ở RETIRED_TPL dưới.
if [ -f "$ROOT/.sdd/version" ] && [ "$(layout "$ROOT")" = v6 ]; then
  HAS_UC="$(find "$ROOT/specs/contexts" -type f -path '*/use-cases/UC-*/UC-*.md' 2>/dev/null | head -1)"
  HAS_BR=""; grep -qE '^# BR-[0-9]+: *[^ <]' "$ROOT/specs/br.md" 2>/dev/null && ! br_untouched "$ROOT" && HAS_BR=1
  if [ -n "$HAS_UC" ] || [ -n "$HAS_BR" ]; then
    bad "repo đang ở bố cục 6.x có nội dung (specs/contexts/ · specs/br.md) — 7.0 đổi cây sang core|nghề × br-###"
    info "chạy MIGRATE TRƯỚC, init sau: viết .sdd/migrate-v7.map rồi  bash .sdd/scripts/migrate.sh --layout v7 --dry-run  →  bỏ --dry-run  →  commit"
    info "  (bản migrate.sh 7.0 nằm ở plugin: ${PLUGIN}/scripts/migrate.sh — .sdd/scripts/ của repo còn bản cũ cho tới khi init --update xong)"
    info "rồi mới /sdd-solo:init --update — nó dọn khuôn 6.x còn sót và chép khuôn 7.0 (vision.md, core/br-000/, adr/, layer-check.sh)"
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
    # 7.0: KHÔNG có dòng manifest mà file đã có → của user (hoặc file thật vừa migrate tới đúng tên khuôn:
    # specs/architecture.md từ internal/). Bản cũ chép đè ở đây — ca thật: architecture.md của runxops thay bằng
    # khuôn, không một dòng đỏ. Chỉ ghi đè khi sha hiện tại KHỚP sha lúc cài (chưa ai sửa).
    if [ "$rec_inst" = "$cur" ]; then
      cp "$src" "$dst"; echo "$rel $(sha "$dst") $tsha" >> "$MAN"; ok "cập nhật $rel"
    elif [ -z "$rec_inst" ] && [ "$cur" = "$tsha" ]; then
      echo "$rel $cur $tsha" >> "$MAN"; ok "ghi nhận $rel — đã có sẵn, y hệt khuôn"
    elif [ -z "$rec_inst" ]; then
      cp "$src" "$dst.new"; echo "$rel $cur $tsha" >> "$MAN"; warn "giữ  $rel — file có sẵn, không có trong manifest nên coi là của anh; khuôn ở $rel.new (xem rồi xoá .new)"
    else
      cp "$src" "$dst.new"; echo "$rel $rec_inst $tsha" >> "$MAN"; warn "giữ  $rel — anh đã sửa; bản mới ở $rel.new (tự merge rồi xoá .new)"
    fi
  fi
done

# Dọn TEMPLATE bản cũ đã đổi tên — cùng lý do như RETIRED của scripts ở cuối file:
# chép tên mới vào mà không dọn tên cũ thì repo nâng cấp xong vẫn còn nguyên đường cũ.
# Ca 4.2.0: `specs/internal/adr/ADR-000-template.md` khớp glob `ADR-000*` của
# `id_exists()`, nên `design.md` trích `ADR-000` được `design-check` cho qua MÀU XANH
# trong mọi repo vừa scaffold — không cần ai viết sai gì, chỉ cần cài. Đổi tên trong
# plugin mà để lại file cũ trong dự án là không sửa gì cả.
#
# KHÁC một điểm so với RETIRED của scripts: file dưới `specs/` là NỘI DUNG của dự án,
# không phải bản sao hành vi. Ranh giới "dự án giữ nội dung" đứng trên việc dọn dẹp,
# nên chỉ xoá khi user CHƯA đụng vào (sha khớp manifest). Đã sửa tay thì cảnh báo và
# để nguyên — thà để lỗi kêu to còn hơn tự tay xoá chữ của người khác.
RETIRED_TPL="specs/internal/adr/ADR-000-template.md
  specs/internal/adr/_adr-template.md specs/internal/architecture.md specs/internal/decisions.md specs/br.md
  specs/context-map.md specs/story-map.md specs/internal/design-system.md
  specs/internal/onboarding.md specs/internal/runbooks/README.md specs/changes/README.md
  specs/contexts/README.md specs/internal/README.md README.md
  .sdd/checklists/definition-of-done.md .sdd/checklists/feedback-triage.md
  .sdd/prompts/session-start.md .sdd/gate/README.md
  .sdd/templates/change/delta/UC-000.delta.md .sdd/templates/change/design.md
  .sdd/templates/change/proposal.md .sdd/templates/change/tasks.md
  .sdd/templates/context/README.md .sdd/templates/context/diagrams/README.md
  .sdd/templates/context/entities.md .sdd/templates/context/use-cases.md
  .sdd/templates/use-case/UC-000.design.md .sdd/templates/use-case/UC-000.flow.md
  .sdd/templates/use-case/UC-000.md .sdd/templates/use-case/UC-000.sequence.md
  .sdd/templates/use-case/UC-000.tasks.md .sdd/templates/use-case/screens/README.md"
# 5.0.0: 13 "ngăn kéo trống" (đo hai lần: không script/skill nào đọc, và ở runxops
# vẫn nguyên byte sau nhiều tuần) + 13 khuôn của .sdd/templates/ (chỉ skill đọc, mà
# skill chỉ chạy khi có plugin — bản sao trong dự án không phục vụ CI hay người
# clone, nên lý do tồn tại của .sdd/scripts/ không áp cho chúng; giờ ở
# templates/skel/ của plugin). Khuôn 43 → 16 file. Xem CHANGELOG 5.0.0.
for rel in $RETIRED_TPL; do
  # chốt an toàn: không bao giờ xoá đường dẫn mà bản NÀY đang phát hành
  [ -f "$TPL/$rel" ] && continue
  dst="$ROOT/$rel"; [ -f "$dst" ] || continue
  esc="$(printf '%s' "$rel" | sed 's/[.[\*^$/]/\\&/g')"
  rec_inst="$(grep -E "^$esc " "$MAN" | tail -1 | awk '{print $2}')"
  if [ -n "$rec_inst" ] && [ "$rec_inst" = "$(sha "$dst")" ]; then
    rm -f "$dst"; ok "dọn  $rel — không còn trong khuôn (CHANGELOG 4.2.0 / 5.0.0)"
  else
    warn "còn  $rel — anh đã sửa tay nên KHÔNG xoá; khuôn 5.0.0 không còn file này (xem CHANGELOG)"
  fi
done
# Thư mục rỗng sau khi dọn — git không theo dõi thư mục rỗng, nhưng người mở
# Finder thì thấy, và một thư mục trống trông y hệt "chưa làm tới".
for d in .sdd/templates/use-case/screens .sdd/templates/use-case .sdd/templates/context/diagrams \
         .sdd/templates/context .sdd/templates/change/delta .sdd/templates/change .sdd/templates \
         specs/internal/runbooks specs/internal/adr specs/internal specs/contexts; do
  [ -d "$ROOT/$d" ] && rmdir "$ROOT/$d" 2>/dev/null && ok "dọn  $d/ (rỗng)"
done

# CLAUDE.md: khối giữa marker
CL="$ROOT/CLAUDE.md"; B='<!-- sdd-solo:begin -->'; E='<!-- sdd-solo:end -->'
BLOCK="$(cat "$PLUGIN/templates/CLAUDE.md.tmpl")"
if [ -f "$CL" ] && grep -q "$B" "$CL"; then
  node "$PLUGIN/scripts/js/util.mjs" marker "$CL" "$B" "$E" "$BLOCK"
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
  mkdir -p "$ROOT/.sdd/hooks"
  for h in "$PLUGIN/templates/githooks/"*; do [ -f "$h" ] && cp "$h" "$ROOT/.sdd/hooks/" && chmod +x "$ROOT/.sdd/hooks/$(basename "$h")"; done
  # #50: pre-commit.d/ · commit-msg.d/ — luật riêng của repo. Chỉ làm mới README và .example;
  # file thực thi của user ở đó là NỘI DUNG của dự án, plugin không đụng.
  for d in pre-commit.d commit-msg.d; do
    mkdir -p "$ROOT/.sdd/hooks/$d"
    for h in "$PLUGIN/templates/githooks/$d/"*; do [ -f "$h" ] && cp "$h" "$ROOT/.sdd/hooks/$d/"; done
    chmod +x "$ROOT/.sdd/hooks/$d/"*.sh 2>/dev/null || true   # set -e: pre-commit.d không có *.sh
  done
  # 7.2: ranh giới vai dời từ pre-commit.d/10-role-boundary (theo nhánh) sang commit-msg.d/10-vai.sh (theo .sdd/roles).
  # Khuôn .example cũ là của plugin → dọn. Bản user đã bật (10-role-boundary.sh) là file của repo → không xoá, chỉ nhắc:
  # hai mảnh cùng chặn thì D/T bị chặn hai lần với hai thông điệp khác nhau.
  rm -f "$ROOT/.sdd/hooks/pre-commit.d/10-role-boundary.sh.example"
  [ -f "$ROOT/.sdd/hooks/pre-commit.d/10-role-boundary.sh" ] && \
    warn "pre-commit.d/10-role-boundary.sh (chặn theo nhánh, tới 7.1) còn đó — 7.2 chặn theo .sdd/roles ở commit-msg.d/10-vai.sh; xoá bản cũ: git rm .sdd/hooks/pre-commit.d/10-role-boundary.sh"
  git -C "$ROOT" config core.hooksPath .sdd/hooks
  [ -f "$ROOT/.sdd/gitmessage" ] && git -C "$ROOT" config commit.template .sdd/gitmessage
  ok "git hooks: commit-msg, pre-commit (core.hooksPath=.sdd/hooks) + pre-commit.d/ commit-msg.d/ (10-vai.sh: ranh giới vai theo .sdd/roles, 7.2)"
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
    echo "# nghe_paths: tên các nghề — thư mục specs/<nghề>/ và src/<nghề>/ (7.0). core không kể. Trống thì"
    echo "# script dò từ specs/*/ (thư mục có br-###/, glossary.md hay entities/). migrate --layout v7 ghi giúp."
    echo "nghe_paths="
  } > "$ROOT/.sdd/config"
  ok ".sdd/config — code_paths=$DC · test_paths=$DT (dò từ repo; sửa nếu sai)"
  # tests/ · __tests__/ · spec/ là ba quy ước khác hẳn nhau. Đoán trượt thì
  # ac-coverage mù mà không ai biết, nên nói ngay thay vì ghi lặng.
  [ -d "$ROOT/$(printf '%s' "$DT" | awk '{print $1}')" ] || \
    warn ".sdd/config: uc_test_dir=$UCT là ĐOÁN — thư mục test chưa tồn tại. Sửa cho khớp quy ước của repo (tests/ · __tests__/ · spec/)."
else
  info ".sdd/config đã có — code_paths=$(code_paths "$ROOT")"
  # 7.0: repo cũ chưa có key nghe_paths → thêm (không đụng dòng nào khác của config)
  if ! grep -qE '^nghe_paths=' "$ROOT/.sdd/config" 2>/dev/null; then
    NG="$(nghe_list "$ROOT")"
    printf '# nghe_paths: tên các nghề — thư mục specs/<nghề>/ và src/<nghề>/ (7.0). core không kể. Trống thì script dò từ specs/*/.\nnghe_paths=%s\n' "$NG" >> "$ROOT/.sdd/config"
    ok ".sdd/config — thêm nghe_paths=${NG:-(trống)} (7.0)"
  fi
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
KEEP="lib.sh mermaid.sh role.sh phieu.sh queue.sh hoi-check.sh layer-check.sh br-scope-diff.sh br-check.sh gate-check.sh change-check.sh close-check.sh design-check.sh pass.sh status.sh metrics.sh decisions.sh context.sh version-check.sh deps-check.sh migrate.sh uc-steps.sh"
for f in $KEEP; do
  [ -f "$PLUGIN/scripts/$f" ] && cp "$PLUGIN/scripts/$f" "$ROOT/.sdd/scripts/$f"
done
# 7.6.0: js/ — mã node của plugin (mermaid.mjs · mermaid-real.mjs …). Chép cả thư mục, cùng lý do như
# KEEP: cổng phải chạy được ở CI và trên máy người clone, nơi không có plugin.
[ -f "$PLUGIN/scripts/kw.tsv" ] && cp "$PLUGIN/scripts/kw.tsv" "$ROOT/.sdd/scripts/kw.tsv"
if [ -d "$PLUGIN/scripts/js" ]; then
  mkdir -p "$ROOT/.sdd/scripts/js"
  for f in "$PLUGIN/scripts/js/"*.mjs; do [ -f "$f" ] && cp "$f" "$ROOT/.sdd/scripts/js/"; done
fi
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
# 7.6.0: mermaid.py (7.5.0) đã thành js/mermaid.mjs. Bản sao cũ còn nằm đó thì repo có HAI parser,
# và cái không được cập nhật nữa vẫn chạy được — cùng lý do với RETIRED ở trên, nên cũng đích danh.
for f in mermaid.py; do
  [ -f "$ROOT/.sdd/scripts/$f" ] && { rm -f "$ROOT/.sdd/scripts/$f"; ok ".sdd/scripts/ — dọn $f (7.6.0: parser mermaid chạy bằng node)"; }
done
echo "$VER" > "$ROOT/.sdd/version"
echo; echo "Xong. Commit: git add -A && git commit -m \"chore(sdd): init sdd-solo $VER\""
# Dòng này là câu chỉ đường ĐẦU TIÊN user đọc, trước khi biết bất cứ thứ gì khác.
# Tới 3.2.0 nó vẫn nói "/requirements (AIUP) hoặc tự viết specs/br.md" — mà
# /requirements đọc vision.md (không ai tạo), còn "tự viết br.md" chính là chỗ
# người ta đứng lại. Xem #20.
echo "BƯỚC TIẾP — Phase 1: gõ /sdd-solo:intake"
echo "  Bước 0: chủ dự án nói hướng đi (specs/vision.md) bằng lời thường; rồi 7 câu (khổ gì · ai khổ · tốn gì · ...)"
echo "  và intake viết BR đầu tiên vào specs/<core|nghề>/br-001/br.md."
echo "  Đang cầm sẵn brief của agent khác: /sdd-solo:intake duong/dan/brief.md"
echo "  Muốn tự viết: đọc BR-000 mẫu trong specs/core/br-000/br.md, hoặc specs/_intake.md để tự hỏi mình."

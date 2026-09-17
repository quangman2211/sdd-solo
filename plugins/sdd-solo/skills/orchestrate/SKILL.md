---
name: orchestrate
description: Điều phối nhiều agent trên cùng một repo SDD-Solo — tám vai A/B/C/R/V/D/T/Q, ranh giới theo đường dẫn từ .sdd/config, sổ hỏi đáp L0–L3, khuôn lời giao, chuỗi chuẩn T→D→C→R→(spec‖D‖T) cho một UC sau cổng. Dùng khi user nói "chạy nhiều agent", "giao việc cho agent code/test", "dựng đội", hoặc khi một UC đã qua gate + design và muốn code/test song song.
disable-model-invocation: true
argument-hint: "setup | UC-### | round UC-###"
allowed-tools: Bash Read Write Edit Grep Glob Agent AskUserQuestion
---

Điều phối cho `$ARGUMENTS`.

**Vì sao skill này tồn tại (#39):** sdd-solo viết cho *một dev + một AI*. Ở runxops (2026-09-17, một ngày, 46 đợt
spec, UC-014 từ start tới close) chủ dự án chạy **tám agent song song**, mỗi agent một vai, phối hợp bằng file
trong repo. Mọi luật đó trả giá mới có (D sửa fake của T · R lệch D vì worktree không thấy spec mới · C đẩy lên
chủ dự án cái design đã quyết) và tới 6.5.0 chỉ nằm trong sổ của một repo. Skill này nói **vai · file · thứ tự**;
công cụ chạy song song (herdr, tmux, nhiều cửa sổ) là việc của user — phụ lục cuối có bẫy đã gặp.

Người đang đọc skill này **là vai A**. A không làm việc chuyên môn: đọc kết quả → quyết đường đi → giao việc →
commit các sổ agent khác không được commit → cập nhật STATE → hỏi chủ dự án khi L3.

`$ARGUMENTS` = `setup` → **§1**. `UC-###` → **§1 nếu chưa setup, rồi §4** (chuỗi chuẩn). `round UC-###` → **§4**
từ lượt hiện tại. Không tham số → in bảng vai (§2) và hỏi user muốn gì.

---

## 1. `setup` — một lần cho repo

1. Đọc `.sdd/config`: `code_paths` · `test_paths` · `uc_test_dir`. Ranh giới vai **lấy từ đó**, không viết chết.
   Thiếu `uc_test_dir` → dừng, bảo user khai (mặc định `tests/use-cases`).
2. Sổ hỏi đáp: `specs/internal/hoi-dap.md`. Chưa có → copy từ
   `${CLAUDE_PLUGIN_ROOT}/templates/skel/hoi-dap.md` (không thay được biến: `find ~/.claude/plugins -name hoi-dap.md
   -path '*sdd-solo*' | head -1`). Có rồi → không đụng.
3. Hook ranh giới: `.sdd/hooks/pre-commit.d/10-role-boundary.sh` chưa có → `cp .sdd/hooks/pre-commit.d/10-role-boundary.sh.example
   .sdd/hooks/pre-commit.d/10-role-boundary.sh && chmod +x …` (#50). Nhắc: hook nằm trong git, worktree chỉ thấy nó
   sau khi `merge main`.
4. Commit `chore(sdd): orchestrate setup — hoi-dap.md + hook ranh giới vai`.
5. Hỏi user bằng `AskUserQuestion` **hai câu**: (a) quyền tự quyết của R — *tới L2 (Recommended, runxops chốt) ·
   tới L1 · chỉ L0*; (b) có vai Q (QA e2e) ngay không — *bật khi compose/deploy chạy được (Recommended) · bật ngay ·
   không có*. Ghi hai câu trả lời vào đầu `hoi-dap.md` (dòng *Quyền tự quyết mặc định*) và `decisions.md`.

## 2. Bảng vai — ranh giới theo ĐƯỜNG DẪN, không theo "test hay code"

`<code>` = `code_paths`, `<test>` = `test_paths`, `<uctest>` = `uc_test_dir` từ `.sdd/config`.

| Vai | Được ghi | Không được ghi | Kết thúc lượt bằng |
|---|---|---|---|
| **A · Điều phối** | `STATE.md`, `specs/internal/decisions.md`, `specs/internal/hoi-dap.md` (commit thay R), sổ điều phối | code, spec | giao việc; **cổng duy nhất hỏi chủ dự án** (`AskUserQuestion`, mỗi lựa chọn một câu hệ quả, luôn có "Uỷ quyền R") |
| **B · Spec** | `specs/` | code, `STATE.md`, `decisions.md` | commit `docs(ID)` + hash + danh sách `___` còn lại |
| **C · Soi** | file phát hiện (scratchpad → A chép vào `specs/internal/soat-<ID>-luot-N.md`) | nội dung spec/code | số phát hiện + đường dẫn file; **phiên mới mỗi lượt**, không đọc sổ điều phối/STATE, không hỏi ai — HỎI ghi vào file |
| **R · Trọng tài** | chỉ `specs/internal/hoi-dap.md`, **không commit** | mọi file khác | phiếu `#n · L? · Cho: spec · D · T` |
| **V · Trình bày** | `specs/internal/` ghi chú, artifact | spec, code | link; **không quyết** |
| **D · Code** | `<code>/**`, migrations, `<test>/**` **trừ** `<uctest>/**`, deploy — trong **worktree riêng**, nhánh `code/<uc-###>` | `<uctest>/**`, `specs/` (trừ `specs/internal/hoi-D.md`) | `feat(UC-###)` · câu hỏi → `specs/internal/hoi-D.md` (`HỎI-D#` · `TEST-#`) |
| **T · Test** | `<uctest>/<ctx>/UC-###/**` (test, harness, fake, fixture) — nhánh `test/<uc-###>` | `<code>/**`, spec (trừ `specs/internal/hoi-T.md`) | `test(UC-###)` · câu hỏi → `specs/internal/hoi-T.md` (`HỎI-T#`) |
| **Q · QA** | `specs/internal/qa-UC-###.md`, fixture ẩn danh | code, spec | báo cáo; bật khi compose/deploy chạy được |

**Luật đã trả giá để có — đọc trước khi giao lượt đầu:**
1. **Fake/harness của cổng thuộc T.** D thấy fake sai → **không sửa**, ghi `TEST-#` (file, dòng, cần gì, vì sao) vào
   `hoi-D.md`, tạm bỏ ca đó; T sửa lượt kế. Lời giao lượt 3 ở runxops chỉ cấm "sửa test của T" → D sửa `fakes.ts`
   (`c0e7137`) vì coi fake là "cài đặt cổng". Ranh giới phải gọi **đường dẫn**.
2. **Kiểm cơ học sau mỗi lượt D, không tin mắt:** `git diff <đầu nhánh T> HEAD -- <uctest>` **rỗng** và
   `git log --no-merges --format=%h -- <uctest>` **không có commit của D**. Pane Claude Code vẽ file đổi do `git merge`
   y hệt agent tự sửa — chủ dự án đã tưởng D "vẫn viết test" một lần vì thế.
3. **D/T mở lượt bằng `git merge main`** (và merge nhánh vai kia nếu lời giao bảo) rồi đọc **đúng phiếu được chỉ**,
   không đọc cả sổ. D từng chọn ngược quyết định của R vì worktree không thấy spec mới.
4. **Hợp đồng T↔D nằm ở một file harness** (T viết từ `design.md`); D "chấp nhận hoặc ghi lý do". `design.md`
   phải khai **chữ ký cổng/hàm use-case**, không chỉ tên file (skill `design` §3 từ 6.6.0).
5. **C hay đẩy lên chủ dự án cái design đã quyết** (hai lần một ngày). R tra design trước khi xếp mức; câu "cần
   chủ dự án chốt" của C chỉ tới chủ dự án **sau khi R xác nhận L3**. A không hỏi thẳng theo lời C.
6. **Tối đa hai agent ghi chạy cùng lúc** vào cùng vùng; không song song hai UC khác context nếu cùng ghi
   `glossary.md`/`rules.md`; đổi tên lớn không song song với việc code nào.
7. **Không bao giờ giao cho agent:** đặt số/ngưỡng/giá · câu chốt hình dạng UC · `gate`/`close` · push/deploy/xoá.
   Đó là L3 của `hoi-dap.md`, và là việc A hỏi chủ dự án.

## 3. Khuôn lời giao

**Lời giao vai** (một lần khi khởi động agent, ≤ 1.500 ký tự):
```
Vai: <D · Code cho UC-###>. Nhánh/worktree: <code/uc-###, đường-dẫn-worktree>.
Được ghi: <code_paths> migrations. KHÔNG ghi: <uc_test_dir>/** (của T), specs/ (trừ specs/internal/hoi-D.md).
Không tự quyết nghiệp vụ: spec thiếu số/enum/quyền → DỪNG, ghi HỎI-D# vào specs/internal/hoi-D.md, không đoán,
không AskUserQuestion, không nhắn agent khác. Không chạy /sdd-solo:*. Commit <type>(UC-###), không push.
Kết thúc mỗi lượt: báo ngắn (commit · số kiểm · HỎI/TEST mới) rồi DỪNG.
CHƯA có việc. Đọc <design.md, tasks.md> rồi trả lời đúng một dòng: "D sẵn sàng".
```

**Lời giao việc** (mỗi lượt) — mười mục, thiếu một là lượt trôi:
```
Lượt <D-6> · nhánh <code/uc-014> · worktree <đường-dẫn>.
Luật cũ một dòng: <được ghi / không được ghi / kiểu commit / không push / hỏi ghi vào đâu>.
Bước 0: git merge main [và git merge test/uc-014].
Đọc: <file:mục> — ĐÚNG phiếu #<n>, phần "Cho: D"; không đọc phiếu khác. (trỏ, không chép nội dung)
Việc, theo thứ tự (L0 trước): 1. <K1 …> 2. <K2 …>
Lệnh kiểm phải chạy: <npm test …> — in số ca xanh/đỏ, không nói "xanh" suông.
Kiểm ranh giới cuối lượt: git diff --stat <đầu nhánh T>..HEAD -- <uc_test_dir> phải rỗng.
Commit: <feat(UC-014): …>, tách theo khối. Không push.
Báo cuối ≤ 10 dòng: commit · số kiểm · HỎI-D#/TEST-# mới · điều chưa làm. Kết quả dài → ghi file, trả đường dẫn.
Xong thì DỪNG.
```
Soạn lời giao vào file trong scratchpad trước, rồi mới gửi — lời giao > ~1.500 ký tự qua một số công cụ bị dán thành
khối không tự gửi (phụ lục).

**Lời giao soát code cho C** (sau mỗi lượt D, phiên mới): diff `git -C <worktree> diff <base>..<head>`; năm câu:
(1) truy vết việc → AC → test → code; (2) đúng tầng domain / use-cases / adapters; (3) mặc định ngầm và chỗ D khai
"ĐOÁN"; (4) chuyển trạng thái theo `entities.md`, cột cấm (CON) không lọt; (5) code đổi lặng lẽ so với `design.md`.
Mỗi phát hiện **theo khuôn phiếu** (`Câu · Đã tra · Nếu chọn sai thì · Agent nghiêng về`) để R xếp mức không phải
dịch lại. Ghi trong prompt của C và R: **phép đo nào có thể đã cũ** vì T đang sửa song song.

## 4. Chuỗi chuẩn cho một UC sau cổng

Điều kiện vào: `.sdd/gate/UC-###.ok` · `design.md` qua `design-check` · `tasks.md`. Thiếu → dừng, chỉ lệnh
(`/sdd-solo:gate`, `/sdd-solo:design`). Không dựng D khi chưa đủ — đó là luật của `CLAUDE.md`, không phải của A.

```
T lượt 1  — test ĐỎ từ AC (mỗi AC một file trong <uctest>/<ctx>/UC-###/), harness + fake từ design; nhánh test/uc-###
D lượt 1  — khối nền (tasks "việc không gắn AC nào"), rồi merge test/uc-### từng AC, làm xanh; nhánh code/uc-###
C soát    — phiên mới, diff lượt D, năm câu §3 → file phát hiện → A chép vào specs/internal/soat-UC-###-luot-N.md
R         — một phiếu gom K1…Kn: mức từng K, Cho: spec · D · T, thứ tự áp; A commit sổ
spec ‖ D ‖ T — ba vai áp CÙNG LÚC, mỗi vai đọc đúng phần "Cho:" của mình
… lặp: D lượt n → C soát → R → spec ‖ D ‖ T … tới khi hai suite xanh trên code thật và C không còn K mức L0/L1
C soát trọn — phiên mới, cả nhánh, đo cả migrate vào DB trống (số xanh trên cụm đã migrate không chứng minh gì)
D self-review 5 câu (.sdd/checklists/self-review.md) — ba trong bốn mục thành việc ở runxops, đừng bỏ
merge code/uc-### → main (A hoặc chủ dự án) → /sdd-solo:close (chủ dự án, không giao agent)
```
Một vòng `C → R → spec ‖ D ‖ T` ≈ 35–45 phút ở runxops. Ba vai cuối luôn phát cùng lúc vì họ chỉ cần chữ của
phiếu, không cần nhau.

**Sau mỗi lượt, A làm đúng bốn việc:** (1) đọc `git log` của nhánh + khối báo cuối của agent (không tin bản đọc màn
hình cho kết quả dài); (2) kiểm ranh giới bằng máy (§2 luật 2); (3) commit sổ agent không được commit
(`hoi-dap.md`, file soát) — `chore(sdd): hoi-dap #n` hoặc `docs(UC-###): soát lượt N`; (4) `STATE.md` một dòng:
lượt nào đang chạy, phiếu nào chờ Duyệt.

**Luồng phiếu:** agent ghi `HỎI-<vai>#` vào `specs/internal/hoi-<vai>.md` (trong worktree của nó) rồi DỪNG → A đọc
worktree, giao R: *"phiếu #n: xếp mức L0–L3, tra spec/ADR/design, ghi Cho: từng vai, thứ tự áp; chỉ ghi
hoi-dap.md, không commit"* → L0–L2: A phát phần `Cho:` cho từng vai · L3: A hỏi chủ dự án `AskUserQuestion` (2–4
lựa chọn, hệ quả một câu, có "Chưa quyết") → A ghi `decisions.md`/spec trước khi D bắt đầu lượt kế. Agent lặp lại
câu đã trả lời → lời giao lượt sau nhắc *"đọc mục Trả lời của phiếu trước khi hỏi lại"*.

**Khi dùng ở repo plugin / repo nhỏ:** ba vai đủ — A (phiên này), D (sửa theo nhóm việc, worktree), C (phiên mới, soi
diff của D so với thân việc và với chỗ khác đang nói). R gộp vào A vì câu hỏi thường L1.

## 5. Giới hạn — nói với user

1. Skill này **không đo được** agent có tuân lời giao không; thứ đo được là githook `.d` (ranh giới đường dẫn) và
   hai lệnh `git diff`/`git log` ở §2 luật 2. Còn lại là kỷ luật của A.
2. Agent tự nén ngữ cảnh giữa lượt thì `wait` vẫn đúng nhưng nó có thể quên luật vai → lời giao việc **nhắc lại luật
   cũ một dòng** mỗi lượt, không chỉ lúc khởi động.
3. Không thay được `/sdd-solo:verify` và ba vai adversarial: C soát **code**; verify soát **spec**. Hai việc khác nhau.

---

## Phụ lục — bẫy đã gặp với herdr 0.9.0 (không phụ thuộc; công cụ khác có bẫy khác)

- `agent wait --timeout` tính **mili-giây**: `900` = 0,9 s trông như agent xong; dùng `900000` cho 15 phút. `wait`
  trả sớm giữa các pha subagent → chờ bằng vòng `for i in 1..6: wait; đọc agent_status; break khi != working`.
- Lời giao > ~1.500 ký tự dán vào ô nhập thành `[Pasted text #N]` và **không tự gửi**: `prompt` trả `agent_prompted`,
  trạng thái vẫn `idle`. Sau mỗi prompt kiểm `agent_status = working`; `idle` + màn hình có `[Pasted text` → `send-keys
  <tên> enter`.
- Lời giao qua zsh: `<wt>`, `$(…)`, backtick bị hiểu là cú pháp shell → `parse error`, prompt không tới. Viết vào
  file scratchpad rồi `prompt "$(cat file)"`; gọi tên bằng chữ ("đường-dẫn-worktree").
- Shell nền mất PATH → `export PATH=/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin:$PATH` đầu mỗi lệnh nền.
- Claude mới khởi động có thể kẹt hộp thoại, trạng thái vẫn `idle` không `blocked` → sau `agent start`, đọc màn hình
  trước khi prompt. Hộp thoại có lựa chọn riêng tư (quét shell history) → A không tự bấm, hỏi chủ dự án.
- Ô nhập hiện gợi ý mờ (`\x1b[2m` khi đọc `--format ansi`) sau khi một skill kết thúc — là gợi ý ma, vô hại; `agent
  read` text không phân biệt được với chữ đã gõ.
- `agent read` có thể không lấy lại được câu trả lời dài → kết quả dài bắt agent ghi file.
- C phiên mới: `send-keys soi "/clear" enter`, chờ ~8 s, rồi prompt. Agent báo "3% until auto-compact" → `/clear`
  trước đợt kế; D/T giữ phiên vì đang có ngữ cảnh code.
- Pane Claude Code vẽ file đổi do `git merge` y hệt agent tự sửa (§2 luật 2).

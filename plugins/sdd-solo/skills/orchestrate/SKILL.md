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

1. Đọc `.sdd/config`: `code_paths` · `test_paths` · `uc_test_dir` · `nghe_paths`. Ranh giới vai **lấy từ đó**, không viết chết.
   Thiếu `uc_test_dir` → dừng, bảo user khai (mặc định `tests/use-cases`). `nghe_paths` (7.0) là tên các nghề —
   nó quyết `<uctest>/<core|nghề>/UC-###/` của vai T và vùng `src/<nghề>/` của vai D; trống ở repo còn bố cục 6.x
   thì ranh giới vẫn tính theo `code_paths`/`uc_test_dir` như cũ.
2. Sổ hỏi đáp: `notes/hoi-dap/hoi-dap.md` (vết quá trình, **ngoài `specs/`** từ 7.0). Chưa có → copy từ
   `${CLAUDE_PLUGIN_ROOT}/templates/skel/hoi-dap.md` (không thay được biến: `find ~/.claude/plugins -name hoi-dap.md
   -path '*sdd-solo*' | head -1`). Có rồi → không đụng.
3. Vai (7.2): `.sdd/roles` chưa có → `/sdd-solo:init --update` chép bộ vai mẫu (A B R D T); đọc lại cùng user, sửa vùng
   ghi/cấm cho đúng repo. Hook `commit-msg.d/10-vai.sh` đọc nó — mặc định `vai_bat_buoc=khong` chỉ nhắc; chạy
   `bash .sdd/scripts/role.sh --kiem-lich-su` (chỉ đọc, 300 commit) rồi mới bật `nhanh-vai`. Bản cũ
   `pre-commit.d/10-role-boundary.sh` (theo nhánh) còn thì `git rm`, kẻo hai mảnh cùng chặn. Hook nằm trong git, worktree
   chỉ thấy nó sau khi `merge main`.
4. (7.3) `notes/hang-doi.md` (hàng đợi, chỉ A ghi qua `queue.sh`) và `notes/uy-quyen.md` (uỷ quyền + điểm dừng có tên) —
   `init --update` chép khuôn. Đọc `uy-quyen.md` cùng chủ dự án: **Phạm vi** do chủ dự án viết (còn khuôn thì A không
   quyết câu L3 nào), sửa tên điểm dừng cho đúng repo. `status.sh` kiểm: mọi `DỪNG-<tên>` trong hàng đợi phải có tên ở
   bảng Điểm dừng; dòng Sổ trỏ `#n` thì `decisions.md` phải có dòng khớp.
5. Commit `chore(sdd): orchestrate setup — hoi-dap.md + .sdd/roles + hang-doi.md + uy-quyen.md`.
6. Hỏi user bằng `AskUserQuestion` **hai câu**: (a) quyền tự quyết của R — *tới L2 (Recommended, runxops chốt) ·
   tới L1 · chỉ L0*; (b) có vai Q (QA e2e) ngay không — *bật khi compose/deploy chạy được (Recommended) · bật ngay ·
   không có*. Ghi hai câu trả lời vào đầu `hoi-dap.md` (dòng *Quyền tự quyết mặc định*) và `decisions.md`.

## 2. Bảng vai — ranh giới theo ĐƯỜNG DẪN, không theo "test hay code"

`<code>` = `code_paths`, `<test>` = `test_paths`, `<uctest>` = `uc_test_dir` từ `.sdd/config`.

| Vai | Được ghi | Không được ghi | Kết thúc lượt bằng |
|---|---|---|---|
| **A · Điều phối** | `STATE.md`, `specs/decisions.md`, `notes/hoi-dap/hoi-dap.md` (commit thay R), sổ điều phối | code, spec | giao việc; **cổng duy nhất hỏi chủ dự án** (`AskUserQuestion`, mỗi lựa chọn một câu hệ quả, luôn có "Uỷ quyền R") |
| **B · Spec** | `specs/` | code, `STATE.md`, `decisions.md` | commit `docs(ID)` + hash + danh sách `___` còn lại |
| **C · Soi** | `notes/soat/soat-<ID>-luot-N.md` — ghi thẳng (runxops) hoặc scratchpad rồi A chép; **A commit**, C không commit | nội dung spec/code | số phát hiện + đường dẫn file; **phiên mới mỗi lượt**, không đọc sổ điều phối/STATE, không hỏi ai — HỎI ghi vào file |
| **R · Trọng tài** | chỉ `notes/hoi-dap/hoi-dap.md`, **không commit** | mọi file khác | phiếu `#n · L? · Cho: spec · D · T` |
| **V · Trình bày** | `notes/ban-do/` ghi chú, bản đồ, artifact | spec, code | link; **không quyết** |
| **D · Code** | `<code>/**`, migrations, `<test>/**` **trừ** `<uctest>/**`, deploy — trong **worktree riêng**, nhánh `code/<uc-###>` | `<uctest>/**`, `specs/` (toàn bộ) | `feat(UC-###)` · câu hỏi → `notes/hoi-dap/hoi-D.md` (`HỎI-D#` · `TEST-#`) |
| **T · Test** | `<uctest>/<core\|nghề>/UC-###/**` (test, harness, fake, fixture) — nhánh `test/<uc-###>` | `<code>/**`, `specs/` (toàn bộ) | `test(UC-###)` · câu hỏi → `notes/hoi-dap/hoi-T.md` (`HỎI-T#`) |
| **Q · QA** | `notes/soat/qa-UC-###.md`, fixture ẩn danh | code, spec | báo cáo; bật khi compose/deploy chạy được |

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
6. **Tối đa hai agent ghi chạy cùng lúc** vào cùng vùng; không song song hai UC khác lát nếu cùng ghi một
   `glossary.md`/`rules.md` (gốc hay của cùng một nghề); đổi tên lớn không song song với việc code nào.
7. **Không bao giờ giao cho agent:** đặt số/ngưỡng/giá · câu chốt hình dạng UC · `gate`/`close` · push/deploy/xoá.
   Đó là L3 của `hoi-dap.md`, và là việc A hỏi chủ dự án.
8. **Agent con không được mở `AskUserQuestion`** — không ai ở đó để bấm, lượt treo tới hết hạn (#53). Lời giao chạy
   `/sdd-solo:adversarial` ghi **`--phieu`**: câu hình dạng thành một phiếu K1…Kn cuối `hoi-dap.md`, UC/BR ghi
   `Chưa quyết — Open Question (phiếu #n K#)`; A commit sổ rồi giao R. `/sdd-solo:verify` từ 7.0.1 không bao giờ hỏi
   — mọi `F#` chưa bác thành `Chưa quyết (… · đề xuất: …)` và vẫn commit, không cần cờ. A đang ngồi cùng chủ dự án
   mà muốn hỏi thẳng thì chạy adversarial trong **phiên của A** với `--hoi`, không giao.

## 3. Khuôn lời giao

**Từ 7.2 lời giao việc sinh bằng máy:** `bash .sdd/scripts/role.sh <vai> notes/hoi-dap/phieu/NNN-*.md [--luot N]` in sáu
phần (mục tiêu · gói đọc `file:mục` qua lib · việc chép nguyên phần `Cho: <vai>` + mọi `[neo:]` · vùng cấm từ `.sdd/roles` ·
lệnh kiểm + commit kê đích danh + đuôi `Vai:` · dòng `KETQUA`). Chỉ nhận **file phiếu** — 137 lượt giao tay ở runxops
đều là chép lại phiếu, và chỗ hay rơi là neo. A sửa câu mục tiêu nếu cần rồi gửi; > 1.500 ký tự thì ghi file, `prompt
"$(cat file)"`. Agent kết lượt bằng `role.sh --ketqua <khoá> ket=xong neo=<hash>` **trước** khi gửi tin — file ở
`git-common-dir/sdd-ketqua/`, tin nhắn mất thì file còn (P-26); A đọc `role.sh --ketqua <khoá>`, không đọc màn hình.
Mỗi vai một worktree: `role.sh --worktree D UC-###` · `role.sh --worktree T UC-###`; **B giữ checkout chính trên
`main`** (cái B viết là sự thật chung); R và C đặt dấu bằng `role.sh R` / `role.sh C` ở worktree của mình.
Hai khuôn dưới là để đọc hiểu sáu phần đó nói gì, và để dùng khi chưa có phiếu (lời giao vai lần đầu).

**Lời giao vai** (một lần khi khởi động agent, ≤ 1.500 ký tự):
```
Vai: <D · Code cho UC-###>. Nhánh/worktree: <code/uc-###, đường-dẫn-worktree>.
Được ghi: <code_paths> migrations, notes/hoi-dap/hoi-D.md. KHÔNG ghi: <uc_test_dir>/** (của T), specs/ (toàn bộ).
Không tự quyết nghiệp vụ: spec thiếu số/enum/quyền → DỪNG, ghi HỎI-D# vào notes/hoi-dap/hoi-D.md, không đoán,
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
"ĐOÁN"; (4) chuyển trạng thái theo file entity (`specs/<core|nghề>/entities/<Tên>.md`), cột cấm (CON) không lọt;
(5) code đổi lặng lẽ so với `design.md`; (6) `src/core` có import `src/<nghề>` không — `layer-check.sh` đếm hộ.
Mỗi phát hiện **theo khuôn phiếu** (`Câu · Đã tra · Nếu chọn sai thì · Agent nghiêng về`) để R xếp mức không phải
dịch lại. Ghi trong prompt của C và R: **phép đo nào có thể đã cũ** vì T đang sửa song song.

## 4. Chuỗi chuẩn cho một UC sau cổng

Điều kiện vào: `.sdd/gate/UC-###.ok` · `design.md` qua `design-check` · `tasks.md`. Thiếu → dừng, chỉ lệnh
(`/sdd-solo:gate`, `/sdd-solo:design`). Không dựng D khi chưa đủ — đó là luật của `CLAUDE.md`, không phải của A.

```
T lượt 1  — test ĐỎ từ AC (mỗi AC một file trong <uctest>/<core|nghề>/UC-###/), harness + fake từ design; nhánh test/uc-###
D lượt 1  — khối nền (tasks "việc không gắn AC nào"), rồi merge test/uc-### từng AC, làm xanh; nhánh code/uc-###
C soát    — phiên mới, diff lượt D, năm câu §3 → notes/soat/soat-UC-###-luot-N.md (C ghi thẳng, A commit)
R         — một phiếu gom K1…Kn: mức từng K, Cho: spec · D · T, thứ tự áp; A commit sổ
spec ‖ D ‖ T — ba vai áp CÙNG LÚC, mỗi vai đọc đúng phần "Cho:" của mình
… lặp: D lượt n → C soát → R → spec ‖ D ‖ T … tới khi hai suite xanh trên code thật và C không còn K mức L0/L1
C soát trọn — phiên mới, cả nhánh, đo cả migrate vào DB trống (số xanh trên cụm đã migrate không chứng minh gì)
D self-review 5 câu (.sdd/checklists/self-review.md) — ba trong bốn mục thành việc ở runxops, đừng bỏ
merge code/uc-### → main (A hoặc chủ dự án) → /sdd-solo:close (chủ dự án, không giao agent)
```
Một vòng `C → R → spec ‖ D ‖ T` ≈ 35–45 phút ở runxops. Ba vai cuối luôn phát cùng lúc vì họ chỉ cần chữ của
phiếu, không cần nhau.

**Hàng đợi (7.3):** `queue.sh add <khoá> <làn> <vai> --can "<khoá trước>"` · `queue.sh next` in việc phát được ngay (mọi
Cần đã xong, làn còn chỗ) — A hỏi máy, không hỏi trí nhớ · `queue.sh take <khoá>` khi phát · `queue.sh done <khoá>` chỉ khi
có KETQUA `ket=xong` + neo · `queue.sh stop <khoá> <tên dừng>` với tên ở `uy-quyen.md` · `queue.sh board` là bảng giao việc
(việc quá hạn chỉ cắm cờ `nghi-chết`, A đi nhìn, không tự đổi trạng thái). Agent không ghi bảng; worktree phụ đọc bản
`main`. Mỗi lượt của A kết thúc bằng **một lệnh chờ nền hoặc một điểm dừng có tên** — không có trạng thái thứ ba.
**Sổ hỏi có địa chỉ:** D/T mở câu bằng `phieu.sh hoi D "<câu>"` (bốn ô: nguồn · chặn không · đang làm gì trong lúc chờ ·
việc cho spec khi trả lời); A trả lời vào ô `Trả lời (A/R)` + `đích:` (design.md · decisions.md), **không sửa lời hỏi**;
thân UC chỉ mở lại khi một AC đổi — `hoi-check.sh D` đỏ khi cổng đã mở mà đích trỏ thân UC.

**Sau mỗi lượt, A làm đúng bốn việc:** (1) đọc `git log` của nhánh + khối báo cuối của agent (không tin bản đọc màn
hình cho kết quả dài); (2) kiểm ranh giới bằng máy (§2 luật 2); (3) commit sổ agent không được commit
(`hoi-dap.md`, file soát) — `chore(sdd): hoi-dap #n` hoặc `docs(UC-###): soát lượt N`; (4) `STATE.md` một dòng:
lượt nào đang chạy, phiếu nào chờ Duyệt.

**Luồng phiếu:** phiếu mới cấp số bằng `bash .sdd/scripts/phieu.sh new "<việc>" <vai>` (khoá nguyên tử chung mọi
worktree, commit dòng giữ chỗ ngay — P-21 trùng số bốn lần một ngày khi cấp tay); đóng bằng `phieu.sh close <n>` (đếm
F#/K# trên file, đòi KETQUA từng vai — P-33). Agent ghi `HỎI-<vai>#` vào `notes/hoi-dap/hoi-<vai>.md` (trong worktree của nó) rồi DỪNG → A đọc
worktree, giao R: *"phiếu #n: xếp mức L0–L3, tra spec/ADR/design, ghi Cho: từng vai, thứ tự áp; chỉ ghi
hoi-dap.md, không commit"* → L0–L2: A phát phần `Cho:` cho từng vai · L3: A hỏi chủ dự án `AskUserQuestion` (2–4
lựa chọn, hệ quả một câu, có "Chưa quyết") → A ghi `decisions.md`/spec trước khi D bắt đầu lượt kế. Agent lặp lại
câu đã trả lời → lời giao lượt sau nhắc *"đọc mục Trả lời của phiếu trước khi hỏi lại"*.

**Khi dùng ở repo plugin / repo nhỏ:** ba vai đủ — A (phiên này), D (sửa theo nhóm việc, worktree), C (phiên mới, soi
diff của D so với thân việc và với chỗ khác đang nói). R gộp vào A vì câu hỏi thường L1.

## 5. Giới hạn — nói với user

1. Skill này **không đo được** agent có tuân lời giao không; thứ đo được là githook `commit-msg.d/10-vai.sh` (ranh
   giới vai theo `.sdd/roles`, đuôi `Vai:` trong `git log`), file KETQUA, và hai lệnh `git diff`/`git log` ở §2 luật 2.
   Còn lại là kỷ luật của A.
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
- `agent send-keys` chỉ nhận **phím đặt tên** (`enter`, `escape`, `ctrl-u`…), không gõ được chữ — `send-keys soi
  "/clear" enter` trả `invalid_key` và không làm gì. Mọi lệnh gạch chéo đi qua `agent prompt <tên> "/clear"`.
  C phiên mới: `prompt soi "/clear"`, chờ ~8 s, rồi prompt lời giao. Agent báo "3% until auto-compact" → `/clear`
  trước đợt kế; D/T giữ phiên vì đang có ngữ cảnh code.
- Khởi động lại agent để nạp plugin mới (bản mới không áp vào phiên đang mở): `agent prompt <tên> "/exit"` → pane về
  shell, tên agent biến mất → `agent start <tên> --kind claude --pane <pane> --timeout 90000` → đọc màn hình → gửi lại
  lời giao vai. Runxops làm cho 6 pane sau 6.6.1, cả 6 trả "sẵn sàng".
- Pane Claude Code vẽ file đổi do `git merge` y hệt agent tự sửa (§2 luật 2).

# Changelog

## 2.0.1 — 2026-09-08
Đóng #8 — lỗi nặng nhất của cả đợt, và là lỗi trong **hướng dẫn của chính tôi**.

Làm đúng thứ tự tôi chỉ định (`/sdd-solo:update` rồi `migrate`) thì `scaffold --update` dựng sẵn toàn bộ cây đích bằng template rỗng, migrate thấy đích đã có nên bỏ qua hết, root không đổi, **mọi file nhân đôi và bản có nội dung thật kẹt ở chỗ cũ**. Không một dòng ✗ nào — script in `Xong 3 việc` rồi thoát bình thường. Đúng cơ chế đã vá cho `--dry-run` ở 2.0.0, chỉ khác thủ phạm là bước 1 của quy trình.

Ba lớp, theo đúng thứ tự độ kín mà runxops-2c xếp:

1. **`scaffold` từ chối chạy** khi repo đã cài sdd-solo mà còn dấu vết 1.x (`checklists/definition-of-ready.md`, `prompts/adversarial-pass.md`, `specs/contexts/_template`, `changes/_template`, `.githooks/commit-msg`, `.gitmessage`). Chặn đúng bước người ta hay chạy trước theo thói quen. Không dùng riêng `docs/` làm dấu hiệu — repo có thể có `docs/` của họ.
2. **`migrate` quét trước, dời sau.** Phát hiện "hai cây cùng tồn tại" giờ xảy ra **trước khi đụng file đầu tiên** — bản vá đầu của tôi kêu đúng nhưng dừng giữa chừng, đúng thứ chính tôi viết là trạng thái tệ nhất có thể.
3. **Bỏ cổng `[ ! -d specs/internal ]`** ở khối `docs/` và `changes/`. Đây mới là chỗ im lặng thật: đích tồn tại thì **cả khối** bị bỏ qua, `mv1` không bao giờ được gọi nên không có gì để kêu. Giờ để `mv1` xét từng file.

Kèm: `.sdd/manifest` khử trùng theo đường dẫn sau khi đổi tên, giữ dòng cuối đúng như `scaffold` đọc — nếu không, một đường dẫn có hai dòng và `init --update` có thể ghi đè nhầm. README thêm mục **Nâng cấp 1.x → 2.0.0** với thứ tự đúng.

Đã thử: đường đúng (18 việc, `Postgres` và `RULE-001` theo sang chỗ mới, manifest 0 dòng trùng, `init --update` sau đó chạy được) · `init --update` trên repo 1.x bị chặn, nội dung không suy suyển · repo hai cây thì dừng và **chưa đụng file nào** (so danh sách file trước/sau, khớp tuyệt đối).

## 2.0.0 — 2026-09-08
Gom về hai thư mục như Spec Kit. Đóng #3 và #7. **Bản major — dự án đang chạy phải chạy `migrate-1to2.sh`.**

### Bố cục
```
.sdd/     config gate/ scripts/ hooks/ checklists/ prompts/ templates/ gitmessage version manifest
specs/    br.md rules.md … contexts/  internal/ (từ docs/)  changes/ (từ changes/)
STATE.md  CLAUDE.md  <code>/  <tests>/
```
Root từ 10 mục xuống 4. `_template` rời khỏi cây nội dung nên `ac-coverage` và `status` bỏ được `--exclude-dir`/`-not -path`. Artifact của một UC nằm trọn trong thư mục UC, kể cả `.bpmn` — `gate-check` đọc `$DIR/$ID.bpmn`, không cần dựng lại đường dẫn từ `ctx_of()`; thấy file còn ở chỗ cũ thì bảo chạy migrate.

### Ranh giới đổi có chủ đích
`.sdd/scripts/` giữ **bản sao** script kiểm. Trái với "plugin giữ hành vi" của 1.x, và đã được chấp nhận đổi: cổng DoR giờ chạy được ở CI và trên máy người clone repo, thay vì dừng ở máy tác giả — `.sdd/gate/UC-###.ok` nằm trong repo mà trước đây không ai ngoài tác giả xác minh được. Giá phải trả là bản sao có thể trôi version; `.sdd/version` so với version plugin, lệch thì hook SessionStart và `status` cảnh báo (cơ chế dựng sẵn ở 1.2.0–1.4.0).

### `scripts/migrate-1to2.sh`
`git mv` nên giữ history — đã kiểm `git log --follow` xuyên qua chỗ dời và git ghi nhận `rename … (100%)`. Viết lại `.sdd/manifest` theo đường dẫn mới, đổi `core.hooksPath` và `commit.template`. **Dừng ngay từ đầu nếu working tree bẩn** — dừng giữa chừng ở script dời file là trạng thái tệ nhất. Idempotent. `--dry-run` liệt kê trước.

Ba lỗi tự bắt khi thử: `--dry-run` **có đụng đĩa** (`mkdir` thư mục đích) khiến lần chạy thật bỏ qua `docs/` và `changes/`; nhãn "(thử)" hiện cả khi chạy thật (`${DRY:+…}` với `DRY=0` vẫn khai triển); dry-run liệt kê trùng vì không nhớ thứ đã dời. Ca thiếu `.bpmn.svg` không làm script dừng — đúng cảnh báo của runxops-2c.

### #7 — `gate-pass` tự phá điều kiện qua cổng
`gate-pass` tạo commit `docs(UC-###): spec reviewed — qua cổng DoR` hôm nay, rồi `gate-check` lần sau thấy commit docs mới hôm nay và báo đỏ "spec phải được đọc lại ở một buổi khác". Qua cổng xong thì cổng đỏ liên tục tới hôm sau. Xếp là **lỗi, không phải nới ranh giới**: quy tắc ngủ qua đêm đo việc người sửa spec, còn đây là commit sổ sách của chính script. Chỉ bỏ qua khi commit docs mới nhất **khớp đúng tiêu đề** gate-pass sinh ra — sửa spec thật sau khi qua cổng vẫn phải ngủ lại một đêm.

### Khác
- Githook: dotfile thuần (`.gitmessage`, `.gitignore`) không còn bị coi là file nguồn — 1.6.0 tính `.tên` là có phần mở rộng nên báo nhầm.
- `templates/project` bỏ `src/README.md` và `tests/README.md`: tạo sẵn `src/`+`tests/` là đúng thứ `.sdd/config` sinh ra để thôi đoán.

## 1.6.2 — 2026-09-08
Đóng #6. Gốc là lỗi của `bash` 3.2 trên macOS, không phải của plugin — runxops-2c tìm ra.

```
bash -c 'M=1.6.1; echo "→ $M…"' | od -c
0000000    →  **  **     200 246  \n          ← "1.6.1" bay mất, "…" cụt đầu
```

`echo` của bash 3.2 nuốt cả phép khai triển biến khi nó đứng **ngay trước** một ký tự nhiều byte. Không riêng `…`: `$M→` `$M✓` `$Mà` đều hỏng. Chèn một ký tự ASCII vào giữa là hết. Chỉ hỏng dưới locale UTF-8 — tức đúng môi trường thật của người dùng, sạch dưới `C`/`POSIX`. `printf` và `zsh` không dính.

Khớp mọi dữ kiện từng mâu thuẫn: `is_semver` cho qua và `od -c` sạch vì **biến chưa bao giờ bẩn** — byte chỉ mất lúc `echo` ghi ra; nhánh quyết định luôn đúng vì `vcmp` đọc biến trong bộ nhớ, không qua `echo`; chỉ dòng ② hỏng vì nó là dòng duy nhất có `$MKT` dính `…`. Bảng `version-check` thoát nhờ `printf %-8s` chèn khoảng trắng — 1.2.0 đảo thứ tự vì lý do canh cột, hoá ra chữa luôn chỗ này.

- Dòng ② dùng `printf` nên giữ lại được `②` `→` `…` cho dễ đọc, không phải bỏ.
- Gỡ `od -c` chẩn đoán của 1.6.0.
- Quét cả repo tìm biến dính sát ký tự phi-ASCII trong mọi script và githook: **0 chỗ**. Kiểm động 5 script, không script nào in ra byte hỏng.

Bốn giả thuyết trước đều sai và đều bị bác bỏ bằng thực nghiệm: output ANSI/CR, đọc file viết dở, version cộng đuôi rác, spinner ghi thẳng `/dev/tty` (loại bằng: phiên không có tty mà vẫn hỏng, và dòng in **trước** mọi lệnh `claude` cũng đã hỏng sẵn).

## 1.6.1 — 2026-09-08
- `/sdd-solo:status` nhắc lại `uc_test_dir` chừng nào thư mục còn chưa tồn tại. `!` lúc init đủ cho lần đầu, nhưng từ lần `--update` thứ hai trở đi người ta lướt qua output — mà `ac-coverage` mù thì không tự lộ ra ở đâu khác.

## 1.6.0 — 2026-09-08
Xanh giả trong `close-check`, và ba góp ý của runxops-2c sau khi kiểm 1.5.0. Đóng #5.

- **Thư mục rỗng thắng file thật (#5).** `find -type d` chạy trước và `head -1` cắt phần còn lại, nên `mkdir src/domain/place-order` cạnh `place-order.js` là DoD nhảy từ "1 cảnh báo" sang **"sạch, 0 cảnh báo"**. Thư mục rỗng đó không ai dựng cố ý: `git mv <slug>/index.js <slug>.js` để lại đúng như vậy vì git không theo dõi thư mục rỗng — refactor bình thường là dính. Giờ gộp mọi đường dẫn khớp, quét hết, và **đếm số file thật sự đọc được**: 0 file là "không biết", không phải "sạch".
- **Dòng nhắc Open Question không chạy.** Regex cũ đòi chữ "Open Question" nằm ngay trên dòng gạch đầu dòng, trong khi spec viết nó là tiêu đề mục còn các câu là `- [ ]` bên dưới. Tách làm hai điều kiện.
- **Danh sách đuôi file đổi từ CHO PHÉP sang LOẠI TRỪ.** Danh sách cho phép bỏ sót `.sql` (migration, ràng buộc CHECK), `.sh`, `.tf`, `.ex`, `.scala`, `.dart`, `.lua`… — đúng những chỗ hay chứa số nghiệp vụ. Sai sót giờ nghiêng về chặn nhầm thay vì bỏ lọt. File không có phần mở rộng (Makefile, Dockerfile) không tính, để repo chưa có code không bị chặn oan.
- **`uc_test_dir` là ĐOÁN thì phải nói.** `tests/` · `__tests__/` · `spec/` là ba quy ước khác hẳn nhau; đoán trượt thì `ac-coverage` mù mà không ai biết. Init in `!` khi thư mục test suy ra chưa tồn tại, thay vì ghi lặng vào config.
- Nhãn `trace-ratio` khử trùng đường dẫn (`app, lib, lib` → `app, lib`). `close-check` không còn rỉ `fatal: no commits yet` ở repo mới.

**#6 chưa đóng.** Chuỗi rác ở dòng ② sống sót qua bản vá 1.4.1, và lần này `is_semver` — **neo hai đầu** `^[0-9]+\.[0-9]+\.[0-9]+$` — đã cho qua, `od -c` không in gì. Nghĩa là **biến sạch, hiển thị hỏng**; giả thuyết "version hợp lệ cộng đuôi rác" của 1.4.1 cũng sai. Manh mối còn lại: chỉ dòng có `→` và `…` sát số mới hỏng, còn bảng của `version-check` (version trước, nhãn sau) chưa hỏng lần nào. Bản này bỏ hết ký tự nhiều byte khỏi dòng ② và in `od -c` **vô điều kiện** một lần để lần bump sau có vật chứng thay vì giả thuyết thứ tư.

## 1.5.0 — 2026-09-08
`.sdd/config` — bỏ giả định `src`/`tests`. Đóng #2. Kèm hai lỗi `close-check` do runxops-2c báo.

- **Lỗ chính:** `src|tests` viết chết ở 6 chỗ. Repo đặt code ở `app/` thì `commit-msg` không thấy code nên **cho qua mọi commit không ID, không cần marker gate**, `pre-commit` cho trộn spec với code, hai con số đếm ra `0/0`. Không một dòng cảnh báo. README quảng cáo "không có cờ bỏ qua" — hoá ra không cần cờ, chỉ cần đặt code sai chỗ.
- **`.sdd/config`** sinh một lần lúc init bằng cách dò repo (`src app lib cmd internal pkg apps packages source`), **không** nằm trong `templates/project` nên `init --update` không bao giờ ghi đè — đây là nội dung của dự án. Mặc định `src`/`tests` giữ nguyên hành vi cũ cho repo đang chạy.
- **Githook parse config bằng shell thuần** (`sed -n 's/^key=//p'`), không cần `lib.sh` — hook chạy `bash` trần, không có `${CLAUDE_PLUGIN_ROOT}`.
- **Config sai thì chặn, không chỉ cảnh báo.** Phân biệt "repo chưa có code" với "config sai" bằng chính danh sách file đang stage: có file nguồn mà không thư mục nào trong `code_paths` tồn tại → `✗`, kèm tên file. Có file nguồn nằm ngoài `code_paths` trong khi thư mục vẫn tồn tại → `!`.
- **`0/0` đọc như "sạch" chứ không như "mù".** `trace-ratio` in `? — repo có file nguồn nhưng không commit nào đụng: <paths>`; `ac-coverage` in `?` khi thiếu `uc_test_dir`. `/sdd-solo:status` in mục `=== .sdd/config ===` khi lệch.
- **`close-check`: soi rule ngầm chỉ chạy khi slug là THƯ MỤC.** `src/domain/place-order.js` (file) thì không tìm ra, in `!` rồi đóng được — mà đặt file là cách phổ biến hơn, nên với phần lớn dự án bước này chưa bao giờ chạy. Giờ tìm cả file lẫn thư mục; đã có `feat(UC-###)` mà vẫn không tìm ra thì là `✗`, không phải `!`.
- **`close-check`: grep literal bỏ sót số trong object literal.** Bắt `> 20` nhưng bỏ `holdMinutes: 15` — đúng loại đắt nhất, vì spec ghi Open Question còn code đã âm thầm điền số. Mở rộng sang số sau `:` `,` `(` `=`, trừ chỉ số mảng, số một chữ số, chuỗi và số version. Thêm nhắc khi UC còn Open Question mà code đã có literal.

Cả 4 test của runxops-2c đã chạy lại trên bàn thử layout `app/` + `lib/__tests__/`: test 1 chuyển từ lọt sang chặn, test 2 và 3 chặn đúng, test 4 chuyển từ `0/0` sang `?`.

## 1.4.2 — 2026-09-08
Hai lỗi ở nhánh `--remote`, do session runxops-2c báo.

- **Cache 24h phục vụ số thiu, không có đường thoát.** TTL hợp lý cho người dùng, sai hẳn cho tác giả bump ba lần trong một buổi. Thêm `--no-cache`, và quan trọng hơn: **cache tự biết mình thiu** — nếu bản cục bộ đã vượt số trong cache thì cache chắc chắn cũ, hỏi lại ngay dù còn hạn. Không phải nhớ gõ cờ.
- **`✓ không lệch` mâu thuẫn với bảng nó vừa in.** Khe ① chỉ bắt chiều "GitHub mới hơn"; chiều ngược bị bỏ. Mà chiều ngược có nghĩa thật: **cục bộ mới hơn GitHub = có bản chưa push**. Giờ in `!`. Im ở đây đúng là loại hỏng im lặng mà cả file này sinh ra để chống.
- Chỉ nhận số từ GitHub khi đúng dạng semver, nên không ghi rác vào cache.

Khe ④ của 1.4.0 đã được xác nhận chạy đúng end-to-end trên repo thật: session mới, hook ghi cache, bảng ra đủ bốn dòng có số.

## 1.4.1 — 2026-09-08
Bản vá "chuỗi rác" ở 1.3.0 không giữ được. Lần này tìm ra vì sao, và bịt đúng chỗ nguy hiểm.

- **Glob `[0-9]*.[0-9]*` của 1.3.0 quá lỏng.** Nó CHO QUA `1.4.0<rác>` nên không bao giờ đọc lại. Giá trị hỏng là **version hợp lệ cộng đuôi rác**, không phải rác hoàn toàn — điều đó giải thích trọn bộ triệu chứng: `vcmp 1.3.0 "1.4.0junk"` ra `-1` (vì `awk` tách theo `.` rồi `+0`, nuốt đuôi), nên nhánh update **vẫn chạy và vẫn ra quyết định đúng**, chỉ có dòng in là xấu.
- **Chỗ nguy hiểm không phải dòng in, mà là `vcmp` ăn giá trị không tin được** — lần này quyết định đúng do may. Thêm `is_semver` (neo hai đầu `^[0-9]+\.[0-9]+\.[0-9]+$`) và `clean_ver`; mọi giá trị đi vào so sánh đều lọc trước, không khớp thì thành `-`.
- **`update.sh` không đọc được version marketplace thì bỏ qua bước ②** kèm lệnh làm tay, thay vì đi tiếp. Cùng nguyên tắc "không có dữ liệu thì in `?`, không đoán" của khe ④.
- **Cài dụng cụ đo:** không khớp thì `od -c` ra bytes. Hai giả thuyết trước — output ANSI của `claude plugin`, và đọc trúng file viết dở — đều đã **bác bỏ bằng thực nghiệm** (output không có ESC/CR; file cắt dở cho ra rỗng chứ không ra rác). Nguồn của đuôi rác vẫn chưa biết; lần sau sẽ có bytes để lần.
- `version-check.sh` chỉ nhận version từ GitHub khi đúng dạng semver, nên không ghi rác vào cache 24h.

Lỗi do session runxops-d0 báo về, kèm nhận xét đúng trọng tâm: giá trị hỏng chỉ dùng để in, nhưng nếu `vcmp` cũng ăn nó thì có ngày quyết định sai trong im lặng.

## 1.4.0 — 2026-09-08
Khe thứ tư: phiên Claude Code đang mở. Lỗi do một session khác báo về.

- **`✓ không lệch` từng nói dối đúng lúc nguy hiểm nhất.** Vừa `/plugin update` xong, `.sdd/` đã mới, mọi thứ trên đĩa đều khớp — nhưng phiên đang mở vẫn chạy code nạp lúc mở. Gõ `/sdd-solo:gate` là nhận logic cũ. Bảng cũ không có dòng nào cho chỗ đó.
- **Nhãn cũ "plugin đang chạy" nói quá.** Nó là version của bản mà *script đang nằm trong*, chỉ đúng nghĩa "đang chạy" khi gọi qua skill. Gọi thẳng bằng đường dẫn — như `update.sh` vẫn làm — thì nó là bản mới, trong khi phiên vẫn là bản cũ. Đổi thành **`bản đã cài`**, đọc từ `installed_plugins.json` cho đúng nguồn.
- **Thêm dòng `phiên này đang chạy` và khe ④.** Không lệnh nào sửa được khe này, chỉ mở session mới.
- **Cách biết phiên nạp bản nào:** hook SessionStart chạy *từ* thư mục plugin mà phiên thật sự nạp — chỗ duy nhất biết điều đó — nên nó ghi version ra `${XDG_CACHE_HOME:-~/.cache}/sdd-solo/session-$CLAUDE_CODE_SESSION_ID`, dọn file quá 7 ngày. Không biết thì in `—`, không đoán.
- **`CLAUDE_PLUGIN_ROOT` không phải env var** — nó là token Claude Code thay trong `hooks.json` và `SKILL.md`. `env | grep CLAUDE` không có nó. Đề xuất ban đầu định đọc biến này; dùng `CLAUDE_CODE_SESSION_ID` (có thật trong env) mới chạy được.
- `update.sh` lấy dòng "phiên này đang chạy" từ cùng nguồn, thôi suy từ đường dẫn script.

## 1.3.0 — 2026-09-08
`/sdd-solo:update` — một lệnh thay ba.

- **`scripts/update.sh`** chạy đúng thứ tự và **chỉ những khe đang lệch**: `claude plugin marketplace update` → `claude plugin update` → `scaffold --update`. Cả ba gọi được từ bash nên không cần gõ slash command.
- **Dùng `scaffold.sh` của bản VỪA CÀI, không phải bản đang chạy.** Đường dẫn lấy từ `installed_plugins.json`. Nếu chạy scaffold của bản cũ thì dự án nhận template cũ — đúng thứ mà `/plugin update` rồi `init --update` bằng tay hay dính.
- **Nói thật về giới hạn:** bản mới không áp vào phiên đang mở. Claude Code cũng vậy (`claude plugin update` in sẵn *"restart required to apply"*). Nên cuối script in bảng ba dòng — bản đã cài · `.sdd/` · phiên này đang chạy — và bảo mở session mới.
- Không gọi lại `version-check.sh` ở cuối: sau update thì `.sdd/` mới hơn phiên đang chạy, nó sẽ báo động giả "plugin bị hạ cấp".
- `jver`/`vcmp`/`mkt_of`/`mkt_field` chuyển lên `lib.sh` dùng chung.
- Đọc `marketplace.json` ngay sau khi làm mới clone có lần ra chuỗi rác — nghi đọc trúng lúc file đang được ghi. Kiểm dạng semver, không đúng thì đọc lại một lần.

Đã chạy thật: bản cài 1.0.0 → 1.2.0 trong một lệnh.

## 1.2.0 — 2026-09-08
`version-check.sh` — cảnh báo khi đang chạy bản cũ. Dựng trước 2.0.0 vì bản đó chép `scripts/` vào dự án, cần sẵn cái này để bắt trôi version.

- **Không phải một chỗ lệch mà là chuỗi bốn mắt xích:** `GitHub ──①──▶ marketplace đã tải ──②──▶ plugin đã cài ──③──▶ .sdd/ của dự án`. Mỗi khe một lệnh sửa khác nhau (`/plugin marketplace update` · `/plugin update` · `/sdd-solo:init --update`), nên script chỉ đúng lệnh cho đúng khe thay vì bảo chạy cả ba như CLAUDE.md trước đây.
- **Khe ① không thấy được nếu không hỏi mạng.** Đo trên máy thật: mọi file cục bộ nói "khớp 1.0.0" trong khi GitHub đã có 1.1.0. Nên `--remote` hỏi `raw.githubusercontent.com` (0.6s, chặn cứng bằng `curl --max-time 3` vì macOS không có `timeout(1)`), nhớ kết quả 24h ở `${XDG_CACHE_HOME:-~/.cache}/sdd-solo/remote-check`.
- **Hook SessionStart không bao giờ gọi mạng** — chỉ so ② ③. Hook có `timeout: 10`, mà github.com đã từng timeout 75 giây; một lần như thế là mọi session mở ra đều treo.
- **`gate-check.sh` không gọi version-check.** Cổng DoR đo chất lượng spec; cho version làm rớt cổng là thêm lý do chặn không liên quan tới spec.
- Bắt thêm chiều ngược: `.sdd/` **mới hơn** plugin đang chạy → repo init bằng bản dev, hoặc plugin bị hạ cấp.
- Lệch major in ✗, minor/patch in `!`.
- Đọc metadata từ `installed_plugins.json` và `known_marketplaces.json` của Claude Code thay vì glob mò đường dẫn.
- So semver bằng awk (bash 3.2, đúng cả `1.0.9 < 1.0.10`). Bảng in version trước nhãn sau, vì `printf %-8s` đệm theo byte nên nhãn tiếng Việt có dấu làm lệch cột.

## 1.1.0 — 2026-09-08
`deps-check.sh` và `/sdd-solo:init --with-deps` — mục (a) (b) của #1. Xong #1.

- **`scripts/deps-check.sh`** — kiểm Spec Kit (lệnh `specify`, `.specify/`, spec-template đã thay chưa, đủ 4 lệnh `/speckit-*`), AIUP (`aiup-core` trong cache plugin), Camunda Modeler (chỉ macOS). Mỗi ✗ kèm lệnh copy-paste đúng. Exit 1 nếu thiếu.
  Kiểm được cả **cái bẫy thứ tự**: `.specify/` có nhưng spec-template vẫn là bản gốc → dấu hiệu đã chạy `specify init` SAU `/sdd-solo:init`, mà lần init sau không nhắc lại nữa. Trước đây chỗ này hỏng im lặng.
- **`/sdd-solo:init --with-deps`** — chạy `deps-check.sh --fix`: `specify init` (đủ cờ non-interactive), `claude plugin marketplace add` + `install aiup-core`, rồi tự chạy lại `scaffold --update` để thay spec-template. Sau khi cài thì **tự kiểm lại từ đầu** thay vì tin bộ đếm, nên dòng tổng kết không nói dối. Không có cờ thì hành vi y như cũ: chỉ nhắc, không đụng vào máy — đúng ranh giới trong CLAUDE.md.
  `--fix` không cài lệnh `specify` (cần `uv`), chỉ in `uv tool install specify-cli --from git+https://github.com/github/spec-kit.git`.
- **`/sdd-solo:status`** in mục `=== Phụ thuộc ===` khi thiếu, im khi đủ.
- `trace-ratio.sh`: repo chưa có commit nào thì `git log` in `fatal:` ra stderr giữa output init. Nuốt đi.
- **Đính chính 1.0.1:** mục cuối ghi đã sửa `<github-user>` trong `plugins/sdd-solo/README.md` — thực ra chưa, lệnh sửa nằm sau một bước fail nên không chạy. Sửa ở bản này.

## 1.0.1 — 2026-09-08
Sửa tên lệnh Spec Kit và cách cài phụ thuộc — phần (c) của #1. Không đổi hành vi script.

- **Tên lệnh Spec Kit sai ở 10 file.** Spec Kit 1.0.5 cài skill với tiền tố `speckit-`: `/specify` `/plan` `/tasks` `/implement` thật ra là `/speckit-specify` `/speckit-plan` `/speckit-tasks` `/speckit-implement`. Gõ tên cũ không ra gì.
  Nặng hơn tài liệu: **cả hai tầng chặn mềm đều gọi sai tên nên không chặn được**. `templates/CLAUDE.md.tmpl` và `scripts/session-start.sh` dặn AI "không chạy `/specify` cho UC chưa qua cổng" — user gõ `/speckit-specify`, không khớp danh sách cấm, AI chạy tiếp. Sửa ở: README (2 bản), `CLAUDE.md.tmpl`, `session-start.sh`, `gate-pass.sh`, `skills/` (sdd-process, gate, init), `templates/speckit/spec-template.md`, playbook.
- **URL AIUP không cài được.** `add ai-unified-process/marketplace` sai hoa thường (thật là `AI-Unified-Process`) và dạng `owner/repo` rơi sang SSH → `Permission denied (publickey)` trên máy chưa có SSH key. Đổi sang URL https đầy đủ, và `install aiup-core@ai-unified-process-marketplace`.
- **`specify init --here` treo trong session agent** vì hỏi tương tác. Đổi thành `specify init --here --force --non-interactive --integration claude`.
- **Nói rõ thứ tự bắt buộc:** `specify init` chạy TRƯỚC `/sdd-solo:init --update`. Ngược lại thì spec-template mỏng không được cài, và lần init sau không nhắc lại nữa vì nó chỉ cảnh báo khi thiếu `.specify/` — hỏng im lặng.
- `plugins/sdd-solo/README.md` còn ghi `add <github-user>/sdd-solo` — sửa thành `quangman2211`.

Còn lại của #1: `deps-check.sh` và `--with-deps` (mục a, b) để bản 1.1.0.

## 1.0.0 — 2026-09-07
- Bản đầu: 8 skill (sdd-process, init, start, adversarial, gate, close, state, status), hook SessionStart, git hooks, scaffold có manifest, template dự án, spec-template mỏng cho Spec Kit, playbook mẫu.

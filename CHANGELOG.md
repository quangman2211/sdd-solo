# Changelog

## 8.4.0 — 2026-09-24

### P-52 — hoá ra `pass.sh` chưa bao giờ kiểm gì cả

A đề nghị một cờ cho phép agent chạy `pass.sh gate|close` **kèm** ba bằng chứng bắt buộc. Đo trước khi làm thì
tiền đề của cả hai bên đều hụt một chỗ: đầu `pass.sh` ghi *"run AFTER the matching check exits 0"* và **nó tin
người gọi** — không nhánh nào gọi `gate-check` · `close-check` · `change-check`. Ca kiểm 57 dựng lại được: xoá
hẳn mục `## Acceptance Criteria` của UC-001, `gate-check` đỏ, rồi `pass.sh gate UC-001` **vẫn đóng dấu**
`.sdd/gate/UC-001.ok` — và githook `commit-msg` tin đúng cái dấu đó để cho `feat(UC-001)` đi qua.

Nghĩa là thứ giữ marker trung thực không phải phím bấm của chủ dự án, mà là **văn skill** người ta đọc rồi làm
theo. Luật "chỉ người thật được gõ" không mua được một phép kiểm nào; ở runxops 24/09 nó mua **5 tiếng chờ**
(03:30 → 08:50) trên một UC đã xanh. Đúng lập luận 6.0.0 đã dùng để bỏ cửa "qua đêm" (#38): một đêm đo thời
gian trôi, một phím bấm đo sự có mặt, không cái nào đo việc đã-kiểm.

Nên tách làm hai thứ A đang gộp:

**(1) `pass.sh` tự chạy phép kiểm tương ứng và từ chối khi có ✗ — cho mọi người, không cờ nào.** Đây là **siết**,
không phải nới: nó bịt một lỗ đang mở cho cả chủ dự án. Không có cờ bỏ qua và không có biến môi trường, y như
`gate-check`. `deprecate` **cố ý miễn**: bỏ một UC không được đòi nó xanh — không xanh thường chính là lý do bỏ.

**(2) Ai được ký là câu hỏi riêng**, và nó là **chính sách đội agent** nên ở `.sdd/roles`, không ở `.sdd/config`:
`A.ky=gate close`. **Bật hai chiều**: repo không khai dòng `.ky` nào thì hành vi y hệt hôm nay, có dấu vai hay
không cũng vậy — repo một người không đổi một byte. Có một dòng `.ky` thì repo đã nói "chữ ký là một quyền có
khai báo", và phiên nào suy ra được vai mà không được liệt kê thì bị từ chối. Phiên **không** suy ra được vai
vẫn qua — đó là chủ dự án ở một checkout không đánh dấu, và plugin không phân biệt được người với agent.

Có (1) rồi thì (2) không còn là "tin agent đã kiểm" — máy kiểm — mà chỉ là **ghi lại ai bấm một cái nút đã
được xác minh**. Marker thêm dòng `signed-by:` (dòng 1 vẫn **đúng hash**, không gì đọc nội dung file này) và
commit cổng thêm đuôi `Vai:` trong thân. **Chủ đề commit không đổi một ký tự** — `gate-check` §9 và githook
nhận commit theo chủ đề, có ca kiểm giữ.

**Một lỗ A không nêu, và nó nghiêm trọng nhất:** `.sdd/roles` mẫu cho `A.ghi=… .sdd/**`, tức agent điều phối
ghi được chính file cấp quyền cho nó. **Uỷ quyền tự cấp thì không phải uỷ quyền.** `.sdd/roles` giờ nằm trong
`A.cam`. Repo `doc_lang=vi` không nhận thay đổi khuôn (P-45) nên phải sửa tay — và nên sửa **trước** khi khai
`.ky`.

**"0 ✗ ngoài dòng marker" không cần thành ngoại lệ.** Em chạy `close-check.sh UC-031` trên runxops thật, chỉ
đọc: `CAN BE CLOSED (3 warnings)`, 0 ✗. Cái ✗ lúc 03:30 là dòng 9 — *"no .sdd/gate/UC-031.ok marker"* — tức
close-check đỏ **vì cổng chưa đóng dấu**. Đó là thứ tự, không phải xung đột: chạy gate trước thì close-check tự
xanh. Khoét ngoại lệ vào đúng dòng marker sẽ là một lỗ im lặng, và không cần khoét.

**Cái vỡ, nói thẳng:** ca 20 của bộ test đỏ ngay — nó sửa một AC *sau* cổng rồi đóng, đúng thứ close-check §9
vẫn luôn gọi là sai. Đó là tính năng chạy đúng. Trạng thái ấy chỉ repo đóng bằng bản cũ mới có, nên ca tự dựng
nó (`close_cu` trong chính file ca). Đây là giàn giáo của bộ test, **không** phải cửa thoát của plugin.

### P-50 — `queue.sh done <key> --theo-phieu #n`

Việc kết `ket=chan hoi=#n` rồi được phiếu giải quyết thì tới 8.3.0 không có đường đóng: `done` đòi một
`ket=xong` mới (phải giao lại agent chỉ để sinh ra nó) và `stop` đòi tên điểm dừng (nó không dừng, nó xong).
`--theo-phieu` là **hình dạng bằng chứng thứ hai, không phải miễn trừ**: phiếu #n phải mang dấu `Đã áp` do
`phieu.sh close` đóng vào **file** (8.3.0) — mà `close` chỉ đóng dấu sau khi đếm F#/K# trên file và đòi đủ
KETQUA của mọi vai trong `Cho:`. File phiếu thành neo. "Thời gian trôi không phải bằng chứng" vẫn nguyên.

### P-51 — lời giao bảo IN, không bảo gửi

Mục 6 viết *"send exactly that KETQUA line back to the coordinator"*. Đọc đúng chữ, agent hiểu là nhắn sang
phiên khác — đo được: một vai trọng tài gửi `KETQUA key=r-214` vào **phiên repo plugin** lúc 02:47, nơi không
có hàng đợi và không có phiếu #214. Giờ: *"PRINT that KETQUA line as the first line of your last message IN
THIS SESSION … Do not send it to another pane or session"*. File KETQUA dưới `git-common-dir` mới là kênh, và
nó dựng ra đúng cho việc này (P-26).

### Một dòng dọn

`hooks.json` đặt `${CLAUDE_PLUGIN_ROOT}` trong nháy kép (8.3.0 đã làm, ghi lại cho đủ).

### Test

Hai ca mới: `57-pass-tu-kiem` (12 phép, **6 đỏ trên 8.3.0** trước khi sửa — gồm cả việc đóng dấu lên UC không
còn AC) · `58-done-theo-phieu` (7 phép). Ca 20 và ca 42 đổi theo, đều vì luật đổi chứ không vì ca sai.
Bộ test: **58 ca · 313 PASS · 0 FAIL**.

## 8.3.0 — 2026-09-24

### P-49 — mục lục phiếu thôi làm nguồn, nó được SINH RA

Tới 8.2.0 `phieu.sh new` nối một dòng vào `notes/hoi-dap/hoi-dap.md` ở bất cứ đâu nó chạy, còn R sửa cột Trạng
thái của một dòng cũ trên `main`. **Hai người ghi, một bảng.** Đo ở runxops: mỗi lượt
`git merge --no-ff soi/uc-031` xung đột ở đúng file đó và A gộp tay (`cb380e3a`, lượt 2 và 3 của UC-031).
Không ai ghi sai cả — cái sai là file có hai người ghi.

Ca kiểm 56 **tái hiện đúng lỗi đó trên 8.2.0** trước khi sửa: `CONFLICT (content): Merge conflict in
notes/hoi-dap/hoi-dap.md`. Đó là phép đo, không phải suy đoán.

`queue.sh` đã trả lời câu hỏi này ở 7.3 — chỉ checkout chính ghi bảng, agent ghi KETQUA, bảng suy ra từ đó.
Bản này làm y hệt, thêm một bước: **mục lục không còn được ghi nữa, nó được tính**.

- `phieu.sh new` ở **worktree phụ**: commit file phiếu, **không đụng mục lục**. Số vẫn an toàn — `max_n` lấy max
  của ba nguồn, và hai nguồn sống sót đúng là hai nguồn xuyên worktree: tên file, và `git log --all` đọc kho
  object mọi worktree dùng chung. Mục lục thật ra là nguồn **yếu nhất** ở đây, vì nó chính là cái cũ trong một
  worktree chưa merge. P-21 không yếu đi một chút nào, có ca kiểm giữ.
- `phieu.sh muc-luc --gom`: dựng lại mọi dòng từ file phiếu, **chỉ chạy ở checkout chính** (chạy ở nhánh vai
  chính là cái ghi sinh ra xung đột, nên nó từ chối và nói vì sao). Văn phía trên bảng không bị đụng.
- **Cột Trạng thái suy từ file**: `mở` → `đã trả lời` khi ô `**Trả lời (R):**` hết chỗ giữ chỗ `<…>` → `đã áp`
  khi `close` **đóng dấu vào FILE**. Dấu ấy là dòng mới ở cuối phiếu, vì `đã áp` là trạng thái duy nhất không
  đọc được từ phiếu: nó là kết luận của `close` (đếm F#/K# trên file + đủ KETQUA của mọi vai trong `Cho:`).
  Không có nó thì "file là nguồn duy nhất" chỉ đúng gần hết, mà gần hết là chỗ mọi thứ trôi trở lại.

**Cái mất, nói thẳng:** dòng mục lục sửa tay sẽ bị lần `--gom` sau ghi đè — đó là chủ ý, nhưng nếu đội đang ghi
chú gì trong ô Việc thì phải chuyển vào file phiếu trước. Và phiếu tạo ở worktree phụ **vô hình với
`phieu.sh list --mo` ở main cho tới khi merge**; A biết số qua dòng `KETQUA ket=chan hoi=#n`, đúng kênh đã thiết
kế cho việc đó.

**Bẫy đã trả giá, ghi lại vì nó sẽ lặp:** `kw('p_ans')` trả về `Trả lời (R)|Answer (R)` — **dấu ngoặc đó là
nhóm regex**, nên mẫu ghép thẳng khớp `Trả lời R:`, thứ không phiếu nào viết, và **mọi phiếu đọc ra "còn mở"**.
Mẫu dựng từ `kwAlts()` rồi escape từng vế. Từ khoá có siêu ký tự thì `kw()` không dùng thẳng được.

`.sdd/roles` mẫu: thêm `notes/hoi-dap/phieu/**` vào vùng ghi của D và T. Một vai mà hợp đồng bảo "viết phiếu rồi
dừng" thì phải ghi được phiếu; thiếu dòng này, ngày bật `vai_bat_buoc` là ngày `phieu.sh new` của D/T bị chặn —
đúng lúc agent không còn đường nào khác để báo gì. **Repo `doc_lang=vi` không nhận thay đổi khuôn này** (P-45,
8.1.1) nên phải tự thêm bằng tay.

### Ghi chú herdr · README — `/clear` không nạp lại plugin

`/clear` xóa ngữ cảnh nên phiên *trông như* mới, nhưng mã plugin nạp lúc mở phiên và ở nguyên bản đó tới khi
phiên kết. Khe ④ của `version-check` báo đúng; người đọc tưởng `/clear` là xong. Ca thật ở runxops lúc 02:34:
một agent từ chối việc vì phiên còn 8.1.0 trong khi mọi thứ trên đĩa đã mới. Ghi một dòng ở
`references/herdr-traps.md` và một ở README mục "Đang chạy bản nào". (`/exit` không đóng pane đã ghi từ 8.2.0.)

### Một dòng dọn kèm

`hooks.json`: đường dẫn `${CLAUDE_PLUGIN_ROOT}` của hook SessionStart giờ nằm trong dấu nháy kép — `claude plugin validate`
cảnh báo từ trước bản này: cài plugin vào thư mục có dấu cách thì lệnh tách làm nhiều từ và hook im lặng không chạy.
Chỉ thêm hai dấu nháy, **không** đổi sang dạng `args` — đây là hook mọi phiên phụ thuộc, và đổi cơ chế chạy
của nó để chữa một lỗi chưa ai gặp là đổi một rủi ro nhỏ lấy một rủi ro to hơn.

### Test

Ca mới `56-muc-luc-gom`, 13 phép, đã kiểm là **đỏ trên 8.2.0** (4 phép đỏ, trong đó có chính dòng xung đột merge).
Bộ test: **56 ca · 293 PASS · 0 FAIL**.

## 8.2.0 — 2026-09-24

Hai mục runxops ghi trong ngày, **cả hai không chặn gì** — đều là chỗ cơ chế vai 7.2/7.3 thiếu một nửa.

### P-48 — `--worktree` có lượt đi, không có lượt về

`role.sh --worktree` dựng worktree cộng nhánh `<V>.nhanh`, và tới 8.1.1 không có lệnh ngược nào; chuỗi chuẩn
§4 của `orchestrate` kết ở `/sdd-solo:close` rồi hết. Đo ở runxops 24/09: **4 workspace + 18 nhánh**
`code/`·`test/` của UC-016…030 còn sót sau close, và **chủ dự án tự phát hiện** — không phép kiểm nào hỏi.

`role.sh --don UC-### [--dry-run]`: gỡ các worktree của UC đó theo `<V>.nhanh`, `worktree prune`, xoá các nhánh
tương ứng. Cộng một dòng "dọn làn" ở cuối §4 và một dòng ở `references/herdr-traps.md`: **`/exit` không đóng
pane** — nó kết phiên và trả pane về shell, pane vẫn còn; ai mở pane thì người ấy đóng, plugin không cấp runner.

**Không có `--force`, và đó là cả thiết kế.** `git worktree remove` từ chối worktree còn file chưa commit hoặc
chưa theo dõi; `git branch -d` từ chối nhánh chưa hợp nhất. Hai lời từ chối ấy được giữ nguyên và **nêu tên**,
rồi lệnh thoát 1. Một cái làn không xoá được là một cái làn còn thứ gì đó trong đó — đó là việc phải nhìn, không
phải chướng ngại phải vượt. Nhánh không có `*` trong mẫu (vai spec giữ `main`) thì không bao giờ bị đụng.

### P-47 — lời giao coi mọi vai là vai ÁP, kể cả vai TRẢ LỜI

`role.sh R <phiếu>` in mục 1 *"áp đúng phần Cho: R"* và mục 3 rỗng. Lý do đơn giản đến mức dễ bỏ qua: **R là
vai viết ra `Cho:`**, nên lúc R nhận việc thì phiếu chưa có `Cho:` nào để áp. A phải viết tay mọi lời giao cho R.

Vai có `<V>.commit=khong` giờ nhận **khuôn trả lời**: xếp mức từng `K` L0–L3 · tra nguồn `file:line` (không nguồn
thì không phải L0) · viết ô `Trả lời (R):` cộng một dòng `Cho:` mỗi vai · **không commit** (A commit) ·
`KETQUA neo=<file phiếu>` chứ không phải hash. Mục 3 liệt kê các khối `**K#**` của phiếu, rơi về dòng `Câu:` khi
phiếu chỉ có một câu. Mục 2 trỏ thêm sổ hỏi để tra bảng bốn mức. Và một câu nói thẳng: **L3 thì R không quyết** —
soạn 2–4 lựa chọn cho chủ dự án, luôn kèm "Chưa quyết — ghi Open Question".

Công tắc là `commit=khong`, **không phải chữ R**: plugin giữ cơ chế, repo giữ tên vai (7.2) — một repo gọi trọng
tài là gì cũng được. Vai `commit=co` nhận đúng khuôn áp như cũ, có ca kiểm giữ chiều đó.

### Test

Hai ca mới, cả hai đã kiểm là **đỏ trên 8.1.1** trước khi sửa (7/8 và 6/8 phép đỏ, trên một worktree ở `HEAD`):
`54-loi-giao-tra-loi` · `55-don-lan`. Bộ test: **55 ca · 280 PASS · 0 FAIL**.

## 8.1.1 — 2026-09-24

Hai lỗi runxops gặp trong ngày, ghi ở `notes/sdd-solo-issues.md` mục **P-46** và **P-45**.

### P-46 — `rr_undecided` đếm chữ đã chết, và ở trần 8.0.0 đó là cổng đỏ không có cách gỡ

`lib.sh rr_undecided()` grep `→ Chưa quyết` trên **cả dòng**. Sổ đọc lại là sổ **chỉ-thêm**: một phát hiện đã
được giải quyết vẫn giữ nguyên chữ cũ và mang câu trả lời ở đuôi — `→ Chưa quyết (chờ chủ dự án) → **sửa v4**`.
Đếm cả dòng thì nó là "Chưa quyết" vĩnh viễn.

Tới 7.8 điều đó chỉ làm sai một con số trong lời cảnh báo. **8.0.0 biến nó thành một cái chặn**: chạm trần
`rr_max` mà còn tồn đọng thì cổng đỏ, và trần là một điểm DỪNG — thêm một vòng không mở được. Nên nước duy nhất
còn lại là sửa lời cũ, tức là đúng thứ luật sổ chỉ-thêm cấm. Đo ở runxops: UC-031 đủ 3 vòng, 13 dòng `F#`,
**11 đã trả lời**, đếm tay đuôi sống = 2, cổng in *"13 Undecided, ceiling reached"*.

`rr_tail()` — "chỉ đuôi sống mới tính" — đã có từ 7.4 (P-37) và §7 của `gate-check` đã dùng nó cho vòng quét ID.
`rr_undecided` là chỗ duy nhất còn lại đọc phần chữ đã chết. Giờ nó đi qua cùng phép rút gọn: bỏ `` `…` ``, bỏ
`(…)` lồng nhau, lấy phần sau mũi tên **cuối**. Sửa một hàm là sửa cả bốn chỗ gọi — `gate-check` §8 (trần) và
§9 (`rr_warn`), `change-check` §8, `status.sh`.

Lỗi này là của 8.0.0, không phải của runxops: 8.0.0 dựng một cái chặn lên trên một phép đếm đã sai sẵn.

### P-45 — `init --update` áp bản dịch tiếng Anh lên nội dung tiếng Việt của dự án

7.8.0 chuyển vỏ plugin sang tiếng Anh và hứa repo đang chạy **không đổi một byte**. Với `.sdd/config` và các
script thì đúng; với `templates/project/` thì không, vì đó là **nội dung**. Ở runxops, `init --update` ghi đè
thẳng 3 file (khối `CLAUDE.md` · `specs/adr/_adr-template.md` · `specs/core/br-000/br.md`) và sinh 11 file
`.new` là khuôn tiếng Anh trống, không có gì để gộp.

Đo phía plugin trước khi sửa: cả diff `templates/project` từ 7.7.0 (`761d519`) tới 8.1.0 là **thuần dịch** —
0 file mới, 0 mục mới; khối `CLAUDE.md` 29 dòng trước và sau, 23 dòng đổi lấy 23 dòng. Nên phía dự án không
được gì cả, mà mất cả một repo tiếng Việt.

Từ 8.1.1, `doc_lang != en`:

- file **đã có** thì để nguyên — không ghi đè, không `.new`; `scaffold` ghi lại sha khuôn mới vào manifest nên
  lần sau không hỏi lại.
- file **thiếu** thì vẫn tạo (tiếng Anh vẫn hơn là không có), và dòng đầu của `scaffold` nói rõ điều đó.
- khối giữa `<!-- sdd-solo:begin/end -->` giữ nguyên.
- `migrate --trace` viết mục con trỏ theo `doc_lang`: `## Dấu vết` + văn tiếng Việt, và tiêu đề file cạnh cũng
  vậy. Tới 8.1.0 nó viết `## Evidence` cùng hai câu tiếng Anh vào 20 thân UC/proposal tiếng Việt. Cổng đọc được
  **cả hai cách viết** — `kw trace` là nhóm song ngữ — nên repo đã trót nhận mục tiếng Anh không cần sửa gì.

Cách chọn ngược lại là `doc_lang=en` trong `.sdd/config`, không có cờ nào khác. Giá phải trả, nói thẳng: một
repo `doc_lang=vi` từ đây **không nhận cập nhật khuôn nào nữa**, vì plugin không còn khuôn tiếng Việt để gửi.
Đổi lại là không bao giờ mất chữ trong im lặng. Cơ chế (`.sdd/scripts/` · `kw.tsv` · `js/` · githook) vẫn chép
vô điều kiện như cũ — nó là hành vi, không phải nội dung.

### Test

Hai ca mới, cả hai đã kiểm là **đỏ trên 8.1.0** (chạy bộ ca mới trên một worktree ở `HEAD`) trước khi sửa:
`52-duoi-song-chua-quyet` (5 phép, gồm bản tiếng Anh cho cùng verdict) · `53-doc-lang-khuon` (8 phép, gồm cả
chiều `doc_lang=en` vẫn ghi đè như cũ). Ca `47-trace-ben-canh` đổi theo: mục con trỏ giờ là `## Dấu vết` ở repo
tiếng Việt. Bộ test: **53 ca · 264 PASS · 0 FAIL**.

Chỗ còn lệch, biết và để lại: khuôn `templates/skel/use-case/UC-000.md` vẫn ghi `## Evidence` cho mọi dự án, kể
cả `doc_lang=vi` — khuôn là tiếng Anh từ 7.8.0 và cổng đọc được cả hai, nên đây là chuyện chính tả chứ không
phải chuyện verdict.

## 8.1.0 — 2026-09-23

**Nhánh loại trừ nhau của skill ra `references/`.** Kế hoạch ghi "rút gọn sáu skill nặng". Đo trước thì tiền đề
ấy **sai**: 157 KB skill, trong đó chỉ 4–11% là văn hậu nghiệm (và nó gánh việc — nó ngăn model "cải tiến" mất
một luật), 2,3% là trùng lặp giữa skill, còn lại là chỉ dẫn. Cắt chữ để đạt một con số dòng là cắt mất hành vi.

Cái đo được lại là chuyện khác hẳn: **các skill nặng vì chứa những nhánh loại trừ nhau, và mỗi lượt chạy nạp
hết cả hai.** `adversarial` có **87%** thân là tầng UC (12,1 KB) cộng tầng BR (7,0 KB) — một lượt dùng đúng một
tầng. `intake` **60%** là chế độ phỏng vấn (6,6 KB) cộng chế độ chuyển brief (7,4 KB). Phụ lục herdr của
`orchestrate` (2,5 KB) tự nó ghi *"not a dependency"*.

**Cơ chế đã kiểm, không suy đoán.** `skill-creator` của Anthropic nói rõ ba mức nạp: *metadata* luôn trong ngữ
cảnh → *`SKILL.md` body* nạp trọn mỗi lần skill chạy → *bundled resources* đọc khi cần, và với thư mục
`references/`: **"Claude reads only the relevant reference file."** Mười mấy skill chính thức trên máy đang dùng
đúng mẫu này. Nên đây là mẫu có sẵn của nền tảng, không phải sáng chế của plugin.

| Lượt chạy | trước | sau | |
|---|---|---|---|
| `adversarial BR-###` | 21.955 B | 11.192 B | **−49%** |
| `intake` (phỏng vấn) | 23.277 B | 17.099 B | −27% |
| `adversarial UC-###` | 21.955 B | 16.470 B | −25% |
| `intake <brief>` | 23.277 B | 17.823 B | −23% |
| `orchestrate` (không chạy herdr) | 20.738 B | 18.810 B | −9% |
| `verify UC-###` | 20.363 B | 18.915 B | −7% |
| `verify` (quét cây) | 20.363 B | 21.078 B | **+4%** |

Dòng cuối tăng thật, và nó là một đánh đổi có chủ ý: phần A của `verify` (vòng đọc lại một ID) **ở lại trong
thân** vì đó là lượt chạy thường xuyên; chỉ nhánh quét cây — hiếm — ra file riêng. Lượt hiếm cõng thêm 715 B
để lượt thường bớt 1.448 B. Ghi ra đây chứ không giấu: một bảng chỉ toàn dấu trừ là một bảng đã bị chọn lọc.

**Ba luật khi tách**, vì hỏng ở đây hỏng im lặng — `SKILL.md` vẫn hợp lệ, `plugin validate` vẫn xanh, chỉ là
model được bảo đọc một file không có, hoặc một file có thật mà không ai bảo đọc (luật biến mất):
① router phải **mệnh lệnh**, nêu đủ `${CLAUDE_PLUGIN_ROOT}/skills/<tên>/references/…` kèm đường lùi
`find ~/.claude/plugins …` — đúng khuôn skill đã dùng cho script từ 1.0.0; đọc hụt là mất trắng luật, không
phải chạy chậm hơn. ② tách xong **xoá hẳn** khỏi thân, không để hai bản trôi. ③ ca 51 giữ **cả hai chiều**.

**Hai chỗ cố tình KHÔNG tách**, và đây là phần khó hơn phần tách:
- `design` (139 dòng) là một mạch tuyến tính bảy bước — ai chạy cũng qua đủ, không có nhánh nào để cắt.
- `sdd-process` (21 KB, skill **model tự gọi**) — nó là *kiến thức nền*, và model gọi nó chính **vì** muốn khối
  kiến thức ấy. Tách ra là bắt đọc router rồi đọc tiếp: tệ hơn, không tốt hơn. Cám dỗ ở đây là tách file to nhất.
- Và **không rút ngắn `description`** — đó là thứ duy nhất nạp ở MỌI phiên (18 mô tả ≈ 1.500 token), nhưng tài
  liệu nói mọi thông tin "khi nào dùng" phải nằm ở đó và nên viết *hơi thúc*, vì Claude có xu hướng **bỏ sót**
  skill chứ không phải gọi thừa. Cắt ở đó là đổi đúng thứ đang có tác dụng lấy 750 token.

**Ca 51** kiểm năm điều: mọi `references/*.md` được nhắc đều có thật · mọi file có thật đều được nhắc · router
nêu đủ đường dẫn và đường lùi · mọi `SKILL.md` dưới 500 dòng (ngưỡng của `skill-creator`) · phần đã dời không
còn sót trong thân. Kiểm ngược lại phép kiểm: đổi tên một file → đỏ ở chiều "thiếu"; thêm một file lạc → đỏ ở
chiều "mồ côi"; khôi phục → xanh lại.

Bộ test: **51 ca · 248 xanh · 0 đỏ**. Không đụng script, không đụng khuôn, không đổi một luật nào của cổng.

## 8.0.1 — 2026-09-23

**Lỗi chặn phát hành của 8.0.0: `UC-###.trace.md` không nằm trong pathspec spec của `gate-check`.** Từ 8.0.0
vòng đọc lại ghi CHỈ vào file cạnh, nên commit của `/sdd-solo:verify` trên repo đã migrate chạm **đúng một
file** — và file đó không có trong `SPECP`, nên `glog` không thấy commit ấy. Cổng hoặc bỏ qua nó (lọt qua cửa
vân tay "sau đọc lại chỉ sửa chữ nghĩa"), hoặc không tìm thấy commit đọc lại nào cả.

**Vì sao mọi phép đo của 8.0.0 vẫn xanh.** Phép đo là so verdict trước/sau trên một repo THẬT — và trong một
repo thật chưa từng tồn tại một commit chỉ chạm `UC-###.trace.md`, vì trước 8.0.0 file đó không phải chỗ ghi.
Một lỗi chỉ xuất hiện ở trạng thái mà lịch sử chưa có thì so sánh lịch sử không bao giờ thấy. Nên ca 50 dựng
đúng trạng thái đó: migrate, viết một vòng đọc lại vào file cạnh, commit **chỉ** file ấy, rồi đòi cổng nhận ra
nó là commit đọc lại. Bỏ bản vá đi thì 2/4 phép đo của ca này đỏ.

- `SPECP` thêm `$ID.trace.md` ở cả hai nhánh bố cục (7.0 và 6.x).
- `verify` nói rõ commit gồm những file nào: file cạnh, cộng mọi file spec vòng ấy thật sự có sửa.
- `adversarial` · `change`: `## History` v+1 ghi ở `UC-###.trace.md` — ba chỗ còn nói như trước 8.0.0.

Bộ test: **50 ca · 240 xanh · 0 đỏ**.

## 8.0.0 — 2026-09-23

**Dấu vết ra khỏi thân UC · trần vòng đọc lại · gom câu hỏi số.** Ba thay đổi, một nguyên nhân chung đo được
trên bản sao runxops: quy trình vẫn đúng ở từng bước, nhưng cái nó *để lại* đã lớn hơn cái nó đặc tả.

### ① Dấu vết ở file cạnh, từ dòng đầu

`## Adversarial pass` · `## Đọc lại` · `## History` giờ ghi vào **`UC-###.trace.md`** ngay khi UC ra đời; thân
UC giữ một mục `## Evidence` trỏ sang. 5.0.0 đã nén chúng **khi UC đóng** — nhưng UC đóng không phải ca đắt.
UC **đang mở** mới là file mọi phiên làm việc nạp lại, và phép đo nói thẳng:

| | thân UC | trong đó là dấu vết |
|---|---|---|
| 16 UC của runxops | 2,33 MB | **56%** |
| file lớn nhất (UC-029) | 455 KB | **72%** |
| sau khi dời | **1,01 MB** | 0% |

- `lib.sh` thêm `trace_of` · `ev_body` · `rr_rounds` · `rr_max`. **Mọi** chỗ đọc dấu vết đi qua `ev_body`:
  `gate-check` §7 §8 và mục bắt buộc, `uc-steps` ⑦ ⑧, `change-check` §8.
- **Thân THẮNG file cạnh** khi thân còn mục đó. Đây không phải chi tiết: repo viết trước 8.0.0 thường có CẢ
  `UC-###.trace.md` cũ do `pass.sh close` để lại, và bản đầu đọc file cạnh trước làm cổng trả lời từ **bản lưu
  trữ** thay vì bản sống — verdict trôi trên UC không ai đụng (đo được: **+28 ✓** trên một UC). Đọc thân trước
  nghĩa là repo chưa migrate không nhận ra 8.0.0 tồn tại.
- `## History` rời danh sách mục bắt buộc của thân UC và được hỏi lại qua `ev_body`: cùng một câu hỏi, hỏi đúng
  chỗ. Để nguyên thì mọi repo vừa migrate đỏ vì đã migrate.
- `migrate.sh --trace [--dry-run]` dời một repo sang — 16 UC + 4 proposal của runxops trong một lượt.
  **Idempotent, và đó là ràng buộc thiết kế, không phải tính chất phụ**: một migration trên repo sống bị ngắt
  giữa chừng, bị chạy từ hai worktree, bị chạy lại vì không ai nhớ đã chạy chưa. Nên nó quyết theo **nội dung
  từng file** — thân không còn mục dấu vết là đã xong, file cạnh đã chứa đúng khối sắp nối thì không nối lần
  hai. Không đọc ngày, không đọc file cờ: đó là hai thứ một lượt chạy dở làm sai. Chạy ba lần trên bản sao
  runxops: cây `specs/` giống nhau **từng byte**.
- Dấu vết chép sang **nguyên văn**, dưới một tiêu đề có ngày. Không tóm tắt, không đánh số lại, không viết lại
  câu nào — một dấu vết mà migration đã sửa thì không còn là dấu vết.

### ② Trần vòng đọc lại — một điểm DỪNG, không phải một cửa

`rr_max` ở `.sdd/config`, **mặc định 3**, kể cả cho repo chưa có dòng đó. Tới 7.8 `→ Chưa quyết` là một đầu ra
hợp lệ và chỉ được ĐẾM (7.0.1 #53: mở cổng với một câu hỏi chưa trả lời là món nợ chủ dự án nhận có ý thức).
Đo trên runxops thì đó chính là lỗ hổng — số vòng và số tồn đọng lên **cùng nhau**:

| UC | vòng đọc lại | còn Chưa quyết | cỡ file |
|---|---|---|---|
| UC-024 | 13 | 105 | 110 KB |
| UC-029 | 13 | 74 | 455 KB |
| UC-026 | 12 | 71 | 231 KB |
| UC-025 | 9 | 37 | 242 KB |
| mọi UC dừng ở 1 vòng | 1 | **0** | 2,9–91 KB |

Thêm một vòng không phải là câu trả lời cho vòng trước; nó là cách rẻ nhất để trông có vẻ đang làm, và nó là
thứ nuôi một file UC lên 455 KB. Nên: **dưới trần không đổi gì**; **chạm trần thì một `Chưa quyết` không được
mang sang vòng sau** — nó thành Câu hỏi mở (chủ dự án nợ câu trả lời) hoặc một phiếu (người khác nợ). Không có
cờ bỏ qua, và **chạy thêm một vòng nữa vẫn đỏ**: số chỉ xuống bằng cách quyết. `rr_max=0` tắt hẳn.

Mặc định là một con số chứ không phải "tắt" — một cái trần không ai đứng dưới thì không phải cái trần. Giá
phải trả nói thẳng: trên bản sao runxops, **7 UC đỏ thêm một dòng** ngay sau khi cập nhật (và 2 UC chạm trần mà không còn tồn đọng thì thêm một dòng xanh). Đó là chủ ý của một
bản major; `status.sh` in danh sách đó kèm số vòng / số tồn để biết việc phải làm là gì.

### ③ `/sdd-solo:numbers` — gặp mọi ô trống cùng một lúc

Luật "không bịa số" cộng cổng chặn `___` sinh ra **588 ô trống rải trên 34 file**, và chủ dự án gặp **từng cái
một**, mỗi cái giữa một lượt chạy cổng, mỗi cái là một lần bị ngắt. Ở đúng khoảnh khắc đó đường rẻ nhất luôn
là điền một con số nghe được — tức là đúng cái thất bại mà luật kia sinh ra để chặn, đạt tới bằng cách tuân
thủ nó. `scripts/numbers.sh` in tất cả một lượt, và thêm thứ biến một danh sách thành một bảng việc: **ai đang
chờ**. Một `___` trong tham số của RULE không phải một ô trống, nó là mọi UC trích luật đó.

Phân loại **theo cấu trúc, không theo tên mục** (nên đọc spec tiếng Việt và tiếng Anh như nhau): ô trống đứng
**một mình trong ô bảng** = tham số; dòng `- [ ]` = câu hỏi mở chưa có quyết tạm; còn lại là văn xuôi. Phép
phân biệt đó không phải chi tiết — bản đầu nhận mọi hàng bảng có `___` và chôn **26 tham số thật giữa 94
hàng**. Read-only, luôn exit 0: đây là bảng việc, không phải cổng. `status.sh` in một dòng nói còn bao nhiêu
file có `___`, vì một bảng việc không ai thấy thì vô giá trị.

### Không hồi quy

So **verdict** (exit · số ✓ · số ✗ · số !) của 93 lệnh trên bản sao runxops:

- 7.8.0 ↔ 8.0.0 **trên repo CHƯA migrate**: 10/93 dòng đổi, và đúng những dòng của trần — `+1 ✓` ở UC chạm trần mà không còn
  tồn đọng, `+1 ✗` ở UC còn tồn đọng. Không một dòng nào khác.
- 8.0.0 **trước ↔ sau `migrate --trace`** (cùng plugin, cả hai repo đã commit): **0 dòng khác**. Đây là phép đo
  quan trọng nhất của bản này — dời 1,3 MB dấu vết mà cổng phải trả lời y hệt, nếu không thì migration đang
  giấu bằng chứng chứ không phải dời nó. Ba lỗi CHỈ phép đo này bắt được, cả ba cùng một họ "cổng thôi kiểm mà
  không ai biết":
  · `ev_body` khớp tiêu đề theo TIỀN TỐ, nên khối lưu trữ `## Đọc lại — 2026-09-17` do `pass.sh close` cất đi bị
    gộp vào dấu vết sống — một UC từng đóng nhảy từ 38 ✓ lên 65 ✓. Giờ khớp đúng tiêu đề trần.
  · phép kiểm "RULE được trích phải tồn tại" quét `grep -oE RULE- "$F"`, nên **6 UC lặng lẽ thôi kiểm 1–5 RULE**
    ngay khi dấu vết rời thân. Giờ quét qua `uc_text` = thân + dấu vết: dời chỗ cất không đổi thứ được kiểm.
  · vân tay hành vi của §9 lấy danh sách RULE từ chính file UC, nên commit dời dấu vết của một UC đã đóng bị
    đọc thành "spec đổi HÀNH VI sau khi đóng — areas: rules". `spec_fp` giờ đọc cả `UC-###.trace.md` ở đúng
    revision đó, nên tập RULE không phụ thuộc vào chỗ cất.

Bộ test: **49 ca · 235 xanh · 0 đỏ**. Ba ca mới: 47 (dời · verdict giống nhau trước/sau · ba lần chạy giống
từng byte · `--dry-run` không đụng đĩa), 48 (trần: dưới trần im, chạm trần đỏ, **thêm vòng vẫn đỏ**, quyết
xong thì hết, `rr_max=0` tắt, không có dòng thì mặc định 3), 49 (`numbers`: ô bảng là tham số, ô có giá trị
không tính, văn xuôi không tính, `blocks:` đúng UC).

### Nâng cấp

`/plugin update sdd-solo` → `/sdd-solo:init --update` → `bash .sdd/scripts/migrate.sh --trace --dry-run`, đọc,
rồi chạy thật và commit. `update.sh` tự nhắc khi thấy repo còn dấu vết trong thân UC, và im khi không còn.
**Không migrate cũng chạy được**: `ev_body` đọc thân trước, nên cổng cho verdict y hệt 7.8.0 (trừ trần).

## 7.8.0 — 2026-09-23

**Plugin nói tiếng Anh; giọng trả lời đi theo ngôn ngữ anh gõ.** 7.7.0 dựng cơ chế (bảng từ khoá song ngữ,
hướng ghi theo `doc_lang`); bản này *dùng* nó: vỏ của plugin — khuôn, skill, thông điệp in ra, chú thích mã,
README — chuyển sang tiếng Anh. Không một luật nào đổi, không một đường dẫn nào đổi. **Repo đang chạy không
đổi một byte**: `doc_lang` của nó vẫn là `vi` (không có dòng đó thì rơi về `vi`), chiều ĐỌC vẫn nhận cả hai
thứ tiếng, và mọi cổng cho cùng verdict như 7.7.0.

- **`templates/` sạch chữ tiếng Việt** — 47 file, 0 ký tự có dấu. Dự án MỚI sinh ra tài liệu tiếng Anh từ
  đầu; `scaffold.sh` nay thật sự ghi `doc_lang=en` vào `.sdd/config` mới. (7.7.0 nói nó ghi, nhưng nó không
  ghi — lỗi im lặng đúng loại đắt nhất: khuôn tiếng Anh mà script vẫn ghi tiếng Việt vào, và không phép kiểm
  nào đỏ vì chiều đọc nhận cả hai.)
- **17/17 skill viết bằng tiếng Anh**, mỗi skill mở đầu bằng một dòng: *Reply in whatever language the user
  writes in; keep file names, IDs and slugs in English.* Văn skill không còn là chỗ giữ tiếng Việt — từ khoá
  tài liệu đã có chỗ riêng ở `kw.tsv`.
- **36 script + 10 `js/*.mjs` + 3 githook**: chú thích và thông điệp in ra sang tiếng Anh. Logic không đụng.
- **9 dòng mới trong `kw.tsv`** (162 dòng): sáu nhãn ô của phiếu · `c_ticket_w` · `In Scope` / `Out of Scope`.
  `c_ticket_w` có vì `kw_w c_ticket` trả về *mẫu đọc* `phi[eế]u #` và mẫu đó đang được ghi thẳng vào tiêu đề
  commit của `phieu.sh` — một dòng `write` riêng là cách duy nhất không lẫn hai chiều.
- `br-scope-diff.sh` đọc tên mục qua `kw` (In Scope · Out of Scope · Dropped), `uc-steps.sh` và `phieu.sh`
  cũng vậy. `js/brief.mjs` sinh lời giao sáu phần bằng tiếng Anh, tên mục lấy qua `kwW` nên vẫn khớp phiếu
  của dự án.
- **Ở lại tiếng Việt, có lý do:** khoá và giá trị trong `.sdd/roles` (`vai` · `.ghi` · `.cam` · `ket=xong`…)
  — đó là *định danh* mà githook bash trần đọc, không phải văn; mọi chuỗi `migrate.mjs` đọc từ hoặc ghi vào
  một repo 6.x (`Liên quan tới BR:` · `**Lát:**`…) — đổi là migrate hụt; `docs/playbook-example-khoskill.html`
  — nó là một tài liệu mẫu, không phải mã.

**Phép đo.** Bản này đổi *mọi* thông điệp in ra, nên `tests/snap.sh` so chữ thành vô nghĩa. Thay bằng so
**verdict**: mỗi lệnh một dòng `exit · số ✓ · số ✗ · số !` trên bản sao runxops, 7.7.0 so với bản này —
93 lệnh trên 30 UC · 0 dòng khác. Bộ test: **46 ca · 208 xanh · 0 đỏ**; ca 46 mới, ba phép đo cơ học để 7.8.0 không trôi
ngược: `templates/` không còn ký tự có dấu · mọi skill có dòng *Reply in whatever language* · `scaffold`
trên repo trắng ghi `doc_lang=en`. `tests/lib.sh` ghim bản nền của bộ test về `doc_lang=vi` ngay sau
scaffold — nếu không, chiều ghi ra tiếng Anh thì bản nền tự nó thành bản đã dịch và ca 45 không còn gì để so.

## 7.7.0 — 2026-09-23

**Từ khoá tài liệu thành song ngữ.** Khuôn của plugin sẽ sinh ra tài liệu tiếng Anh (7.8.0), nhưng repo đang viết
tiếng Việt phải qua cổng y hệt như trước — nên bản này tách *từ khoá* ra khỏi *chỗ khớp*: mọi chỗ script đọc vào
NỘI DUNG tài liệu đi qua một bảng, không viết thẳng chuỗi tiếng Việt vào `grep`/`sed`/`awk` nữa.

- **`scripts/kw.tsv`** — bảng bốn cột: tên · kiểu dùng · tiếng Việt · tiếng Anh. `kiểu dùng` nói từ khoá đứng ở
  đâu trong tài liệu (`head` `## X` · `label` `**X:**` · `cell` ô bảng · `raw` nguyên văn · `group` nhiều dạng chỉ
  để đọc · `commit` mảnh tiêu đề commit · `write` chỉ để ghi). Bash đọc qua `kw` · `kwh` · `kwl` · `kw_w` (lib.sh),
  node qua `js/kw.mjs` — **cùng một file**, không bơm bảng qua biến môi trường: quên một `export` là hụt im lặng,
  đọc chung một file thì không có chỗ nào để quên. `scaffold` chép `kw.tsv` và `js/` sang `.sdd/scripts/` như mọi
  script khác, nên cổng vẫn chạy được ở CI và trên máy người clone repo.
- **Hướng GHI theo `doc_lang`** (`.sdd/config`, mặc định `vi`). Chỗ script ĐỌC nhận cả hai thứ tiếng; chỗ script
  GHI ra file hay ra commit dùng `kw_w`, một vế theo dự án. `scaffold` ghi `doc_lang=en` khi tạo `.sdd/config`
  MỚI, nên dự án đang chạy không đổi một byte còn dự án mới thì tiếng Anh từ đầu. Phía node đọc qua
  `SDD_DOC_LANG`, và `lib.sh` export biến đó **một chỗ duy nhất** ở cuối file thay vì ở từng script gọi `node`:
  quên một chỗ thì file đó ghi tiếng Việt trong repo khai `en` và không phép kiểm nào đỏ, vì chiều ĐỌC nhận cả hai.
- Kiểu `write` có mặt vì vế tiếng Việt của vài từ khoá là chữ thường trong văn xuôi — `vai` · `anh` · `đã đóng`.
  Chúng vẫn ghi ra được theo `doc_lang`, nhưng bộ test không đổi chúng: đổi thô thì bản tiếng Anh hỏng vì một lý
  do không liên quan gì tới cổng, và phép đo mất nghĩa.
- **githook không cần bảng** — soi hết `templates/githooks/`: 0 chỗ khớp chữ tiếng Việt, chúng chỉ khớp
  `feat(UC-###)`. Một chỗ ít hơn phải giữ đồng bộ.

**Vì sao KHÔNG đổi hẳn sang tiếng Anh, kể cả khi muốn.** Lịch sử git bất biến. runxops có 50 commit subject tiếng
Việt mà `gate-check` §9 grep vào chính chúng (`docs(UC-###): đọc lại`); bỏ vế tiếng Việt là mọi UC đã đóng mất
bằng chứng đọc lại, và không `migrate` nào chữa được — file thì viết lại được, commit thì không. Vế tiếng Việt ở
lại vĩnh viễn: đó là chủ ý, không phải nợ.

**Phép đo — ca 45, và nó là loại phép đo mà bộ test cũ không có.** Ca này chép repo, viết lại MỌI từ khoá sang vế
tiếng Anh theo đúng bảng (đổi theo vị trí cấu trúc, không thay chuỗi thô — `Từ` · `mở` · `câu` là từ tiếng Việt
thường gặp trong văn xuôi), rồi đòi cổng cho **cùng verdict, cùng số ✗, cùng số ✓**. Chỗ nào còn viết thẳng chuỗi
tiếng Việt thì CHỈ ca này đỏ — bản tiếng Việt vẫn xanh, nên mọi phép đo khác vẫn xanh trong khi spec tiếng Anh rớt
cổng. Bảng là nguồn duy nhất, nên thêm một dòng vào `kw.tsv` là ca 45 tự phủ luôn: thêm từ khoá mà quên định
tuyến một chỗ khớp thì nó đỏ. Ca so verdict của **bảy** lệnh: `gate-check` (đủ và `--pre`) · `uc-steps` ·
`br-check` · `decisions.sh` · `close-check` · `layer-check`; `decisions.sh` so SỐ DÒNG chứ không so chữ, vì thân
quyết định vừa bị đổi sang tiếng Anh — cái phải giống là đếm được bao nhiêu, và trước khi định tuyến nó là
190 → 173, mất 17 quyết định không một dòng đỏ.

**Hai lỗi ca 45 bắt được ngay trong chính bản này**, cả hai đều thuộc loại "mẫu hụt im lặng":

- `kwl()` phía node trả nhóm BẮT (`(vi|en)`). `.source` của nó được nối vào một mẫu lớn hơn, nên nhóm lạc đó đẩy
  số thứ tự của mọi nhóm sau — `hoi.mjs` đọc `mm[1]` ra chính từ khoá thay vì giá trị ô, và **phép kiểm bốn ô của
  sổ hỏi đọc ô trống nào cũng thành "có điền"**. Hai mẫu `kwh`/`kwl` chuyển sang nhóm không bắt.
- `rr_count` khớp `[neo: …]` bằng chữ. Định tuyến nó bằng `-v nb="…\\[…\\]"` thì `awk -v` xử lý escape của chuỗi
  TRƯỚC máy regex, `\\]` tới nơi còn `\]` và mẫu hụt — bản **tiếng Việt** đang xanh thành đỏ "chưa đọc lại". Viết
  ngoặc vuông bằng `[[]` và `[]]`: trong ngoặc vuông không còn escape nào để nuốt. Đây là cửa duy nhất mở cổng
  Phase 5, nên hụt ở đây là hụt đắt nhất trong file.

Khảo sát trước khi sửa (hai lượt soi độc lập, vì máy quét bằng regex bỏ sót): **96 chỗ DOC + 11 chỗ COMMIT** trong
`scripts/*.sh`, **38 DOC + 3 COMMIT + 26 chỗ GHI** trong `scripts/js/*.mjs`. Máy quét hụt `decisions.sh` trọn vẹn
(nó đọc `Từ:` `Trạng thái:` `Kiểm lại:` `Phát biểu:` của cả bốn nguồn — spec tiếng Anh sẽ cho sổ tra quyết định
RỖNG mà không một dòng đỏ), và mọi danh sách tên mục viết bằng mảng hằng thay vì regex (`context.mjs` 5 tên mục
của architecture.md, `hoi.mjs` 4 nhãn ô bắt buộc).

Không hồi quy: snapshot đầu ra mọi script trên hai bản sao runxops (bố cục 7.0 và 6.x) — **0 dòng khác**.
Bộ test: 45 ca · 205 xanh.

## 7.6.0 — 2026-09-23

Mã nguồn của plugin **bỏ python, chạy bằng node**. Tới 7.5.0 plugin là hai ngôn ngữ: 4.953 dòng bash cộng **1.193 dòng
python** (872 dòng nhúng trong heredoc ở 9 script + `mermaid.py` 321 dòng). Bản này chuyển trọn phần đó sang
`scripts/js/*.mjs` — 9 file, 1.798 dòng, **không một gói npm nào**, ESM, chạy thẳng bằng `node`. Bash ở lại: nó vẫn là
thứ githook và CI gọi.

Lý do là của dự án, không phải của plugin: **dự án dùng sdd-solo viết bằng node**, và sdd-solo dùng mermaid rất nhiều
để kiểm luồng (parser 7.5.0, bốn chỗ gọi). Ngôn ngữ thứ hai chỉ để đọc sơ đồ là một ngôn ngữ nữa phải cài trên mọi máy
clone repo, trong khi node thì đằng nào cũng có. Từ nay plugin nói đúng một thứ tiếng với dự án nó phục vụ — sửa một
phép kiểm mermaid không còn phải đổi ngữ cảnh sang python.

- **`scripts/js/`** — `mermaid.mjs` (parser + lint, bản chuyển từ `mermaid.py`, luật giữ y nguyên) · `context.mjs` ·
  `migrate.mjs` · `pass.mjs` · `brief.mjs` · `hoi.mjs` · `table.mjs` · `util.mjs` · `mermaid-real.mjs`.
- **`mermaid-real.mjs`** — mới: khi dự án đã có `mermaid` + `jsdom` trong `node_modules` của nó, đặt
  `SDD_MERMAID_REAL=1` thì `--lint` gọi **chính mermaid** thay vì luật lint. Không tra được thì trả 3 và vỏ bash rơi về
  parser trong plugin. Đây là thứ chỉ làm được vì đã sang node: plugin mượn mermaid của dự án, không tự cài gì.
- **`need_node`** (lib.sh) — ba script SỬA/ĐỌC file không có đường lùi (`context.sh` · `pass.sh` · `migrate.sh`) dừng có
  lời khi máy không có node, thay cho `node: command not found` của shell. Chỗ CÓ đường lùi giữ nguyên nếp 7.5.0: không
  có node thì `mermaid.sh` exit 0 im lặng, `jver`/`mkt_field`/`installed_*` rơi về `grep` — **một phép kiểm không chạy
  được không bao giờ thành một phép kiểm đỏ**.
- `deps-check.sh` kiểm `node >= 18`; `scaffold.sh` chép cả `scripts/js/` sang `.sdd/scripts/js/` và **dọn `mermaid.py`**
  của bản 7.5.0 (hai parser cạnh nhau thì cái không được cập nhật nữa vẫn chạy được).

**Cái bẫy đắt nhất khi chuyển, và cách bắt được nó.** `\b` của JS chỉ biết `[A-Za-z0-9_]`, của python biết cả chữ có
dấu — nên cùng một biểu thức cho hai kết quả NGƯỢC nhau trên tiếng Việt: `\b[A-Z][A-Za-z]{2,}\b` trên `Khoá API` thì
python không khớp (sau `Kho` còn `á`), JS khớp `Kho`; còn `\bđiều phối\b` sau dấu `*` thì python khớp, JS **không**
(với JS cả `*` lẫn `đ` đều không phải chữ, nên không có biên). Chỗ thứ nhất làm `context.sh` gói thừa hai entity không
ai nhắc — **126 dòng lệch trên bản sao runxops 6.x**, và chỉ lộ ra ở phép so snapshot, không lộ ở bộ test. Đã thay mọi
`\b` quanh chữ bằng biên từ hiểu chữ có dấu (`(?<![\p{L}\p{N}_])` … `(?![\p{L}\p{N}_])`) ở `context.mjs`,
`brief.mjs`, `migrate.mjs`. Ba bẫy nhỏ hơn đã ghi tại chỗ trong mã: cờ `(?m)` inline không có ở JS (phải là tham số thứ
hai của `RegExp`), `$` với cờ `m` là cuối DÒNG chứ không phải cuối chuỗi, và `String.split` bỏ lát rỗng đầu khi khớp
rỗng ở vị trí 0 còn `re.split` của python thì không (hàm `splitAt` trong `migrate.mjs`).

**Cách kiểm — chạy thật cả hai bản, so từng byte, không đọc mã đoán:**
- `migrate --layout v7` trên **bản sao runxops 6.x chưa migrate** (75 phép dời thật): bản python 7.5.0 và bản node cho
  đầu ra **khớp từng byte** (254 dòng `--dry-run`, và bản chạy thật), **cây khớp hoàn toàn** (`diff -r`), git index
  khớp. `migrate --evidence` chạy trên cả ba BR, hai lượt liên tiếp (kiểm cả tính idempotent): khớp từng byte.
- Snapshot đầu ra **mọi** script trên hai bản sao runxops (bản 7.0 và bản 6.x), 7.5.0 ↔ 7.6.0: **0 dòng khác** ở cả
  hai. Đây là phép đo đã bắt được lỗi `\b` ở trên.

Bộ test: **ca 44 — `migrate.sh`, script tới 7.5.0 KHÔNG có một ca nào**, trong khi nó là script dời cây thật của người
ta và khó hoàn tác nhất. 19 phép đo trên một repo 6.x thu nhỏ: thiếu map thì đỏ và kê đích danh · `--dry-run` không
đụng một byte · BR thành lát của nghề · UC ghi `Nghề · Lát` · bảng Related Use Cases có cả UC chưa mở · `internal/` về
gốc và `notes/` · `entities.md` tách mỗi entity một file · rules/glossary theo nghề · test UC dời theo nghề và import
tương đối được sửa (#56) · index trả về trống và in hai lệnh commit (#57) · chạy lại thì dừng · `--evidence` tách rồi
không tách lại · không có node thì dừng có lời chứ không dời nửa chừng. Ca 43 sửa một phép đo đo nhầm exit của pipe
thay vì exit của script. Bộ test cũng bỏ python (`tests/lib.sh` và 4 ca) — repo giờ cần đúng `git`, `bash`, `node`.
**44 ca · 194 xanh · 0 FAIL · 0 XFAIL.**

## 7.5.0 — 2026-09-23

Parser mermaid (**P-32**) — bốn chỗ đọc sơ đồ bằng `grep` từng dòng đổi sang đọc bằng một parser thật. Ca gốc, đo được:
17/88 khối mermaid của runxops **không render được** (trình đọc hiện chữ đỏ thay cho hình) mà mọi cổng vẫn xanh, kể cả
trên UC đã `implemented`.

- **`scripts/mermaid.py` + `scripts/mermaid.sh`** — tách khối ```` ```mermaid ````, parse flowchart (14 hình, nhãn node,
  nhãn cạnh, id), sequence · state · class; bốn chế độ `--lint` · `--edges` · `--nodes` · `--states` (thêm `--kinds`,
  `--json`). Đây là file python **duy nhất** trong `scripts/`; `mermaid.sh` là vỏ bash, không có `python3` thì exit 0 im
  lặng và mọi chỗ gọi rơi về đường `grep` của 7.4 — một phép kiểm không chạy được không bao giờ thành một phép kiểm đỏ.
- **Luật lint đo bằng mermaid thật, không đoán.** Ground truth: `mermaid.parse` + `getDiagramFromText` (mermaid v11 qua
  jsdom, node 25) chạy trên 88 khối thật của runxops (bản 7.0 và bản 6.x) cộng một ma trận **27 ký tự × 13 ngữ cảnh**.
  Kết quả đối chiếu cuối: **17/17 khối vỡ bắt được, 0/71 khối lành báo oan**. Năm mã:
  · `MMD-E01` nhãn node/cạnh flowchart chưa bọc nháy kép mà có `( ) [ ] { } |`
  · `MMD-E02` nháy kép lồng trong nhãn đã bọc nháy kép (và nháy mở không đóng)
  · `MMD-E03` dấu `;` trong lời sequenceDiagram (message · Note · alt/else/opt · participant as) hoặc nhãn quan hệ class
  · `MMD-E04` dấu `;` trong nhãn stateDiagram — **mất chữ im lặng**: parse qua, nhưng đo trên
    `core/entities/Account.md` của runxops thì **4/4 quan hệ về nhãn rỗng** và mermaid sinh 5 state rác (`;` `hôm` `nay`
    `seed` `SQL)`). grep vẫn thấy chữ `UC-016` và vẫn in ✓, trong khi sơ đồ người đọc thấy không còn một chữ nào.
  · `MMD-E05` dấu `:` thứ hai trong note stateDiagram / nhãn quan hệ classDiagram
  Đo được là **vô hại** nên KHÔNG báo: `;` trong nhãn flowchart (nhãn giữ nguyên) · `#` · `,` · `·` · `→` · `<br/>` ·
  nháy đơn · `%%` trong nháy · `[VIỆC LỖI]` bên trong nhãn đã bọc nháy kép.
- **Bốn chỗ gọi:** `gate-check` §5 (nhãn cạnh E# và id node lấy từ parser, cộng lint `flow` · `sequence` · UC ·
  `screens/README`) · `gate-check` §6 (state diagram "có mũi tên gắn UC" đọc **nhãn mermaid hiểu được**, không grep
  dòng — đây là chỗ `MMD-E04` từng cho ✓ giả) · `br-check` §7 (lint mọi khối của `br.md`, Impact Map vỡ thì cả mục
  thành chữ đỏ) · `uc-steps` ④ ("đã vẽ" nghĩa là **vẽ ra được**). `lib.sh` thêm `mmd` · `mmd_ok` · `mmd_lint`.
- `scaffold.sh` chép `mermaid.py` + `mermaid.sh` vào `.sdd/scripts/` (cần `init --update` ở dự án), kẻo cổng chạy ở CI
  rơi về grep im lặng.
- Giá: `gate-check` trên UC lớn nhất của runxops (UC-025) 4,85 s → 5,44 s — thêm ~0,6 s cho một lượt cổng.

Đo trên hai bản sao runxops (snapshot 7.4.0 ↔ 7.5.0): bản 7.0 **18/135** file đầu ra khác, bản 6.x **6/49** — và
**không một verdict nào đổi** (mọi `QUA CỔNG` / `KHÔNG QUA CỔNG` / `ĐỦ ĐIỀU KIỆN` giữ nguyên ở cả hai bản). Cái khác
là các dòng ✗ mới chỉ đúng file và dòng có sơ đồ vỡ, trên những UC vốn đã đỏ. Lint toàn cây: bản 7.0 có 7 `MMD-E01` ·
25 `MMD-E03` · 10 `MMD-E04`, bản 6.x có 18 `MMD-E03` · 5 `MMD-E04` — nợ thật, sửa rẻ (đổi `;` thành `·` hoặc `—`, bọc
nhãn trong `"…"`). Khuôn và fixture của chính plugin: 0 lỗi.

Bộ test: ca 43, 11 phép đo mới (lint bắt ngoặc chưa bọc nháy · bọc nháy thì qua · `;` ở sequence · `--edges` không nhặt
chữ trong nhãn node · `--nodes` in id + hình + nhãn · cổng đỏ khi flow vỡ · cổng đỏ khi `;` xoá nhãn state · **không có
`python3` thì cổng vẫn qua, không đỏ oan** · scaffold chép parser). 43 ca · 175 xanh · 0 FAIL.

## 7.4.0 — 2026-09-23

Đợt vá 18 lỗi còn mở của bản đánh giá runxops (`notes/sdd-solo-issues.md`, P-## · I-8), theo kế hoạch 2026-09-23 sau
7.1–7.3. Mỗi lỗi đã có ca `xfail` từ 7.1.0; bản này sửa script rồi đổi 20 phép đo sang `chk` — **42 ca · 164 xanh · 0 FAIL ·
0 XFAIL**. Thứ tự theo giá phải trả: **cổng xanh oan / đỏ oan trước** (đỏ oan thì bị học cách phớt lờ, rồi kéo theo cả dòng
đỏ thật), rồi hụt kiểm, rồi tiện ích. Không có cờ bỏ qua nào được thêm; hai chỗ luật đổi nghĩa (P-16, P-20) ghi rõ dưới.

**Cổng đỏ oan** (gate-check):
- **P-18** `--pre` không đếm `<...>` trong `## History` — sổ chỉ-thêm, ghi cả lời cảnh báo có `E<số>`.
- **P-38** `--pre` bỏ chữ trong nháy mã trước khi tìm placeholder (`<tr>` là tên thẻ HTML, không phải chỗ chưa điền).
- **P-43** `--pre` miễn `___` trên dòng trích một RULE mà chính rule đó còn tham số `___` ở rules.md — số chưa quyết nằm ở
  rule, UC chỉ chép lại chỗ trống; chặn thì lối thoát duy nhất là bịa số vào UC trước khi rule có số. In `info` đếm số chỗ.
- **P-38b** bảng Screens: ô đầu `**E1**` (in đậm) và `E1 · E2` (ô gộp) đều tính là "E# có màn hình" — so nguyên từ trên ô
  đầu thay vì regex `| E1` sát mép.
- **P-17** cảnh báo "id node dạng E<số>" chỉ xét TRONG khối ```` ```mermaid ```` — ghi chú văn xuôi dưới sơ đồ không phải id.
- **P-31** pathspec §9 là MẪU `specs/*/br-*/use-cases/UC-###-*/…` (tắt glob của shell bằng `set -f` khi gọi git), không phải
  đường hiện tại — UC vừa `git mv` sang lát khác giữ nguyên lịch sử đọc lại thay vì đỏ "đổi HÀNH VI (không rõ)".
- **P-16** UC đã `implemented`: mốc so của §9 là **commit đóng** (`docs(UC-###): implemented — traceability`), không phải
  lần đọc lại (đã nén còn một dòng). Sau đóng mà vùng hành vi không đổi → ✓ "§9 không áp"; đổi → ✗ chỉ sang Phase 5
  (`/sdd-solo:change`) thay vì chỉ sang verify. Đây là đổi nghĩa: cổng DoR không còn đòi UC đã đóng "đọc lại lần nữa".
- **I-8** design-check bỏ nháy mã trước khi tìm `<...>` ở architecture.md — `tests/use-cases/<core|nghề>/UC-###/` là quy
  ước đường dẫn, không phải chỗ chưa quyết.
- **P-25** br-check chỉ đếm dấu chấm của CÂU Goal — bỏ dòng khai nguồn (`*Nguồn: …*`, in nghiêng, blockquote, chú thích).
- **P-42** githook `pre-commit` cho qua commit **merge** (có `MERGE_HEAD`) chở cả spec lẫn code của nhánh kia — hai bên đã
  tách ở nhánh gốc; chặn thì worktree `code/uc-###` không merge được `main`. Cần `init --update` để nhận.

**Cổng xanh oan / hụt kiểm:**
- **P-30** `--pre` cũng soi bảng Screens (hàm `screens_check` dùng chung với cổng đầy đủ) — thiếu dòng E# đỏ ngay ở ⑦,
  không đợi ⑨.
- **P-37** `## Đọc lại`: kiểm ID trên ĐUÔI SỐNG của dòng F# — chữ sau mũi tên cuối, sau khi bỏ `…` và `(…)` lồng nhau
  (`rr_tail` ở lib) — thay cho `case *"→ Chưa quyết"*` miễn cả dòng. Đuôi sống `→ sửa AC-9` núp trước cụm trích `(→ Chưa
  quyết …)` giờ bị kiểm; ngược lại mũi tên trong trích dẫn (UC-027 F74 runxops chép nguyên `✗ … → E4 …` của cổng) không
  còn là đầu ra — đo trên runxops: 0 dòng đỏ mới, 6 dòng đỏ oan của bản nháp đầu biến mất.
- **P-35** §9 so vân tay TRƯỚC khi tin "commit đọc lại là commit spec mới nhất" — `docs(RULE-###)` sửa phát biểu rule không
  mang tên UC nên tiêu đề vẫn là đọc lại mà hành vi đã đổi; câu báo nêu commit chạm spec gần nhất bất kể tiêu đề.
- **P-10** close-check so vân tay hành vi từ commit gate-pass tới HEAD (`fp_changed`) — sửa AC sau cổng bằng
  `docs(UC-###)` thì marker cổng còn mà điều nó chứng nhận không còn; ✗ kèm lệnh `verify --since <gate>` rồi gate lại.
  UC đã `implemented`/`deprecated` chỉ **cảnh báo** (vết lịch sử — đo runxops: 10/12 UC đã đóng có vùng đổi sau cổng,
  chặn thì close-check đỏ trên thứ đã đóng). Hàm vân tay (`spec_fp` · `fp_changed` · `fp_uc` …) dời từ gate-check sang
  `lib.sh` để hai cổng dùng chung.
- **P-22** br-check ✗ khi một UC có ở `## Related Use Cases` của hai BR — một UC thuộc một lát; lát kia trỏ bằng
  `**Upstream UC:**` của UC, không kê vào bảng.
- **P-24** layer-check gom cả `CON-###` của lát nghề (`- **CON-### …:**` trong `specs/<nghề>/br-*/br.md`) vào ID nghề;
  trừ số cũng có ở gốc/core và bỏ BR-000 mẫu (khuôn có sẵn CON-001..003, không phải của ai).
- **P-20** cổng nói ra bao nhiêu dòng `## Đọc lại` còn `→ Chưa quyết`: `rr_undecided` ở lib, gate-check và change-check
  in `! k/n phát hiện còn '→ Chưa quyết' — cổng mở là nợ anh tự nhận`. **Không đổi luật #53 (7.0.1)**: Chưa quyết vẫn là
  đầu ra hợp lệ, cổng vẫn mở — chỉ hết chuyện ✓ giống hệt nhau ở "đã quyết hết" và "chưa quyết gì" (CHG-002 phải đổi tay
  11 đuôi mới biết). Đề nghị gốc của P-20 (không tính là đầu ra) sẽ đóng cổng với mọi lượt verify không hỏi — ngược
  quyết định chủ dự án ở 7.0.1, nên không làm.

**Tiện ích:**
- **P-40** `pass.sh close` nén dấu vết dù thân có `<hash>`, `<label for="…">`, chữ trong nháy mã — khuôn thật là
  `YYYY-MM-DD`, `Ngày chạy: ___`, và `<...>` còn lại sau khi bỏ nháy mã và thẻ dạng HTML (tên ASCII + thuộc tính).
- **P-23** `context.sh BR-###`: bối cảnh một lát — mục quyết định của BR (không Background, in cỡ KB của nó), dòng của
  lát ở `vision.md`, RULE/ADR BR trích, architecture, entity/glossary BR nhắc; `--why` · `--brief` như UC. 6.x lấy đúng
  mục `# BR-###:` trong `specs/br.md`.

Đo trên hai bản sao runxops (snapshot `tests/snap.sh`, 7.3.0 ↔ 7.4.0 — lần này khác là chủ ý, mỗi dòng khác quy được về một
mục trên): bản 7.0 (15 UC · 5 BR) 54/135 file khác, bản 6.x chưa migrate 17/49. `--pre`: 7 UC (7.0) + 2 UC (6.x) từ đỏ
thành xanh (P-18 · P-38 · P-43), 1 UC đỏ thêm vì thiếu dòng E# ở Screens (P-30). `br-check`: 5/5 BR (7.0) và 3/3 (6.x)
đỏ P-22 — 27 cặp UC ở hai bảng, đúng ca runxops đã ghi (UC-016…024 ở `core/br-004` lẫn `ebay/br-003`). `layer-check`:
+7 file gốc/core trích `CON-###` của nghề (P-24). `close-check`: 10 UC đã đóng giữ ĐÓNG ĐƯỢC (cảnh báo P-10, không
chặn); 1 UC 6.x còn mở đỏ P-10 thật. `gate-check` UC implemented: 9 chỗ "đổi HÀNH VI sau khi đóng — vùng: rules" (P-16
chỉ sang Phase 5) thay cho ✓ "commit đóng" cũ; 3 dòng "chưa đọc lại" oan biến mất. Verdict cổng đầy đủ của mọi UC còn
mở không đổi.

Còn mở, chưa có ca: P-32 parser mermaid (7.5.0) · P-39b `[chặn]` trần vòng (8.0.0) · P-41 lỗi `$1` ở thân skill (xem 7.1.0).

## 7.3.0 — 2026-09-23

Đội agent, phần hai — nốt các mục (5) đến (7) của kế hoạch 2026-09-23. Cùng nguyên tắc 7.2: plugin giữ cơ chế, repo giữ
chính sách; không có sổ thì im lặng. Đo bằng `tests/` (ca 38–42, 41 phép đo mới; 42 ca · 139 xanh · 0 FAIL) và snapshot
đầu ra mọi script trên hai bản sao runxops (6.x chưa migrate · 7.0) khác 0 dòng so với 7.0.1.

- **Sổ hỏi có địa chỉ cho vai code/test** — `templates/skel/hoi-vai.md` bốn ô (nguồn · chặn không · đang làm gì trong
  lúc chờ · việc cho spec khi trả lời) + ô `Trả lời (A/R)` · `đích:`. `phieu.sh hoi <V> "<câu>"` mở mục `HỎI-<V>n` (chép
  khuôn khi chưa có sổ, số = max + 1). `hoi-check.sh <V> [--lich-su]`: bốn ô không còn khuôn · `Chặn không` là chặn |
  không chặn · đã trả lời phải có đích · **cổng UC-### đã mở mà đích trỏ thân UC (không phải design.md/decisions.md,
  không nói AC đổi) → ✗** — đó là luật 6 của runxops thành phép đo (UC-025: 25 câu HỎI, mỗi câu kéo một lượt sửa UC
  rồi một lượt verify) · số HỎI trùng/nhảy · `--lich-su` bắt commit sửa dòng `### HỎI-` đã có (sổ chỉ-thêm). Chạy ở
  `status.sh`, không ở githook (hoi-D.md runxops 3.309 dòng). Đây là thứ điều phối runxops chọn nếu chỉ được đưa một
  thứ vào plugin — hôm nay là 421 mục hỏi trong hai sổ không khuôn.
- **Sổ uỷ quyền có khuôn** — `templates/project/notes/uy-quyen.md`: Phạm vi (chủ dự án viết; còn khuôn thì điều phối
  không quyết câu L3 nào) · Thứ tự nguồn · Điểm dừng có tên (năm dòng mẫu S1–S5 từ runxops, đổi tuỳ ý) · Sổ. Hai phép
  kiểm ở `status.sh` mục "Đội agent", **không** ở cổng DoR (cổng đo chất lượng yêu cầu, không đo phối hợp): mọi
  `DỪNG-<tên>` trong hàng đợi phải có tên ở bảng Điểm dừng; dòng Sổ trỏ `#n` thì `specs/decisions.md` phải có dòng nhắc
  `#n` — không thì điều phối quyết xong mà quyết định vô hình với mọi phiên sau (runxops: 147 phiếu L3, chủ dự án thật
  sự được hỏi ~6 lần, 90 lần A quyết thay, 81 ô Duyệt trống).
- **Hàng đợi trong git — `notes/hang-doi.md` + `queue.sh add|next|take|done|stop|board|list`.** Bảng markdown cột cố
  định (tiền lệ `uc_table_status`/`uc_table_set`): khoá · làn · vai · cần (nhiều khoá) · trạng thái (tập đóng: chờ · đang ·
  xong · bỏ · `DỪNG-<tên>`) · neo · ghi chú; bảng `## Làn` có sức chứa. `next` in việc phát được ngay (mọi cần đã xong, làn
  còn chỗ) — điều phối hỏi máy, không hỏi trí nhớ. **Chỉ điều phối ở checkout chính ghi**: `add|take|done|stop` từ chối ở
  worktree phụ (git-dir ≠ git-common-dir); agent chỉ ghi KETQUA; `done` đọc KETQUA, đòi `ket=xong` + neo rồi mới ghi dòng
  — xung đột ghi biến mất thay vì phải xử lý. Worktree phụ đọc bản `main` qua `git show`. `xong` không neo là đỏ ở `board`
  (tám việc xong giả lúc hết hạn mức 22:16). Việc `đang` quá hạn (90 phút, `--qua-han`) chỉ cắm cờ `nghi-chết` để điều phối
  đi nhìn — **không tự đổi trạng thái** (bài học bỏ cửa qua đêm, 6.0.0). Mỗi lần ghi một commit `--only`. Thay cho `q.sh`
  88 dòng trong scratchpad runxops (mất là dựng lại) và bảng giao việc sinh mỗi phút không commit. Plugin không cấp runner.
- **`session-start.sh` theo vai** — worktree có dấu vai (hay `SDD_ROLE`) thì hook bơm **hợp đồng vai** (được ghi · cấm ·
  cách commit · kiểm · luật phiếu/KETQUA) + **việc đang giao** cho vai đó từ hàng đợi + KETQUA đã ghi, thay cho đoạn văn
  viết cho một người ngồi gõ; worktree phụ kèm "sau main N commit — git merge main" và marker cổng main có mà nhánh
  chưa (hook, marker, `.sdd/version` ở worktree là bản của nhánh nó). Vai điều phối nhận thêm `queue.sh board` + STATE.
  Hook đã chạy lại mỗi `/clear` (matcher `startup|resume|clear`) — đúng nhịp "mỗi việc một phiên": phiên vừa xoá tự biết
  mình là ai. Chữa hai trong ba sự cố lặp của điều phối: quên `/clear`, quên đặt lệnh chờ.
- **Bốn skill còn hỏi có chế độ phiếu** — `start` · `design` · `intake` · `deprecate`: chạy dưới lời giao của agent khác
  (hoặc `role.sh --xem` ra vai không phải điều phối) → không `AskUserQuestion`, mỗi câu thành `phieu.sh new`, `___` +
  quyết định tạm, DỪNG, `role.sh --ketqua … ket=chan hoi=#n` (khuôn `adversarial --phieu` 7.0.1). `close` · `gate` nói
  rõ không giao agent. Skill mới `/sdd-solo:queue`; `orchestrate` §1 setup + §4 trỏ hàng đợi, sổ hỏi, uỷ quyền.
- Scaffold `KEEP` + `queue.sh hoi-check.sh`; `templates/project/notes/` hai khuôn. Ba phép đo chỉ đọc trên bản sao
  runxops trước khi phát hành (kế hoạch): `role.sh --kiem-lich-su HEAD~300..HEAD` với bộ vai mẫu → **15/466 commit**
  không vai nào được ghi đủ (3%, phần lớn `docs(UC-###)` chở cả test hay HỎI-T); `role.sh B` qua **208 phiếu**: 0 lỗi,
  11 lời giao còn `___`, 36 không tách được dòng riêng của B (đưa cả khối), 2 gói đọc có đường dẫn không tồn tại;
  `phieu.sh muc-luc` bắt **#178 trùng** cả ở mục lục lẫn tên file — P-21 lần thứ năm, lần này máy thấy trước người.
- Còn lại của kế hoạch: 7.4.0 đợt vá lỗi cũ (18 XFAIL) · 7.5.0 parser · 8.0.0 dời dấu vết, trần vòng, gom số · 8.1.0 rút skill.

## 7.2.0 — 2026-09-23

Đội agent, phần một (kế hoạch 2026-09-23 sau phỏng vấn điều phối runxops): sdd-solo viết cho một dev + một AI, runxops
chạy một điều phối + 11 vai song song trên một repo, và mọi cơ chế cho việc đó (hợp đồng vai 291 dòng, hàng đợi ngoài
repo, cấp số phiếu tay, 137 lượt giao tay) đều phải tự dựng. Bản này đưa **cơ chế** vào plugin, **chính sách** ở lại repo
(`.sdd/roles`). Repo không khai vai thì hành vi y hệt 7.1 — đo bằng `tests/` (ca 30–37, 61 phép đo mới) và không ca cũ
nào đổi. Không đụng cây `specs/`, runxops nhận giữa chừng được. Bốn điều chủ dự án chốt: làm ngay sau bộ test · cơ chế
kèm bộ vai mẫu · dấu vai theo worktree, mỗi vai ghi một worktree · hàng đợi là file trong git (7.3).

- **`.sdd/roles`** — khai vai theo `khoá=giá trị` như `.sdd/config` (githook bash trần đọc được): `vai=A B R D T`,
  `<V>.ten .ghi .cam .nhanh .commit .kiem`, `vai_bat_buoc=khong|nhanh-vai|moi`. Vùng ghi nhận `@code_paths`
  `@test_paths` `@uc_test_dir` `@tool_paths` nở từ `.sdd/config` — đường dẫn không chép hai nơi. Cấm thắng ghi. Bộ vai
  mẫu ship trong `templates/project/` (init --update chép, không đè bản đã sửa). `lib.sh`: `role_list` `role_paths`
  `role_deny` `role_checks` `role_may_commit` `role_of_path` `role_current` `glob_re` (chỉ `*` và `**`, không `case` để
  gọi được trong `$( )`; tắt glob của shell khi duyệt — `specs/**` không quote từng nở thành 11 đường dẫn thật).
- **Dấu vai theo worktree** — `role.sh <vai>` ghi `$(git rev-parse --git-path sdd-role)`: `.git/sdd-role` ở checkout
  chính, `.git/worktrees/<tên>/sdd-role` ở worktree phụ. Không vào git, không theo nhánh — nhánh không đủ vì spec/soi/trọng
  tài cùng ở `main` và đã cuốn file của nhau hai lần một ngày (P-29). `role.sh --worktree D UC-###` dựng
  `../<repo>-d-uc-###` trên nhánh theo `<V>.nhanh`, đặt dấu. Vai không có mẫu nhánh (B spec) **giữ checkout chính**:
  cái B viết là sự thật chung, ngồi worktree riêng thì vai khác đọc `main` cũ (ca D chọn ngược quyết định của R).
- **Hook chặn thật — `commit-msg.d/10-vai.sh`** gọi `role.sh --commit <msg>`: suy vai `$SDD_ROLE` → đuôi `Vai: <V>` →
  dấu worktree → mẫu nhánh; file stage ngoài vùng → thông điệp *"chỗ này của vai T"* (`role_of_path`), `commit=khong`
  (R) → không được commit. Mặc định `vai_bat_buoc=khong` chỉ nhắc — bản phát hành là minor, repo tự chọn lúc bật sau khi
  `role.sh --kiem-lich-su` (chỉ đọc, 300 commit) cho số chấp nhận được. Hook ghi thêm đuôi `Vai: <V>` để `git log --grep`
  đo được. Đặt ở commit-msg (không pre-commit) vì chỉ ở đó đọc được cả message lẫn file stage. Commit merge bỏ qua.
  `pre-commit.d/10-role-boundary.sh.example` (theo nhánh, 6.2) gỡ; bản user đã bật thì scaffold nhắc `git rm`.
  **`commit-msg` mẹ:** `Merge`/`Revert`/`chore(sdd)` vẫn miễn kiểm ID nhưng **không còn `exit 0` trước vòng `.d/`** — tới
  7.1 mọi mảnh `.d` mù với ba loại commit đó.
- **`role.sh <vai> <file phiếu> [--luot N]`** — lời giao **sáu phần** sinh bằng máy: mục tiêu · gói đọc `file:mục` (tra
  qua lib từ ID ở dòng đầu phiếu, kiểm tồn tại) · việc chép nguyên phần `Cho: <vai>` (mục đậm `- **B (…):**`, mục inline
  `B (…) · A (…)`, bảng `| K | … | Cho |`) + mọi `[neo:]` · vùng cấm từ `.sdd/roles` · lệnh kiểm + commit `--only` kê
  đích danh + đuôi `Vai:` · dòng KETQUA với khoá `<vai>-<id>-p<n>[-l<lượt>]`. **Chỉ nhận file phiếu**, chuỗi tự do bị từ
  chối — 35% công của điều phối runxops là soạn lời giao, và chỗ hay rơi là neo, mà neo chỉ có trong phiếu. Trần 1.500
  ký tự: vượt thì cảnh báo (dán vào một số công cụ không tự gửi).
- **KETQUA — `role.sh --ketqua <khoá> ket=xong|chan|do neo=… [kiem= hoi= con=]`** ghi một dòng khoá=giá trị vào
  `$(git rev-parse --git-common-dir)/sdd-ketqua/<khoá>.txt` — **chung mọi worktree, ngoài git**: đặt ở `notes/` thì vai
  code ghi trong worktree của nó, điều phối ngồi `main` không thấy gì; đưa vào git thì mỗi lượt một commit một xung đột.
  `ket=xong` bắt buộc `neo` **có thật** (hash `cat-file -e` · marker `.sdd/gate/…` · file); `ket=chan` bắt buộc `hoi=`.
  Agent ghi file **trước** rồi gửi tin — bốn báo cáo mất trắng một buổi (P-26) và tám việc xong giả lúc hết hạn mức
  22:16 ngày 22/09 là hai ca nó chữa. Khoá `[a-z0-9][a-z0-9._-]{1,39}`.
- **`phieu.sh new|close|muc-luc|list`** — cấp số phiếu có khoá: `mkdir` nguyên tử ở `git-common-dir/sdd-lock/`
  (`.sdd/` nằm trong cây làm việc, mỗi worktree một bản — khoá ở đó vô hình với đúng đối tượng nó phải chặn); số = max
  của mục lục ∪ tên file ∪ `git log --all "phiếu #n"` (bắt cả phiếu ở worktree chưa merge); tạo file theo khuôn, thêm dòng
  mục lục, **commit dòng giữ chỗ ngay** bằng `--only`, xong mới viết thân — P-21, trùng số bốn lần một ngày khi cấp tay. Đo:
  hai worktree × 8 lượt song song → 17 số khác nhau. `close <n>` đếm `F#`/`K#` **trên file** so với số tự khai (P-33, kê số
  thiếu) và đòi KETQUA `ket=xong` của từng vai trong `Cho:` (mục *"không có việc"* miễn); `muc-luc` bắt số trùng · số nhảy
  · file không dòng · dòng không file. Sổ 6.x `specs/internal/hoi-dap.md` nhận như 7.0. `templates/skel/hoi-dap.md` có
  bảng mục lục sẵn. Slug bỏ dấu bằng python (iconv macOS không dịch được tiếng Việt).
- **P-29 — bảy chỗ commit qua vùng stage chung**: `adversarial` (2) · `intake` (2) · `design` · `verify` (2) đổi từ
  `git add specs/ && git commit` sang `git add <file> && git commit --only -m … -- <file>` **kê đích danh** — `--only --
  specs/` vẫn cuốn mọi thay đổi dưới `specs/` của vai khác, nên không dùng thư mục. Ca 37 chặn hồi quy.
- Skill mới `/sdd-solo:role` · `/sdd-solo:phieu`; `orchestrate` §1 setup dùng `.sdd/roles`, §3 trỏ sang lời giao sinh
  bằng máy + KETQUA, luồng phiếu qua `phieu.sh`. Scaffold: `KEEP` + `role.sh phieu.sh`; `chmod +x` mảnh `.d/*.sh`.
- Chưa có trong bản này (7.3): sổ hỏi có địa chỉ cho D/T, sổ uỷ quyền có khuôn, hàng đợi `notes/hang-doi.md` +
  `queue.sh`, `session-start.sh` bơm hợp đồng vai, năm skill còn `AskUserQuestion` (start · design · intake · deprecate · close).

## 7.1.0 — 2026-09-23

Bộ test cho script — việc (1) trong bản đánh giá 10 ngày của runxops (`notes/sdd-solo-danh-gia-2026-09-23.md`): 73 bản
phát hành trước đó không bản nào có test, người dùng làm QA thay cho repo. **Không đổi hành vi** — bản này chỉ thêm
`tests/` ở gốc repo plugin (không phát vào dự án). Từ đây phát hành khi `bash tests/run.sh` không FAIL.

- `tests/run.sh` + `tests/lib.sh`: runner bash 3.2, mỗi ca một file `tests/cases/NN-<slug>.sh`, repo giả 7.0 dựng bằng
  `scaffold.sh` thật + `tests/fixtures/v7/` (một nghề · một lát · `UC-001` đã adversarial + đọc lại, qua cổng xanh), bốn
  commit có ngày cố định để §9 so được. Bốn kết quả: PASS · FAIL (chặn phát hành) · **XFAIL** (lỗi còn mở — ca mô tả
  hành vi đúng mà bản này chưa có) · **XPASS** (lỗi đã hết, đổi ca sang `chk`). Kịch bản smoke 1.0.0 (hook chặn code
  trước cổng · chặn trộn spec+code · cho qua sau cổng · gate-pass · close nén vết) giờ là ca 08 · 09.
- `tests/snap.sh`: chụp đầu ra mọi script trên một repo thật để `diff -r` trước/sau — cách kiểm "không hồi quy" mà
  CHANGELOG 7.0.0 mô tả, giờ là một lệnh.
- 29 ca · 42 phép đo hồi quy xanh (7.0.1: #51 #52 #53 P-13 P-15, lát có ·, layer-check, I-4 context bỏ vết).
- **Đã biết — 18 lỗi còn mở, 21 phép đo XFAIL**, mỗi lỗi một ca, sửa ở 7.4.0 (đợt vá) hoặc 7.5.0 (parser) rồi đổi sang `chk`:
  - cổng xanh oan / đỏ oan ở `--pre`: **P-18** `<…>` trong `## History` · **P-38** thẻ HTML trong nháy mã · **P-43** `___`
    trích tham số RULE còn trống · **P-30** `--pre` không soi `## Screens`.
  - cổng đầy đủ: **P-38b** ô `**E1**` / ô gộp `E1 · E2` trượt phép "E# có màn hình" · **P-17** cảnh báo `E<số>` bắt cả chữ
    ngoài khối mermaid · **P-37** `case *"→ Chưa quyết"*` miễn cả dòng nên đuôi sống `→ sửa AC-9` thoát kiểm ID (nợ tự khai
    7.0.1) · **P-35** sửa thân RULE bằng `docs(RULE-###)` sau đọc lại vẫn xanh im lặng · **P-31** đổi thư mục UC → §9 mất mốc
    đọc lại, đỏ "vùng đổi: (không rõ)" · **P-16** UC implemented + `docs(UC-###)` sau đóng → đỏ §9 (hai hình: đã nén → "chưa
    đọc lại", chưa nén → "đổi HÀNH VI").
  - `lib.sh`: **P-20** `rr_count` đếm `→ Chưa quyết` là có đầu ra.
  - githook: **P-42** `pre-commit` chặn commit merge chở spec + code của `main`.
  - tầng BR / ranh giới: **P-22** một UC ở hai bảng Related Use Cases không đỏ · **P-24** `layer-check` không đo `CON-###` ·
    **P-25** `br-check` đếm dấu chấm cả đoạn khai nguồn dưới câu Goal.
  - khác: **P-40** `pass.sh close` không nén mục vết có `<hash>` · **P-23** `context.sh` không nhận `BR-###` · **I-8**
    `design-check` coi `<core|nghề>` trong nháy mã là placeholder · **P-10** sau cổng không script nào so lại vân tay.
- Không có ca cho: P-32 (parser mermaid — 7.5.0), P-21 · P-29 · P-26 · P-33 (cấp số phiếu, commit qua stage chung, bàn giao —
  cơ chế chưa có, đến 7.2.0 kèm ca), P-39b (`[chặn]` là quy ước riêng của runxops, plugin chưa có — 8.0.0 trần vòng),
  P-41 (lỗi `$1` ở thân skill, không phải script).

## 7.0.1 — 2026-09-19

Chín lỗi gặp khi chạy 7.0.0 trên runxops thật (Bước C) — gộp một bản vá như peer điều phối giao. Thử trên bản sao
runxops **trước** migrate (6.x) và **sau** migrate (7.0): snapshot output mọi script 7.0.0 ↔ 7.0.1 chỉ khác ở
close-check (P-15) và một dòng đếm của `gate-check --pre` (#52). Fixture mới (repo giả 7.0 + bản sao 6.x): 17/17 xanh
trên 7.0.1, 3/17 trên 7.0.0 — ba cái xanh sẵn là các ca "phải đỏ".

- **#53 — verify không bao giờ hỏi; adversarial có chế độ phiếu.** Chạy dưới lời giao của agent khác, cả hai mở
  `AskUserQuestion`: không ai bấm, lượt treo tới hết hạn, `## Adversarial pass` / `## Đọc lại` không được ghi.
  - `/sdd-solo:verify` bỏ `AskUserQuestion` hẳn (khỏi `allowed-tools`). Mỗi `F#` ra một trong hai đầu ra agent tự
    ghi: `→ không phải lỗi vì <lý do truy được>` hoặc `→ Chưa quyết (chờ chủ dự án: <câu> · đề xuất: <ID>: <chữ mới>)`
    — rồi ghi + commit như cũ. Lượt đọc không sửa spec; sửa theo câu trả lời là lượt áp, đọc lại bằng `--since`.
    Tới 7.0.0 có nhánh "không có người thì đừng hỏi", nhưng agent không biết chắc mình ở nhánh nào.
  - `gate-check`: dòng `→ Chưa quyết` ở `## Đọc lại` không bị kiểm ID có thật — đề xuất được trỏ tới AC/RULE chưa
    tạo. Dòng khai `→ sửa AC-9` mà AC-9 không có vẫn đỏ. `Chưa quyết` vẫn là đầu ra hợp lệ của cổng (như 6.x).
  - `/sdd-solo:adversarial … [--phieu | --hoi]`. **phiếu** (`--phieu`, hoặc chạy theo lời giao của agent khác, hoặc
    không chắc): câu hình dạng thành một phiếu `K1…Kn` cuối sổ hỏi đáp (`notes/hoi-dap/hoi-dap.md`; 6.x
    `specs/internal/hoi-dap.md`; chưa có thì chép khuôn), UC/BR ghi `→ Chưa quyết — Open Question (phiếu #n K#)`,
    không áp hướng mình nghiêng; tầng BR không áp phiếu nào đổi phạm vi, nên `br-scope-diff` phải rỗng trước
    History. **hỏi** (mặc định khi chủ dự án tự gõ, hoặc `--hoi`): như cũ. `orchestrate` luật 8: lời giao chạy
    adversarial ghi `--phieu`; `sdd-process` 1b thêm ngoại lệ "không có người ở đầu kia".
  - Hai skill ghi rõ đường dẫn 6.x (UC ở `specs/contexts/`, BR ở `specs/br.md`, sổ ở `specs/internal/`); verify
    bước 1 tìm UC ở cả hai cây (tới 7.0.0 chỉ glob `*/br-*/use-cases/`).
- **#56 — migrate sửa cả đường dẫn không có tiền tố `uc_test_dir`.** Test dời nghề còn được import tương đối
  (`'../use-cases/orders/UC-014/fakes.js'`, `'../../../use-cases/intake/UC-012/…'`); 7.0.0 chỉ thay chuỗi đầy đủ
  `tests/use-cases/<ctx>/UC-###` nên bỏ sót — runxops phải sửa tay import trong `tests/` và `src/`. Giờ thêm mẫu
  `<đuôi uc_test_dir>/<ctx>/UC-###` chặn biên hai đầu (`UC-014` không ăn vào `UC-0140`); quét thêm đuôi
  `.tsx .jsx .mjs .cjs .mts .cts .py`. Đo trên bản sao 6.x: 11 import tương đối ở 8 file ngoài `uc_test_dir` đổi sang `use-cases/ebay/…`, file đích
  đều có thật; mọi file sửa in ở "File đã sửa đường dẫn".
- **#57 — migrate để index trống, in hai lệnh add theo ranh giới `.sdd/config`.** 7.0.0 kết bằng `git add -A` cả
  `specs/` lẫn `tests/` → commit kế bị pre-commit chặn "trộn spec và code", gỡ bằng tay dễ kéo theo file lạ. Giờ
  `git reset -q` cuối lượt; in (a) `git add -A -- specs notes .sdd/config .sdd/manifest <file khác đã sửa>` và (b)
  `git add -A -- <uc_test_dir> <file code/test đã sửa>`, cả hai `chore(sdd): …` (commit-msg cho `chore(sdd)` qua kể cả
  khi đụng code — không cần bịa ID). Danh sách tường minh: file untracked có từ trước (runxops: `example.md`) không bị
  cuốn vào. Đo: hai lệnh chạy qua hook 6.x của bản sao, commit (a) 0 file code/test, commit (b) 0 file spec.
- **#51 — `pass.sh deprecate` UC chỉ có dòng trong bảng.** UC dự kiến rồi bỏ, chưa từng có file → 7.0.0 exit 1 im
  lặng, bảng nói `draft` mãi. `uc_table_file` giờ tìm bảng có dòng đó khi không có file UC (br.md của mọi lát; 6.x
  `use-cases.md` mọi context); deprecate sửa bảng + thêm dòng decisions + commit, in "chưa có file UC — chỉ sửa bảng".
  Không có file lẫn dòng bảng → `✗ … ID sai?`, exit 1.
- **#52 — `gate-check --pre` bỏ qua `## Adversarial pass`** như đã bỏ `## Đọc lại`. Lượt adversarial thứ hai (câu cũ
  còn `___`, vai mới chưa chạy) bị chính mục nó sắp điền chặn.
- **Tên lát có ` · ` bên trong** (runxops: `core · đăng nhập · app quản lý (console)`, `ebay · (cũ) gán khoá sản phẩm ·
  agent hỏi số liệu`). `br-check` dựng tên lát bằng `awk -F' · ' '{$1=""…}'` — awk ghép lại bằng dấu cách, mất dấu
  chấm giữa, đỏ oan "không có trong bảng Nghề và lát". Giờ `${LAT#* · }`: cắt đúng một tiền tố nghề.
- **layer-check bỏ qua mục vết** `## History` · `## Adversarial pass` · `## Đọc lại` (tới heading `## ` kế), ở cả ba chế
  độ (R phiếu #71, chủ dự án uỷ quyền). Luật sổ cấm sửa dòng History, nên glossary/rules/7 ADR gốc có History cũ nhắc
  ID nghề đỏ mỗi lần ai chạm file — cùng loại với `*.trace.md`/`evidence.md` đã miễn theo file. Dòng bỏ in thành
  dòng trống: số dòng in ra giờ là số dòng thật (7.0.0 lệch vì xoá dòng trong khối ```). Fixture: ADR gốc History
  trích `RULE-012` → xanh; thêm dòng Decision trích `RULE-012` → đỏ, chỉ đúng dòng 4.
- **P-13 — gate-check "UC ở core trích ID của nghề"** gọi layer-check nên hết đếm mục vết theo luôn. runxops bản sao:
  UC-024 hết ba hit ở Adversarial pass / Đọc lại; vẫn đỏ vì thân còn trích `BR-003`/`UC-014` (nợ thật).
- **P-15 — close-check tìm code của UC theo commit, không chỉ theo slug.** Bố cục 7.0 đặt code theo khái niệm
  (`src/core/{domain,use-cases,adapters}/session/`, `web/`, `deploy/`) → UC-024 runxops đỏ "đã có feat nhưng không
  đọc được file code nào" dù 17/17 AC có test. Tập file = file trong `code_paths` mà commit không-merge có `(UC-###)`
  **ở tiêu đề** đã chạm, còn tồn tại, không phải test (`test_paths` · `uc_test_dir` · `*.test.*`/`*.spec.*`); cộng
  đường cũ theo slug. Số literal: in số đếm, 8 dòng đầu, danh sách đủ ở `.git/sdd/literal-UC-###.txt` (không cắt lặng
  lẽ; trong `.git/` nên không làm bẩn cây); bỏ dòng chỉ là chú thích (`//` `/*` `*` `#` `--`) vì tập theo commit kéo
  cả `.sh`/`.sql`. Bản sao runxops: UC-009 45 file · UC-012 63 · UC-014 95 (7.0.0: chỉ thư mục slug).

## 7.0.0 — 2026-09-18 (Bước B của plan 7.0, #54 #55)

**Đổi lớn:** trục `specs/contexts/<ctx>/` → `core|<nghề>` × `br-###/`, thêm tầng 0 `specs/vision.md`. Repo 6.x
chưa migrate vẫn chạy y nguyên (đo bằng snapshot output của mọi script trên bản sao runxops 6.x: khác 0 dòng ngoài
nhãn "③ RULE + entity + glossary"). Từng mốc ghi dưới đây; mốc chưa ghi là chưa làm.

- **(1) `lib.sh` là chỗ DUY NHẤT tra đường dẫn (#55).** Tới 6.6.x có 11 script + 2 githook tự `find`/`grep` vào
  `specs/contexts/…`, `specs/br.md`, `specs/internal/…` — đổi cây là đổi 13 chỗ, hụt thì im. Hàm mới, mỗi hàm tra
  bố cục 7.0 trước rồi rơi về 6.x: `layout` · `find_vision` · `find_uc` (glob `specs/*/br-*/use-cases/UC-###-*/`) ·
  `all_uc_files` · `owner_of` (core|nghề, 6.x = context; `ctx_of` giữ làm bí danh) · `br_of` · `br_dir` · `br_file` ·
  `br_files` · `br_text` · `br_title` · `evidence_file` · `owner_of_br` · `rules_files` · `rule_file` · `rules_text` ·
  `adr_dirs` · `adr_file` · `arch_file` · `decisions_file` · `glossary_files` · `nghe_glossary` · `nghe_rules` ·
  `nghe_list` (config `nghe_paths=`, không có thì dò `specs/*/`) · `entity_files` · `entity_cited` · `entity_names`.
  `br_body/br_ids/br_untouched/uc_table_file/id_exists/brief_rec_sha` đi qua các hàm đó. Bảng UC ở 7.0 là
  `## Related Use Cases` của `br.md` lát, cùng cột `| UC | Tên | Actor | BR | Status |` — `pass.sh gate/close/deprecate`
  và `status.sh` đọc/ghi qua `uc_table_file`, không còn ca #51 ở v7.
  - `gate-check.sh`: entity theo T2 (mỗi entity một file; "entities của UC" = file UC nhắc tên); RULE tra
    `specs/rules.md` + `specs/<nghề>/rules.md`; §9 pathspec kể cả đường 6.x nên commit đọc lại TRƯỚC migrate vẫn tìm
    thấy, và `spec_fp` tra đường dẫn THEO REVISION (`git ls-tree`) — vân tay so được qua mốc migrate; riêng vùng
    mermaid entities khác bố cục hai bên mốc thì bỏ qua kèm một dòng info (một file/context ↔ một file/entity, nối
    lại không so được). Đo trên fixture: cổng xanh ngay sau migrate · commit nhãn qua · đổi Main Flow đỏ "vùng đổi: main".
  - `context.sh`: python nhận danh sách file qua env từ lib (`SDD_RULES SDD_BRS SDD_ADRS SDD_ARCH SDD_ENTS SDD_GLOS
    SDD_OTHERS`); 7.0 in nguyên file entity UC nhắc tên. `br-check` (UC nằm trong `br-###/use-cases/` là khai thuộc
    lát) · `decisions` · `design-check` · `change-check` · `close-check` · `uc-steps` · `metrics` · `status` · `pass` ·
    `session-start` đều qua lib.
  - Githook `commit-msg` (chạy bash trần, chép logic): RULE/BR/ADR tra cả hai bố cục; ADR hỏi từng thư mục — bản đầu
    `ls a b c d` chặn oan ADR-001 có thật ở runxops (bẫy #16, chính hook đã ghi chú mà vẫn dẫm). `pre-commit` nhận
    `specs/<nghề>/rules.md` là spec.
  - Mọi `cat $DANH_SÁCH | grep` có `/dev/null` đứng đầu — danh sách rỗng thì `cat` đọc stdin và treo cổng.
- **(2) Khuôn theo cây 7.0.** `templates/project/specs/`: thêm `vision.md` (tầng 0: định vị · không thu hẹp ·
  bảng nghề và lát · "xong" mỗi nghề (T1, số là ý muốn chủ dự án, ví dụ runxops 7 ngày) · sổ sửa ngược);
  `internal/{architecture,decisions,adr/}` lên gốc; `br.md` gộp → `core/br-000/br.md` (mẫu điền đủ, có
  `**Lát:**`, Related Use Cases là bảng, Out of Scope mỗi dòng có đích `→ lát ___` / `→ mở lại khi ___` /
  `cố ý thu hẹp — chủ dự án chốt YYYY-MM-DD`); `core/entities/README.md` (T2: mỗi entity một file). Bỏ
  `internal/`. `skel/`: bỏ `context/`; thêm `nghe/{README,glossary,rules,entities/README}` · `br/{br,evidence}`
  · `entity.md`; UC/design/tasks đổi đường `tests/use-cases/<core|nghề>/`, UC Metadata `**Nghề:** · **Lát:**`
  thay `Bounded Context`. `CLAUDE.md.tmpl` thứ tự đọc mới `STATE → vision → glossary gốc → nghề → entity →
  UC + RULE → decisions/adr → brief` + luật ranh giới lõi/nghề + "vision.md là của chủ dự án". `specs/README`
  bảng ID theo chỗ mới; `_intake.md` câu 0 (vision) và luật 4 đòi đích; DoR · prompts · STATE · hoi-dap trỏ
  `specs/architecture.md` · `notes/hoi-dap/`. Scaffold repo trắng → cây 7.0, `layout`=v7, mọi script chạy
  xanh; fixture v7 (`mk-testrepo7.sh`) qua cổng DoR.
- **(3) `migrate.sh --layout v7 [--map <file>] [--dry-run]`.** Đọc `.sdd/migrate-v7.map` (mỗi dòng ba từ:
  `context <ctx> <nghề>` · `uc UC-### BR-###` · `br BR-### <core|nghề>` · `adr ADR-### <nghề>` · `rule RULE-### <nghề>`
  · `entity <Tên> <core|nghề>` · `glossary <từ-đầu-heading> <nghề>`; thiếu context/BR thì in đủ chỗ thiếu và KHÔNG
  chạy). Làm: `internal/{architecture,decisions}` lên gốc · ADR về `specs/adr/` hay `specs/<nghề>/adr/` · `hoi-*`/`soat-*`/
  `*ban-do*` sang `notes/{hoi-dap,soat,ban-do}/` · `br.md` tách mỗi BR một `specs/<nghề>/br-###/br.md` (thêm `**Lát:** <nghề>
  · ___`, `→ evidence.md`, bảng `## Related Use Cases` dựng từ `use-cases.md` + thư mục UC, giữ nguyên văn cũ bên dưới) ·
  `br.evidence.md` tách theo BR · `git mv` thư mục UC vào lát của BR (BR chỉ có trong map → dựng khung `br.md` từ skel,
  Status draft, có sẵn dòng UC — không đỏ) · `entities.md` mỗi `## Tên` một file (tên lấy trong backtick nếu có:
  `## Khoá API (\`ApiKey\`)` → `ApiKey.md`; mục không phải entity vào `entities/README.md`) · RULE theo map sang
  `specs/<nghề>/rules.md` · mục glossary tên context sang `specs/<nghề>/glossary.md` · `tests/use-cases/<ctx>/UC-###` →
  `<nghề>/` · `vision.md` từ khuôn · `nghe_paths=` vào config · UC Metadata `Bounded Context` → `**Nghề:** · **Lát:**`.
  Sửa đường dẫn trong file theo TÊN THẬT vừa dời (dài trước ngắn sau); đích mơ hồ (`specs/br.md`, `specs/contexts/`)
  không sửa, chỉ đếm; **brief nguồn không đụng** (sha phải giữ). Cuối cùng in ba bảng: đã dời · file đã sửa đường ·
  CẦN TAY. Không commit hộ. Đo trên bản sao runxops (84a38fc, map thử theo plan §4): 71 chỗ dời, 118 rename +
  32 A + 17 D + 23 M; gate-check UC-014/UC-024/UC-009, br-check BR-003, decisions (190 mục), design-check, metrics
  ra cùng kết luận trước và sau; commit đọc lại trước migrate vẫn là mốc (§9 pathspec cũ); close-check trỏ
  `tests/use-cases/ebay/UC-014` đúng chỗ mới.
  - `lib.sh brief_rec_sha`: nhiều `br.md` thì lấy dòng `Nguồn brief:` có `nạp <ngày>` muộn nhất — bản đầu lấy dòng đầu
    theo thứ tự file, gặp BR-001 cũ của runxops (sha cũ) là br-check đỏ oan "brief đã đổi".
- **(4) Tầng 0 kiểm bằng máy + ranh giới lõi/nghề.** `br-check` ở bố cục 7.0 (6.x không đổi một dòng — đo bằng snapshot):
  (a) BR phải có `- **Lát:** <nghề> · <tên lát>`; nghề phải là thư mục chứa BR, tên lát phải có ở bảng `## Nghề và lát`
  của `specs/vision.md` — thiếu/lệch/không có trong bảng → đỏ. (b) `## Không thu hẹp` của vision.md viết
  `- **<từ khoá>** — <giải thích>`; dòng Out of Scope nào chứa từ khoá (không phân biệt hoa thường) → đỏ, trừ dòng
  ghi `cố ý thu hẹp — chủ dự án chốt YYYY-MM-DD` (in info). Dòng Out of Scope chưa nói đi đâu → cảnh báo.
  (c) mỗi dòng `## Đã loại khỏi brief` phải có `→ lát …` / `→ mở lại khi …` / `→ chuyển: …` → thiếu là đỏ (6.x vẫn
  chỉ cảnh báo như cũ). Đo trên fixture: đúng ba ca đỏ (thiếu Lát · "Chiều ghi" ở Out of Scope · dòng loại không đích),
  ca có nhãn chủ dự án qua.
  - `scripts/layer-check.sh [--staged | --file …]` (mới, vào `.sdd/scripts/`): ① gốc `specs/*.md` · `specs/adr/` ·
    `specs/core/**` không trích ID của nghề (RULE/ADR/UC/BR sống trong `specs/<nghề>/` + tên entity ở
    `specs/<nghề>/entities/`; bỏ khối `<!-- -->` và ``` ```; trừ vision.md · decisions.md · traceability.md · trace ·
    evidence · notes/); ② `src/core/**` không import `../<nghề>/` · `src/<nghề>/` · `@/<nghề>/`. Repo 6.x → "không có
    nghề để kiểm", exit 0. Đo trên bản sao runxops sau migrate: 18 file gốc/adr/core đang trích ID nghề — đó là nợ cũ
    có thật, Bước C của runxops soát; hook chỉ chặn nợ MỚI. **Tên entity của nghề** (Channel, Product…) chỉ CẢNH BÁO,
    không đỏ, không chặn: hiến pháp kỹ thuật và ADR gốc nhắc tên entity là chuyện thường; đỏ nhiều thì hook thành
    nhiễu và người tắt nó (peer runxops chốt 2026-09-18; thử: ADR gốc trích RULE-012 → ✗ exit 1, ADR gốc nhắc
    Product → ! exit 0).
  - `templates/githooks/pre-commit.d/20-layer-boundary.sh.example`: gọi `layer-check.sh --staged`, tắt mặc định (`.example`).
    `gate-check` (UC ở core) và `design-check` (design.md của UC ở core) gọi `layer-check --file` — chỉ cảnh báo.
  - `migrate --layout v7`: mục glossary theo context sang nghề nhưng **từng dòng từ** là entity đã map về core (hay
    khai `glossary <từ> gốc`) ở lại gốc dưới `## Chung — từ của entity core` (từ tên trong `**đậm**`/`` `backtick` ``
    của dòng đầu khối; suy thẳng từ map, không đoán — ca thật: `Việc (WorkItem)` về core mà dòng glossary theo
    mục "orders" sang ebay, gate UC-024 cảnh báo oan). Dấu vết "dời từ context X, BR-Y" của UC ghi trong `<!-- -->`
    để layer-check không tính UC về core là trích nghề cũ. Khuôn `skel/br/br.md` Impact Map dùng `BR-000` (bản
    đầu ghi `BR-001`, khung BR-004 sinh ra tự trích BR-001).
- **(6) `scaffold.sh` nâng cấp lên cây 7.0 — ba cơ chế, không để hai cây cùng lúc (bug #8 cũ).** ① Chặn `init` trên
  repo 6.x CÓ NỘI DUNG (UC trong `specs/contexts/` hay BR thật trong `specs/br.md`) chưa migrate, chỉ đường
  `migrate.sh --layout v7`; repo 6.x còn nguyên khuôn thì cứ init. ② `RETIRED_TPL` thêm `specs/internal/{adr/_adr-template,
  architecture,decisions}.md` · `specs/br.md` (chỉ xoá khi sha khớp manifest — chưa ai sửa); dọn thư mục rỗng
  `specs/internal/adr` · `specs/internal` · `specs/contexts`. ③ `.sdd/config` sinh mới có `nghe_paths=`; config cũ chưa có
  key thì thêm một dòng (dò `specs/*/`), không đụng dòng khác. `KEEP` thêm `layer-check.sh` · `br-scope-diff.sh`.
  - **Sửa một lỗi mất dữ liệu im lặng** tìm ra khi đo trên bản sao runxops đã migrate: scaffold coi "không có dòng
    manifest" là "chưa cài" và **chép đè** — `specs/architecture.md` THẬT (vừa dời từ `internal/`) và
    `specs/core/entities/README.md` (Domain Model vừa tách) bị thay bằng khuôn, in "✓ cập nhật". Giờ: không dòng
    manifest mà file đã có → `.new` + cảnh báo; file y hệt khuôn thì chỉ ghi nhận. `migrate --layout v7` đổi tên đường
    dẫn trong manifest cho khuôn vừa dời (`internal/architecture.md` → `architecture.md`, giữ sha lúc cài) và bỏ dòng
    của khuôn 6.x không còn, nên `init --update` sau migrate vẫn phân biệt "chưa sửa" (ghi đè) với "đã sửa" (.new).
    Đo lại: architecture.md nguyên vẹn, decisions.md 85 KB nguyên vẹn, `specs/internal` không còn.
  - `scripts/br-scope-diff.sh BR-### [<rev>]` (mới): dòng thêm/bớt của In Scope · Out of Scope · Đã loại khỏi brief so
    với HEAD — "được và mất" cho skill adversarial đọc cho chủ dự án gật trước History v+1. Prompt
    `adversarial-pass.md`: vai hoài nghi "dừng, nói rõ BR sẽ co từ gì thành gì, hỏi chủ dự án, rồi mới viết lại"; ba vai
    đọc thêm `## Không thu hẹp`.
  - README plugin và CLAUDE.md gốc: cây 7.0, ranh giới "mọi đường dẫn qua lib.sh", "vision.md là của chủ dự án",
    "scaffold không ghi đè file không có trong manifest".
- **(5) Skill theo cây 7.0** (12/14 skill; `gate` · `change` không có đường cũ). `sdd-process`: bảng 4 tầng → 5 tầng
  (Hướng · BR · UC · Entity · AC), mục "ba tầng chỗ: gốc · lõi · nghề", quy tắc gốc/core không trích nghề, thứ tự đọc
  mới. `intake`: **bước 0** trước bảy câu — hỏi chủ dự án ba câu bằng lời thường (định vị · không thu hẹp · nghề mở
  trước và "xong"), chỉ hỏi và chép vào `vision.md`, gật rồi mới BR; BR mới: hỏi lát/nghề, số BR kế tiếp trên cả dự án,
  tạo lát từ `skel/br/`, nghề mới từ `skel/nghe/`, ghi `**Lát:**`; Out of Scope và Đã loại bắt buộc có đích.
  `adversarial`: ba vai BR đọc `## Không thu hẹp`; **bước 6 "được và mất"** — `br-scope-diff.sh`, nói bằng lời BR co từ gì
  thành gì, chủ dự án gật (AskUserQuestion ba lựa chọn) rồi mới History; vai hoài nghi "dừng, nói rõ cái mất, hỏi, rồi
  mới viết lại". `start`: `argument-hint` `UC-### [BR-###] [slug]`, hỏi lát thay context, nghề suy từ thư mục BR, BR chưa
  có thư mục → bảo intake; thêm dòng UC vào bảng của `br.md` lát; entity chưa có file → `skel/entity.md`. `verify` ·
  `design` · `close` · `deprecate` · `state` · `status` · `init` (bước 6: hướng dẫn migrate 6.x → 7.0) · `orchestrate`
  (sổ/soát/bản đồ sang `notes/`, vùng cấm D và T là cả `specs/`, câu soát thứ sáu về `src/core` import nghề).
  - `migrate.sh --evidence` đi qua `br_file`/`evidence_file` — tới đây nó hardcode `specs/br.md`, chạy trên cây 7.0 là
    "No such file"; dòng đếm để lại trỏ `→ evidence.md` (tên tương đối với `br.md` của lát).

## 6.6.2 — 2026-09-18

- `orchestrate` phụ lục herdr: `agent send-keys` chỉ nhận phím đặt tên, không gõ chữ — dòng "C phiên mới:
  `send-keys soi /clear enter`" của 6.6.0 sai (trả `invalid_key`, không làm gì); đúng là `agent prompt <tên> "/clear"`.
  Thêm cách khởi động lại agent để nạp plugin mới (`prompt "/exit"` → `agent start` → đọc màn hình → lời giao vai).
  Peer runxops báo sau khi restart 6 pane lên 6.6.1.

## 6.6.1 — 2026-09-18

- `orchestrate` §2/§4: vai C được **ghi thẳng** `specs/internal/soat-<ID>-luot-N.md` (cách runxops đang chạy), hoặc ghi
  scratchpad rồi A chép — cùng kết quả, bớt một bước; A vẫn là người commit. Runxops đã áp 6.6.0 (`955d50a`,
  `54e5ac6`): dời sổ hỏi đáp, `hoi-D/T.md`, 5 file soát từ `notes/` sang `specs/internal/`; file soát và QA cùng ở
  `specs/internal/` — "chỉ người xây quan tâm" đúng nghĩa internal, không cần khoá `.sdd/config`.

## 6.6.0 — 2026-09-18

### `/sdd-solo:orchestrate` — nhiều agent trên một repo (#39)

sdd-solo tới 6.5.0 viết cho *một dev + một AI*. Ở runxops (2026-09-17, một ngày, 46 đợt spec, UC-014 start → close)
chủ dự án chạy **tám agent song song** phối hợp bằng file trong repo; mọi luật nằm ở `notes/dieu-phoi.md` §1–§27 và
`notes/hoi-dap.md` (62 phiếu) của repo đó. Đưa vào plugin để lần sau không dựng lại bằng tay. Không phụ thuộc herdr.

- **Skill `orchestrate`** (`setup | UC-### | round UC-###`), người đọc là vai A: §1 `setup` — sổ hỏi đáp
  `specs/internal/hoi-dap.md` copy từ `templates/skel/hoi-dap.md` (chủ dự án chốt vị trí 2026-09-18: phiếu là quyết
  định, nằm cạnh `decisions.md`; **không** rơi vào `templates/project` — chỉ repo chạy nhiều agent mới có), bật hook
  ranh giới vai từ `.example` (#50), hai câu `AskUserQuestion` (quyền R tới L2 · bật Q khi nào); §2 bảng tám vai
  A/B/C/R/V/D/T/Q với **ranh giới theo đường dẫn từ `.sdd/config`** (`code_paths` · `test_paths` · `uc_test_dir`)
  + bảy luật đã trả giá (fake thuộc T · kiểm ranh giới bằng `git diff`/`git log --no-merges`, không tin pane ·
  merge main đầu lượt + đọc đúng phiếu · hợp đồng T↔D ở một harness · câu "cần chủ dự án" của C chỉ đi sau khi R
  xác nhận L3 · tối đa hai agent ghi · không giao số/hình dạng UC/gate/close/push); §3 khuôn lời giao vai và lời
  giao việc mười mục + lời giao soát code năm câu; §4 chuỗi chuẩn `T₁ → D₁ → C → R → (spec ‖ D ‖ T) … → C trọn →
  self-review → merge → close`, bốn việc của A sau mỗi lượt, luồng phiếu `hoi-<vai>.md` (trong worktree) → R →
  `Cho:`; §5 giới hạn; phụ lục bẫy herdr 0.9.0 (timeout ms · `[Pasted text]` không tự gửi · `<…>` qua zsh · PATH
  shell nền · hộp thoại khởi động · gợi ý mờ · `/clear` cho C).
- **`templates/skel/hoi-dap.md`**: thang L0–L3 (L0 phải có `file:dòng`; phân vân → mức cao hơn; bài kiểm *"quyết sai
  thì khách thấy khác hoặc Main Flow viết lại?"* → L3), khuôn phiếu `Câu · Đã tra · Nếu chọn sai thì · Agent nghiêng
  về · Trả lời (R) · Nguồn · Cho: · Duyệt:`, quyền tự quyết mặc định tới L2, luật "R tra design trước khi xếp".
- `verify-pass.md` và `adversarial-pass.md`: chạy trong mô hình nhiều agent thì mỗi phát hiện/câu kèm ba dòng khuôn
  phiếu (`Đã tra · Nếu chọn sai thì · Agent nghiêng về`) — R xếp mức không phải dịch lại. `templates/project` → cần
  `init --update`.
- `design` §3: `## Cấu trúc code` phải khai **chữ ký cổng / hàm use-case**, không chỉ tên file — T viết harness từ
  đó (HỎI-T1 runxops).
- Vai D/T được ghi **một** file trong `specs/`: `specs/internal/hoi-D.md` / `hoi-T.md` (câu hỏi của nó) — ngoại lệ
  cố ý của ranh giới đường dẫn; hook ranh giới (#50) chỉ chặn `uc_test_dir` ↔ `code_paths` nên không đụng.
- Không có script mới: skill này chỉ nói vai · file · thứ tự; thứ đo được là hook `.d` và hai lệnh git ở §2.

## 6.5.0 — 2026-09-18

### `context.sh --brief` cho subagent ⑦/⑧ (#43 phần còn lại, chủ dự án uỷ quyền) · vá nhỏ sau ca thật 6.1–6.4

- **`context.sh UC-### --brief`**: ADR chỉ in **đoạn đầu** của `## Decision` + tên các mục con làm con trỏ
  (đoạn đầu rỗng thì in mục con đầu tiên); `architecture.md` chỉ `## Cấm · ## Ranh giới · ## Nơi chạy` (bỏ Ngăn
  xếp, Ai gọi). Ba vai adversarial và verify soi **hành vi và ràng buộc**, không soi "dựng bằng gì" — hai skill đó
  gọi `--brief`; `design` (⑩) vẫn đọc trọn. **Không cắt RULE** (mâu thuẫn nấp trong văn xuôi của rule — RULE-012
  phát biểu một mình đã 2 KB), **không lọc glossary** theo thuật ngữ UC nhắc (đo: bỏ 24 mục, không bớt KB).
  Đo runxops UC-014: trọn **221,9 KB → `--brief` 176,0 KB** (ADR 59,8 → 30,9 · architecture 45,1 → 28,0). Phần
  còn lại là UC 47 KB (27 AC) · RULE 25 KB · glossary 17 KB — nội dung hiệu lực; muốn thấp hơn nữa là quyết định
  về spec, không phải về script.
- `gate-check` hàm `siblings` (#48) đọc **phần hiệu lực** của UC (bỏ Adversarial pass · Đọc lại · History) khi rút
  RULE/ADR/entity — ca thật: *"dải rule 001–011"* trong `## Đọc lại` của UC-014 làm nó tưởng UC trích RULE-001.
  Sau khi runxops sửa hai lệch thật: `--pre UC-014` = 0 cảnh báo.
- `scaffold.sh` gọi tay thiếu tham số → in usage thay vì *"invalid option"* từ `source` một đường rỗng.
- `pre-commit.d/README.md`: thử luật `.d` ở worktree — hook mẹ tìm `.d` dưới toplevel của **worktree**, nên
  `git -c core.hooksPath=<repo chính>/.sdd/hooks commit` ở worktree không chạy luật; merge main trước hoặc gọi thẳng
  script với env (peer runxops lọt hai commit, reset hai lần).
- `pass.sh deprecate`: không ghi dòng `decisions.md` thứ hai khi đã có *"Bỏ UC-###"*; chỉ nhắc *"Related Use Cases
  của BR cha"* khi BR cha chưa deprecated (ca UC-009/UC-012 runxops, BR-001 đã deprecated).
- Chủ dự án chốt (AskUserQuestion, 2026-09-18): `core.hooksPath` **giữ tương đối** (worktree merge main là đủ; đường
  tuyệt đối gãy khi đổi tên repo) — đóng câu hỏi để ngỏ ở 6.2.0; skill #39 tên `orchestrate`; sổ hỏi đáp ở
  `specs/internal/hoi-dap.md`.

## 6.4.0 — 2026-09-18

### Ba lệnh/câu hỏi mới từ ngày chạy thật ở runxops (#45 #46 #47)

- **`/sdd-solo:deprecate UC-### [--by UC-###] <lý do>`** (#45) + `pass.sh deprecate`: `Status: deprecated` ·
  `## History` v+1 *"deprecated — <lý do> · thay bằng UC-###"* · **gỡ `.sdd/gate/UC-###.ok`** (githook từ đó chặn
  `feat(UC-###)`) · cột Status bảng `use-cases.md` · một dòng `specs/internal/decisions.md` · một commit
  `docs(UC-###): deprecated — <lý do>`. Ca thật: UC-009/UC-012 deprecated bằng tay, marker còn nguyên, History và
  decisions ghi tay, STATE ghi nợ nhiều ngày. Skill hỏi lý do bằng lời và UC thay thế bằng `AskUserQuestion`, không
  tự chọn; không xoá file, không đụng code (gỡ code là việc của CHG hoặc UC thay thế). `status.sh` cảnh báo *"UC
  deprecated nhưng marker còn"* và *"STATE.md đang làm UC đã deprecated"*; `gate-check` §0: `deprecated` → ✗.
  Đo repo giả: qua cổng → deprecate → marker mất, 4 file một commit, History v3, bảng `deprecated`, decisions +1;
  đặt lại marker tay → status `!`.
- **Intake từ brief hỏi ba câu bằng lời trước khi điền Goal/In Scope** (#46, #47): *"khổ gì, vì sao rơi?"* ·
  *"chạy cho mình trước hay đi hỏi khách trước?"* · *"v1 xong, anh mở cái gì lên để làm việc mỗi ngày?"* — ghi
  nguyên văn có ngày vào `## Background` (`**Khổ gì, vì sao rơi:**`, `**Chạy cho mình trước hay bán:**`) và
  `## In Scope` (`**Mở lên mỗi ngày:**`); brief mâu thuẫn thì brief thua. Ca thật BR-003: hai câu lộ ra **sau**
  adversarial đổi plan nhiều hơn mọi phát hiện kỹ thuật. `br-check` cảnh báo BR có `**Nguồn:** brief` mà thiếu dòng
  `**Khổ gì, vì sao rơi:**` — đo runxops BR-003: `!` đúng.
- **Vai "người sẽ phải vận hành nó mãi"** (`adversarial-pass.md` + skill B) hỏi bắt buộc đầu tiên: *"v1 xong, anh mở
  cái gì lên để làm việc mỗi ngày? tự đổi được gì mà không cần dev?"* — đối chiếu với In Scope trước khi cắt. Ca
  thật: In Scope BR-003 ghi *"v1 không có bước người trên runX"*, sau bị lật thêm app quản lý M1–M8. `templates/project`
  → cần `init --update`.
- Sửa nhỏ: `gate-check` hàm `siblings` (6.3.0) không nhận `- **Order** —` vì đòi một ký tự trước tên — đã sửa.

## 6.3.0 — 2026-09-18

### Vòng verify hội tụ: `--since`, luật dừng, cổng phân biệt commit chữ (#49) · cổng cảnh báo file anh em (#48)

Ca thật runxops UC-014: **sáu lần đọc lại** (19 → 23 → 11 → 7 → 7 → 10) — mỗi đợt áp 1–2 chỗ hành vi lộ 1–2 chỗ
chữ/nhãn ở file bên cạnh; cổng đòi commit đọc lại là mới nhất nên mọi sửa chữ kéo theo một lượt verify trọn
(~200 KB, ~10 phút). Và 14/18 phát hiện lần 1 là lệch UC ↔ file anh em (glossary, entities, sequence, `Áp dụng
cho`) sau ba đợt áp chỉ sửa file UC, `--pre` xanh vì chỉ kiểm UC + flow. Chủ dự án chốt: *lặp tới khi chặn = 0*;
chỉ **mâu thuẫn hai chỗ** hoặc **AC không test được** là chặn.

- **`/sdd-solo:verify UC-### --since [<commit>]`** (skill `verify` mục A″): mốc mặc định = commit
  `docs(UC): đọc lại` gần nhất; subagent đọc `git diff <mốc>..HEAD -- specs/` + các mục bị chạm + mọi chỗ nhắc
  cùng khái niệm (grep cũ và mới), áp nguyên `verify-pass.md`; ghi một khối mới trong `## Đọc lại` (F# tiếp
  nối); commit `docs(UC): đọc lại --since <hash> — n phát hiện, m chặn, k nợ chữ` — cổng nhận tiền tố nên đó
  là mốc mới.
- **`verify-pass.md` mục *Luật dừng*:** mỗi `F#` mang `[chặn]` hoặc `[nợ chữ]`; bài kiểm một câu *"sửa xong,
  test nào phải viết khác, khách thấy gì khác?"*; không chắc → chặn. Đầu ra xếp chặn trước, cuối có dòng đếm.
  `templates/project` → cần `init --update`.
- **`gate-check` §9 phân biệt commit chữ:** tính *vân tay hành vi* ở commit đọc lại gần nhất và ở HEAD — Main
  Flow · Alternative · Exceptions · Postconditions · AC của UC · `flow.md` · phát biểu RULE được trích (bỏ dòng
  `Áp dụng cho`) · khối mermaid của `entities.md`. Không đổi vùng nào → ✓ *"N commit spec sau đó chỉ áp
  chữ/nhãn"*; đổi → ✗ *"spec đổi HÀNH VI … vùng đổi: ac"* và in sẵn lệnh `--since <mốc>`. Nhánh gate-pass và
  nhánh đã đóng giữ nguyên. Đo repo giả: sửa Dependencies + glossary sau đọc lại → xanh; sửa Then của AC-1 → đỏ
  `vùng đổi: ac`.
- **`gate-check` hàm `siblings` (#48), chạy ở cả `--pre` lẫn cổng, chỉ cảnh báo:** (1) cụm treo `chờ phiếu` ·
  `đang xét lại` · `(chưa mở)` trong UC/flow/sequence/rules/br/entities/glossary/ADR được trích — ngoài mục dấu
  vết và ngoài dòng `[x]`; (2) entity UC nhắc tên chưa có trên dòng `- **…**` nào của glossary (nhận cả kiểu
  runxops `- **Việc** (`WorkItem`)`); (3) RULE được trích mà `Áp dụng cho` không có UC này. Danh sách anh em rút
  từ ID UC trích — cùng nguồn với `context.sh`. Đo runxops UC-014: ADR-011 `(chưa mở)` · `NotifyConfig` thiếu
  glossary · RULE-001 không nhận UC-014 — ba lệch thật.
- `adversarial` bước 5 và `verify` bước 6 thêm **grep chỗ anh em** cho mỗi khái niệm vừa đổi (cũ **và** mới),
  rồi `gate-check --pre` trước khi commit. `sdd-process` (6.1.0) đã trỏ `--since` ở đoạn ⑦→⑧→⑨.
- Chưa làm: gate không đọc nhãn `[chặn]`/`[nợ chữ]` — nó là chỉ dẫn cho người/agent áp, không phải cổng; cổng
  đo hành vi bằng vân tay, không đo lời khai.

## 6.2.0 — 2026-09-18

### Thêm — `pre-commit.d/` · `commit-msg.d/`: chỗ cắm luật riêng của repo (#50)

Ca thật runxops: muốn nhánh `code/*` không chạm `tests/use-cases/**` (của vai T), `test/*` không chạm `src/**`.
Sửa thẳng `.sdd/hooks/pre-commit` thì (a) `update.sh` ghi đè mất, (b) `core.hooksPath=.sdd/hooks` là đường tương đối
và thư mục nằm trong git nên **worktree chạy bản hook của nhánh nó** — sửa trên `main`, commit thử ở `code/uc-014`
lọt, phải `reset --hard`.

- `pre-commit` và `commit-msg` của plugin chạy mọi file **thực thi** trong `.sdd/hooks/pre-commit.d/` /
  `commit-msg.d/` theo thứ tự tên, sau các kiểm của plugin; exit ≠ 0 là chặn, in `✗ <thư mục>/<file> chặn commit
  (exit N)`. `.example` và `README.md` không chạy. `commit-msg.d/*` nhận `$1` = file thông điệp như hook gốc.
  Hook mẹ export `SDD_ROOT · SDD_STAGED · SDD_CODE_PATHS · SDD_TEST_PATHS · SDD_UC_TEST_DIR` (+ `SDD_MSG`) để script
  con khỏi parse `.sdd/config` lại.
- `templates/githooks/pre-commit.d/10-role-boundary.sh.example` — khối ranh giới vai của runxops (`c3db645`), tổng
  quát theo `uc_test_dir` và `code_paths` thay vì viết chết `tests/use-cases` / `src`; merge (có `MERGE_HEAD`) qua.
- `scaffold.sh`: chép từng **file** trong `templates/githooks/` (cp trần lên thư mục dưới `set -e` sẽ gãy), tạo hai
  thư mục `.d`, chỉ làm mới `README.md` và `.example` — file thực thi của user là nội dung dự án, không đụng.
- README (mục *Mức chặn*) và `README.md` trong mỗi thư mục `.d` ghi rõ: **hook theo nhánh khi dùng worktree**, luật
  mới chỉ có hiệu lực sau merge.
- Đo trên repo giả: script exit 3 → `(exit 3)`, chặn; bỏ đi → qua; `code/uc-001` chạm `tests/use-cases/` → chặn
  đúng dòng ranh giới; `test/uc-001` chạm `src/` → chặn; nhánh chính chạm test → không có dòng ranh giới (chỉ
  `commit-msg` chặn vì chưa qua cổng); `init --update` giữ `10-role-boundary.sh` của user, làm mới README.
- Bẫy đã gặp lúc viết: `echo "… $(basename "$h") (exit $?)"` in `exit 0` — command substitution chạy trước khi `$?`
  khai triển. Bắt `rc=$?` trước.
- **Chưa làm, chờ chủ dự án quyết:** đặt `core.hooksPath` **tuyệt đối** tới `.sdd/hooks` của repo chính để mọi
  worktree chạy cùng một bản hook. Đổi hành vi: hook không còn theo nhánh, và đường tuyệt đối gãy khi đổi tên/di
  chuyển thư mục repo. Không tự chọn.

## 6.1.0 — 2026-09-18

### Năm lỗi cơ học từ một ngày chạy thật ở runxops (2026-09-17, #40 #41 #42 #43 #44)

- **#44** `pass.sh gate` → `reviewed`, `pass.sh close` → `implemented` **cả trong bảng
  `specs/contexts/<ctx>/use-cases.md`**, cùng commit với file UC. Ca thật: UC-014 đóng (`45dc32f`) mà bảng vẫn
  `draft`, `/sdd-solo:state` gợi UC tiếp theo sai, phải sửa tay một commit riêng (`cfbead4`). `lib.sh` thêm
  `uc_table_file · uc_table_status · uc_table_set` (ô đầu là ID, ô cuối là Status). Không có dòng thì nhắc, không
  chặn. `status.sh` in `!` khi file UC và bảng nói hai trạng thái, `–` khi UC không có dòng; và danh sách UC không
  còn in `UC-###.flow ?` / `UC-###.trace ?` như hai UC không status (lọt từ 5.0.0 khi có `.trace.md`).
- **#40** `verify`: *lượt verify kết thúc bằng commit đọc lại, không kết thúc bằng báo cáo.* Ca thật: subagent trả
  19 phát hiện, agent chính in "Báo cáo về…" rồi idle; `## Đọc lại` vẫn `___`; chạy bằng agent tự động thì dừng
  hẳn và cổng ⑨ đỏ dù đã đọc lại. Bước 4→5→6→7 là một lượt. Không có người trả lời (lời giao của agent điều
  phối, hoặc user bảo "tự chạy") thì **không** mở `AskUserQuestion` — agent chính đối chiếu, bác thì `→ không phải
  lỗi vì`, còn lại `→ Chưa quyết (chờ <ai>)`, vẫn ghi + commit. `--no-commit`: vẫn ghi `## Đọc lại`, chỉ bỏ commit,
  và nói rõ cổng chưa mở.
- **#41** `sdd-process` 14 bước thêm đoạn *"⑦ → ⑧ → ⑨ phải liền nhau"*: áp hết phát hiện ⑦ (kể cả chữ/nhãn, file
  bên cạnh) **trước** ⑧; sau ⑧ mọi commit đụng spec làm ⑨ đỏ, sửa là chấp nhận verify lại. `gate-check` §9 nhánh
  *"spec đổi sau lần đọc lại"* in thêm một dòng thứ tự — trước chỉ nói "chạy lại verify": đủ để sửa, thiếu để hiểu
  (họ hàng #37).
- **#42** `verify-pass.md` loại #2 tách hai nửa: khai nội dung mà diff không có → lỗi, thành `F#`; diff chạm thêm
  file bên cạnh mà thông điệp không kể → **cảnh báo mức thấp gộp một dòng**, không `F#`. Cách kiểm: so **nội dung
  khai** với diff, không so danh sách file. Ca thật F16 UC-014: hai commit bị xếp sai, tốn một lượt bác.
  `templates/project` → cần `init --update`.
- **#43** `context.sh`: `drop_trace()` cắt `## Adversarial pass · ## Đọc lại · ## History` **ở mọi cấp heading** của
  mọi nguồn trích (RULE, ADR Decision, BR, architecture, entities, glossary) và mọi dòng `- [x]`; entities không
  còn nhận khối "History" vì UC có chữ History; glossary bỏ `## History` và mục `## <context khác>` (tên context
  lấy từ `specs/contexts/*`); RULE nhận heading `##` lẫn `###`; ID trích lấy từ phần hiệu lực của UC, không từ dấu
  vết. **Cuối output in kích thước từng nguồn**, đánh dấu nguồn lớn nhất.
  Đo runxops UC-014: **250,9 → 221,6 KB** · entities 18,3 → 4,4 · glossary 28,3 → 16,5 · RULE 6 → 5. Nói thật phần
  còn lại: 9 ADR `## Decision` 60 KB · architecture 4 mục 45 KB · UC 27 AC 47 KB — là nội dung hiệu lực, không phải
  dấu vết. Muốn về ~30 KB như skill hứa thì phải **quyết cắt gì** (ADR chỉ in đoạn đầu Decision? architecture chỉ
  `## Cấm` cho verify?) — chưa quyết, chưa làm; skill `design` sửa lời hứa "≤ 30 KB" thành số đo thật.

## 6.0.0 — 2026-09-13

### Đổi luật — không còn cửa "qua đêm" ở cổng nào (#38, chủ dự án chốt)

Nguyên văn: *"anh muốn verify là bắt buộc, bỏ option qua đêm đi."* Ca thật: runxops `CHG-001` — `change-check`
xanh mọi dòng, đỏ mỗi *"commit docs(CHG-001) mới hôm nay — đọc lại ở một buổi khác"*; mục §8 của nó **chỉ có**
cửa qua đêm dù chú thích ghi "cùng luật với cổng DoR" (DoR đã có cửa verify từ 3.5.0/#27). Vì sao bỏ hẳn thay vì
thêm cửa verify cho Phase 5: một đêm đo *thời gian trôi qua*, không đo *việc đọc có xảy ra không* (#27); giữ hai
cửa song song qua hai bản lớn thì cửa rẻ hơn vẫn là cửa được đi. **Major** vì UC đang mở đã qua cổng bằng cửa qua
đêm (không có `F#` trong `## Đọc lại`) sẽ đỏ khi chạy lại `gate-check` → phải chạy `/sdd-solo:verify`. Đo trên
runxops: **0 UC bị đụng** (UC-009 implemented → nhánh "đã đóng"; UC-012 có 30 `F#`; UC-008 chưa qua cổng).

- `gate-check.sh` §9: bỏ cửa 1 và nhánh "gate-pass hôm nay" theo ngày. Còn: đã đóng → ✓ · commit spec mới nhất là
  gate-pass → ✓ · `## Đọc lại` có ≥ 1 `F#` đủ `[neo]` + đầu ra **và** commit `docs(UC): đọc lại …` là commit spec
  mới nhất → ✓ · không `F#` → ✗ "chưa đọc lại" · có `F#` nhưng spec đổi sau đó → ✗ "spec đổi sau lần đọc lại". Bộ
  lọc đường dẫn 5.2.0 giữ nguyên (design.md không tính). Không còn `today()` trong §9.
- `change-check.sh` §8: cùng hình — đọc `## Đọc lại` **trong `proposal.md`**, commit `docs(CHG): đọc lại …` phải
  là commit `docs(CHG)` mới nhất trong thư mục change; `change reviewed` của `pass.sh` vẫn ✓.
- `lib.sh`: `rr_lines` · `rr_count` dùng chung cho hai cổng (awk chuyển từ gate-check, không đổi logic).
- `uc-steps.sh` ⑧: chỉ đếm `F#` (hoặc dòng nén sau close); bỏ vế "commit qua một đêm".
- **`/sdd-solo:verify CHG-###`** (skill `verify` mục A′): subagent đọc proposal + delta + design + `context.sh`
  của mỗi UC baseline + toàn bộ rules.md + git log thư mục change; ghi `## Đọc lại` vào `proposal.md`; commit riêng.
- Khuôn `skel/change/proposal.md` có `## Đọc lại` (comment, không có dòng `F#` giả — đo: `rr_count` = 0 trên khuôn).
- Chữ: `adversarial` bước 7 (một đường, không còn "đóng máy buổi sau") · `verify` mô tả/bước 8 · `gate` mô tả ·
  `change` bước 3 · `sdd-process` ⑧ · `definition-of-ready.md` (templates/project → cần `init --update`) ·
  `skel/use-case/UC-000.md` · README gốc (bảng lệnh + mục "Nâng cấp 5.x → 6.0.0") · CLAUDE.md gốc (ranh giới mới).
- Đo trên bản sao runxops: UC-012 không `F#` → ✗ (5.2.0: ✓ cửa 1) · 30 `F#` + commit đọc lại → ✓ · sửa spec sau →
  ✗ · commit design.md → không đổi kết luận · đọc lại lần nữa → ✓ · gate-pass → ✓ · UC-009 → ✓ đã đóng ·
  CHG-001: thêm `F#` + commit đọc lại → ✓ · sửa delta → ✗ · đọc lại → ✓ · change-pass → ✓.
- Hệ quả cố ý, nói thật: **đọc không ra gì thì cổng không mở**, không có cửa thoát. Đường đúng là mở rộng phạm vi
  đọc (rule UC không trích, sequence, entities, đo lại số) — một dòng `→ không phải lỗi vì <lý do>` sau khi đọc
  thật là đầu ra hợp lệ; bịa một dòng `F#` thì không, và `gate-check` §7/§9 kiểm ID trong dòng đó có thật.

## 5.2.0 — 2026-09-13

### Sửa — cổng DoR đỏ oan sau bước ⑩ (runxops-ea)

`gate-check.sh` §9 tìm commit `docs(UC-###)` mới nhất **theo tiêu đề**. Bước ⑩ (skill `design` §6) bảo
commit `docs(UC-###): thiết kế — design.md + tasks.md` → cổng đỏ *"spec mới hôm nay"* dù `UC-###.md`
không đổi một byte. "Luật đúng, phạm vi sai." Tái hiện trên repo tạm với nội dung runxops: đỏ ngay sau
commit design.md. → Chỉ tính commit `docs(UC-###)` **có đụng spec**: `UC-###.md` · `UC-###.flow.md` ·
`screens/` · `rules.md` · `entities.md`. Đo 6 ca: commit design.md hôm nay → xanh cửa 1; sửa `UC-###.md`
hôm nay → đỏ; commit gate-pass → xanh nhánh gate-pass; design.md sau gate-pass → xanh; commit đóng UC → xanh
"đã đóng"; sửa `rules.md` dưới `docs(UC-###)` → đỏ. Lỗ **có sẵn từ trước, chưa xử**: sửa `rules.md` dưới
tiêu đề `docs(UC-010)` hay `docs(RULE-###)` thì UC-009 không thấy — bỏ grep tiêu đề sẽ đúng nghĩa hơn nhưng
làm mọi UC cùng context đỏ khi ai đó sửa rules.md; chờ ca thật.

### Thêm — câu cần người quyết phải hiện bằng `AskUserQuestion` (#36)

Đo ở runxops 2026-09-11, một session: bốn câu "chốt trước" ở `start` bước 8 viết thành bullet cuối tin
nhắn → chủ dự án tự đánh số trả lời, trả lời một nửa; cùng ngày, câu đi qua `AskUserQuestion` (E1/E5/E9 của
UC-009, context của UC-012) → dứt điểm ngay. Issue #25 đã đòi ngữ cảnh + phương án, chưa nói **kênh**.

- `sdd-process` luật **1b**: câu chọn giữa các hướng → `AskUserQuestion`; ≤ 4 câu/lượt · 2–4 lựa chọn kèm
  hệ quả · đề nghị đặt đầu "(Recommended)" · `Chưa quyết — ghi Open Question` luôn là một lựa chọn. Câu
  treo được thì không hỏi. Câu mở (khổ gì, ai khổ) vẫn hỏi bằng lời. Đặt ở kiến thức nền vì ca ADR-007
  trong issue nằm **ngoài mọi skill lệnh** — chỉ chỗ này với tới.
- `start` bước 3 (chọn context) và bước 8 (nhóm "chốt trước") nói rõ kênh; nhóm "treo" ghi thẳng, không hỏi.
- `intake`: "BR mới hay sửa BR cũ" qua `AskUserQuestion`; bảy câu phỏng vấn giữ nguyên là câu mở.
- **Không sửa** `adversarial` (A5/B5) · `verify` (bước 4) · `design` (§2): ba chỗ đã nói đúng
  `AskUserQuestion` từ #25 — issue #36 kể cả ba vào "chưa nói kênh" là chưa đo lại.
- Không có script kiểm — đây là chỉ dẫn cho agent, không phải cổng.

## 5.1.1 — 2026-09-10

### Sửa (hai lệch runxops-ea báo sau khi chuẩn hoá theo 5.1.0)

- **`specs/internal/decisions.md` khuôn** trỏ `.specify/###/design.md` và `changes/CHG-###/` — hai đường
  không còn từ 4.0.0 và 2.0.0. → `<ADR-### | UC-###/design.md | specs/changes/CHG-###>`.
- **`commit-msg`** cảnh báo *"file nguồn nằm ngoài code_paths"* cho file đang bị `git rm` — `git diff
  --cached --name-only` liệt kê cả file xoá (đo: có; `--diff-filter=d` → rỗng). Lọc **chỉ ở `SRCLIKE`**,
  không ở `$STAGED` toàn cục như peer đề xuất: `$STAGED` còn nuôi `TOUCH_CODE` và `pre-commit`, và một
  commit *xoá* code domain gắn UC chưa qua cổng vẫn là commit đụng code — phải chặn y như thêm. Đo cả
  hai chiều: `git rm` file ngoài code_paths → hết cảnh báo; `git rm` code domain gắn `UC-001` không marker
  → vẫn bị chặn.

## 5.1.0 — 2026-09-10

### `## Adversarial pass` của BR — dấu vết chưa nén, lời khai chưa kiểm (issue từ runxops-c1)

5.0.0 nén dấu vết cho **UC** (`trace.md`) và từ 3.x cổng UC đã kiểm lời khai `→ spec` trống (#12).
Cả hai chưa bao giờ lan sang **BR**. Peer đo, em đo lại — số khớp:

| | Peer | Đo lại |
|---|---|---|
| `## Adversarial pass` BR-001 | 6,5 KB | 6,5 KB |
| Câu / chưa có đầu ra | 30 / 10 `→ ___` | 30 / 10 |
| `br-check` chỉ grep `Ngày chạy:` | [br-check.sh:224] | đúng — có chữ đó là xanh |
| Luật *"không có để đó"* có, phép kiểm không | `skills/adversarial:149` | đúng |
| BR hiện v14 | v14 | **v14** — em từng nói v2, sai: awk của em dừng sớm; `sec()` của br-check đọc đúng |

Câu đắt nhất của tầng BR — *"đây có thật là BR không"* — được hỏi một lần trên v1, đầu ra treo 10
câu, BR đã sang v14, và không phép kiểm nào nhìn thấy. **Luật đúng, phạm vi sai.**

### Thêm
- **`migrate.sh --evidence BR-###`** dời thêm thân `## Adversarial pass` sang `br.evidence.md`, để lại
  MỘT dòng đếm bằng máy — và **in số `___` ra mặt tiền**, vì Phase 1 được phép còn `___` (quyết định
  3.x, vẫn đúng): nợ lộ ở chỗ ai cũng đọc, thay vì chôn ở dòng 300.
  `- Ngày chạy: 2026-09-08 · 3 vai · trên v2 · 30 câu → 20 đã áp · 10 → ___ → specs/br.evidence.md`
  Background và Adversarial tách **độc lập** — repo đã tách Background ở 5.0.0 (đúng trạng thái runxops
  sau khi peer chạy) vẫn tách được Adversarial. Bản đầu không thế: "Background đã tách rồi" thoát sớm và
  Adversarial không bao giờ được xét — bắt được vì test đúng trạng thái runxops thay vì bản gốc.
- **`br-check` §10b**: cảnh báo kèm số `N/M câu chưa có đầu ra`. **Đỏ** khi có `→ Open Question` mà
  `## Open Questions` cùng BR không có dòng `- [ ]` nào — lời khai trỏ vào chỗ trống. Khớp từng câu
  bằng từ khoá (3 từ dài nhất, cần ≥ 2 trùng) → chỉ **cảnh báo** kèm câu: diễn đạt lại thì máy chịu,
  và đỏ oan dạy người ta phớt lờ. Đọc được cả thân lẫn dòng đếm + `br.evidence.md` sau khi tách.
- **`br-check` §10c**: *"ba vai đọc bản nào?"* — Adversarial ghi `trên vN` (hoặc chỉ ngày), History có
  vM; N < M → cảnh báo. Không bắt chạy lại, chỉ nói ra. runxops: *"ba vai chạy trên v2, BR đã là v14"*.

### Không làm
`___` = đỏ ở Phase 1 — peer và em cùng ý, đó là quyết định có chủ ý. Cần **đếm ra**, không chặn.
`## History` của BR (4,9 KB) để riêng: nó mang ngày, và 4.2.0 nói ngày là thứ duy nhất không tái tạo được.

## 5.0.0 — 2026-09-10

### Vừa với một người — bớt file · bớt dấu vết · một lệnh cho agent

Không cắt bước nào trong 14. Cắt **thứ mỗi bước để lại** và **chỗ nó nằm**. Số đo trên `runxops`
(dự án thật, nhiều tuần làm việc) trước khi quyết cắt gì:

| Đo | Kết quả |
|---|---|
| Chữ đã viết trong `specs/` | **44.761 từ · 258 KB · 30 file** — đổi lấy 0 dòng `src/`, 0 UC implemented, `57 docs : 1 feat` |
| File rơi vào dự án | **55**, trong đó **34 vẫn nguyên khuôn** (62%), chỉ **13** có nội dung |
| Để hiểu một UC agent phải đọc | **210 KB ≈ 53k token**, 15 file, 6 thư mục |
| `UC-009.md` 56 KB | 18 KB hiệu lực · **33 KB dấu vết** — `## Đọc lại` 11,3 · `## Adversarial pass` 11,0 · `## History` 6,3 — không ai đọc lại |
| `BR-001` 73 KB | 15 KB quyết định · **56 KB** — `## Background` 31,8 KB chứng cứ · Open Q 12,9 · Adversarial 6,5 · History 4,9 |

Sách nguồn (`SDD-Ebook.epub`) **không** định nghĩa 14 bước — chuỗi đó do ta đắp dần, mỗi bước vì một
lần hỏng thật, và chưa lần nào đứng lại hỏi cả 14 cộng lại có còn vừa với một người. Sách xếp *"side
project một người"* vào **"khi nào không nên dùng"**; runxops lại trúng 4–5/6 dấu hiệu "nên dùng"
(sống > 6 tháng · rule nghiệp vụ không tầm thường · **AI sinh phần lớn code** · lõi sản phẩm) — nhưng
**vì lý do khác sách**. Sách viết cho *truyền đạt giữa người và người*; lý do của một dev solo là *trí
nhớ xuyên thời gian* và *đầu vào chính xác cho AI*. Chỗ khác đó là đường cắt:

> Artifact phục vụ truyền đạt / biên bản cho người thứ hai → bỏ.
> Artifact phục vụ trí nhớ và đầu vào AI → giữ.
> **Một bước là công cụ để nghĩ thì để lại một quyết định, không để lại một tài liệu.**

Sách còn dặn đúng thứ đã xảy ra: *"Đừng đo SDD bằng số dòng spec… Lines of spec: khuyến khích viết dài."*

Rút lại một nhận xét cũ: bước ⑥ và ⑬ (chạy xong không để lại gì) từng bị em gọi là "thiếu". Số đo nói
ngược lại — chúng là hai bước duy nhất **có hình dạng đúng** cho solo. Bệnh ở ⑦ ⑧: cùng loại *công cụ
để nghĩ* nhưng lưu biên bản như thể có người thứ hai sẽ kiểm.

### A. Bớt file — khuôn 43 → 16, runxops 55 → ~28

- **`.sdd/templates/` (14 file) về plugin** tại `templates/skel/{use-case,context,change}/`. Chỉ skill
  đọc chúng, mà skill chỉ chạy khi có plugin → lý do "bản sao chạy được không có plugin" (lý do
  `.sdd/scripts/` tồn tại) **không áp**. Bốn skill (`start` · `design` · `change` · `sdd-process`) copy
  từ `${CLAUDE_PLUGIN_ROOT}/templates/skel/`.
- **13 ngăn kéo trống bỏ khỏi khuôn** — đo hai lần: không script/skill nào đọc, và ở runxops vẫn
  nguyên byte sau nhiều tuần: `context-map` · `story-map` · `design-system` · `onboarding` ·
  `runbooks/README` · `changes/README` · `contexts/README` · `internal/README` · `README.md` gốc ·
  `definition-of-done` · `feedback-triage` · `prompts/session-start` · `.sdd/gate/README`. Phase 0 /
  Phase 4 không còn file hứa hộ — `specs/README.md` ghi một dòng "chưa có lệnh".
  Ranh giới đã dùng: *chưa ai đụng + không ai đọc = chết · chưa ai đụng + đang được chạy = sống*
  (`verify-pass.md` 27,5 KB nguyên khuôn nhưng là prompt đang chạy → giữ).
- `scaffold.sh` **`RETIRED_TPL`** liệt kê đích danh 27 đường dẫn, xoá **chỉ khi sha khớp manifest**
  (đã sửa tay → giữ + cảnh báo), rồi `rmdir` thư mục rỗng. Đo: repo 4.2 nguyên khuôn → dọn 27, sạch;
  một file sửa tay → còn nguyên.
- `specs/README.md` là biển chỉ đường duy nhất; `docs/` (một khái niệm cũ không còn thư mục) ra khỏi
  mục *Ranh giới*.

### B. Dấu vết → quyết định

**B1. `pass.sh close` dời thân `## Adversarial pass` · `## Đọc lại` · `## History` · Open Question đã
`[x]` sang `UC-###.trace.md`** cùng thư mục, để lại tại chỗ một dòng có **số đếm bằng máy**:
```
- Ngày chạy: 2026-09-09 · 3 vai · 24 câu, đã áp hết → UC-009.trace.md
- Ngày chạy: 2026-09-09 · 51 phát hiện · 1 dương tính giả · đã áp hết → UC-009.trace.md
- v14 (2026-09-10): implemented · lịch sử đầy đủ → UC-009.trace.md
```
Nén ở ⑭ chứ không ở ⑨: lúc UC còn mở, `F#` là danh sách việc và cổng đọc nó bằng máy. Không xoá gì —
git giữ, tranh chấp thì mở `trace.md`. Đo trên `UC-009` thật: **56 → 27 KB**, `trace.md` 29 KB, tổng
56 = 56. `uc-steps` ⑦⑧⑭ xanh; `gate-check`/`close-check` chạy lại sau close **không đỏ oan** (nhánh
mới nhận commit `implemented — traceability`); chạy close lần hai không nén kép.
Lỗi bắt được khi test: UC **khuôn trống** cũng bị "dời 3 mục" — nó nén cả `YYYY-MM-DD`. → thân còn
placeholder thì không phải dấu vết, không dời.

**B2. `migrate.sh --evidence BR-###`** dời thân `## Background` sang `specs/br.evidence.md`, giữ trong
`br.md` mọi `### heading` (+ dòng `→ specs/br.evidence.md`) và mọi đoạn bắt đầu bằng `**` (`**Vì sao
vẫn xây:**`, `**Nguồn brief:**` — `br-check` đọc chúng). Đo trên `BR-001` thật: **31,8 → 6,4 KB**, 15
`###` + 13 dòng `**` ở lại, `br-check` xanh, `--dry-run` không đụng đĩa, chạy lại không làm kép.
`/sdd-solo:intake` từ nay viết chứng cứ thẳng vào `br.evidence.md`; Background trong `br.md` là mục lục.

### C. `context.sh UC-### [--why]` — một lệnh, đúng đủ bối cảnh

Thay cho lời dặn đọc **13 tên file** ở `/sdd-solo:design` §2 — lời dặn không kiểm được, và đã hụt ở #34.
In ra (không ghi file): UC bỏ ba mục dấu vết và Open Q đã đóng · flow · **chỉ những** `RULE`/`CON`/`ADR`
được trích (thiếu → dòng `!`) · mục BR cha không Background · bốn mục `architecture.md` (còn `<...>` →
dòng `!`) · entity/glossary UC nhắc tên · dòng brief để đọc riêng (ngoài `specs/`, #34 giữ nguyên).
Cuối có dòng đo KB. `--why` chỉ in RULE · CON · ADR · `## Cấm` — nửa còn lại của `decisions.sh`: một
cái đi từ thời gian xuống quyết định, cái kia đi từ một UC lên.

Đo trên `UC-009` runxops: **210 KB → 88,8 KB** (−58%), 9 nguồn; `--why` **28,7 KB**. Mục tiêu ~30 KB
trong plan là **sai** cho bản đầy đủ — soi từng mục thì không có mục nào bất thường (UC 26,7 · RULE
11,0 · architecture 9,7 · entities 9,3 · BR 8,8 · CON 7,5 · ADR 6,8 · glossary 5,2): 89 KB là cỡ thật
của phần đang hiệu lực. Ghi số thật, không ép.
`adversarial` · `verify` · `design` · `status` gọi nó; `design-check` §4 gợi ý `--why`; vào `KEEP`
của scaffold.

### D. Bớt context thường trực
`sdd-process/SKILL.md`: đoạn sử AIUP (#29) thành một quy tắc chung không gọi tên lệnh ai; thêm luật
*"cần bối cảnh UC thì chạy `context.sh`, không tự nhặt file"*. `skills/start` bỏ hai chỗ trỏ
`/use-case-spec` (AIUP).

### Ở dự án — major, phải làm tay
`/plugin marketplace update` → `/plugin update` → `/sdd-solo:init --update` → session mới →
`bash .sdd/scripts/migrate.sh --evidence BR-### --dry-run` rồi thật. `br.md` còn `BR-000` mẫu →
xoá (4.2.0). Xem README *Nâng cấp 4.x → 5.0.0*.

## 4.2.0 — 2026-09-10

### Bộ tài liệu này chứa những quyết định gì — trả lời được bằng một lệnh

Câu hỏi mở màn không phải "thiếu phép kiểm nào" mà là *"anh cần nắm bắt chính xác bộ tài liệu
này chứa những quyết định gì. Nó có thể đi theo anh 5–10 năm."* Phép đo trả lời: **7 loại quyết
định, ở 6 chỗ, 4 khuôn khác nhau.**

| Loại | Ở đâu | Ngày | Vì sao | Thay được? | Script kiểm |
|---|---|:--:|:--:|:--:|:--:|
| `RULE-###` | `specs/rules.md` | ✓ | ✗ | ✓ | **không** |
| `ADR-###` | `specs/internal/adr/` | ✓ | ✓ | ✓ | **không** |
| `BR-###` | `specs/br.md` | ✗ | ✓ | ✗ | có (status vòng đời) |
| `CON-###` | `br.md`, một gạch đầu dòng | ✗ | ✗ | ✗ | **không** |
| `Cấm` | `internal/architecture.md` | ✗ | ✓ | ✗ | cảnh báo `nguyên văn` |
| `CHG-###` | `specs/changes/` | ✓ | ✓ | — | có |

Hai dòng đầu có đủ giải phẫu của một quyết định. Nhưng `grep 'Status' scripts/*.sh` cho thấy
**mọi** chỗ đó đều là status vòng đời của UC/BR/CHG; `deprecated` xuất hiện đúng **một lần**,
ở `change-check.sh:134`, cho AC bị gỡ. Tức khuôn có ô để điền mà không ai kiểm ô đó — hình
dạng của `constitution.md` bên Spec Kit vẫn còn `[PROJECT_NAME]` sau nhiều tháng.

### Chỗ 5–10 năm đánh gãy: một quyết định mất ngày thì mất vĩnh viễn

Ca runxops đã ghi ở `architecture.md`: *"đó là HAI điều cấm từ hai thời điểm, cái sau ngặt hơn
và nuốt luôn thứ In Scope đang cho phép"*. Câu đó **chỉ nói được khi có ngày**. Không ngày thì
hai dòng nằm cạnh nhau, đọc đều trôi chảy, và không ai — kể cả chủ dự án — dựng lại được cái
nào ra trước. Ca đó xảy ra sau vài tháng, không phải sau 5 năm.

Đó là thứ duy nhất trong bộ tài liệu **không tái tạo được**. Bố cục file lúc nào cũng sắp lại
được; ngày và lý do thì không.

### `CON` không phải quyết định — nên nó có một trường riêng

Ba ví dụ trong khuôn: hosting không chạy job quá 30 giây · bản ghi giữ 10 năm theo luật kế
toán · người bán chỉ có buổi tối. **Không cái nào do ta chọn.** Đó là *sự thật về thế giới*
đang ràng buộc quyết định, khác loại với RULE (ta đặt ra) và ADR (ta chọn phương án).

Khác loại thì hỏng theo cách khác:
- một **quyết định** hết đúng khi *lý do* của nó hết đúng — lý do nằm ngay trong file;
- một **ràng buộc** hết đúng khi *thế giới* đổi — và thế giới đổi thì **không có gì trong repo
  động đậy cả**.

Đổi hosting năm 2028 thì `CON-001` lặng lẽ thành sai, mọi UC dựng quanh nó vẫn xanh. Cùng lớp
"báo xanh sai", nhưng nguồn nằm ngoài repo. Nên khuôn CON có `Kiểm lại:` — trường biến chuyện
đó thành một dòng **có thể quá hạn**, tức đo được. Nó không cần là ngày; *"khi đổi gói hosting"*
là mốc hợp lệ và thường đúng hơn ngày.

`CON` **ở lại `br.md`**: nó là đầu vào của một BR cụ thể, `## Constraints` đang lồng trong từng
BR, và 19 chỗ trong plugin neo vào vị trí đó. Dời ra là cắt sự thật khỏi lập luận đã dùng nó.

### Thêm

- **`scripts/decisions.sh [--md]`** — sổ tra gom `CON` · `RULE` · `ADR` · `Cấm` · `CHG` · ghi chú
  từ sáu chỗ về **một dòng thời gian**. Xếp theo thời gian là chủ ý, không phải cho đẹp: hai
  quyết định cách nhau vài tháng, đọc rời từng file thì đều trôi chảy; nằm cạnh nhau thì cái sau
  ngặt hơn tự lộ ra. Mắt người bắt được thứ không phép kiểm cơ học nào bắt được.
  - **Không ghi file.** Sổ sinh ra rồi commit là một bản sao sẽ trôi khỏi nguồn — lại đúng cái
    bẫy cả 3.x đi chữa. `--md` để xuất khi cần dán đi chỗ khác, người dùng tự hứng.
  - **Luôn `exit 0`.** Nó là thứ để đọc, không phải cổng.
- **Khuôn CON** (`br.md`) có dòng thứ hai: `Từ:` · `Biết qua:` · `Kiểm lại:` · `Trạng thái:`.
- **Khuôn RULE** (`rules.md`) thêm `Từ:` và `Vì sao:`. `Vì sao` khác `Nguồn`: nguồn nói rule
  này *từ đâu ra*, vì sao nói nó *tồn tại để làm gì*. Rule mất `Vì sao` thì năm năm sau không
  ai dám bỏ — không phải vì nó còn đúng, mà vì không ai biết bỏ đi thì hỏng chuyện gì.
- **Mục `## Cấm`** (`architecture.md`) thêm `Từ:` · `Trạng thái:`. Hết hiệu lực thì ghi
  `thay bởi <ID> từ <ngày>`, **không xoá dòng** — xoá một điều cấm là xoá bằng chứng nó đã từng
  được cân nhắc.

### Sửa — `ADR-000-template.md` làm `id_exists ADR-000` báo XANH SAI

`id_exists()` tra ADR bằng `ls specs/internal/adr/ADR-000*`, mà chính cái khuôn mang tên đó.
Nên trong **mọi repo vừa scaffold**, một `design.md` trích `ADR-000` được `design-check` cho
qua màu xanh — dù chưa ai viết một ADR nào. Thứ "tồn tại" mà phép kiểm nhìn thấy chỉ là cái
khuôn của chính nó. Không cần ai viết sai gì cả; chỉ cần cài.

→ đổi tên thành **`_adr-template.md`**, và `decisions.sh` bỏ qua mọi file `adr/_*`.

`scaffold.sh` có thêm **`RETIRED_TPL`**: chép tên mới vào mà không dọn tên cũ thì repo nâng cấp
xong vẫn còn nguyên đường cũ, lỗi sống tiếp. Khác `RETIRED` của scripts một điểm — file dưới
`specs/` là *nội dung của dự án*, nên chỉ xoá khi sha khớp manifest (user chưa đụng). Đã sửa
tay thì cảnh báo và để nguyên: thà để lỗi kêu to còn hơn tự tay xoá chữ của người khác.

### Sửa — `BR-000` phải BIẾN MẤT khi đã có BR thật

Tìm ra bằng cách chạy sổ tra mới lên `runxops`. Luật cũ của `/sdd-solo:intake` là *"Giữ nguyên
`BR-000` mẫu"* — và đó chính là chỗ hỏng.

`BR-000` mang `CON-001/002/003` **của riêng nó**, và `BR-001` thật ở `runxops` cũng mang
`CON-001/002/003`. `id_exists()` tra CON bằng `grep` **dòng đầu tiên khớp**, nên nó luôn trúng
bộ của `BR-000`. Hệ quả đo được, không phải giả định:

- `UC-009.md:277` trích `CON-002` → cổng DoR khớp vào *"bản ghi thanh toán phải giữ 10 năm theo
  quy định kế toán"*, trong khi `CON-002` thật là *"sáu gian, mỗi gian một profile Multilogin"*.
- `architecture.md ## Cấm` viết *"Không gọi API eBay. `CON-001` — tài khoản cá nhân, không có tài
  khoản dev"* → `design-check` báo **XANH** bằng cách trỏ vào *"hosting chia sẻ, không chạy được
  job nền quá 30 giây"*.

`UC-009` **đã qua cổng DoR** với những trích dẫn trỏ nhầm mục.

Một BR mẫu có ích đúng lúc chưa có gì để đọc. Sau đó nó là một dãy **ID giả đứng trước mọi ID
thật trong cùng một file** — và ID giả đứng trước thì mọi phép tra "dòng đầu tiên khớp" đều rơi
vào nó. Chữa bằng cách đánh lại số CON của BR thật là chữa triệu chứng.

- `skills/intake`: **xoá cả mục `BR-000`** khi viết BR thật đầu tiên (thay câu "giữ nguyên").
- `br-check.sh`: **đỏ** khi br.md đã có BR thật mà `BR-000` còn đó.
- `br-check.sh` §6b: **đỏ** khi hai BR mang cùng một số `CON` — quét cả file, không chỉ BR đang
  kiểm. Không thừa sau khi `BR-000` đi: hai BR *thật* cũng đụng nhau y hệt, và mỗi BR viết ở một
  thời điểm khác nhau thì không ai nhớ BR trước đã dùng số tới đâu.

Bản đầu của chính hai phép kiểm này **báo đỏ oan trên repo vừa scaffold**: khuôn phát ra sẵn
`# BR-001: <Tên business requirement>`, nên "có ID BR-001" là đúng ngay lần cài đầu. Đếm bằng
*sự có mặt của một ID* là sai; "BR thật" phải là **tiêu đề không còn `<...>`**. Bắt được vì
chạy trên repo trắng trước khi tin — cùng một luật đã cứu ba lần trong bản này.

### Sửa — `design-check` tố oan dòng nằm GIỮA một khối chú thích

Bộ lọc placeholder của §1 dùng `strip_tags` (chỉ bỏ **thẻ**) cộng một `grep -v` bỏ dòng **bắt
đầu** bằng `<!--`. Nên một `<ID>` nằm ở dòng *giữa* khối `<!-- … -->` nhiều dòng vẫn bị tính là
placeholder. Chính khuôn `architecture.md` của bản này dính: khối giải thích mục `## Cấm` có câu
*"thay bởi `<ID>` từ YYYY-MM-DD"*, và `design-check` báo đỏ một repo **vừa scaffold**.

Lần thứ ba cùng một bẫy (4.0.1, 4.0.x, giờ 4.2.0), và lần này là code của chính bản này tố oan
template của chính bản này. → cả hai chỗ dùng `strip_markup` của `lib.sh`, thứ bỏ **cả khối**.
Nó giữ nguyên số dòng (đo: 97→97) nên `grep -n` vẫn trỏ đúng dòng trong file gốc.

`strip_tags()` cục bộ **xoá hẳn**, không để lại. Hai hàm chỉ khác nhau ở đúng điểm gây lỗi; giữ
một hàm chỉ-bỏ-thẻ nằm cạnh là mời người sau dùng lại đúng cái vừa hỏng.

### Bốn lỗi khác bắt được khi test, đều bằng cách chạy thật

1. **Sổ tra liệt kê chính lời giảng trong khuôn.** Repo trắng ra 9 mục, trong đó `RULE-000
   <Tên rule — ĐÂY LÀ MẪU>` và `không <việc bị cấm>`. → `ghost()` bỏ dòng còn `<...>` / `...`
   / `___`. Dấu đóng `>` là bắt buộc nên `"response < 200ms"` không bị bắt oan.
2. **`BR-000` là BR mẫu và nó Ở LẠI VĨNH VIỄN** — `/sdd-solo:intake` dặn thẳng *"Giữ nguyên
   BR-000 mẫu"*, `br-check.sh:11` bỏ qua nó vì cùng lý do. Không bỏ ở `decisions.sh` thì ba
   `CON` dạy-việc của nó (hosting, luật kế toán) nằm trong sổ tra của **mọi dự án, mãi mãi** —
   và chúng không phải placeholder, chúng đọc y như quyết định thật. Đây là lỗi nặng nhất
   trong bốn cái, và nó chỉ lộ ra vì đã chạy trên repo trắng trước khi tin.
3. **Cột lệch vì đếm byte.** `awk length()` ở macOS đếm **byte**; `"ràng buộc"` 9 ký tự nhưng
   12 byte, đủ lệch cả bảng. `${#v}` của bash đếm **ký tự**. → căn cột ở bash bằng `padc()`,
   và ID của mục `## Cấm` dùng ASCII `CAM-N`.
4. **`grep -c` in `0` rồi exit 1**, nên `$(grep -c . f || echo 0)` cho ra `"0
0"`.

Một điều đã tự sửa lúc viết: `CAM-N` đánh theo **thứ tự xuất hiện**, và điều đó có chủ ý —
*"số không phải danh tính, nó là vị trí, và vị trí thì đổi"*. Chèn một điều cấm ở giữa là mọi
số sau nó chạy. Nên đừng trích `CAM-N` từ đâu cả; cần trích được thì nâng nó thành `RULE-###`
hoặc `ADR-###`, hai thứ có ID thật.

### Chưa làm — cố ý

**`decision-check.sh` (cổng cứng) để bản sau.** Bật cổng ngay lúc này thì runxops đỏ toàn tập
với hàng chục dòng thiếu ngày, và cách duy nhất đi tiếp là học cách phớt lờ nó — đúng câu đã
ghi từ 3.x: *"báo đỏ oan thì bị học cách phớt lờ, rồi kéo theo cả những dòng đỏ thật"*. Nhìn
bảng, điền xong, rồi mới khoá.

Phép kiểm muốn nhất ở bản đó: **`nguyên văn: "X"` → `grep -F "X"` vào đúng file của nguồn,
không thấy thì đỏ.** Đó sẽ là phép kiểm đầu tiên trong cả plugin **đọc nội dung của nguồn**
thay vì chỉ hỏi ID có tồn tại — món nợ đã ghi năm lần: *mọi luật kiểm ID có tồn tại, không luật
nào kiểm ID có dính gì tới thứ đang gắn nó*.

### Ở dự án

`/plugin marketplace update sdd-solo` → `/plugin update sdd-solo` → `/sdd-solo:init --update`
(đụng `templates/`) → `bash .sdd/scripts/decisions.sh`.

## 4.1.1 — 2026-09-10

### Đính chính — cơ chế nêu ở 4.0.0 ① là sai; kết luận thì không đổi

Cài `specify` bản mới nhất (`1.0.5.dev0` → **`1.0.6.dev0`**), dựng một bản `specify init` sạch, rồi
cho subagent soi. Kết quả chạm thẳng vào câu chính bản này đã viết ở 4.0.0.

**Đã viết (sai):** *"`create-new-feature.sh` hardcode `SPECS_DIR="$REPO_ROOT/specs"`, và
`get_highest_from_specs` quét `specs/*` để lấy số kế tiếp."*

**Đo lại:** script đó **có tồn tại và làm đúng như mô tả**, nhưng **không skill nào gọi nó** —
`grep -rl 'create-new-feature' .claude/skills/` ra rỗng, cả trên `1.0.6.dev0` lẫn trên bản cũ hơn đã
cài ở `runxops`. Nó chỉ với tới được qua một hook đọc `.specify/extensions.yml`, mà file đó **không
tồn tại** trong bản init sạch. Tức là một **script ngủ**.

**Bản đúng:** thứ chạy thật là **lời văn trong `speckit-specify/SKILL.md`** (dòng 84, 88, 91, 93):
specs nằm dưới `specs/`, số tiếp theo lấy bằng cách *"scanning existing directories in `specs/`"*,
rồi `mkdir -p specs/<NNN>-<slug>`.

**Kết luận ① không đổi, và thật ra mạnh hơn.** Một script thì cấu hình lại được, đọc biến môi trường
được, thay được. **Một câu dặn nằm trong skill của agent thì không** — nó là hành vi mặc định của
model khi chạy lệnh đó. Hai cây spec vẫn chung một thư mục, và phép đếm số của họ vẫn quét cả
`br.md`, `contexts/`, `changes/` của mình.

**Vì sao em viết sai:** đọc script, thấy nó khớp hoàn hảo với hiện tượng, dừng lại ở đó. **Không hỏi
câu tiếp theo: có ai gọi nó không.** Đúng hình lỗi đã ghi ở 3.4.1 — *suy ra cơ chế từ tên (ở đây là
tên và nội dung file) rồi đi tìm bằng chứng khớp*, thay vì đi tìm bằng chứng nó thật sự chạy.

**Câu sai nằm ở NĂM chỗ** — `CHANGELOG` · `README.md` gốc · `plugins/sdd-solo/README.md` ·
`migrate.sh` · `deps-check.sh`. Bốn chỗ sửa tại chỗ; mục 4.0.0 trong CHANGELOG **giữ nguyên văn**
kèm một dòng đính chính trỏ sang đây — lịch sử không viết đè, đó là luật đã dùng từ 3.4.1.

### Ghi nhận — hai chỗ Spec Kit đo được, đáng đối chiếu với chính mình

Không đổi code, chỉ ghi lại để lần sau khỏi đo lại:

- **`## Constitution Check` của `plan-template.md:39-43` là văn xuôi tự do** — không ID, không
  checkbox, không bảng; không script nào trong `.specify/scripts/bash/` kiểm nó; kết quả pass/fail
  **không được lưu ở đâu** cho công cụ khác đọc lại. Cổng quan trọng nhất của họ dựa hoàn toàn vào
  việc model tự đọc tự quyết. Đó là lý do `.specify/memory/constitution.md` trong bản init **sạch
  mới nhất** vẫn nguyên `[PROJECT_NAME]`: không phải ai quên điền, mà **không gì bắt điền**.
- **`setup-plan.sh` không kiểm `spec.md` có tồn tại không** (grep toàn file: không có dòng nào), và
  `/speckit-implement` không truyền `--require-spec`. Chuỗi của họ chặn cứng quanh `plan.md`, không
  quanh `spec.md`.

Hai điều đó xác nhận quyết định 4.0.0 từ một góc chưa lường: `design-check.sh` kiểm `architecture.md`
**bằng máy** — chỗ này sdd-solo đã đi xa hơn bản gốc nó học theo, nên đừng "đồng bộ ngược" về sau.

Ngược lại, **hai chỗ Spec Kit làm chặt hơn hoặc gọn hơn**, ghi lại để cân nhắc chứ chưa làm:

- **`speckit-claude-design` là extension do chính chủ dự án viết** (`author: quangman`, cài bằng
  `specify extension add … --dev` ở `IOS-Hoi-Thoai`) — sáu động từ `import · pull · inventory ·
  ensure · verify · drift`. Trong đó `drift` giữ `context-snapshot.json` băm từng artboard rồi so
  lại — **đúng hình cơ chế `brief_sha` mà #34 dựng cho brief**, chỉ khác đối tượng. Và `verify` với
  `strict_verify: true` thì **exit non-zero** — tức nó có cái cổng bằng máy mà `Constitution Check`
  không có. Bước ⑤ của sdd-solo (Claude Design) hiện **không có artifact nào kiểm được**; đây là
  bản thiết kế sẵn để học.
- **`shared_infra.py:432-475` gần trùng `scaffold.sh` của mình**: so hash với manifest lần cài
  trước, khớp thì ghi đè, lệch thì giữ và cảnh báo. Khác một chỗ và khác về phía nguy hiểm:
  `specify init --force` **ghi đè thẳng file người ta đã sửa tay, không hỏi**. `scaffold.sh` không
  bao giờ làm thế — nó đẻ file `.new`. Giữ nguyên ranh giới đó.

## 4.1.0 — 2026-09-10

Ba thứ, đều đến từ lượt dùng thật đầu tiên của tầng `architecture.md` ở `runxops`.

### Thêm — `design-check` kiểm ID trích trong `architecture.md`, và `id_exists` biết `CON-###`

Tới 4.0.3 luật *"mọi ID trích phải có thật"* chỉ áp cho `design.md`. Cùng một script, hai văn bản,
một cái được kiểm một cái không — **luật đúng, phạm vi sai**, đúng loại đã ghi nhiều lần. Mà
`architecture.md` mới là chỗ hay trích `CON`/`ADR`/`BR` nhất, vì nó là chỗ **duy nhất buộc phải nêu
nguồn cho một điều cấm**.

Kéo theo một lỗ nữa: `id_exists()` **không có nhánh `CON-*`**, nên nó trả `false` cho **mọi** `CON`.
Bật phép kiểm ID lên mà không vá chỗ này thì nó tố oan sạch — một phép kiểm mới sinh ra để bắt nhãn
bịa lại tự bịa ra nhãn sai. Thêm nhánh: `CON-###` sống trong `## Constraints` của một BR
(`- **CON-001 Technical:** …`). Hai chỗ gọi `id_exists` hiện có đều không truyền `CON` nên nhánh này
thuần cộng thêm.

**Và phép kiểm phải `strip_markup` trước khi quét.** Khối `<!-- … -->` của chính template có nhắc
`CON-002`, `ADR-001` làm ví dụ; quét cả chú thích là tự tố oan một repo vừa `scaffold`. Bắt được
trước khi phát hành, bằng cách chạy thử trên repo trắng chứ không bằng cách đọc lại.

### Thêm — `## Cấm` phải trích **nguyên văn** khi nêu nguồn (cảnh báo, không chặn)

Ca thật, `runxops`. Một dòng trong `## Cấm`:

> *"Không tự động hoá chạy **trong** phiên Multilogin. `BR-001` Out of Scope: đã thử, rủi ro chết acc"*

`BR-001` cấm chạy **ngoài** phiên; còn `In Scope` của nó thì **cho phép** chạy trong. Dòng đó vừa
**đảo nghĩa** một điều cấm, vừa **dán nguồn cho câu mà nguồn không nói** — và nó đọc rất trôi chảy.

Nó ngồi trong `br.md` từ đầu, qua `br-check` xanh, qua adversarial ba vai, qua cổng DoR. Không phép
kiểm nào bắt được, vì **không phép kiểm nào đọc brief và BR cùng lúc**. `design-check` cũng **không**
bắt được: nó kiểm ID **có tồn tại**, không kiểm ID **có nói đúng thứ đang gắn nó** — và `BR-001` thì
có thật. Đây là lần thứ tư khoảng trống ấy được ghi vào đây.

Thứ làm nó lộ ra là **động tác chép nguyên văn**: đi lấy đúng câu về dán vào thì thấy ngay nó nói
*"ngoài"* chứ không nói *"trong"*. Nên template đòi dạng
`— nguồn: BR-001 · nguyên văn: "…" — vì …`, và `design-check` **cảnh báo** khi một dòng nêu ID mà
không có `nguyên văn:`.

**Cảnh báo chứ không đỏ, và đây là chỗ cân nhắc ngược với thói quen của repo này.** Thiếu trích dẫn
là một *thói quen chưa có*, không phải một *artifact hỏng*; cho nó đỏ là báo đỏ trên một file đang
đúng, và dòng đỏ oan thì kéo theo cả những dòng đỏ thật. Khác hẳn ca `gate-pass.sh` ở 4.0.2 — ở đó
thứ để lại là một **cánh cửa mở được cổng**, nên mới phải xoá chứ không nhắc.

Ca đó còn dạy thêm một điều mà bản vá không dạy được: sửa xong mới lộ ra nó **không phải lỗi chép**
— đó là **hai điều cấm từ hai thời điểm**, cái sau ngặt hơn và nuốt luôn thứ `In Scope` đang cho
phép. Nên hướng dẫn kết bằng: hai nguồn đá nhau thì **đừng chọn hộ** — ghi cả hai, thêm một
`## Open Questions`, để chủ dự án quyết.

### Sửa — hướng dẫn `## Nơi chạy` nói sai giá trị của chính nó

Bản 4.0.0 kể mục này để *"bắt mâu thuẫn"*. Sai, và sai theo hướng làm người đọc đi tìm nhầm thứ.
Giá trị là **buộc phải viết chỗ nối ra**: mâu thuẫn giả **tan** ngay khi viết, mâu thuẫn thật thì
không tan — cả hai kết cục đều là thu hoạch, và không ai biết trước sẽ ra cái nào.

Ca thật kèm theo: `CON-002` *"phần chạm eBay bắt buộc chạy ở máy có Multilogin"* và `ADR-001`
*"server không bao giờ chạm ổ đĩa khách"* đọc rời thì như chọi nhau; viết vào cùng một mục mới thấy
chúng nói về **hai chủ thể khác nhau** — một câu nói việc thủ công của NGƯỜI làm ở đâu, câu kia nói
CODE chạy ở đâu. Không có mục này thì mâu thuẫn giả đó sống tới lúc ai đó ở bước ⑪ tự giải theo
cách của họ, trong im lặng.

**Đo:** repo trắng vừa `scaffold` → chỉ đỏ vì placeholder, **không** tố oan `CON-002`/`ADR-001` nằm
trong chú thích · dòng `## Cấm` nêu nguồn không trích → cảnh báo · thêm `nguyên văn:` → im · trích
`CON-099` không có thật → đỏ · `CON-001`/`CON-002` thật → xanh, `CON-099`/`BR-099` → đỏ · đường
xanh trọn vẹn vẫn `exit 0`.

## 4.0.3 — 2026-09-10

### Sửa — `migrate.sh` bỏ phụ thuộc vào ngữ nghĩa đệ quy của `grep`

Phiên `runxops` báo `grep -r` im lặng bỏ sót cả một cây, và lo `migrate.sh` cũng hụt theo. Đo lại
thì **kết luận ngược ở chỗ họ lo, nhưng đúng ở chỗ sâu hơn.**

**Nguyên nhân, đo được:** trên máy này `grep` trong shell tương tác là một **shell function bọc
ugrep 7.8.4**, và ugrep **tôn trọng `.gitignore`**. `.specify/.gitignore` liệt kê `feature.json`,
nên `grep -rn` ở đó trả rỗng trong khi `cat` nhìn thấy chuỗi. Nó cũng giải thích luôn ca `2 hit`
so với `3 hit` mà phiên kia từng cho là repro không ổn định.

**Nhưng `migrate.sh` không dính ca đó.** Script chạy bằng `bash`, và shell function của zsh không
truyền sang bash subshell — đo trực tiếp: trong script, `command -v grep` ra `/usr/bin/grep`, và nó
tìm thấy `feature.json` bình thường. Ba hit của `migrate.sh` mới là con số đủ; hai hit của shell
tương tác mới là con số hụt.

**Vẫn sửa, vì ca thật nằm chỗ khác và nó sát sườn:** `.specify/feature.json` — file `migrate.sh`
**bắt buộc phải sửa** — chính là một file bị `.gitignore`. Plugin không kiểm soát được `grep` nào
đứng đầu `PATH` trong bash không tương tác trên máy người dùng. Ở máy nào `grep` là ripgrep hoặc
ugrep cấu hình sẵn, `migrate.sh` sẽ **im lặng để lại một con trỏ chết**: danh sách ngắn đi trông y
hệt *"không có gì để sửa"*.

Thay `grep -rnF` bằng `find … -type f … | tr '\n' '\0' | xargs -0 grep -nF "…" /dev/null`. Bỏ hẳn
phụ thuộc vào đệ quy của grep. `/dev/null` là toán hạng luôn có: nó ép grep in tên file kể cả khi
chỉ còn một file, **và** chặn grep quay ra đọc stdin khi `find` không ra gì — hai bẫy nằm ở hai
đầu ngược nhau của cùng một lệnh.

**Đo bốn ca:** file **bị gitignore** phải sửa → sửa · file tracked phải sửa → sửa · tài liệu vendor
không được đụng → nguyên vẹn · đầu vào rỗng → không treo, không nổ · chỉ một file → vẫn in tên file.

**Hai chỗ `grep -r` còn lại cố ý giữ nguyên** (`status.sh` quét `specs/contexts`, `close-check.sh`
quét thư mục nguồn): cả hai chỉ quét cây **đã tracked**, nơi một grep biết `.gitignore` hành xử y
hệt, và hụt ở đó chỉ làm mất một dòng cảnh báo chứ không làm sai một phép ghi đĩa. Sửa cả loạt cho
"đồng bộ" là đổi ba chỗ đang đúng để lấy cảm giác gọn.

## 4.0.2 — 2026-09-10

Hai lỗi của chính 4.0.0, cùng bắt được ở lượt chạy thật đầu tiên trên `runxops`.

### Sửa — `migrate.sh` viết lại một câu ví dụ trong tài liệu vendor của Spec Kit

`sed 's#specs/\([0-9][0-9][0-9]-\)#…#g'` quét **mọi** `*.md` dưới root, nên nó không phân biệt
*đường dẫn trỏ tới thư mục vừa dời* với *chuỗi trông giống thế trong văn bản*. Ca thật,
`.claude/skills/speckit-specify/SKILL.md`:

```diff
-  …path value (for example, `specs/003-user-auth`), not the literal string…
+  …path value (for example, `.speckit/work/003-user-auth`), not the literal string…
```

`003-user-auth` **không tồn tại trong repo**. Và sau lượt sed, file vendor nói sai về chính công cụ
nó mô tả — Spec Kit thật sự ghi vào `specs/` theo mặc định, đó là toàn bộ lý do 4.0.0 phải tách cây.
Một script dọn nhà mà sửa lời khai của người khác.

Sửa: dời và tìm theo **tên thư mục thật sự vừa dời** (`$NAMES` gom trong chính vòng lặp `git mv`),
`grep -rnF "specs/$b"` rồi `sed "s#specs/$b#…#g"` cho từng tên. Cùng luật đã dùng cho `strip_markup()`
ở 4.0.1: liệt kê đích danh thì **không thể** đụng nhầm, chứ không phải *ít khả năng* đụng nhầm; hụt
thì hụt về phía an toàn.

Lợi thứ hai, và nó không nhỏ: mục *"Đường dẫn trỏ tới chỗ cũ"* giờ in ra **đúng những chỗ sắp bị sửa
thật**. Một danh sách trộn lẫn dương tính giả thì người đọc học cách lướt qua nó — cùng cơ chế với
dòng đỏ oan, chỉ khác chỗ đứng.

### Sửa — `init --update` chép script mới mà không dọn script cũ, nên repo có HAI đường

Sau khi nâng lên 4.0.0, bảy script đã gộp vẫn nằm nguyên trong `.sdd/scripts/` của dự án:
`ac-coverage` · `trace-ratio` · `gate-pass` · `close-pass` · `change-pass` · `uc-ready` · `migrate-1to2`.

Đáng lo nhất là `gate-pass.sh`: **nó vẫn chạy được, vẫn đóng dấu cổng được**, đứng song song với
`pass.sh gate`. Và `uc-ready.sh` vẫn đo bốn thứ mà `gate-check.sh --pre` đang đo — tức đúng **hai
bản đo cùng một thứ trên cùng một file**, thứ mà mục 4.0.0 nói là gộp lại để chúng khỏi trôi khỏi
nhau. Gộp trong plugin rồi để lại cả hai bản trong dự án là **không gộp gì cả**.

Sửa: `scaffold.sh` xoá những script bản cũ và in ra tên từng cái. `.sdd/scripts/` là thư mục
plugin **sở hữu** — `cp` ở đó vốn đã vô điều kiện, không hỏi han gì — nên rác ở đó là rác của
plugin, không phải nội dung của user.

Danh sách xoá là **đích danh những tên plugin TỪNG phát hành**, không phải luật *"mọi `.sh` không
nằm trong danh sách chép"*. Người dùng có thể để script của họ ở đó; một phép dọn theo luật chung
thì có thể xoá nhầm, một danh sách đích danh thì không thể. Kèm một chốt: không bao giờ xoá tên mà
bản **này** đang phát hành — `migrate-1to2.sh` bị bỏ trong khi `migrate.sh` được giữ, hai tên gần
nhau đủ để một lần sửa cẩu thả biến phép dọn thành phép tự xoá.

**Đo:** repo giả có đủ bảy script cũ **cộng một script riêng của user** (`my-own.sh`) → 21 file còn
14; bảy cái cũ mất sạch, `my-own.sh` **còn nguyên**, `migrate.sh` còn nguyên. Repo trắng thì không
in dòng "dọn bản cũ" nào — nói khi không có gì để dọn là dạy người ta lướt qua dòng đó.

## 4.0.1 — 2026-09-10

### Sửa — `filled()` báo đỏ oan trên ba loại cú pháp markdown hợp lệ

Ca gốc, đo trên `runxops`: `## Background` của `BR-001` dài **425 dòng**, mỗi khối số kèm lệnh đo,
**không một `<...>` nào** — vẫn ra `✗ ## Background rỗng hoặc còn placeholder`. Thủ phạm là **đúng
một dòng, dòng 238**: một dấu `>` đơn độc.

`filled()` có nhánh `>[[:space:]]*$` để bắt nửa **đóng** của placeholder trải nhiều dòng
(`<Vì sao ...` mở ở dòng này, `...>` đóng ở dòng sau). Nhưng trong markdown, một dòng chỉ có `>` là
**dòng trống bên trong blockquote** — cú pháp hợp lệ và dùng thường xuyên.

**Đo rồi mới sửa, và phép đo tìm ra ba chứ không phải một.** Phiên báo lỗi thấy ca blockquote; chạy
đủ bộ ca thì hiện thêm hai:

| Nội dung trong `## Background` | Tới 4.0.0 | Đúng ra |
|---|---|---|
| `>` đơn (dòng trống trong blockquote) | ✗ | ✓ |
| `A["<b>x</b><br/>y"] --> B` (mermaid) | ✗ | ✓ |
| `<!-- chú thích -->` | ✗ | ✓ |

Ca thứ hai là **đúng cùng hình lỗi `<br/>`** vừa chữa cho `design-check` ở 4.0.0, chỉ nằm ở nhánh
khác nên lượt vá đó không với tới. Một kết luận đúng nằm đúng một chỗ thì không bảo vệ được chỗ kia
— luật này CHANGELOG đã ghi, và lần này chính nó tái diễn trong cùng một bản.

**Thuốc là liệt kê đích danh, không phải nới regex.** `strip_markup()` mới bỏ ba thứ trước khi đi
tìm placeholder: khối `<!-- ... -->` (kể cả trải nhiều dòng) · thẻ HTML **có tên trong danh sách**
(`b` `br` `i` `em` `strong` `code` …) · autolink `<https://…>`. Nửa đóng đổi thành
`[^[:space:]>=-]>[[:space:]]*$` — phải có ký tự thật ngay trước `>`, và `-`/`=` bị loại vì đó là
mũi tên mermaid (`A -->`), không phải nửa đóng.

**Đo 12 ca, hai chiều.** Tám ca phải xanh (văn xuôi · blockquote có dòng `>` rỗng · mermaid có
`<b>`/`<br/>` · so sánh `a > b` · chú thích một dòng · chú thích nhiều dòng · mũi tên cuối dòng ·
autolink) và bốn ca phải đỏ (placeholder một dòng · trải hai dòng · chỉ nửa mở · chỉ nửa đóng), cộng
bốn ca cho hai nhánh cũ (rỗng · `...` · `- ...` · có chữ thật). **16/16.** Chiều thứ hai quan trọng
ngang chiều thứ nhất: sửa đỏ oan mà làm hụt đỏ thật là đổi một lỗi lấy một lỗi tệ hơn.

Trên `br.md` thật của `runxops`: `BR CHƯA DÙNG ĐƯỢC — 1 lỗi` → `BR DÙNG ĐƯỢC`.

### Sửa — `filled()` và `nonempty()` có HAI bản sao y hệt nhau

Chúng nằm trong `br-check.sh` **và** `change-check.sh`, không nằm ở `lib.sh`. Nên một lượt vá chỉ
trúng một nửa — và phiên báo lỗi còn báo nhầm địa chỉ là `lib.sh:49`, vì ai cũng cho rằng thứ dùng ở
hai nơi thì phải ở chỗ chung. Bản sao im lặng còn tốn thêm một lần nữa: nó làm chính người đi sửa
tin rằng mình đã sửa xong.

4.0.1 đưa cả hai về **một bản duy nhất** trong `lib.sh`; hai script gọi bản chung. Đây là cùng lý do
`design-check.sh` cố ý kiểm cả hai mức trong một script thay vì tách đôi.

**Vì sao vá ngay thay vì gộp vào bản sau.** `BR-001` là BR duy nhất của `runxops`, nên mỗi lần chạy
`br-check` là thấy đúng **một** dấu ✗ — và nó sai. Đỏ oan thì bị học cách phớt lờ, rồi kéo theo cả
những dòng đỏ thật. Chỗ nó đứng còn hiểm hơn: `filled()` gác `## Background`, nơi chứa **toàn bộ số
đo** của tầng BR. Phép kiểm bảo vệ chỗ nhiều số nhất lại là phép kiểm bị vô hiệu hoá đầu tiên.

## 4.0.0 — 2026-09-10

**Đổi lớn: sdd-solo chạy trọn vòng bằng chính nó.** Phụ thuộc bắt buộc từ ba xuống **không** —
chỉ còn `git`. Bước ⑩ đổi chủ: `/speckit-plan` → `/sdd-solo:design`. Và tầng thiết kế — thứ bốn
tầng BR/UC/Entity/AC chưa bao giờ có chỗ cho — giờ có nhà, ở **hai mức**.

Repo đang chạy **phải sửa tay**: xem mục *Nâng cấp* ở cuối.

### Vì sao Spec Kit ra khỏi chuỗi — ba phép đo, không phải sở thích

> ⚠️ **Đã đính chính ở 4.1.1** — kết luận của ① vẫn đúng, nhưng cơ chế nêu dưới đây là **sai**:
> không skill nào gọi `create-new-feature.sh`. Giữ nguyên văn để đối chiếu, đọc bản đúng ở 4.1.1.

**① Hai hệ tranh nhau một thư mục.** `.specify/scripts/bash/create-new-feature.sh` hardcode
`SPECS_DIR="$REPO_ROOT/specs"`, và `get_highest_from_specs` quét `specs/*` để lấy số kế tiếp — tức
nó đang đếm cả `br.md`, `contexts/`, `changes/` của sdd-solo. Ở `runxops`: `specs/001-assign-product-key/`
nằm cạnh `specs/contexts/`. Hai hệ ID (`001-` và `UC-###`), một thư mục, không bên nào biết bên kia.

**② Bước quyết kiến trúc chạy trên hai đầu vào rỗng.** `speckit-plan/SKILL.md` bước 2, nguyên văn:
*"Read FEATURE_SPEC and `.specify/memory/constitution.md`"* — đúng hai thứ. FEATURE_SPEC là bản mỏng
21 dòng **chính sdd-solo sinh ra**, chỉ chứa ID. Còn `runxops/.specify/memory/constitution.md` vẫn
nguyên placeholder `[PROJECT_NAME]`, 50 dòng chưa ai điền. **Brief không nằm trong hai đầu vào đó và
chưa bao giờ nằm.** Sự lệch ở #34 — plan viết ra kiến trúc ngược hẳn brief suốt hai ngày — không
phải tai nạn. Nó là hệ quả số học của hai đầu vào rỗng.

**③ "Spec Kit" không phải một thứ.** Bốn repo trên cùng một máy: 10 · 24 · 25 · 35 lệnh `speckit-*`.
Tài liệu của mình gọi đích danh 4 lệnh. Đặt tên lệnh của người khác vào **quy tắc cứng** nghĩa là
quy tắc đó hỏng theo lịch release của người khác.

Nên luật mới: **quy tắc cứng nói về TRẠNG THÁI REPO, không nói tên lệnh.** `CLAUDE.md.tmpl` và
`session-start.sh` giờ chặn *"viết code khi chưa có `.sdd/gate/UC-###.ok` hoặc chưa có `design.md`"*
thay vì chặn *"chạy `/speckit-*`"*. Spec Kit vẫn đáng cài và đáng đọc — nó update thường xuyên và là
nguồn tham khảo thiết kế tốt; hình dạng `design.md` học thẳng từ `plan.md` của nó. Chỉ một luật: nó
ghi vào `.speckit/`, không ghi vào `specs/`.

### Thêm — tầng thiết kế hai mức

**Mức dự án: `specs/internal/architecture.md`.** File này đã nằm trong template từ 1.x, **không
script nào kiểm và không bước nào sinh ra** — một cái ngăn có sẵn mà chưa ai được giao bỏ gì vào.
Giờ nó có sáu mục bắt buộc: `## Ngăn xếp` · `## Nơi chạy` · `## Ai gọi` · `## Ranh giới` · `## Cấm` ·
`## Đã chốt từ brief`. Mục cuối là **chỗ nhận hàng** của cơ chế `→ chuyển:` mà 3.21.0 vừa dựng: trước
4.0.0 đó là một địa chỉ có thật nhưng chưa có nhà.

`___` hợp lệ (chưa quyết được, nhưng biết là mình chưa quyết); `<...>` thì **đỏ** — cùng ranh giới
tầng BR đã dùng.

**Mức UC: `/sdd-solo:design UC-###` (bước ⑩)** sinh `design.md` + `tasks.md` **trong chính thư mục
UC**. Nó đọc **sáu nguồn** thay vì hai nguồn rỗng: UC + flow + AC · các RULE được trích · entities +
glossary · mục BR · **brief nguồn** · architecture.md + ADR. `design.md` bắt buộc có
`## Đối chiếu architecture.md` và `## Đối chiếu brief` — mỗi chỗ đi khác phải **nói ra** kèm ADR.

**`scripts/design-check.sh`** kiểm cả hai mức trong một script. Cố ý gộp: thứ kiểm `design.md` bắt
buộc phải đọc `architecture.md` để biết nó đối chiếu với cái gì; tách đôi là tạo hai script đọc cùng
một bộ file rồi trôi khỏi nhau. Đỏ khi: chưa qua cổng DoR · `architecture.md` thiếu mục hoặc còn
`<...>` · thiếu `design.md`/`tasks.md` · hai mục đối chiếu **rỗng** · ID trích không có thật · AC nào
của UC thiếu việc trong `tasks.md`, **và chiều ngược** — `tasks.md` nhắc một `AC-#` UC không có.

`close-check.sh` (bước ⑭) nay đỏ khi UC không có `design.md`: đóng một UC mà không có nó nghĩa là
code đã viết ra từ một quyết định kỹ thuật không nằm ở đâu cả, và *"chưa bàn"* trông y hệt *"đã bàn
rồi quên ghi"*.

### Sửa — gộp lại cho gọn: 19 script còn 16, 12 skill vẫn 12 nhưng một cái đổi việc

| Gộp | Từ | Thành |
|---|---|---|
| ba script "pass" | `gate-pass` · `close-pass` · `change-pass` | `pass.sh <gate\|close\|change> <ID>` |
| hai chỉ số | `trace-ratio` · `ac-coverage` | `metrics.sh` |
| cổng nhỏ trước ⑦ | `uc-ready.sh` | `gate-check.sh --pre` |
| chuyển bố cục | `migrate-1to2.sh` (bố cục 1.x, đã chết) | `migrate.sh` (tách cây Spec Kit) |
| skill | `/sdd-solo:update` | `/sdd-solo:init --plugin` |
| mới | — | `design-check.sh` · `skills/design/` |

`pass.sh` nhận **mode tường minh**, không đoán theo tiền tố ID: `UC-###` đi qua **hai** pass khác
nhau (⑨ gate và ⑭ close), tiền tố không phân biệt được, và một script tự đoán sai giữa `reviewed`
với `implemented` thì hỏng im lặng. Từng câu commit message giữ nguyên **đúng ký tự** — `gate-check`
§9 và githook nhận diện commit bằng tiêu đề.

`uc-ready` và `gate-check` đo cùng bốn thứ trên cùng một file ở hai thời điểm. Để tách là để hai phép
đo cùng một thứ trôi khỏi nhau — mà đó là loại hỏng repo này đã ghi nhiều lần.

`deps-check.sh` 122 dòng còn 53, và **không bao giờ đỏ vì một thứ tuỳ chọn** nữa. Nó chỉ còn kiểm
`git` + repo đã `git init`. Spec Kit · AIUP · Camunda mỗi thứ một dòng `–`. Thêm một cảnh báo có
điều kiện: `specs/` đang chứa thư mục `00N-*` thì chỉ đúng lệnh `migrate.sh --dry-run` — và **chỉ
nói khi thật sự có gì để dọn**, vì nói khi không có gì là dạy người ta phớt lờ dòng đó.

### Sửa — hai lỗi bắt được trong lúc test, cùng loại đang chữa

**`uc-steps` ⑩ mượn được dấu vết của UC khác.** Bản đầu quét `plan.md`/`tasks.md` ở **bất kỳ đâu**
dưới `specs/` — nên một `plan.md` của UC khác làm UC này báo *"đã thiết kế"*. Cùng hình lỗi với #32.
Sửa: hỏi đúng thư mục của chính nó. Đo: `UC-002` có `design.md` copy từ `UC-001` vẫn ra `?`.

**`design-check` báo đỏ oan trên `<br/>`.** Phép tìm placeholder `<...>` bắt luôn `<br/>` trong khối
mermaid của `architecture.md` — tức một file **đã điền xong** vẫn đỏ. Dòng đỏ oan thì bị học cách
phớt lờ, rồi kéo theo cả những dòng đỏ thật. Sửa bằng `strip_tags()` liệt kê **đích danh** những thẻ
HTML có thật trong template, không nới regex thành "bỏ mọi `<...>` ngắn". Lượt sửa đó đồng thời gỡ
một bộ lọc sai khác (`grep -v '"<'`) vốn đang **giấu** placeholder thật trong node mermaid.

### Nâng cấp — repo đang chạy phải làm tay

```
/plugin marketplace update sdd-solo   →   /plugin update sdd-solo
/sdd-solo:init --update
bash .sdd/scripts/migrate.sh --dry-run     # xem trước
bash .sdd/scripts/migrate.sh               # git mv, giữ history; KHÔNG tự commit
```
rồi **mở session mới**. Sau đó điền `specs/internal/architecture.md` — mọi UC chưa `implemented` sẽ
cần nó ở bước ⑩. `/sdd-solo:update` không còn; dùng `/sdd-solo:init --plugin`.

## 3.21.0 — 2026-09-10

### Sửa — brief thành file chỉ-ghi ngay sau intake, và không phép kiểm nào có nhiệm vụ nhìn tới nó (#34)

Ca thật ở `runxops`. Ngày 1: `/sdd-solo:intake` nạp một brief 259 dòng, sinh `specs/br.md` đúng
luật — kể cả mục `## Đã loại khỏi brief` dài 13 dòng, trong đó có:

> *"Mục 3 toàn bộ kiến trúc ba lớp — là thiết kế, thuộc `/speckit-plan` và ADR, không thuộc tầng BR"*

Ngày 3: `plan.md` được viết với kiến trúc **ngược hẳn brief**. Brief: một MCP server từ xa giữ token
của hàng trăm shop. Plan: plugin chạy trên máy khách, *"thông tin đăng nhập không bao giờ rời khỏi
máy"* — viết như một điểm mạnh. Hai tài liệu nói ngược nhau hai ngày, không ai thấy, vì **mỗi bên
tự nó nhất quán**.

`intake` không có lỗi. Nó làm đúng cả sáu luật. Chỗ hỏng nằm ở chữ *"thuộc `/speckit-plan`"*:
`/speckit-plan` đọc `spec.md` + `constitution.md`, nó **không đọc brief** và chưa bao giờ đọc.
Đó là **một địa chỉ chuyển tiếp mà không ai giao hàng** — và nó trông y hệt một việc đã bàn giao xong.

Loại hỏng này khác mọi loại đã ghi ở đây. Trước nay là *phép kiểm đo sai thứ* hoặc *phép kiểm báo
xanh sai*. Lần này **không phép kiểm nào sai cả** — chỉ là không phép kiểm nào được giao nhìn vào
vùng đó. `gate-check` đo trong `specs/`, `verify` đọc trong `specs/`, ba vai adversarial **cố ý** mù
với brief (để không mượn kết luận của người viết brief). Ba lớp phòng thủ, cùng một điểm mù.

**Sửa — và không chỗ nào trong số dưới đây một mình đủ:**

- `.sdd/config` có `brief_path=`; `lib.sh` có `brief_path()` · `brief_sha()` · `brief_rec_sha()`.
- **SessionStart nạp brief vào ngữ cảnh bắt buộc.** Đây là chỗ duy nhất trong cả bộ nhìn ra ngoài
  `specs/`. Kèm cảnh báo khi sha brief lệch bản đã nạp.
- `br-check.sh`: brief khai mà không có file → **đỏ**; `br.md` chưa ghi `**Nguồn brief:** <đường dẫn>
  · sha256 <12 hex> · nạp <ngày>` → cảnh báo; sha lệch → **đỏ** (brief sửa sau intake nghĩa là hai
  tài liệu có thể đang cãi nhau).
- `br-check.sh`: dòng trong `## Đã loại khỏi brief` mà lý do là **hoãn** (`thuộc tầng thiết kế`,
  `/speckit-plan`, `ADR`, `Phase 5`, `sau này`) thì phải ghi `→ chuyển: <đích>`. Hoãn không đích là
  hoãn vào hư không.
- `intake/SKILL.md` luật 7: sau khi chuyển brief, **bắt buộc** khai `brief_path=` và dán dòng
  `**Nguồn brief:**`. Không có bước này thì cả bốn chỗ trên nằm im — một luật không có ai sản xuất
  dấu vết cho nó thì không kiểm được gì.
- `CLAUDE.md.tmpl`: brief vào **thứ tự đọc bắt buộc**, mục 6.

### Thêm — cổng ⑨ hỏi giả định triển khai (#35, phương án nhẹ)

Bốn tầng yêu cầu (BR → UC → Entity → AC) **không có ngăn nào** cho *"dựng bằng gì · chạy ở đâu · ai
gọi"*. Nên thiết kế rơi hết vào `/speckit-plan`, mà `/speckit-plan` nằm **sau** cổng ⑨. Hệ quả: UC
qua cổng với Main Flow đứng trên một giả định chưa ai viết ra; hôm sau plan lộ ra giả định khác, ba
câu trong Main Flow không thi hành được, phải mở cổng ra sửa.

`gate-check.sh` §7c: thiếu dòng `**Giả định triển khai:** <chạy ở đâu · ai gọi · ngăn xếp>` →
**cảnh báo, không chặn**. Cổng không quyết hộ được kiến trúc; nhưng bắt *nói ra* thì rẻ, và nó bắt
đúng ca `runxops` vừa dính. Thêm vào `UC-000.md` và checklist DoR.

Đề xuất **nặng** của #35 — bỏ `/speckit-specify` khỏi chuỗi và kéo `/speckit-plan` lên trước cổng ⑨,
14 bước còn 13 — **chưa làm**: nó đổi thứ tự quy trình đã ghi trong tài liệu, thuộc quyền quyết của
anh, không phải của em hay của một phiên khác.

### Sửa — cảnh báo lệch sha ở SessionStart chưa bao giờ chạy được (bắt trong lúc test)

Bản đầu của khối này viết `grep -oE '\*\*Nguồn brief:\*\*[^\n]*sha256 ...'`. Trong ERE của `grep`,
`[^\n]` là *"mọi ký tự trừ `\` và `n`"* — không phải "trừ xuống dòng", vì `grep` vốn đã làm việc theo
dòng. Đường dẫn brief nào có chữ `n` (`runxops-brief.md` chẳng hạn) là hụt, và **hụt thì im**: khối
vẫn in dòng brief, chỉ thiếu đúng câu cảnh báo. Y hệt loại đang chữa — một vùng không ai nhìn tới.

Bắt được vì test hỏi *"câu cảnh báo có ra không"*, không hỏi *"khối có chạy không"*. Rút cả phép đo
về một chỗ (`brief_rec_sha()` trong `lib.sh`) để hai nơi dùng không thể lệch nhau nữa — `br-check`
viết đúng, `session-start` viết sai, cùng một con số, khác nhau ở một ký tự.

## 3.20.0 — 2026-09-10

### Sửa — `uc-steps` báo xanh sai: hai script của plugin, cùng một commit, hai kết luận ngược nhau (#32)

Lần đầu chạy `uc-steps.sh` trên một UC thật, nó in:

```
✓ ⑩⑪ Spec Kit + code (commit feat/fix mang UC-009)
```

Trong khi `src/` **không tồn tại**, `plan.md` và `tasks.md` **không có**, và **không một dòng code
sản phẩm nào**. Nó xanh vì đúng một commit — `feat(UC-009): script chuyển ItemSell…` — đụng
`scripts/itemsell-to-sheet.py`, tức **đúng `tool_paths`, thứ 3.19.0 vừa ship để khai rằng nó không
thuộc UC nào và không thể thuộc.**

**Cùng một commit, hai script của plugin, hai kết luận ngược nhau.** `trace-ratio.sh` (3.19.0) cố ý
loại nó ra kèm chú thích *"đếm nó vào commit có ID truy vết được là hỏi một câu không có câu trả
lời đúng"*. `uc-steps.sh` (3.18.0) lấy đúng commit ấy làm bằng chứng rằng code đã viết xong. **Hai
bản vá cách nhau một phiên bản và không biết đến nhau.**

- **⑩⑪ hỏi theo PHẠM VI FILE, không theo câu chữ trong message.** Cùng lý do đã nhận ở #31 — *thứ
  cần phân loại là file, không phải câu chữ*. Ở #31 nó áp cho phép **chặn**; ở đây cho phép **đọc**.
  Luật đã nằm trong code ba hôm trước, chỉ chưa áp hết chỗ.
- **Tách ⑩ khỏi ⑪** — hai bước, hai bằng chứng khác nhau: ⑩ có `plan.md`/`tasks.md` trong `specs/`;
  ⑪ có commit `feat`/`fix` mang ID **đụng `code_paths`/`test_paths` trừ `tool_paths`**. Gộp lại thì
  một bằng chứng yếu ở vế này che chỗ trống ở vế kia — đúng chuyện vừa xảy ra.

**Lần thứ ba trong ba ngày** của chỗ đã khai là chưa vá: *mọi luật kiểm ID **có tồn tại** không,
không luật nào kiểm ID **có dính gì** tới thứ đang gắn nó không.* Lần một hệ ID AIUP (#29) · lần
hai commit gắn ID không liên quan (#31) · lần ba `uc-steps` dùng ID trong message làm bằng chứng về
**nội dung** commit.

### Sửa — `repo_has_code` chưa biết `tool_paths` nên đỏ oan (#33)

`repo_has_code()` không loại `tool_paths`, nên `scripts/*.py` lọt qua và `trace-ratio` in *"repo có
file nguồn nhưng không commit nào đụng: src tests → sửa code_paths/test_paths"* trên một repo vừa
làm **đúng** thứ 3.19.0 bảo họ làm.

Đỏ oan, và tệ hơn im lặng một bậc vì **nó hướng người ta đi sửa một thứ đang đúng**: ai nghe lời sẽ
gỡ `tool_paths` hoặc nhét `scripts` vào `code_paths` — **quay ngược đúng cái bẫy #31 vừa gỡ**. Cùng
hình với #26, nơi một dòng đỏ oan tự tạo ra chính cái nó cảnh báo.

`status.sh` dùng chung `repo_has_code` nên mang cùng lỗi (chỗ #26 từng vá) — sửa ở `lib.sh` là cả
hai hết. Kèm một chỉnh nhỏ cho chính xác: khi đã khai `tool_paths`, câu *"repo chưa có code"* đổi
thành *"chưa có code sản phẩm; code công cụ đã khai ở tool_paths"* — repo **có** code, chỉ là code
không thuộc UC nào.

Bốn ca đo: `tool_paths` rỗng → vẫn cảnh báo (config có thể sai thật) · khai rồi → hết đỏ oan · có
code thật trong `src/` mà chưa commit nào đụng → **vẫn** cảnh báo · `status.sh` chuyển từ `✗` sang
một dòng `!` nói đúng tình trạng.

### Ghi nhận — phần còn lại của `uc-steps` đúng hết

`runxops` đối chiếu 13 dòng còn lại với bảng đếm tay: khớp. Cơ chế phân biệt *bỏ có ghi lý do* với
*quên làm* chạy đúng thiết kế — thêm dòng `**Bỏ bước ⑤:**` thì `?` chuyển sang `–` ngay.

Và đó chính là lý do #32 phải vá nhanh, ghi nguyên văn: **mười ba dòng kia đủ tin để người ta tin
luôn dòng thứ mười bốn.** Một bảng gần đúng nguy hiểm hơn một bảng sai hẳn.

## 3.19.0 — 2026-09-10

### Sửa — `ac-coverage` trộn hai câu hỏi vào một chỉ số (#30)

Trên `runxops`: `Tổng AC: 11` = `UC-009` (reviewed, 9 AC) + `UC-008` (**draft**, 2 AC). Khi
`UC-009` implement đủ, chỉ số đọc **9/11** — và **không thể lên 100%** chừng nào `UC-008` còn
draft, mà nằm draft nhiều tháng là chuyện `/sdd-solo:start` khuyến khích.

**Đây là loại sai #9 ở tầng chỉ số:** `82%` là con số **đúng** cho một câu hỏi **không ai đang
hỏi**. Nó trộn *"cái tôi đã cam kết có test chưa"* với *"spec xây được bao nhiêu"*. Và một chỉ số
không bao giờ đạt được đích thì bị thôi nhìn — đúng luật 3.4.2, ở một script khác.

Nay in **hai dòng, mỗi dòng khai rõ mẫu số**:

```
AC có test / AC của UC đã qua cổng:       9/9      ← đạt 100% được, nên mới có nghĩa để theo dõi
AC có test / AC của MỌI UC (kể cả draft): 9/11
```

### Thêm — `tool_paths`: code thật không thuộc UC nào (#31)

`runxops` có **695 dòng Python** trong `scripts/` không thuộc UC nào và **không thể thuộc**. Hook
cằn nhằn mỗi commit *"Thêm vào `code_paths` nếu đó là code thật"*. Nó **là** code thật. Làm đúng
lời khuyên rồi đo:

```
code_paths=src scripts
  fix(scripts): sửa lệnh đo    exit=1  ✗ phải có ID
  chore(scripts): dọn          exit=1  ✗ phải có ID
  fix(UC-009): sửa lệnh đo     exit=0
```

**Nghe lời hook thì hook chặn.** Ba đường ra, và đường **dễ đi nhất là gắn một ID không liên
quan** — lúc đó `id_exists` **cho qua** vì ID tồn tại thật, và `trace-ratio` đếm nó là đã truy vết.
Cùng hình #16, khác một chữ: lần đó nhãn bịa là ID **không tồn tại**; lần này ID **tồn tại nhưng
không liên quan**. Luật hiện tại kiểm *ID có thật không*, **không kiểm ID có dính gì tới commit
này không** — đúng chỗ vừa ghi khi đóng #29, giờ lộ ra ở tầng thứ hai.

**Và chỗ mâu thuẫn sắc nhất là của chính plugin này:** luật 5b (3.6.0) bắt *"số mô tả dữ liệu thật
phải ghi kèm lệnh đo ra nó"* — tức **plugin đang YÊU CẦU viết loại code này** — rồi hook không cho
commit nó mà không gắn ID giả. **Hai luật đều đúng; đặt cạnh nhau thì hở.**

- `tool_paths` trong `.sdd/config`: miễn ID ở cả hai githook, **không tính vào mẫu số**
  `trace-ratio`. **Mặc định rỗng** — repo chưa khai hành xử y hệt hôm nay.
- **Miễn trừ theo FILE, không theo câu chữ trong commit.** Phương án rẻ hơn (miễn theo tiền tố
  commit cấu hình được) bị bỏ vì thứ cần phân loại là **file**, không phải **câu chữ**: phân loại
  theo câu chữ thì ai gõ nhầm tiền tố là lọt, còn file thì không tự đổi chỗ.
- Cơ chế miễn trừ vốn đã có (`^Merge|^Revert|^chore\(sdd\)`), chỉ là đóng cứng vào một tiền tố.

Đo trên repo tạm, đủ ba chiều: trước khi khai `tool_paths` mọi thứ y như cũ · khai rồi thì commit
chỉ đụng `scripts/` qua mà **không cần ID** · commit đụng `src/` **vẫn bị chặn** như trước ·
`trace-ratio` bỏ `scripts` khỏi danh sách mẫu số.

### Thêm vào loại #7 — một PHÉP THỬ cũng là một phép đo

Ghi chú phương pháp từ `runxops`, và nó **suýt làm cả #31 không tồn tại**:

> Phép thử đầu cho `exit=0` cả ba dòng. Tôi dùng `touch` nên **không có gì được stage** — phép thử
> rỗng, mà kết quả trông y hệt *"hook cho qua, không có vấn đề gì"*. Nếu tôi tin nó thì kết luận sẽ
> **ngược hoàn toàn**.

Thứ bắt được nó là **con số trông vô lý** — ba dòng `exit=0` cạnh một nhánh `exit 1` đọc thấy rõ
trong code. Đúng luật 8, lần này áp cho một phép thử chứ không cho một con số trong tài liệu.

**Và nó xảy ra lần thứ hai ngay trong bản này**: phép thử githook đầu tiên của phiên plugin cho
`exit=127` ba dòng liền — gọi `.githooks/commit-msg` trong khi `core.hooksPath` là `.sdd/hooks`.
Lần đó `127` lộ liễu nên bắt được ngay; nếu nó là `0` thì đã báo cáo một kết quả rỗng. Một ca nữa
trong cùng lượt: `src/a.py` còn kẹt trong stage từ phép thử trước làm một ca "phải qua" thành
`exit=1`.

Luật thêm vào prompt: **trước khi tin một phép thử, in ra thứ nó đang đo** — danh sách file đã
stage, số dòng đầu vào, đường dẫn thật của lệnh.

## 3.18.0 — 2026-09-10

### Sửa — bước ② trỏ vào một lệnh không nên chạy, và không ai biết nó chưa chạy (#29)

**Cách nó lộ ra đáng kể hơn nội dung.** `UC-009` vừa qua cổng — 30 phát hiện verify, 30 phải sửa,
dương tính giả 0. Phiên viết spec soi lại 14 bước và báo *"② → ⑥ đều xong"*. Chủ dự án trả lời:
*"anh nhớ hình như anh chưa chạy `use-case-spec` bao giờ."*

Đúng. **Bước ② chưa từng chạy, suốt cả một UC đi trọn vòng**, và không phép kiểm nào hỏi tới. Lời
khai *"② xong"* dựa trên việc **kết quả tồn tại** — mà kết quả tồn tại vì nó được **viết tay**. Mọi
phép kiểm trong plugin đo **sản phẩm**; không cái nào đo **bước**. Người duy nhất biết sự thật là
người duy nhất gõ được lệnh.

**Rồi đọc `SKILL.md` của `aiup-core` thì hoá ra không nên chạy.** Đo trên bản cài, 4/4 lệnh:

| Lệnh AIUP | Ghi ra | Ta cần |
|---|---|---|
| `use-case-spec` | `docs/use_cases/UC-XXX-<kebab>.md` | `specs/contexts/<ctx>/use-cases/` |
| `entity-model` | `docs/entity_model.md` | `specs/contexts/<ctx>/entities.md` (cổng đọc đúng đường này) |
| `use-case-diagram` | `docs/use_cases.puml` | mermaid, ta đếm nhãn `\|E# …\|` |
| `requirements` | đọc `docs/vision.md` | không skill nào tạo file đó |

**4/4 ghi sai cây, 3/4 sai định dạng.** Và `use-case-spec` còn **đụng hệ ID** — nguyên văn:
*"`BR-XXX` business-rule IDs are unique within their own file only and **restart at `BR-001` in
every file**"*. `BR-###` của nó là business **rule**; `BR-###` của ta là business **requirement**
trong `specs/br.md`.

**Githook sẽ CHO QUA.** Luật *"`BR-` phải có heading trong `specs/br.md`"* thấy `BR-002` có heading
thật và cho đi — trong khi commit đang nói về một business rule của `UC-005`. **Báo xanh sai ở
tầng hệ ID**, đúng #24, và là ca đầu tiên của lớp đó ở tầng *quy ước đặt tên* chứ không ở tầng dữ
liệu.

Kết luận này plugin **đã tự rút ra một lần rồi**: `skills/init` viết *"đừng đề xuất `/requirements`
— AIUP đọc `docs/vision.md` mà không skill nào tạo ra file đó"*. Đúng, nhưng **không lan sang ba
lệnh còn lại**. Một kết luận đúng nằm đúng một chỗ thì không bảo vệ được ba chỗ kia.

- `sdd-process` bước ② đổi **chủ ngữ từ LỆNH sang VIỆC PHẢI XONG**: *điền nội dung UC cùng user
  (Actor · Trigger · Preconditions · Main Flow — bước hiển thị nêu SCR-ID · Alternative ·
  Exceptions · Postconditions)*, kèm khối lý do đầy đủ ở trên.
- `CLAUDE.md.tmpl` bỏ `(AIUP /use-case-spec)` khỏi chuỗi lệnh — nằm trong khối scaffold nên **mọi
  repo nhận sau `init --update`**.
- `deps-check.sh` hạ AIUP từ **dòng đỏ** xuống ghi chú. Nó đang bắt người ta cài một thứ để **không
  bao giờ gọi** — và một dòng đỏ đòi việc vô ích chỉ dạy người ta phớt lờ dòng đỏ.

### Thêm — `uc-steps.sh`: UC này đi qua những bước nào

Phép **liệt kê**, không phải phép kiểm: **luôn `exit 0`, không chặn gì**. Cổng DoR vẫn là
`gate-check.sh`; thêm một cổng thứ hai đo cùng thứ chỉ tạo nhiễu. `/sdd-solo:status` gọi nó cho UC
trong dòng `Đang làm:` của `STATE.md`.

Ba trạng thái, và **ranh giới giữa hai cái sau mới là chỗ đáng giá**:

```
✓  có dấu vết trong file
–  cố ý bỏ, CÓ ghi lý do   (dòng `**Bỏ bước <ký hiệu>:** <lý do>` trong file UC)
?  không có dấu vết nào — có thể đã làm, có thể chưa, KHÔNG AI BIẾT
```

Đối chứng sạch ngay trong `UC-009`: bước ⑤ (Claude Design) **cũng bị bỏ** — `screens/` chỉ có
`README`. Nhưng nó bỏ **có ghi lý do** trong mục Screens (*"cả hai màn hình là text thuần, không có
giao diện đồ hoạ ở v1"*). **Bỏ có ghi lý do và bỏ mà không ai biết là bỏ cho cùng một kết quả trên
đĩa** — sáu tháng sau chỉ cái đầu còn đọc lại được.

Script nói thẳng giới hạn của nó: `⑥` không có artifact riêng (cổng kiểm), `⑬` self-review **không
để lại dấu vết nên không đo được**. Và `?` được ghi rõ là *"không có dấu vết"*, **không phải "chưa
làm"** — hai câu đó khác nhau, và gộp chúng lại là đúng loại lỗi bản này đang sửa.

`uc-steps.sh` thêm vào danh sách `scaffold` copy sang `.sdd/scripts/`; `status.sh` **im nếu không
thấy file** để bản `.sdd/` cũ không gãy cả lượt vì một mục mới. Đo cả hai chiều trên repo tạm.

### Cùng họ #27, khác một chữ

#27 là **luật đúng đặt sai bước** — không bao giờ có cơ hội chạy. #29 là **bước chạy được nhưng
chạy thì hỏng**. Cả hai đều không phải lỗi nội dung, và cả hai chỉ lộ ra khi có người đi hết một
vòng thật rồi hỏi *"khoan, tôi có gõ lệnh đó bao giờ chưa?"*

## 3.17.0 — 2026-09-09

### Đo được — `/sdd-solo:verify` lần chạy thật đầu tiên: 30 phát hiện, 30 phải sửa, **0 dương tính giả**

Con số chờ suốt bảy bản, từ `runxops-54` — phiên thật sự chạy lệnh trên repo thật. Chủ dự án bác
**0** cái.

Cách chạy, để biết con số đo cái gì: **hai** subagent riêng, không cái nào có context buổi viết
spec. Một vai đọc *tài liệu ↔ tài liệu* (loại #1–#6), một vai đối chiếu *con số ↔ dữ liệu thật*
(loại #7), chạy **đúng lệnh đo có sẵn trong spec, không bịa lệnh**. `22 + 10 = 32` thô → gộp trùng
còn `29` → cộng 1 bắt được sau = **30**.

**Tỷ lệ 0 đến từ chỗ nhiễu bị lọc TRONG vai, không đẩy lên người:** hai vai tự bác 4 mục kèm lý do
*trước* khi trình, và ~25 con số chạy lại khớp thì **im**. Đó đúng là hình mà luật *"khớp → im"*
và *"bác phải rẻ"* nhắm tới.

Quan sát về chia vai, đáng giữ: **vai đo số một mình đóng góp 10 phát hiện, 8/10 là loại #7** —
thứ vai đọc tài liệu **không thể** tìm ra vì phải chạy lệnh. Gộp hai vai làm một thì phần đọc sẽ
ăn hết ngân sách chú ý.

Loại #7 nổ **8** lần; loại #8 nổ **2** lần — `glossary.md` để tiêu đề *"Năm entity"* trên danh sách
**sáu**, và `entities.md` viết *"Bảy nhóm lệch cờ tồn"* **bằng chữ** cách bảng ghi `10` đúng 13
dòng, sống sót một commit vừa khai là *"đã quét mọi câu khai số lượng"* — **vì phép quét tìm chữ
số.** Luật *hit lịch sử hợp lệ* (3.11.0): đối chiếu cả 30, **không cái nào** rơi vào diện phải hạ
xuống dòng đếm — nên nó không tốn gì trên lượt này, và cũng **chưa được thử**.

### Thêm — `gate-check` kiểm ID khai trong `## Đọc lại`, y hệt §7 cho adversarial

**Bước sửa tự sinh lỗi mới, và trước bản này không có gì chạy sau nó.** Ca thật: sửa
`RULE-006 → RULE-007` để tránh trùng mã; `RULE-007` chưa có heading trong `rules.md` → **vừa tạo
đúng loại ID rỗng mà luật repo cấm**. Sửa lại xong, cổng **vẫn** đỏ: dòng `F27` trong chính mục
`## Đọc lại` vẫn ghi `RULE-007`.

**Sửa thân mà quên sửa chỗ ghi lại việc sửa** — loại #8, do chính lượt đọc-lại sinh ra, trong chính
cái mục ghi kết quả đọc lại. Cả hai lỗi **cổng bắt, verify không**, vì verify đã chạy xong từ
trước. Cái thiếu là **một vòng kiểm sau bước sửa**, không phải một vai đọc thứ ba.

- `gate-check` §9: mọi `RULE-###` / `AC-#` / `E#` khai trong `## Đọc lại` phải **có thật** — cùng
  luật #12 đã áp cho adversarial. Không kiểm thì **cửa 2 mở bằng một lời khai trỏ vào chỗ không
  tồn tại**. Đầu ra không mang ID (*"không phải lỗi vì …"*) vẫn hợp lệ, không bị đòi ID.
- Bước 6 của skill: quét **cả giá trị MỚI**, không chỉ giá trị cũ — lỗi do bước sửa sinh ra là
  giá trị *mới nằm sai chỗ*, quét giá trị cũ không thấy. Và **mục `## Đọc lại` không được miễn**:
  nó ghi lại việc sửa nên nó trôi như mọi chỗ khác. **Chỗ ghi lại việc sửa cũng là một chỗ phải
  sửa.**

Năm ca đo: khai `RULE-007` không có → ✗ · sửa thành `RULE-006` có thật → ✓ · khai `AC-9` không có →
✗ · `AC-1` có thật → ✓ · đầu ra không mang ID → ✓ (không đòi).

### Hai mục còn lại trong báo cáo — đã vá trước khi báo cáo tới

`runxops-54` nêu ba việc; hai việc đầu đã xong ở bản trước, nên ghi lại đây cho khớp mốc thời
gian: ca mẫu `536 / 525` đã sửa (3.12.0 → 3.16.0, nay là `545` / `601` kèm nhãn đơn vị), và lỗ cấu
tạo *luật quét nằm trong cơ chế không chạy được nó* đã chuyển về bước 6 ở **3.15.0** — đề nghị của
họ trùng khít với thứ đã ship, kể cả điều kiện *"chỉ commit khi kết quả rỗng hoặc mọi hit còn lại
là hit lịch sử hợp lệ"*.

## 3.16.0 — 2026-09-09

### Thêm — loại sai #9: số đúng, chủ ngữ sai

Câu hỏi treo ở 3.15.0 (*ba con số `249 / 1006 / 2523` có mục không?*) có câu trả lời, và nó quan
trọng hơn ánh xạ: **cả ba đo đúng. Chúng chỉ đo đúng một câu hỏi KHÁC.**

```
249   ĐÚNG cho "dòng có TỔNG giá trị > 1"     (Color: Red ; Size: L đếm 2)
215   ĐÚNG cho "dòng gom nhiều Variant"        ← câu trong tài liệu nói về cái này
1006  ĐÚNG cho "tổng giá trị, phép CỘNG"
 920  ĐÚNG cho "tổng tổ hợp, phép NHÂN"        ← số Variant thật khi bung
2523  = 1517 + 1006
2437  = 1517 +  920                            ← số dòng sau khi bung
```

**Đây không phải loại #7.** Loại #7 là *"số từng đúng, dữ liệu đổi bên dưới"* — chữa bằng **đo
lại**. Loại này đo lại vẫn ra `249`, **mãi mãi**. Hỏng không nằm ở con số, nằm ở **cái câu nó được
gắn vào**. Chữa bằng **đọc lại câu**, không bằng đo.

Và **không tầng nào trong bốn tầng bắt được**: vân tay khớp · lệnh đo có thật và in đúng số · cấu
trúc không đổi · phép cộng khớp. **Cả bốn kiểm quan hệ số ↔ dữ liệu; không tầng nào kiểm quan hệ
số ↔ CÂU.** Luật 11 hỏi *lệnh có in ra số này không* — ở đây lệnh in ra thật, nhãn đúng, và vẫn sai.

> **Loại #9 — Số đúng, chủ ngữ sai.** Phép đo hợp lệ nhưng trả lời một câu hỏi khác câu hỏi trong
> văn bản. Dấu hiệu: **một cột sinh ra nhiều mẫu số đều hợp lệ.** Câu phải hỏi: *con số này trả
> lời câu hỏi nào, và câu trong tài liệu đang hỏi câu nào?*

**Kiểm rẻ:** cột nào sinh ra **nhiều hơn một mẫu số hợp lệ** thì mọi con số lấy từ nó **phải mang
nhãn mẫu số, không được đứng trần**.

### Sửa — ba chỗ trong ca mẫu, theo ánh xạ đo được

- Ca `132 → 249` → **`132 → 215`**. Chủ ngữ của câu là *"một listing gom nhiều Variant"*, mà
  `Color: Red ; Size: L` là hai trục mỗi trục một giá trị — **một** Variant.
- Ca *"nhiều hơn 1986"*: `2523` → **`2437`**, và `+27%` → **`+23%`**.
- Bảng đơn vị: `1006` **giữ nguyên nhưng nay mang nhãn `(CỘNG)`**, đứng cạnh `920 (NHÂN)`. `1006`
  chỉ sai khi bị dùng cho phép bung; dùng cho tổng giá trị thì đúng. **Hai số cạnh nhau có nhãn
  mẫu số là hình đúng của cả loại #9.**

Phép quét bước 6 chạy sau khi sửa: hai chỗ `249` còn lại đều nằm trong đoạn **giải thích chính ca
đó**, tức hit hợp lệ. `1517 + 920 = 2437` ✓ và `1517 + 1006 = 2523` ✓ — cộng thử trước khi ghi.

### Ghi lại — `grep` bắt được cả thứ không ai đang đi tìm

Nhận xét từ `runxops` về ca đoạn-văn-trùng ở 3.15.0, giữ lại vì nó là lý do đầy đủ nhất cho toàn
bộ thiết kế của `verify`:

> Bạn chạy `grep` để kiểm `536`, nó trả về một lỗi **khác hẳn**. Người đọc lại thì chỉ tìm được
> thứ mình đang tìm.

Đó là khác biệt giữa **đọc để kiểm một giả thuyết** và **một phép đếm đứng ngoài mắt mình**: cái
đầu bị giới hạn bởi những gì mình nghĩ tới, cái sau thì không.

### Và một ca `13/13` cuối, do chính người dựng ra nó mắc

`runxops` viết *"tôi là người duy nhất trong ba người vi phạm luật đó hôm nay"* — một mẫu số chưa
lọc: họ cũng là người **cầm dữ liệu nhiều nhất**, nên có nhiều cơ hội viết-trước-khi-đo nhất. Hai
phiên kia không vi phạm vì hai phiên kia không cầm bút trên dữ liệu. Họ nhận ngay khi được chỉ ra.

Đáng ghi vì nó khép lại đúng chỗ mở đầu của loạt bản này: **cái bẫy `13/13` bắt được cả người vừa
dựng ra nó**, và lần này ở chỗ khó ngờ nhất — một câu tự kể về mình.

## 3.15.0 — 2026-09-09

### Sửa — luật quét-cả-cây nằm trong một cơ chế cấu tạo không chạy được nó

Chẩn đoán từ `runxops-54`, phiên đang cầm bút trên `specs/`, và nó sắc hơn một dòng bỏ sót:

> Luật quét-cả-cây ở `verify-pass.md` chỉ có nghĩa **sau** khi sửa — vì **trước** khi sửa thì chưa
> có "giá trị cũ" nào để quét theo. Nhưng verify pass chạy **trước** khi sửa. Nên luật ấy đang nằm
> trong một cơ chế **cấu tạo không chạy được nó.**

**Không phải ai quên — là đặt sai bước.** Ca thật: cặp số cũ nằm ở **bốn** chỗ (`entities.md` ·
`br.md` · docstring một script · prompt của chính plugin), và **hai vai verify đọc rất kỹ vẫn bỏ
sót chỗ thứ tư**. Thứ bắt được nó là một `grep -rn` chạy **sau** khi sửa.

- Phép quét chuyển về **bước 6 của `skills/verify`** — sau khi người quyết đã điền đầu ra và các
  sửa đổi đã áp, **trước** khi commit, và là **bắt buộc**: với mỗi giá trị vừa đổi, `grep -rn` giá
  trị **cũ** trên cả cây; còn hit nào ngoài `## History` và ngoài câu `<cũ> → <mới>` thì chưa xong.
- Prompt giữ luật ở dạng *cách soi* cho hai vai; chỗ **thi hành** nằm ở skill.

Đây là ca đầu tiên trong cả loạt mà chỗ hỏng **không** ở một con số hay một nhãn, mà ở **thứ tự
các bước** — cùng họ loại sai #5 (*"thứ tự nói ngược nội dung"*), nhưng ở **tầng quy trình** chứ
không ở tầng tài liệu. Bốn tầng kiểm số dựng trong ngày đều đo **trạng thái**, không tầng nào đo
**thứ tự**, và lỗ này chỉ lộ khi có người đi hết một vòng thật.

### Sửa — một đoạn văn nằm HAI lần trong `verify-pass.md`

Bản 3.14.0 chèn một đoạn mới mà không gỡ đoạn cũ nó thay thế, nên hai đoạn gần như y hệt cùng nằm
trong file. Đúng loại sai #3, trong tài liệu dạy cách bắt loại #3. **Bắt được bằng `grep -rn '536'`
chạy để kiểm chuyện khác** — không phải bằng đọc lại, dù đoạn trùng cách nhau đúng năm dòng.

### Thêm — quan hệ `545 / 555`: hai câu, hai lý do khác nhau

3.14.0 để chỗ này là **một ô trống có nhãn** *"chưa có phép đo nào"*. `runxops` đo xong, và kết quả
đáng ghi vì nó cho thấy ô trống ấy là đúng:

```
545 mã gỡ từ ô `Name Product`  +  10 mã từ cột `Product ID` gốc  =  555 mã
555 mã = 555 ô     VÌ ĐO ĐƯỢC rằng mọi ô chỉ mang MỘT mã ({1: 555})
```

Câu đầu là phép cộng. **Câu sau không suy ra được** — nó là một tính chất của dữ liệu: chỉ cần một
ô mang hai ISBN là đẳng thức gãy. Nếu 3.14.0 viết đại *"555 ô ứng với 545 mã cộng 10"* thì câu đó
**đúng**, và vẫn là **bịa**, vì tính chất chống đỡ nó lúc ấy chưa ai đo. **Kết quả giống hệt, giá
trị khác hẳn.**

Nguyên tắc, và nó là câu gọn nhất của cả ngày: **không viết ra thứ mình chưa đo, kể cả khi nó chắc
chắn đúng.**

### Đo được — verify: 12/12, không có dương tính giả nào

Vòng đầu của `/sdd-solo:verify` trên `runxops`: **12 phát hiện đã sửa xong, 0 dương tính giả**; 17
cái còn lại chờ người quyết. Chưa phải con số cuối, nhưng nếu 17 cái kia giữ hình đó thì phát biểu
đúng **không** phải *"verify chấp nhận được mức nhiễu"* mà là *"verify gần như không nhiễu ở tầng
nghiệp vụ"* — và hai phát biểu đó dẫn tới hai quyết định khác hẳn nhau về việc có bắt buộc chạy nó
trước mọi cổng hay không. **Quyết định đó chờ số cuối, không chốt bằng 12/12.**

Một dấu hiệu luật 11 viết đủ rõ: `runxops-54` **từ chối gắn lệnh đo** cho ba con số nó không tự
dựng lại được, ghi thẳng vào tài liệu rằng chúng chưa có lệnh — *"thà thiếu nhãn còn hơn dán nhãn
sai"* — và nó tự rút ra điều đó, không ai bảo.

## 3.14.0 — 2026-09-09

### Sửa — phép khớp chéo thêm ở 3.13.0 chỉ đúng MỘT phía

3.13.0 khoe `454 + 15 = 469` khớp số ô có biến thể, và kết luận bộ số *"tự chứng minh đã phân
hết"*. `runxops` đo nốt phía kia:

```
phía biến thể   454 + 15 = 469  ✓
phía định danh  513 + 15 = 528  ✗  số ô có Identifiers là 555 — hụt 27
```

Ai đọc ca mẫu rồi **thử phép đối xứng** — việc hoàn toàn tự nhiên ngay sau khi được dạy rằng phân
rã phải cộng đúng — sẽ ra `528 ≠ 555` và kết luận bộ số hỏng.

Nó không hỏng; nó **thiếu hai số hạng mà `982` theo định nghĩa không thể chứa**: `10` từ cột
`Product ID` gốc, và — chỗ đắt — **`17` ô MỘT dòng**, định danh dính sau dấu `|` ngay trên dòng
tên. Mười bảy ô đó nằm ngoài `982` **theo đúng định nghĩa của 982** (*ô có nội dung ngoài
tên+link*). `513 + 15 + 10 + 17 = 555` ✓.

**Phát biểu đúng: `982` KHÔNG phải tập cha của định danh.** Nó là tập cha của trục biến thể (469
nằm trọn trong đó) nhưng chỉ chứa 528/555 ô mang định danh. Bộ số cũ đọc như thể `982` bao cả hai —
**đúng ảo giác mà `536 + 525` tạo ra từ đầu, sống nguyên qua BA lần sửa liên tiếp**, mỗi lần đều
do một bên tưởng mình vừa sửa xong nó.

### Thêm — luật 11 vế 3: thử phân rã ở CẢ HAI phía

> Một phía cộng đúng **chưa chứng minh được gì** — nó chỉ chứng minh phía ấy đúng. **Phía gãy mới
> là phía chỉ ra tập cha thật sự bao cái gì.**

Rẻ hơn cả hai vế trước, và 3.13.0 là bằng chứng: bản đó **dừng lại ngay sau phía khớp**, rồi dùng
phía khớp ấy làm bảo chứng cho cả bộ. Một phép khớp thành công là chỗ dễ dừng nhất.

Ca này mạnh hơn `13/13` một bậc: `13/13` là mẫu số đã lọc mà không nói đã lọc gì — **giấu thông
tin**. `982` bị tưởng là bao cả hai trong khi chỉ bao một — **tạo ra một quan hệ không tồn tại**,
và quan hệ sai kéo theo **mọi suy luận dựng trên nó**, không chỉ một con số.

### Ghi lại — vì sao `536 + 525 ≠ 982` sống được sáu bản

3.13.0 quy cho *"không ai buồn cộng"*. `runxops` đưa lý do đúng hơn, và nó có hệ quả thiết kế:

> Không ai coi ba con số ấy là **một hệ**. Chúng nằm cạnh nhau trong một câu văn, không nằm trong
> một bảng, nên không ai thấy chúng phải khớp với nhau. Cái làm chúng thành một hệ — và làm phép
> cộng thành bắt buộc — chính là việc xếp chúng thành bảng ở 3.12.0.

**Phép kiểm rẻ nhất chỉ xuất hiện sau khi trình bày đúng.** Đó là lý do luật 11 đòi *trưng ra phép
cộng* chứ không chỉ đòi *cộng đúng*: bảng không phải cách trình bày đẹp hơn, nó là **thứ làm phép
kiểm trở nên khả thi**.

### Chỗ chưa đo, nêu ra thay vì lặng lẽ hoà giải

`555` là số **ô** mang định danh; `545` ở tầng kia là số **mã** định danh. Quan hệ giữa hai số đó
**chưa có phép đo nào**. Ca mẫu nói thẳng điều này thay vì suy ra một quan hệ nghe hợp lý — vì tự
bịa một quan hệ ở đúng chỗ này là **đúng cái lỗi cả mục đó đang dạy cách bắt**.

## 3.13.0 — 2026-09-09

### Sửa — ca mẫu vẫn treo người đọc giữa chừng; và luật 11 có vế thứ hai

3.12.0 sửa số và thêm câu *"hai số này KHÔNG cộng lại thành 982"*. Câu đó **đúng cả hai vế** nhưng
vẫn để người đọc treo: gặp `545` và `601` cạnh `982` thì ai cũng hỏi *"vậy bao nhiêu ô mang cả
hai?"*, và câu trả lời trực giác `545 + 601 − 982 = 164` **sai hơn mười lần** — số thật là **15**.

Sai vì **ba con số đó mang ba đơn vị khác nhau**: `982` là số **ô**, `545` là số **mã**, `601` là
số **dòng**. Không có gì trong văn bản nói ra điều đó.

Ca mẫu nay trưng **hai tầng**, vì mỗi tầng dạy một thứ:

```
ĐƠN VỊ = Ô     982 = 513 (chỉ định danh) + 454 (chỉ trục) + 15 (cả hai) + 0   ✓
ĐƠN VỊ = MÃ / DÒNG     545 mã · 601 dòng · 1006 giá trị   — KHÔNG cộng vào đâu cả
```

Phân rã theo ô **cộng đúng, nên tự chứng minh đã phân hết**, và còn khớp chéo: `454 + 15 = 469`,
đúng bằng số ô *"có biến thể"* đo được ở một lần đếm khác.

**Luật 11 vế 2:** con số nào **tự nhận là phân rã** của một con số khác thì **phải cộng lại đúng**,
và chỗ trình bày phải **trưng ra phép cộng**. Cộng không ra → thiếu một nhóm, hoặc các nhóm chồng
nhau, hoặc — hay gặp nhất — **không cùng đơn vị**. Kiểm được bằng máy, rẻ hơn mọi luật khác trong
danh sách.

Chỗ tự phê đáng ghi: **`536 + 525 ≠ 982` đáng lẽ đã bắt được bộ số cũ sáu bản trước, không cần
verify.** Một phép cộng hai số. Nó nằm ngay trong câu, suốt sáu bản, và không ai cộng thử — kể cả
sau khi verify đã bắt được hai con số ấy sai và cả hai phiên cùng ngồi sửa đúng dòng đó.

### Ghi lại — `grep` không phải mẹo vặt

Khi thêm luật 11 ở 3.12.0, bản nháp chèn nó **trước** luật 9 và 10 — lần thứ hai trong hai bản
liên tiếp, cùng một tay, ba phút sau khi viết luật về chính lỗi đó. `runxops` mắc đúng chuỗi ấy
**ba lần trong một ngày**, lần thứ ba ngay sau khi khai vào spec là đã sửa. **Bốn ca, hai tay, một
ngày, không ca nào bắt được bằng đọc kỹ hơn.**

Nhận xét từ `runxops`, giữ nguyên vì nó là cách phát biểu đúng nhất của cả loạt bản này:

> `grep -nE '^[0-9]+\. '` không phải mẹo vặt — nó là **hình thức tối giản của chính luận điểm mà
> `verify` được dựng lên để chứng minh: một phép đếm đứng ngoài mắt mình.**

Đó cũng là lý do bốn ca trên **không phải mẫu về sự bất cẩn**, mà là mẫu về **thứ mà chú ý không
mua được**: biết luật, vừa viết xong luật, biết mình dễ mắc, và vẫn mắc.

## 3.12.0 — 2026-09-09

### Sửa — ca mẫu của loại #7 mang đúng cái lỗi nó dạy cách bắt

**`/sdd-solo:verify` chạy thật lần đầu, và thứ nó bắt được nằm trong `verify-pass.md` của chính
plugin này.** Ca mẫu ghi *"982 ô nhiều dòng — 536 trục biến thể và 525 định danh"*. Đo lại:

| | đang ghi | đúng |
|---|---|---|
| ô có nội dung ngoài tên+link | 982 | **982** ✓ |
| ô mang định danh | 525 | **545** |
| ô mang trục biến thể (số **dòng**) | 536 | **601** |
| ô mang trục biến thể (số **giá trị**) | — | 1006 |

`982` đúng; hai số kia sai **cùng một chiều, cùng một nguyên nhân** — chúng ra từ script khảo sát
đầu tiên, chạy **trước** khi bỏ ký tự vô hình `U+200E` và trước khi bắt được 32 giá trị biến thể
không mang tên trục. Tức **đúng chữ ký mà chính đoạn văn đó đang dạy người ta nhận ra.**

Để nguyên thì thiệt hại là thật và cụ thể: ai chạy `measure` trên `runxops` và ra `545/601` sẽ
kết luận **cơ chế sai**, chứ không phải **con số trong ví dụ sai**.

- Sửa thành `982 · 545 định danh · 601 dòng trục`, kèm câu **hai số này KHÔNG cộng lại thành 982**
  vì một ô mang được cả hai. Bản cũ đọc như một phép chia đôi mà `536 + 525` cũng chẳng ra `982` —
  không ai để ý, vì hai con số thật đứng cạnh nhau trông luôn hợp lý.
- Thêm ca *hai mẫu số cho cùng một thứ*: `601 dòng` cạnh `1006 giá trị` — một ô ghi
  `Color: Brown | Dark Grey` là **một** dòng trục nhưng **hai** giá trị. Dán nhầm số nọ vào câu
  của số kia thì cả hai đều là số thật, câu vẫn trôi chảy, không phép so nào bắt được. **Luôn nói
  rõ đang đếm ĐƠN VỊ nào.**
- Giữ lại trong prompt chính câu chuyện này — ca mẫu từng mang lỗi nó dạy cách bắt — vì nó dạy
  nhiều hơn bộ số đúng.

### Thêm — luật 11: lệnh đo phải THẬT SỰ in ra con số nó được gắn vào

Ca nặng nhất của cả loạt. Hai con số ở `runxops` được gắn `python3 scripts/measure-catalog.py` làm
lệnh đo, mà **lệnh đó không in ra con số nào trong hai**. Không phải số mục — là **một cái nhãn
xác thực dán sai**, và nó **tệ hơn không có nhãn**: không nhãn thì con số trông như chưa ai kiểm,
đúng như nó vốn thế; dán nhãn sai thì nó trông **như đã được kiểm**.

> **Kiểm bằng cách chạy lệnh rồi tìm con số đó trong đầu ra. Không thấy → nhãn sai.**

Luật này đóng chỗ hở mà **ba tầng kia không với tới**: vân tay hỏi *dữ liệu nào* (3.8.0) · luật 5b
hỏi *lệnh nào* (3.6.0) · chốt cấu trúc hỏi *lệnh còn đúng hình dạng không* (3.11.0) — **cả ba đều
giả định lệnh và số là một cặp đúng**, và không tầng nào kiểm chính cái cặp đó. Rẻ, và kiểm được
bằng máy.

### Thêm — giới hạn: lý do bác phải đến từ người ĐỌC, không từ người VIẾT spec

Đưa trước cho verify một danh sách *"ngữ cảnh giúp bác nhanh"* do tác giả spec soạn là **lấy mất
chỗ đứng của nó**: nó sẽ bác đúng những phát hiện mà tác giả đã có sẵn câu trả lời — tức đúng
những chỗ tác giả **tin là mình không sai**.

Ca thật: một danh sách như vậy bị subagent từ chối, và **hai mục trong đó sau đó tự rơi vào nhóm
"khớp / đã bác" bằng phép đo riêng của verify**. Bằng chứng ấy chỉ tồn tại **vì** nó không nghe.
Cùng họ với luật *"chỉ báo, không sửa"*: người có lợi ích trong kết luận không được cầm bút.

### Sửa — hai cái nhãn mang số nữa, lại đúng loại #8

Khi thêm luật 11, bản nháp **chèn nó trước luật 9 và 10** — lần thứ hai trong hai bản liên tiếp,
cùng một tay, ba phút sau khi viết luật về nó. Và mục `## Ba giới hạn` thành bốn dòng ở cả
`verify-pass.md` lẫn `skills/verify/SKILL.md`.

Cả hai bắt được bằng `grep -nE '^[0-9]+\. '`, **không phải bằng đọc**. Cùng cách chữa với 3.9.0:
tiêu đề bỏ hẳn số đếm (`## Giới hạn`), vì **một cái nhãn mang số thì mỗi lần thêm dòng là một lần
nó có thể mục**.

### Đo được — verify hoạt động, và nhiễu nằm ở đâu

Lần chạy thật đầu tiên sinh **29 phát hiện** sau khi gộp; triage chưa xong nên chưa có tỉ lệ dương
tính giả. Đã biết một nửa: **nhiễu tập trung ở tầng 5 (vệ sinh), không ở tầng 1–2.** Và bằng chứng
đắt nhất là chính bản vá này: công cụ tìm ra một lỗi thật **trong tài liệu định nghĩa ra nó**.

## 3.11.0 — 2026-09-09

### Thêm — chốt cấu trúc: lệnh đo khai hình dạng nó giả định, sai thì DỪNG

3.10.0 đặt tên cho loại mục thứ ba — **"lệnh đúng với thế giới cũ"** — và nói là không so số nào
bắt được, vì lệnh vẫn chạy trơn và vẫn ra một con số hợp lý. `runxops` chặn được **một nửa**: bắt
lệnh **khai ra cấu trúc nó đang giả định**, rồi kiểm cấu trúc đó **trước khi** đếm.

`measure-catalog.py` khai ba giả định — tên cột phải có · dấu ngăn trục trong `Variant` là ` ; ` ·
không ô nào còn xuống dòng. Thử đổi ` ; ` thành ` / ` trên một bản tạm:

```
itemsell-flat.csv không còn hình dạng mà lệnh này giả định — KHÔNG đếm,
vì một con số đếm trên cấu trúc đã đổi trông y hệt một con số đúng:
  ✗ không ô Variant nào chứa ' ; ' — dấu ngăn trục có thể đã đổi
EXIT = 1
```

Nó **dừng, không in con số nào**. Đây là nguyên tắc mở đầu của cả repo áp vào chỗ hẹp nhất: *báo
xanh sai tệ hơn không có phép kiểm*, nên **một lệnh đo không chắc mình đang đo đúng thứ thì việc
đúng đắn là im, không phải đoán.**

**Ba thứ, viết thành một câu** — đây là hình gọn của cả loại #7 sau một ngày, đặt lên đầu mục:

> Một con số kiểm lại được cần **ba** thứ, thiếu một là mục lặng: **dữ liệu nào** (vân tay, 3.8.0)
> · **lệnh nào** (luật 5b, 3.6.0) · **lệnh đó còn đúng với hình dạng hiện tại không** (chốt cấu
> trúc, bản này). Hai thứ đầu bắt được số **sai**; chỉ thứ ba bắt được số **đúng-trên-thế-giới-cũ**.

**Nửa còn hở, khai cho đủ:** chốt cấu trúc bắt được **cấu trúc dữ liệu** đổi. Nó **không** bắt được
người sửa cả lệnh lẫn phần khai giả định cùng lúc cho khớp nhau — lúc đó nó lại là một lệnh đúng
với thế giới cũ, chỉ khác là thế giới cũ vừa được viết lại cho hợp. **Ba tầng, tầng nào cũng chỉ
đẩy chỗ mù lùi một bậc chứ không xoá được.** Prompt bắt nói ra chỗ mù còn lại, không được hứa nó
đã hết.

### Sửa — một cái nhãn mang số nữa, cùng loại #8

*"Sáu loại đầu đọc tài liệu so với tài liệu"* → *"Mọi loại trên…"*. Câu đó đúng lúc viết (khi bảng
có sáu dòng), vẫn đúng về mặt kỹ thuật sau khi thêm #7 và #8, nhưng **đã bắt đầu gây hiểu nhầm** —
và mỗi dòng thêm vào bảng là một lần nó gần hơn với chỗ sai hẳn. Cùng cách chữa với tiêu đề ở
3.9.0: **bỏ con số đi thì không còn gì để mục.**

### Nguyên tắc rút ra từ cả loạt 3.5.0–3.11.0 — và một cách kể sai đã bị bác

Trong loạt này có một lúc `runxops` **dừng, không commit** `glossary.md`, dù commit đó sẽ làm dòng
✗ cuối cùng của cổng thành ✓. Cách kể đầu tiên của phiên plugin là *"ở vị trí làm cổng xanh bằng
một lệnh, biết nó sẽ xanh, và không làm"* — tức quy công cho phẩm chất người vận hành. **`runxops`
bác cách kể đó, và bác đúng:**

> *"Tôi không nghĩ tới chuyện 'làm cổng xanh rồi từ chối'. Tôi chỉ thấy commit đó sẽ làm dòng ✗
> thành ✓ trong khi thứ nó đo chưa thay đổi gì. Nó không phải một lựa chọn đạo đức, nó là nhận ra
> phép kiểm đang đo cái khác với cái tôi sắp làm."*

Lý do bác quan trọng hơn chuyện ai đúng: **nếu ghi là "biết mà không làm" thì lần sau người ta
trông chờ vào phẩm chất của người vận hành** — mà chính loạt này vừa chứng minh phẩm chất không
dựa vào được. Cùng cái đầu đó trượt loại #8 **ba lần liền** trong cùng một ngày vì sửa theo trí
nhớ. Hình đúng của nó là:

> **Một phép kiểm đo được đúng thứ nó tuyên bố đo thì việc lách nó trông rõ ràng là lách, kể cả
> với người đang định lách.**

Đó là công của `gate-check`, không phải của ai. Và nó là **vế thứ hai, nặng hơn, của bài học #24**:
một phép kiểm báo xanh sai không chỉ bỏ lọt lỗi — **nó còn làm việc lách trông giống việc làm**,
kể cả trong mắt người đang lách. Đó mới là lý do đầy đủ để câu *"báo xanh sai tệ hơn không có phép
kiểm"* đứng ở đầu repo này.

Ghi kèm cách loạt bản này được làm, vì nó là điều kiện để những nguyên tắc trên có nghĩa: **sáu
lần hai phiên bất đồng, cả sáu lần kết thúc bằng một phép đo, không lần nào bằng nhượng bộ** —
`allowed-tools` truy trong transcript · `26/40` truy trong `br_body` · vùng loại trừ truy bằng chỗ
dấu `→` thật sự được dùng. Không lần nào phải tin nhau.

### Ghi nhận — một chuyện đã đo trước khi bump

`3.9.0 → 3.10.0` là lần đầu số minor lên hai chữ số. `vcmp` trong `lib.sh` so **từng thành phần
bằng số**, nên an toàn — đã chạy thử cả ba chiều trước khi bump. Nếu nó so chuỗi thì `3.10.0 <
3.9.0` và **cả chuỗi bốn mắt xích cảnh báo version sẽ im lặng nói ngược**, đúng dạng hỏng tệ nhất
trong cả bộ này.

## 3.10.0 — 2026-09-09

### Sửa — luật 9 và luật quét kéo ngược nhau; phân loại hit thay vì chỉ tìm hit

`runxops` chạy thử luật quét-cả-cây trên 13 con số đã đổi trong ngày và bắt thêm một chỗ mà **hai
lượt sửa trước đều trượt**: `entities.md` còn ghi *"132 dòng có nhiều giá trị biến thể"* trong khi
số thật là **249**. Phép đếm cũ ra `132` vì nó chỉ thấy dấu `|` **nằm cùng dòng với `Color:`** —
không phải regex sai, mà là **cấu trúc nó đang đếm chưa tồn tại lúc ấy**. Gần gấp đôi.

Nhưng phát hiện đáng giá hơn là một **mâu thuẫn giữa hai luật của chính bản 3.9.0**:

- **Luật 9** (loại #7): sửa số thì **giữ số cũ kèm lý do lệch**.
- **Luật quét** (loại #8): số vừa đổi thì **quét cả cây tìm mọi chỗ nhắc tới nó**.

Càng tuân thủ luật 9 thì cây càng đầy số cũ **hợp lệ**, nên luật quét ra càng nhiều hit đúng-mà-
phải-bác. Hôm nay tỷ lệ còn tốt vì mới một ngày; sau vài tháng mỗi số đổi kéo theo hàng chục hit
lịch sử. Lúc đó *"bác một phát hiện phải rẻ"* (giới hạn 1) **không còn đủ — cái rẻ phải là không
phải bác.**

**Cách giải: phân loại hit ngay khi tìm ra, máy tự dán nhãn, và không bỏ qua chỗ nào.** Hit ở
`## History` hoặc trong câu dạng `<số cũ> → <số mới>` là **hit lịch sử hợp lệ** → gộp thành **một
dòng đếm**, không thành `F#`. Mọi chỗ khác → `F#`.

Chỗ này em cố ý làm **khác** đề nghị gốc (*"chỉ soi hit ngoài `## History` và ngoài câu có dấu
`→`"*): không **loại bỏ** nhóm một khỏi phép quét, chỉ **hạ nó xuống một dòng đếm**. Loại bỏ hẳn
thì một câu văn xuôi sống vô tình mang dấu `→` sẽ **tàng hình vĩnh viễn** — và đó đúng là loại lỗi
cả tài liệu này sinh ra để bắt. Rẻ phải đến từ *đã bác sẵn kèm lý do*, không từ *không nhìn*.

### Thêm — câu định tính đứng thay một con số cũng là hit

*"sẽ nhiều hơn 1986 dòng"* không sai. Số thật là **2523** — **+27%**, và *"nhiều hơn"* che mất đúng
cái phần khiến người ta phải quyết khác đi. Cùng hình với `13/13` ở luật 10: **câu không sai, chỉ
là không đủ để ai quyết được gì.**

### Đo được — luật quét chịu được chạy tự động

`runxops` viết vòng lặp grep 13 con số, **mất một phút**, và phân loại đúng: mọi hit ở History và
ở các câu *"số cũ 1459 → 1388 vì …"* đều hợp lệ; **chỉ một hit** là văn xuôi sống mang số chết.
Tỷ lệ nhiễu thấp hơn dự đoán, nên luật này không cần người lọc trước.

### Ghi lại — thứ chữa được loại #8 không phải cẩn thận hơn

Nhận xét từ `runxops`, giữ nguyên vì nó đúng và đo được: hôm đó `runxops` trượt loại #8 **ba lần
liền** vì sửa theo trí nhớ; bản nháp 3.9.0 của plugin trượt **một lần** và bắt được — không phải
nhờ đọc kỹ hơn, mà nhờ chạy `grep -nE '^[0-9]+\. '`. **Thứ chữa được lớp lỗi này là có một phép
đếm đứng ngoài mắt mình**, không phải quyết tâm cẩn thận.

Và một khái quát đáng giữ, cũng từ `runxops`: **một cái nhãn mang số là một bản sao của thứ nó dán
lên, mà mọi bản sao đều trôi.** Cùng luật với việc tách một entity ra khi một trường bị chép ở
nhiều dòng — hai tầng khác hẳn nhau, một luật.

## 3.9.0 — 2026-09-09

### Thêm — một con số ĐÚNG vẫn có thể là phát hiện

Chín dòng luật của loại #7 tới 3.8.0 đều đi tìm số **sai**. `runxops` tìm ra chiều còn thiếu, và
nó là chiều duy nhất mà bước 3 (*"khớp → im"*) **bỏ sót theo thiết kế**, vì chạy lại vẫn ra đúng
con số đó.

`RULE-004` khai *"phân định được 13/13 nhóm"*. Đo lại: **đúng 13/13**. Nhưng mẫu số thô là **16** —
ba nhóm bị loại vì khoá là chữ giữ chỗ (`Does not apply`, thứ eBay tự điền khi người bán bỏ
trống). **Loại chúng ra là quyết định đúng.** Vấn đề là `13` một mình giấu mất **9 listing không
nhóm được bằng bất cứ khoá nào** — mà đúng chín cái đó là phần việc gán khoá tay của `UC-009`,
tức chỗ đau chính của cả BR.

- **Luật 10 của loại #7:** một con số đúng vẫn là phát hiện nếu nó là **mẫu số đã lọc mà không nói
  đã lọc gì**. Hai câu hỏi: *phép đếm này bỏ ra bao nhiêu?* · *cái bị bỏ ra có phải chính là thứ
  tài liệu đang bàn không?*
- **Hệ quả cho luật 5b:** lệnh đo in **mẫu số thô lẫn mẫu số đã lọc**, kèm cái gì bị lọc và vì sao.
  `13/13` trông hoàn hảo; `16 thô → loại 3 giữ chỗ → 13` nói thật.
- Cùng họ với ca `437 / 32` ở 3.7.0 — thứ bắt được nó là **một con số thứ hai đứng cạnh**. Khác ở
  chỗ ca kia con số trông vô lý, ca này **cả hai đều hợp lý**, nên không có con số thứ hai thì
  không có gì để mà nghi.

### Thêm — loại sai #8: nhãn không đi theo nội dung

Tiêu đề, câu tóm tắt, số đếm trong tiêu đề — ai sửa thân thường không sửa nhãn. Tách riêng khỏi #3
vì nó có **chữ ký riêng**: cái sai do **chính lần sửa trước gây ra**, và nó nằm cách chỗ sửa vài
dòng tới vài trăm dòng nên không lọt vào mắt người vừa sửa.

Ba ca đo được trong **một ngày**, ba người khác nhau:

| Ca | Nhãn | Thân |
|---|---|---|
| `verify-pass.md` (bản 3.6.0–3.7.0) | *"Sáu loại sai phải soi"* | bảng **bảy** dòng |
| `UC-009` một `AC` | tiêu đề nói một đằng | thân nói một nẻo |
| `entities.md` mục `Sourcing` | câu văn xuôi còn *"7 nhóm"* | bảng số và History đã sửa thành **10** |

Ca thứ ba đắt nhất về mặt bài học: nó **sống sót qua chính lượt đi sửa số mục**, vì người sửa sửa
**theo chỗ mình nhớ là có số**, không theo một phép quét. Nên luật soi là: mỗi lần một con số hoặc
một quyết định vừa đổi, **quét cả cây tìm mọi chỗ khác nhắc tới nó**. Trí nhớ của người vừa sửa là
thứ dở nhất để dựa vào — nó nhớ **ý định**, không nhớ **chữ**. Đúng câu mở đầu của `verify-pass.md`,
chỉ khác chỗ áp dụng.

### Sửa — tiêu đề bảng loại sai thôi mang số đếm

`## Bảy loại sai phải soi` → `## Các loại sai phải soi`. Một cái nhãn mang số thì **mỗi lần thêm
dòng là một lần nó có thể mục** — 3.6.0 đã mục đúng như vậy, 3.8.0 sửa con số, và bản này bỏ hẳn
con số đi để lần sau không còn gì để mục. Sửa nguyên nhân thay vì sửa triệu chứng.

Ghi thêm cho trung thực: khi thêm luật 10 ở bản này, bản nháp đầu **chèn dòng 10 lên trước dòng
9** — đúng loại sai #8, ngay trong lượt thêm loại sai #8. Đã sửa trước khi commit; nói ra vì nó là
bằng chứng tốt nhất cho lập luận ở trên rằng lớp lỗi này không chừa ai.

## 3.8.0 — 2026-09-09

### Thêm — lệnh đo in dấu vân tay của dữ liệu nó đọc

3.7.0 kết bằng câu *"có lệnh đo làm số kiểm lại được, không làm số đúng"*, và nói thẳng là **không
có cách chữa**. `runxops` tìm ra **nửa** cách chữa, và nó rẻ: lệnh đo in dấu vân tay của chính dữ
liệu nó vừa đọc, spec ghi lại vân tay đó cạnh bảng số.

```
Nguồn: itemsell-flat.csv · 1986 dòng · sha256 70daf43f · sửa lần cuối 2026-09-09 22:22
Đo lúc: 2026-09-09 22:26
```

Giá trị của nó không nằm ở chỗ bắt thêm lỗi, mà ở chỗ **chuyển một luật người phải nhớ thành một
dòng máy in ra**. Bước 4 của prompt viết *"lệch không có nghĩa spec sai — có thể dữ liệu đã đổi"*;
đó là một câu đúng mà mỗi lần gặp lệch vẫn phải ngồi đoán lại. Có vân tay thì hết đoán: vân tay
khác → dữ liệu đã đổi · vân tay khớp mà số khác → spec sai hoặc lệnh sai.

**Chỗ nó không bịt được, ghi thẳng vào prompt:** vân tay bắt được **dữ liệu** đổi, **không** bắt
được **lệnh** đổi. Sửa chính lệnh đo cho nó đếm sai đi thì vân tay vẫn khớp và cả bảng số vẫn mục
cùng một chiều — lần này còn khó thấy hơn, vì tài liệu trông như *đã được kiểm*. Câu của 3.7.0
đứng nguyên, chỉ hẹp lại đúng một nửa.

`sdd-process` luật 5b mở rộng theo.

### Sửa — tiêu đề `verify-pass.md` nói "Sáu loại sai" trong khi bảng có bảy

3.6.0 thêm loại #7 vào bảng mà quên sửa tiêu đề ngay trên nó. Đúng loại sai #3 của chính tài liệu
này — *hai chỗ nói ngược nhau* — trong file dạy cách tìm loại sai đó, và không phép kiểm nào bắt
được vì cả hai chỗ đều là văn xuôi hợp lệ.

### Đo được — cổng 3.7.0 chạy trên repo thật

`UC-009` ở `runxops`: **32 dòng xanh, 1 dòng đỏ**, và dòng đỏ đúng là cửa 2 như thiết kế. Dòng
`– hai cách qua: …` in ngay dưới dòng ✗ — nhận xét từ `runxops` đáng giữ lại: *"nó biến một dòng
chặn thành một dòng chỉ đường; đó là khác biệt giữa cổng và tường."*

`/sdd-solo:verify` chưa chạy được ở đó: phiên đang mở vẫn nạp 3.4.3 trong khi bản cài đã là 3.7.0.
Đúng cảnh báo ④ của `version-check` — **không lệnh nào sửa được, phải mở session mới.** Hai con số
còn chờ (tỉ lệ dương tính giả của verify, và `UC-009` có qua cửa 2 trong ngày không) vẫn chưa có.

## 3.7.0 — 2026-09-09

### Sửa — loại sai #7 không rơi lẻ, và cách báo nó phải theo cụm

Áp luật 5b vào `entities.md` của `runxops` ra kết quả không ai đoán: **không phải một con số mục,
mà năm.** Cả năm đều đo trên cùng một bản `itemsell-flat.csv` cũ, nhóm theo `Product Name` lúc cột
đó còn dính `Color: Brown` — nên hai dòng cùng sản phẩm khác màu đếm thành hai tên.

| | cũ | đo lại |
|---|---|---|
| tên sản phẩm | 1459 | **1388** |
| nhóm > 1 dòng | 281 | **320** |
| lệch Stock Flag | 7 | **10** |
| lệch Stock Checked | 138 | **158** |
| có biến thể | 427 | **469** |
| thoái hoá | 1559 | **1517** |

**Một phép đo mục thì mọi số dẫn xuất từ cùng nguồn mục theo, và tài liệu vẫn tự nhất quán hoàn
hảo.** Đó là lý do không phép kiểm nội-tại nào bắt được: không có gì mâu thuẫn để mà thấy.

- **Gộp cụm, đừng tách lẻ.** Nhiều số cùng một nguồn thiếu lệnh đo → **một** `F#` nêu cả cụm. Năm
  dòng đỏ giống hệt nhau là thứ người ta học cách phớt lờ nhanh nhất, rồi phớt lờ luôn dòng thứ
  sáu khác hẳn — đúng bẫy đã ghi ở 3.4.2. Cụm **khoanh đúng vùng**, và khoanh đúng vùng đã đủ để
  người biết dữ liệu đi kiểm; vai này không cần tự tìm ra con số đúng.
- **Xem HƯỚNG lệch, không chỉ xem có lệch.** Nhiều số cùng lệch **một chiều** là chữ ký của một
  nguồn chung đã mục, không phải của nhiều sai sót rời rạc. Ở ca này cả năm đều đếm **thiếu**, và
  đều thiếu theo hướng làm vấn đề trông **nhẹ hơn** thực tế: `7 nhóm lệch cờ tồn` là con số dùng
  để lập luận phải tách một entity, và nó nhỏ hơn sự thật **43%**. Lập luận vẫn đúng — nhưng người
  quyết phải biết nó đang đứng trên cái gì.
- **Một con số trông vô lý là một phát hiện, kể cả khi nó CÓ lệnh đo.** Lệnh sai vẫn chạy trơn. Ca
  thật: ghép dòng biến thể bằng ` | ` trong khi ` | ` đã mang nghĩa *"nhiều giá trị cùng một
  trục"*, nên `Color: Brown | Dark Grey` đọc ra thành hai trục và phép đếm ra `437` thay vì `32`.
  Thứ bắt được nó là **con số trông vô lý**, không phải phép kiểm nào.
- **Sửa số thì giữ số cũ kèm lý do lệch, đừng xoá.** *"1459 → 1388 (số cũ nhóm theo `Product Name`
  khi cột đó còn dính trục biến thể)"* dạy được nhiều hơn `1388` trơ trọi — nó nói phép đo cũ hỏng
  ở đâu, nên lần sau khỏi hỏng lại.

### Giới hạn thật của loại #7, đo được chứ không đoán

Vai #7 **không** tự tìm ra `427 → 469`; nó chỉ báo *"những số này không có cách đo lại"*. Nhưng khi
báo theo cụm thì kết quả đó mạnh hơn tưởng: **năm dòng cùng thiếu cách đo, cùng dẫn từ một file,
là một hình đủ rõ để người đọc đi kiểm.** Nó không tìm ra con số đúng — nó khoanh đúng vùng.

Nên phát biểu chính xác của giới hạn là: **loại #7 bắt được số mục chỉ khi ai đó đã từng ghi lại
cách đo; không có lệnh đo thì nó chỉ khoanh được vùng cần người vào xem.** Ghi ra để đừng ai
trông đợi nhiều hơn thế.

Và một điều đúng mãi: **loại #7 phát sinh ngay trong lúc sửa loại #7.** Mọi con số vừa đo lại sẽ
mục lần nữa khi dữ liệu đổi. Khác biệt duy nhất — và là toàn bộ giá trị của luật 5b — là lần này
có lệnh chạy lại.

## 3.6.0 — 2026-09-09

### Thêm — `verify` đối chiếu tài liệu với DỮ LIỆU THẬT, không chỉ với tài liệu

Ca thật ở `runxops`, xảy ra vài giờ sau khi 3.5.0 ra. `entities.md` ghi *"427 dòng đang có trục
nằm kẹt trong `Product Name`"*. Câu đó **qua adversarial pass và ba lượt cổng**. Đo lại: **982**
ô nhiều dòng — 536 trục biến thể **và 525 định danh**. Thứ bắt được nó không phải script nào, mà
là một câu của người biết dữ liệu: *"dữ liệu chưa chuẩn"*.

Sáu loại sai của 3.5.0 đều đọc **tài liệu so với tài liệu**. Loại này khác hẳn, và nó là chỗ mục
nhanh nhất trong cả spec: **con số đúng lúc viết, không ai sửa nó khi dữ liệu đổi, và một con số
đã mục trông y hệt một con số đúng.** Không phép kiểm cấu trúc nào phân biệt được — cổng DoR chỉ
hỏi *"mục này có nội dung chưa"*, và `427` là nội dung hợp lệ y như `982`.

- **Loại sai #7 — con số đã mục**, cùng một vai riêng trong `.sdd/prompts/verify-pass.md`. Số
  nghiệp vụ đã chốt (ngưỡng, thời hạn trong `RULE-###`) **không** thuộc loại này: đó là quyết
  định, không phải phép đo.
- **Mỗi con số mô tả dữ liệu phải có một lệnh đo lại được.** Không có → **bản thân việc thiếu đó
  đã là một phát hiện**. Cấm tự bịa lệnh rồi coi như đã đối chiếu: lệnh mình nghĩ ra không phải
  lệnh tác giả đã dùng, nên hai số lệch nhau chẳng chứng minh được gì.
- **Luật "trích nguyên văn hai phía" áp thẳng vào đây**, chỉ khác chỗ phía B là **một lệnh và đầu
  ra của nó hôm nay** thay vì một dòng file. Người quyết chạy lại lệnh đó là biết ngay.
- **Lệch KHÔNG có nghĩa spec sai.** Có thể dữ liệu đã đổi, có thể lệnh cũ đếm hụt. Báo cả hai số,
  **không kết luận bên nào đúng** — người biết dữ liệu quyết.
- **Soi chỗ phép đếm không nhìn thấy được.** Đây là chỗ ca thật trượt, và nó đáng ghi vì phép đếm
  cũ **không sai công thức**: nó grep `Color:`/`Size:` và đếm đúng thứ nó grep. Nó trượt vì hai
  thứ nằm ngoài tầm với của mọi phép grep — **ký tự vô hình** (`U+200E` dính đầu một ISBN, nhìn y
  hệt dãy số thường) và **giá trị không có nhãn trục** (`Paperback`, `M | L | XL`). Khi số đo lại
  khác số trong spec, câu hỏi đầu tiên là: *phép đếm này không nhìn thấy cái gì?*

`sdd-process` thêm luật 5b: **số mô tả dữ liệu thật phải ghi kèm lệnh đo ra nó.** Một phép đo
không kèm lệnh thì sáu tháng sau không ai kiểm lại được — và `/sdd-solo:verify` đo lại được chính
vì lệnh đó nằm trong file.

## 3.5.0 — 2026-09-09

### Thêm — bước ⑧ có cửa thứ hai, và `/sdd-solo:verify` (#27, #28)

Nguyên văn chủ dự án: *"Tạo issue cần ngủ 1 đêm là không đúng. Tìm giải pháp khác."*

**Bằng chứng nặng nhất nằm trong chính plugin này.** `.sdd/prompts/adversarial-pass.md` dòng 1:
*"chạy trong một session MỚI, không phải session đang viết spec"*. Bước ⑦ và bước ⑧ cần **đúng
một thứ**: người đọc không bị neo bởi giả định của người viết. Bước ⑦ mua nó bằng session mới;
bước ⑧ mua nó bằng một đêm lịch. Không dòng tài liệu nào nói vì sao cùng một nhu cầu lại có hai
giá — và ô `Session mới: [x]` của bước ⑦ **chưa từng được script nào kiểm**, tức chỗ nhẹ hơn thì
tin lời khai, chỗ nặng hơn thì bắt đợi.

**Một đêm đo thời gian trôi qua, không đo việc đọc có xảy ra không.** Ca thật đo được hôm nay trên
`runxops`: commit lúc 21:18 · cổng đỏ đúng một lỗi là dòng ngủ-một-đêm lúc 21:28 · đọc lại ngay
lúc 21:30 tìm ra **7 chỗ, 3 chỗ phải sửa trước cổng** — một trong đó là một Open Question vẫn đang
dạy phương án mà chính `Q18` đã bác vài giờ trước. Thứ luật một-đêm muốn mua **đã xảy ra**, cách
commit 10 phút, và cổng vẫn đỏ. Còn đợi tới mai thì không bảo đảm gì: cùng người, cùng cái neo.

- **Cửa 1 giữ nguyên** — commit `docs(UC-###)` đã qua một đêm. Repo đang chạy không phải sửa gì.
- **Cửa 2 mới:** mục `## Đọc lại` có **ít nhất một** dòng `F#` mang **cả `[neo: ...]` lẫn đầu ra
  khác `___`**, và commit mới nhất là `docs(UC-###): đọc lại …`. Ba điều kiện cùng đúng thì qua
  cổng **trong ngày**.
- **Chốt chống khai gian nằm ở chữ "ít nhất một".** Đọc mà không thấy gì thì cửa 2 không mở, rơi
  về cửa 1 — nên nói dối ở đây tốn **đúng bằng** làm thật: phải bịa ra một phát hiện có neo trỏ
  vào chỗ có thật và có một đầu ra mang ID.
- **`/sdd-solo:verify`** — skill mới. `verify UC-###` chạy **subagent** đọc lại (không có context
  của buổi viết → không bị neo **do cấu tạo**, chứ không do ai khai), trình từng `F#` bằng
  `AskUserQuestion`, ghi `## Đọc lại`, commit riêng. `verify` không tham số thì quét cả cây.

### Vì sao là skill, không phải thêm một phép kiểm vào cổng (#28)

Nguyên văn chủ dự án: *"cần có 1 skill để chạy kiểm tra tính xác thực của tài liệu. Bởi vì đang
trong giai đoạn plan plan có lệch rất nguy hiểm"*. Mười ca thật trên `runxops` trong **đúng một
ngày**, không ca nào bị script bắt — `br.md` kết luận một bảng *"chưa tồn tại"* trong khi commit
trước đó đã tạo nó · commit khai một khối nội dung chưa hề vào file · `RULE-001` đổi sang UUID mà
`br.md` còn ba đoạn nói ngược · `AC-6` hứa hệ thống *biết* một thứ mà không bước nào đi lấy · và
cả con số `26/40` sai trong issue #25.

Đây **không** cùng họ với #11/#13/#17/#24/#26. Bốn cái đó là *"đếm đúng nhưng đếm nhầm chỗ"* —
sửa được bằng cách sửa phép đếm. Loại này là *"không có phép đếm nào cho nó"*: cả sáu loại sai đều
đòi **đọc và so nghĩa**. Viết bằng `grep` sẽ ra đúng cái bẫy đã ghi ở 3.4.2 — một phép kiểm báo đỏ
oan rồi bị học cách phớt lờ. Nên nó là **skill có người quyết từng dòng**, không phải cổng.

Bốn ràng buộc, cả bốn có tiền lệ trong plugin: chỉ báo không sửa (như ba vai) · mỗi phát hiện
**trích nguyên văn hai chỗ đang cãi nhau** (#25 — và đó là thứ làm phát hiện kiểm lại được) · mỗi
phát hiện có đầu ra mang ID (#12) · phạm vi là **cả cây**, vì 6/10 ca là lệch **giữa** các file,
đọc từng file riêng không thấy cái nào.

Ba giới hạn ghi thẳng vào skill, không giấu: nó **sinh dương tính giả** nên bác phải rẻ và lý do
bác phải được ghi lại · **"không thấy gì" là bằng chứng yếu**, cấm in ra câu nào nghe như bảo
chứng, chỉ được nói *"không tìm ra gì trong phạm vi đã đọc"* kèm liệt kê phạm vi · chi phí đọc cả
cây phải thu về theo `git diff` khi cây lớn.

### Sửa kèm

- `uc-ready.sh` bỏ qua mục `## Đọc lại`. Không bỏ thì mục của bước ⑧ còn nguyên template sẽ làm
  uc-ready đỏ ở bước ⑦, `adversarial` từ chối chạy, và không có đường ra: muốn qua ⑦ phải điền
  trước một mục chỉ tồn tại sau ⑦.

### Hai bẫy shell gặp khi viết bản này — cùng họ với những bẫy đã ghi

1. **`${VAR#docs($ID): ...}` không khớp gì cả** vì dấu ngoặc đơn trong pattern bóc tiền tố. Nó trả
   về **y nguyên** chuỗi vào, nên điều kiện luôn sai và cửa 2 **không bao giờ mở** — không lỗi,
   không cảnh báo. Dùng `case ... in "docs($ID): đọc lại"*)`. Cùng họ `ls a b` (#16).
2. **Dấu nháy đơn trong comment tiếng Việt bên trong khối `awk '...'`** đóng chuỗi của shell sớm
   và giết cả chương trình awk. Triệu chứng giống hệt bẫy trên: biến rỗng, không thông báo.

Cả hai đều bị bắt vì test đo **từng ca một** thay vì chạy một ca rồi kết luận. Bốn ca khai gian
(F# không neo · đầu ra còn `___` · `→ đầu ra: ___` có nhãn · commit sai tiêu đề) đều phải đỏ, ba
ca thật phải xanh — bảy ca, đo đủ bảy.

## 3.4.3 — 2026-09-09

### Sửa — `status.sh` tố `code_paths` sai trong khi `code_paths` đang đúng (#26)

Ca đầu tiên của luật vừa ghi ở 3.4.2 — *báo đỏ oan thì bị học cách phớt lờ* — và lần này là đỏ
oan **thật**, đo trên `runxops`, không phải giả định.

`status.sh` gộp hai mối lo khác nhau vào **một `if` HOẶC** rồi thân `if` không kiểm lại vế nào đã
đúng:

```bash
if ! has_code_path "$ROOT" || [ ! -d "$ROOT/$UCT_" ]; then
  ...  bad "code_paths=… — không thư mục nào tồn tại"      # in cả khi has_code_path TRUE
```

Nên chỉ cần `tests/use-cases/` chưa có là `code_paths` bị tố oan. Đo bằng chính hàm của plugin:
`has_code_path` **TRUE**, `[ -d tests/use-cases ]` **không** → vẫn in *"không thư mục nào tồn
tại"*.

**Vì sao nó tệ hơn một dòng đỏ oan bình thường:**

1. **Nó bảo người ta đi sửa một file đang đúng.** `.sdd/config` có comment *"Sửa tay thoải mái"*,
   nên người tin dòng ✗ sẽ đổi `code_paths` sang thứ khác — và **lúc đó githook mới thật sự chặn
   hụt**. Dòng cảnh báo tự tạo ra chính cái nó cảnh báo.
2. Nó đứng ngay cạnh một dòng `!` **đúng** về `uc_test_dir`, nên người đọc học cách bỏ qua cả cụm.

Và nó không hiếm: đúng với mọi repo đã có thư mục code mà chưa implement UC nào — tức khoảng thời
gian `sdd-solo` ở lâu nhất, từ `scaffold` tới `/speckit-implement` đầu tiên. Ở `runxops` thứ làm
`repo_has_code` TRUE chỉ là một script chuyển dữ liệu một lần, không phải code sản phẩm.

- **Tách hai mối lo, hỏi riêng.** `code_paths` chỉ nói khi `has_code_path` sai; `uc_test_dir` chỉ
  nói khi thư mục thiếu.
- **`uc_test_dir` vắng ở Phase 1–2 là BÌNH THƯỜNG** — chưa AC nào implement thì chưa có test nào
  để đặt vào. Dòng `!` nay chỉ hiện khi đã có UC `Status: implemented` mà thư mục vẫn vắng.

Bốn ca đo trên repo thật, `src/` có · `tests/use-cases/` chưa có:

| Ca | Trước | Sau |
|---|---|---|
| `has_code_path` TRUE, chưa UC implemented | ✗ oan | **im** |
| Có UC implemented, chưa có `tests/use-cases/` | ✗ oan + ! đúng | **chỉ ! đúng** |
| Đã có `tests/use-cases/` | ✗ oan | **im** |
| `code_paths` trỏ sai thật, repo có file nguồn | ✗ đúng | **✗ đúng** — giữ nguyên |

`status.sh` vẫn `exit 0`; lỗi này chưa bao giờ chặn cổng hay CI, chỉ dạy người ta ngờ output.

## 3.4.2 — 2026-09-09

### Sửa — bản vá đảo thứ tự bước mà giữ nguyên số thì không cổng nào bắt được

Ca thật ở `runxops`, tìm ra khi sửa nhãn `E#` của `UC-009`: câu adversarial Q1 bảo *duyệt trước,
ghi sau*. Bản vá **đảo nội dung hai bước nhưng giữ nguyên số**, nên đọc `Main Flow` từ 1 xuống vẫn
ra thứ tự cũ — ghi trước, duyệt sau. `UC-009.flow.md` vẽ theo đó nên cũng vẽ ngược.

Nửa sai đó sống sót qua **một lượt adversarial và ba lần chạy cổng**. Không phép kiểm nào bắt
được, và không phép kiểm nào *đáng lẽ* bắt được: mỗi bước đều tồn tại, đánh số đủ, mọi nhãn đều
deref được. **Cái sai nằm ở thứ tự — thứ chỉ đọc mới thấy.** Đây đúng là loại lỗi bước ⑧ *"đóng
máy, đọc lại buổi sau"* sinh ra để bắt, và nó thuộc về người đọc chứ không thuộc về script.

Bước 5 của `skills/adversarial` nay bắt buộc, khi bản sửa làm đổi thứ tự bước:

1. **Đánh số lại** theo thứ tự đúng, sửa luôn `UC-###.flow.md` cho khớp.
2. **Remap mọi nhãn theo NGHĨA, không theo số** — `Main 5` sau khi đánh số lại có thể trỏ vào bước
   khác hẳn. **Số không phải danh tính**; nó là vị trí, và vị trí thì đổi.
3. `## History` ghi **vì sao số đổi**, không chỉ ghi "đã sửa".

### Không thêm cổng cho lớp lỗi này — và ghi rõ vì sao

Phép kiểm gần nhất là đối chiếu thứ tự node trong `flow.md` với thứ tự bước trong `## Main Flow`.
Flow có nhánh nên "thứ tự" không tuyến tính → sẽ **báo oan**. Theo đúng luật của repo này, *một
phép kiểm báo xanh sai tệ hơn không có phép kiểm* — và một phép kiểm báo đỏ oan thì bị người ta
học cách phớt lờ, rồi kéo theo cả những dòng đỏ thật. Ghi lại đây để lần sau không ai đi làm nó.

### Đo được — cổng KHÔNG quá chặt

Phân loại 9 dấu ✗ của `UC-009` trên repo thật, sau khi `glossary.md` được viết (19 thuật ngữ,
`UC-009` còn **2 ✗**):

| Loại | Số dòng |
|---|---|
| Spec thiếu thật | **7/9** — 5 nhãn `E#` vắng trong flow · `E3` không có dòng Screens · glossary còn template |
| Thủ tục, tan khi `/sdd-solo:adversarial` chạy xong | 2/9 |
| **Cổng quá chặt / bắt oan** | **0/9** |

Không dòng nào bắt oan. 9 dòng nhiều là vì spec thiếu thật 7 chỗ, không phải vì cổng khó tính.
Đây là lần đầu có số liệu từ repo sản xuất trả lời câu hỏi đó.

## 3.4.1 — 2026-09-09

### Đính chính — `allowed-tools` KHÔNG phải whitelist

3.4.0 viết: *"không skill nào khai `AskUserQuestion` … không khai thì không gọi được … chưa bao
giờ dùng được ở đâu cả."* **Sai.** Tài liệu chính thức của Claude Code, nguyên văn:

> *"The `allowed-tools` field grants permission for the listed tools during the turn that invokes
> the skill … **It does not restrict which tools are available: every tool remains callable**, and
> your permission settings still govern tools that are not listed."*

Nó là **cấp quyền trước** cho một lượt, không phải hàng rào. Phiên `runxops` đo trên transcript
của chính nó: `AskUserQuestion` được gọi **14 lần**, trong đó có lệnh gọi nằm gọn trong khoảng
`/sdd-solo:intake` với nội dung *"BR-001 viết lại quanh vết thương nào?"* — tức intake đã hỏi
bằng cơ chế đó, chạy thật, người thật trả lời. Tiền đề gốc của #25 đúng ngay từ đầu.

**Hệ quả cho ai đọc sau:** bản vá thật của #25 là **sửa văn bản bước 5**, không phải sửa
frontmatter. Dòng `allowed-tools` giữ lại vì nó bớt được một lần hỏi quyền giữa buổi phỏng vấn,
nhưng ghi sai nguyên nhân thì lần sau gặp lại triệu chứng này sẽ có người đi sửa frontmatter thay
vì sửa câu chữ — và sửa xong sẽ không có gì đổi.

Cách tự kiểm sau này: `allowed-tools` mà thiếu một tool thì triệu chứng là **một lời hỏi quyền**,
không phải một lỗi *"tool không tồn tại"*. Thấy skill vẫn gọi được tool không khai → đó là hành vi
đúng, không phải lỗ hổng.

### Sửa — nhãn nguồn có ba nơi để tra, không phải một (#25 nối tiếp)

`runxops` duyệt cả 24 câu adversarial của `UC-009`, tách từng nhãn rồi truy ngược vào file thật:
**50 nhãn · deref được 49** (Main 19 · E 10 · AC 9 · Section 5 · SCR 3 · RULE 1 · Alt 1 · OpenQ 1).
Không nhãn nào trỏ vào chỗ rỗng — nguyên liệu để dereference có thật.

Cái trượt duy nhất là **`CON-011`**, và nó tồn tại thật ở `specs/br.md`. Script chỉ tra hai chỗ:
file UC và `rules.md`. Bước 5 của `skills/adversarial` cũng vậy — nên ai cài phần "dán nguyên
văn" theo đúng chữ của 3.4.0 sẽ **im lặng bỏ sót mọi nhãn `CON-`**: không lỗi, không cảnh báo,
chỉ là câu hỏi đó mất đúng phần ngữ cảnh đắt nhất, vì `CON-` là nhãn mang ràng buộc.

- Bước 5a nay có **bảng ba nguồn tường minh**: file `UC-###.md` (`Main N` · `Alt Na` · `E#` ·
  `AC-#` · `SCR-###-#`) · `specs/rules.md` (`RULE-###`) · **`specs/br.md`** (`CON-###` ·
  `Background` · `Success Metrics` · `Out of Scope` · `Impact Map`).
- Tra không thấy → **nói thẳng trong câu hỏi** (*"nhãn `[CON-011]` không tìm thấy trong
  `br.md`"*), không lặng lẽ bỏ nhãn đi. Cùng một luật với `→ spec:` trống ở #12: lời khai không
  kiểm được thì phải hiện ra, không được biến mất.

## 3.4.0 — 2026-09-09

### Thêm — câu hỏi phải trả lời được, không chỉ phải trả lời (#25)

Nguyên văn chủ dự án: *"các câu hỏi hiện tại chỉ là 1 dòng. Anh không biết được có nên trả lời
nó hay không. Và ngữ cảnh của câu hỏi là gì, giải pháp nào anh nên chọn."*

3.3.0 trả lời *"câu nào buộc chốt trước bước ②"*. Bản này trả lời câu tiếp theo: **đã biết phải
chốt rồi thì lấy gì mà chốt.** Phân loại xong mà vẫn đưa một dòng thì người dùng biết mình *phải*
trả lời nhưng vẫn không trả lời được — tệ hơn trước, vì giờ không bỏ qua được nữa.

Đo trên `runxops`: **26/40** câu treo ở `br.md` có `(quyết định tạm: ___)` rỗng · **21/24** câu
adversarial của `UC-009` còn `→ đầu ra: ___`.

- **Nguyên liệu đã thu rồi, chỉ là không ai giải nén.** Prompt đã bắt mỗi câu kèm nhãn nguồn
  `[Main 7, RULE-003]`, và ba vai làm đúng **24/24**. Nhưng bước 5 của `skills/adversarial` chỉ
  nói *"trình cho user từng câu"* — không đọc `Main 7` và `RULE-003` ra. Nay bắt buộc
  **dereference**: dán **nguyên văn** chỗ spec đang nói gì.
- **`AskUserQuestion` nay nằm trong `allowed-tools`** của `adversarial`, `intake`, `start`.
  ~~Trước bản này không skill nào khai nó, nên cơ chế tưởng đã có sẵn thật ra chưa skill nào gọi
  được.~~ → **Câu gạch trên SAI. Xem Đính chính ở 3.4.1.** Việc thêm vào `allowed-tools` vẫn giữ,
  nhưng nó chỉ bớt một lần hỏi quyền, không phải nguyên nhân gốc.
- **Mỗi câu kèm ba thứ**, thiếu một là câu hỏi không trả lời được: ngữ cảnh **trích dẫn nguyên
  văn** (tóm tắt là chỗ lén thêm giả định) · mỗi lựa chọn kèm **cái mất** · `Chưa quyết` **luôn
  hiện sẵn** như một lựa chọn, không phải thứ phải tự gõ ra để thoát.
- **Áp bài kiểm hình dạng/giá trị của 3.3.0 vào từng câu**: câu đổi hình dạng thì hỏi, câu đổi giá
  trị thì ghi thẳng Open Question. Hỏi hết 24 câu là cách nhanh nhất để user bấm bừa cho xong.
- **Vai BR nay cũng phải kèm nhãn nguồn** (`[Background]` · `[CON-002]` · `[Success Metrics]`) như
  vai UC. Sửa 36/40 câu treo ở `br.md` không truy được về đâu.
- **Cảnh báo khi `___` chiếm quá nửa** — `br-check` trên `## Open Questions`, `gate-check` trên
  `## Adversarial pass`. `___` là đầu ra hợp lệ và không được biến mất; nhưng khi nó chiếm đa số
  áp đảo thì đó không còn là *"đã cân nhắc và chưa quyết được"*, mà là *"không có gì để cân"*.

### Ranh giới — vì sao đề xuất được phép, và phép tới đâu

Đưa phương án cho người dùng đụng thẳng vào thứ cả tầng BR sinh ra để chặn: AI nêu một con số
nghe hợp lý rồi nó thành sự thật trong spec. Bốn ràng buộc, ba cái đầu từ issue và cái thứ tư là
cái duy nhất **để lại dấu vết trong file**:

1. **Căn cứ phải truy được trong repo, hoặc là một lệnh chạy lại được.** Kiến thức chung của model
   không phải căn cứ — cái đó gọi là *hướng có thể đi*, không được gọi là *khuyến nghị*.
2. **Không xếp hạng, không đánh dấu "nên chọn"** cho câu đổi giá trị nghiệp vụ. Bày ra không gian
   lựa chọn là đưa thông tin; chọn hộ là ra quyết định.
3. **Giá trị do AI nêu mà user chỉ gật thì chưa phải của user** → ghi `___ (AI gợi ý X, chưa ai
   duyệt)`. Chỉ khi user tự nói ra bằng lời của họ mới thành quyết định. Đây đúng là bẫy gật đầu
   `/sdd-solo:intake` đã vá ở 3.2.3 — cùng cái bẫy, chỗ khác.
4. Ba ràng buộc trên sống trong **hội thoại**; ràng buộc này sống trong **file**. Đóng terminal thì
   chỉ còn file — nên provenance của mọi con số phải nằm trong spec, không nằm trong lời nói.

## 3.3.2 — 2026-09-09

### Sửa

- **Dòng ✗ của glossary nói đúng cái gì sai, nhưng không nói bắt đầu từ đâu.** Đo trên lần chạy
  thật ở `runxops`: trong cùng một lần `gate-check`, dòng cảnh báo ngay phía trên nói luôn phải
  gõ gì (*"dùng `P#` cho node kết thường, `X#` cho node kết của ngoại lệ"*), còn dòng glossary chỉ
  nói nó sai. Mà glossary là file **khó bắt đầu hơn nhiều**: *"đổi E1 thành X1"* là một phép thay,
  còn *"viết glossary đi"* là một trang giấy trắng.

  Nay nó chỉ nguồn có sẵn. Người ở bước ⑨ gần như luôn đã viết xong `entities.md`, và tên entity
  chính là mẻ thuật ngữ đầu tiên — nên script đọc thẳng tên entity ra và in kèm:

  ```
  ✗ specs/glossary.md còn nguyên template — CLAUDE.md bảo dùng đúng tên trong đó, mà trong đó chưa có tên nào
    – mẻ đầu có sẵn — tên entity anh đã viết: Account Listing
    – mỗi dòng một từ, dưới heading '## catalog':  - **Tên** — nghĩa một câu. Không nhầm với **từ gần nghĩa**.
  ```

  Biến một trang trắng thành việc chép. `entities.md` chưa có thì nó nói lấy từ đâu.

### Không phải lỗi — đã kiểm

- Báo cáo *"`gate-check.sh` thoát với EXIT rỗng qua pipe"* không phải lỗi của script. Đo lại:
  chạy trực tiếp → `exit 1` đúng; qua pipe thì `$?` là của lệnh cuối trong pipe, đúng chuẩn shell.
  `${PIPESTATUS[0]}` rỗng là vì **zsh** dùng `$pipestatus[1]` (chữ thường, đánh số từ 1), còn
  `PIPESTATUS` viết hoa là của bash. Đo hai chiều:

  ```
  bash:  PIPESTATUS[0] = 1
  zsh:   PIPESTATUS[0] = ''   ·  pipestatus[1] = 1
  ```

  Ai đọc exit code của script trong CI dưới zsh thì nhớ chỗ này; script không cần sửa.

## 3.3.1 — 2026-09-09

### Làm rõ

- **Không phải mũi tên nào trên state diagram cũng do một UC kéo.** Luật cũ viết tuyệt đối —
  *"mỗi mũi tên ghi UC nào được kéo nó"* — nhưng có ca thật ngược lại: `đangSống --> đãSuspend`
  xảy ra vì sàn khoá tài khoản, không UC nào gây ra. Trạng thái đổi vì thế giới bên ngoài (hệ
  thống khác đẩy sang, hết hạn theo đồng hồ) là chuyện bình thường, và ép nó mang một `UC-###`
  cho đủ hình thức chính là **bịa** — đúng thứ cả quy trình này sinh ra để chặn.

  Luật nay viết đúng: mỗi mũi tên ghi **nguyên nhân**, thường là `UC-###` nhưng không bắt buộc.
  Template context có sẵn một mũi tên dạng đó để thấy nó hợp lệ.

- `gate-check` §6 **cố ý** quét cả file thay vì xét từng mũi tên — chỉ cần một mũi tên gắn UC có
  thật là qua. Hành vi này không đổi ở 3.3.0; cái đổi là **lý do của nó nay nằm trong code**, kèm
  ca thật, để lần sau không ai "sửa" nó thành per-arrow rồi bắt oan. Cùng bài học #21: luật không
  để lại dấu vết ở chỗ người ta sẽ đọc thì sẽ trôi — lần này chỗ đó là comment cạnh phép kiểm.

### Đính chính

- Ghi chú nâng cấp ở 3.3.0 nói repo đang chạy sẽ đỏ *bốn* dòng ở §6. Đo trên `runxops` sau khi
  `entities.md` v2 đã viết xong: **đỏ một dòng** (`glossary.md` còn template). Ba phép kiểm còn
  lại xanh trên file viết tử tế — phép kiểm mũi tên bắt đúng thứ nó định bắt và không bắt oan.

## 3.3.0 — 2026-09-09

**Đọc trước khi nâng:** repo nào có `entities.md` hoặc `glossary.md` còn là template sẽ bắt đầu
**đỏ ở cổng DoR**. Đó không phải quy tắc mới — cổng vẫn luôn đòi hai file đó; phép kiểm chỉ báo
xanh sai suốt từ đầu. Viết chúng ở bước ③ là xong.

### Sửa

- **`uc-ready.sh` chặn `___` trong `## Open Questions`, nên lối thoát duy nhất là bịa số** (#23).
  Người viết trung thực `- [ ] Khoá nối là gì? (quyết định tạm: ___)` bị chặn ở bước ⑦, và cách
  duy nhất đi tiếp là thay `___` bằng một giá trị nghĩ ra tại chỗ. Đó đúng là thứ cả tầng BR sinh
  ra để chặn — `specs/br.md` viết thẳng *"`___` là câu trả lời hợp lệ, số bịa thì không"*, rồi bước
  ⑦ của chính quy trình đó chặn `___`.

  Ba chỗ trong quy trình đã nói ngược nhau về cùng một thứ: `gate-check` §8 cho qua (chỉ đỏ khi
  *thiếu* `quyết định tạm`), `br-check` chỉ cảnh báo, `uc-ready` chặn. Nay `___` trong Open Questions
  là hợp lệ và có một dòng `–` nói rõ nó được bỏ qua; `<...>` thì vẫn đỏ ở mọi chỗ, kể cả trong
  Open Questions — đó mới là "chưa ai viết nội dung".

- **`gate-check` §6 báo ✓ trên `entities.md` chưa ai đụng vào** (#24). Phép kiểm là
  `grep -q stateDiagram`, mà template context có sẵn một khối `stateDiagram-v2` mẫu — nên nó khớp
  vào chính nó. `entities.md` còn nguyên `class EntityA` / `class EntityB` vẫn in `✓ context <ctx>
  có entities.md` và không warn một chữ.

  **Một phép kiểm báo xanh sai tệ hơn không có phép kiểm** — không có thì người ta còn tự nhớ.
  Cùng hình lỗi đã vá hai lần: #11 (tiền điều kiện đo cấu trúc) và #13 (RULE placeholder lọt gate).
  Nay đo nội dung: tên entity của template, tiêu đề `<Context>`, và mũi tên state diagram phải ghi
  một `UC-###` có thật thay vì `<UC-### tạo>`.

- **`glossary.md` không script nào kiểm** — `grep -ric glossar scripts/` ra **0 trên cả 15 script**,
  trong khi khối `CLAUDE.md` phát cho dự án bảo AI *"dùng đúng tên trong `specs/glossary.md`"*. File
  đó trôi im lặng suốt. Nay cổng DoR đỏ nếu nó còn nguyên template, và đếm số thuật ngữ thật.

### Thêm

- **`uc-ready.sh` cảnh báo** (không chặn) khi `entities.md` của context hoặc `glossary.md` còn là
  template. Ba vai adversarial đọc hai file đó làm đầu vào; chạy ba subagent trên một mô hình chưa
  viết thì mô hình đổi sau đó và AC phải **sửa lời**. Chi phí thật là vậy — không phải mất trắng,
  nên **cảnh báo chứ không chặn**: chặn ở đây là lặp lại đúng hình lỗi của #23.

- **Chuỗi 14 bước nay đặt tên cho việc viết `entities.md` + `glossary.md`** (bước ③). Trước đây
  bước ⑥ (*đối chiếu SCR ↔ E# ↔ state*) và cổng ⑨ đều đã đòi hai file đó, nhưng không bước nào
  trong chuỗi nói ai viết chúng và lúc nào — nên chúng hay bị làm sau bước ⑦. `skills/adversarial`
  không sai khi đòi đọc `entities.md`; chuỗi bước mới là chỗ thiếu.

- **Câu hỏi nào phải chốt trước bước ②, câu nào treo được** — mục mới trong `sdd-process`, và
  `/sdd-solo:start` nay hỏi và phân loại giúp. Từ câu hỏi thật của chủ dự án: *"anh bị phân vân là
  nên nghiên cứu để trả lời câu hỏi, hay chạy tiếp `use-case-spec`. Flow không có gì hướng dẫn anh."*

  Ranh giới: câu đổi **hình dạng** của UC (actor là ai · dữ liệu đến từ đâu · ai được làm) phải
  chốt trước, vì Main Flow viết theo giả định sai sẽ phải **vứt**. Câu đổi **giá trị** trong một
  bước (ngưỡng · thời hạn · enum · khoá) thì **treo được** bằng `quyết định tạm: ___`. Bài kiểm một
  câu: *câu trả lời ngược lại thì Main Flow có phải viết lại không?*

## 3.2.3 — 2026-09-08

Ba phát hiện từ phép thử bộ câu hỏi (#22): hai subagent đóng vai người dùng, hai đóng vai người
phỏng vấn, **không bên nào biết đang bị đo cái gì**; cả hai nhân vật gật đầu ngay với bất kỳ con số
nào người phỏng vấn nêu ra, nên số nào có trong BR mà không có trong lời nhân vật đều là số do
skill đẻ ra — so file với transcript là ra.

Kết quả nền: cả ba BR qua `br-check` vòng đầu, **0 số nghiệp vụ bịa**, không BR nào để giải pháp
lọt vào Goal.

### Sửa

- **Câu 5 không chặn được gì — chỗ nặng nhất.** SKILL.md gọi câu 5 (*"có cách nào đạt được điều đó
  mà không xây phần mềm không?"*) là *"thứ duy nhất chặn được việc xây một phần mềm không cần tồn
  tại"*. Nhưng khi user trả lời *"chưa nghĩ tới"*, hướng dẫn chỉ bảo ghi một Open Question rồi đi
  tiếp — mà Open Question **không chặn gì**. Một BR ghi thẳng trong Background *"BR này hiện chưa
  có lý do chọn xây phần mềm"* vẫn ra `BR DÙNG ĐƯỢC`, không gì phân biệt nó với BR đã chứng minh xong.

  `## Background` nay có một dòng bắt buộc `**Vì sao vẫn xây:**`, `br-check` **cảnh báo** khi thiếu
  (không đỏ — Phase 1 vẫn phải mềm), và vai hoài nghi ở `/sdd-solo:adversarial BR-###` đọc dòng đó
  **trước tiên**; ghi *"chưa có lý do"* thì đó là câu hỏi số một của nó. Ghi *"chưa có lý do"* vẫn
  qua kiểm — trung thực là hợp lệ; thứ không hợp lệ là im lặng.

- **Bẫy gật đầu: hai luật trong SKILL.md đá nhau.** Một dòng cấm gợi ý số để user gật; một dòng
  khác bắt cách đo không được để trống. Với người chưa từng đo cái gì thì hai câu đó không cùng
  thoả được — họ cần một ví dụ, mà ví dụ nào cũng kèm ngưỡng. Phép thử bắt được đúng ca này: người
  phỏng vấn nêu *"quá một ngày mới trả lời"*, user gật ngay. Nó thoát **nhờ tự giác** (tự ghi Open
  Question rằng số đó là của mình), **không nhờ luật** — và `br-check` báo ✓ cả hai đằng, vì nó
  kiểm *có* cách đo chứ không kiểm cách đo đó **của ai**.

  Ranh giới nay viết rõ: được nêu **khung đếm** (đếm ở đâu · đếm cái gì · bao lâu một lần), không
  được nêu **ngưỡng bên trong khung**; ngưỡng luôn `___` kể cả khi user đã gật. Kèm một mẫu câu an
  toàn, và bắt buộc ghi Open Question *"số này do người phỏng vấn nêu, user chưa quyết"*.

- **Câu 5 mâu thuẫn nhẹ với luật "không đề xuất tính năng".** Muốn user bác được phương án
  không-phần-mềm thì phải nêu phương án; người chưa nghĩ tới không tự liệt kê được. Nay nói rõ đây
  là ngoại lệ có chủ ý, với hai ràng buộc: chỉ nêu phương án **không-phần-mềm**, và nêu **ít nhất
  ba** để user không bị dẫn vào đúng một cái rồi gật.

- `_intake.md`: thêm cảnh báo về số **user tự đoán** (*"tuần nào cũng vài lần"*) — ca này khó hơn
  *"không biết"* thẳng, vì chính user mở đường cho con số vào Background.

## 3.2.2 — 2026-09-08

### Sửa

- **Luật 4 của `/sdd-solo:intake` không để lại dấu vết nào trong file** (#21). Luật này bảo
  *"in danh sách thứ đã bỏ kèm lý do"* — và agent làm đúng chữ đó: đọc ra một danh sách khá kỹ,
  rồi thôi. Grep toàn bộ BR sinh ra: không mục nào ghi thứ đã bỏ. Toàn bộ sản phẩm của luật này
  sống trong **lời nói**; đóng terminal là mất, và sáu tháng sau không ai biết brief từng có
  những gì, vì sao chúng biến mất.

  Ba luật kia đều để lại dấu vết trong file — `___`, Open Question, nhánh `-.->` — nên kiểm được.
  Luật 4 là luật duy nhất không. Cùng họ với #11 #12 #13: **cái gì không kiểm được thì cuối cùng
  sẽ trôi**; khác ở chỗ lần này thứ trôi là một luật chứ không phải một cổng.

  - Template `br.md` có thêm mục `## Đã loại khỏi brief` (chỉ dùng khi BR chuyển từ brief) và
    dòng `- **Nguồn:**` trong Metadata.
  - `br-check.sh` **cảnh báo** khi Metadata nói nguồn là brief mà mục đó thiếu hoặc rỗng. Chỉ
    cảnh báo, và chỉ với BR từ brief — BR viết từ phỏng vấn không loại cái gì nên không có mục
    đó là đúng.
  - Luật 4 trong SKILL.md đổi từ *"in danh sách"* thành *"ghi vào `## Đã loại khỏi brief`, rồi
    mới đọc lại cho user nghe"*.

### Làm rõ

- **Ranh giới số trong luật 1.** Luật cấm số ở chỗ **quyết định nghiệp vụ** — ngưỡng, thời hạn,
  quota, quyền. Nó **không** cấm số ở chỗ **cách đo**: *"bấm giờ 20 lượt đặt bàn liên tiếp"* là
  một cách đo cụ thể và tốt hơn hẳn *"bấm giờ vài lượt"*. Cấm luôn thì cách đo tụt về mơ hồ, tức
  mất đúng thứ `BR-000` đang dạy. Cụ thể ở cách đo là đúng; cụ thể ở quyết định mà không ai duyệt
  là bịa. Đã nói rõ trong `skills/intake/SKILL.md`.

### Ghi nhận

Ba luật đầu chạy đúng trên brief giả 29 dòng: mọi số không nguồn bị hạ thành
`___ (brief đề xuất …, chưa ai duyệt)`, ba khẳng định không bằng chứng xuống Open Questions,
5/8 tính năng ra Out of Scope kèm nhánh `-.->`, dark mode bị gọi thẳng là mồ côi. Con số duy
nhất được giữ nguyên là một số hiệu nghị định — thứ có nguồn thật.

## 3.2.1 — 2026-09-08

### Sửa

- **Cửa vào mới của 3.2.0 chưa được gắn vào đường cũ** (#20). `/sdd-solo:intake` tồn tại,
  nhưng câu chỉ đường **đầu tiên** user đọc — dòng cuối của `scaffold.sh`, ngay sau
  `/sdd-solo:init` — vẫn là:

  > *Bước tiếp: đọc specs/README.md · viết STATE.md · /requirements (AIUP) hoặc tự viết specs/br.md*

  Cả hai lựa chọn đó đều dẫn vào tường: `/requirements` đọc `docs/vision.md` mà không skill
  nào tạo ra, còn *"tự viết br.md"* chính là chỗ người ta đứng lại. `grep intake scripts/`
  ra 5 chỗ trong `status.sh` và **0 chỗ** trong `scaffold.sh` — file nói trước là file sai,
  file đúng chỉ nói khi user đã biết gõ `status`.

  Sửa **sáu** chỗ cùng loại, không phải một:
  - `scaffold.sh` — dòng chỉ đường sau `init`.
  - `skills/init/SKILL.md` bước 5 — chỗ này tệ hơn cả, vì nó là chỉ dẫn cho **chính AI**:
    *"nói bước tiếp là Phase 1 — `/requirements` hoặc tự viết BR"*. Tức trợ lý được dặn
    chỉ sai đường ngay sau khi cài xong.
  - `hooks` SessionStart — khi `br.md` còn nguyên template thì câu đầu mỗi phiên nói thẳng
    *đang ở Phase 1, đừng nói về UC, đừng đề xuất viết code*, thay vì "đang ở UC nào".
  - `specs/README.md` — thêm mục **Bắt đầu từ đâu** lên đầu.
  - `STATE.md` — dòng `Đang làm:` giả định sẵn là đang ở một UC nào đó trong 14 bước.
  - `README.md` — bước sau `init`.

- `specs/_intake.md` không có **chỗ để viết câu trả lời**: nó bảo "không có Claude Code thì
  tự trả lời bảy câu bằng giấy bút", nhưng bảy câu nằm trong hai bảng markdown, không ô trống
  nào. Thêm hai khối trích dẫn đánh số sẵn.

Bài học chung với #10 và #17: thứ mình vừa xây chạy đúng, nhưng chỗ người dùng thật sự đứng
thì vẫn trỏ đi hướng cũ.

## 3.2.0 — 2026-09-08

### Thêm — Phase 1 có cửa vào và có kiểm (#18, #19)

Plugin đi từ 1.0.0 lên 3.1.1 với 17 issue, mà dự án nó phục vụ vẫn chưa có **một dòng BR nào**.
Không phải lười: người dùng nói thẳng là không biết viết thế nào cho đúng. Đo lại thì tầng BR
là tầng duy nhất trong bốn tầng không có gì đỡ ngoài một file template — không script kiểm,
không skill, `/sdd-solo:adversarial` chỉ nhận `UC-###`. Và không skill nào của sdd-solo **hay
của AIUP** tạo ra `vision.md` mà `/requirements` cần: nó *tiêu thụ* file đó.

Chi tiết đáng ghi nhất từ phiên `runxops`: người dùng nói *"chưa có template để mô tả 1 BR đúng"*
**trong khi đang nhìn thẳng vào một template có đủ Background, Goal, Metrics, Impact Map.** Nên
thứ thiếu không phải cái biểu mẫu — mà là **cách đi tới nội dung**. Bản này ưu tiên theo đúng
thứ tự đó: bộ câu hỏi trước, biểu mẫu sau.

- **`/sdd-solo:intake [brief]`** — cửa vào Phase 1, đối xứng với `/sdd-solo:start` của Phase 3.
  - *Không tham số* → **phỏng vấn**, một câu một lượt: khổ gì · ai khổ · tốn gì, rồi bốn câu đào
    sâu. Câu 5 (*"có cách nào đạt được điều đó mà không xây phần mềm không?"*) là câu hay bị bỏ
    nhất và là thứ duy nhất chặn được việc xây một phần mềm không cần tồn tại.
  - *Có đường dẫn* → **chuyển brief** của agent khác, theo bốn luật không có ngoại lệ: số không
    nguồn thì `___` + Open Question **kể cả khi brief có ghi số** (brief *đề xuất* ≠ ai đó *đã
    duyệt*) · mọi "xây X" phải đẩy ngược lên được một mục tiêu đo được, không ra thì đánh dấu mồ
    côi · khẳng định không bằng chứng thì thành Open Question chứ không thành Background · cuối
    phiên phải in ra thứ đã bỏ kèm lý do.
- **`specs/_intake.md`** — bộ bảy câu hỏi nằm **trong dự án**, dùng được cả khi không mở Claude Code.
- **`scripts/br-check.sh BR-###`** — kiểm cơ học tầng BR. Đáng kể nhất: Success Metrics được phép
  để `___` ở phần **số** nhưng **không** được thiếu **cách đo** — đó là ranh giới giữa một metric
  thật và một câu nói hay; Impact Map phải có ít nhất một nhánh `-.->`, vì không có nhánh đứt nào
  nghĩa là chưa map gì, chỉ là đường thẳng từ Goal xuống danh sách việc đã định sẵn; và Goal dùng
  từ mơ hồ (*tối ưu · cải thiện · nâng cao*) khi Metrics chưa có số nào thì đỏ.
- **`/sdd-solo:adversarial BR-###`** — ba vai của tầng BR, hỏi về **lý do tồn tại** chứ không phải
  hành vi: *người trả tiền* · *người sẽ phải vận hành nó mãi* · *người hoài nghi*. Vai thứ ba không
  có ở tầng UC và là vai quan trọng nhất — nó bắt lỗi **BR viết ngược từ giải pháp**. *"Xây dashboard
  theo dõi đơn hàng"* không phải BR; BR thật nằm ở câu hỏi *vì sao cần theo dõi*. Nếu vai này kết
  luận BR đang là giải pháp viết ngược thì **dừng và viết lại**, không ghi thành Open Question rồi đi tiếp.
- **`BR-000` — một BR điền đủ, nằm trong `specs/br.md` của dự án**, kèm cả mục Adversarial pass đã
  chạy. Đọc một BR viết đúng cạnh cái mình sắp viết là cách dạy rẻ nhất; `RULE-000` đã làm vậy ở #13.
  `br-check.sh` bỏ qua `BR-000`.
- **`/sdd-solo:status`** liệt kê BR kèm trạng thái, **đỏ** khi `br.md` còn nguyên template mà repo đã
  có UC (đang xây trên nền chưa viết — loại sai đắt nhất vì nó ở gốc), và cảnh báo khi có
  `docs/requirements.md` của AIUP mà chưa có BR.

Hai chỗ cố ý **mềm hơn** đề xuất trong issue, vì bản gắt sẽ đỏ trên mọi BR trung thực:

- **`___` chỉ cảnh báo, không đỏ.** Ở Phase 1, `___` là dốt một cách trung thực. Ép điền sớm đẻ ra
  đúng loại số bịa mà cả bước intake đang cố chặn. Placeholder `<...>` thì vẫn đỏ.
- **UC trong `## Related Use Cases` chưa tồn tại chỉ cảnh báo** — BR viết *trước* UC, đỏ ở đây thì
  không sửa được. Nhưng **chiều ngược thì đỏ**: UC đã khai `Liên quan tới BR: BR-###` mà BR không
  liệt kê nó là trôi thật, và luôn sửa được. Cùng bài học hai chiều của #12, #15, #17.

### Sửa

- `filled()` trong `br-check.sh` và `change-check.sh` không bắt được **placeholder trải nhiều dòng**:
  `<Vì sao có requirement này —` mở ở dòng này, `... như sự thật>` đóng ở dòng sau, nên regex một
  dòng `<[^>]+>` không khớp cái nào và mục rỗng đi qua như có nội dung. `## Background` của khung BR
  trống lọt đúng theo đường này. Nay bắt cả dòng chỉ mở và dòng chỉ đóng.

### Cách nâng

```
/plugin marketplace update sdd-solo
/plugin update sdd-solo
/sdd-solo:init --update          # br.md, _intake.md, prompts nằm trong templates/
```
`specs/br.md` đã sửa tay thì `init --update` **không** ghi đè — bản mới nằm cạnh dưới tên `br.md.new`,
tự merge rồi xoá `.new`.

## 3.1.1 — 2026-09-08

### Sửa

- **Phép đếm E# của 3.1.0 khớp `E<số>` ở bất cứ đâu trong file, kể cả tên node — nên
  cho `✓` GIẢ** (#17). Đặt một node kết là `E1([Đăng nhập được])` — tức một kết thúc
  **thành công** — thì cổng tin rằng đường lỗi `E1` đã được vẽ, kể cả khi nhánh ngoại lệ
  thật không còn nhãn nào. Sai về đúng phía nguy hiểm: không phải đỏ oan, mà là xanh sai.
  Chiều ngược thì kêu nhầm chỗ — node tên `E7` bị báo là "nhãn bịa".

  Nay **chỉ nhãn cạnh được đếm**: phần nằm giữa hai dấu `|` trên dòng có mũi tên. Tên node
  không bao giờ ở đó. Kèm một cảnh báo mềm khi vẫn có id node dạng `E<số>` — nó không giả
  mạo được nhãn nữa nhưng vẫn khó đọc cho người.

  Đáng sửa vì nó chạm đúng lý do đổi sang mermaid ở 3.1.0: để phép đếm *"số nhánh ngoại lệ
  = số E#"* **chạy được bằng máy** thay vì là một dòng chữ trong checklist. Đếm khớp cả tên
  node thì phép đếm đó chưa đúng, tức lợi ích chính của 3.1.0 chưa thành.

### Đính chính

- CHANGELOG 3.1.0 nói hồi quy chạy trên `runxops`. Không đúng: **`runxops` chưa có UC nào**
  — nó còn ở Phase 0, `specs/` toàn template. Mọi UC có `.bpmn` thật đều nằm ở bàn thử.
  Nên tới giờ chưa có bằng chứng nào từ một repo sản xuất, cho cả 3.1.0 lẫn bản này.

## 3.1.0 — 2026-09-08

### Đổi — bước ④ vẽ bằng Mermaid, không cần cài app

Bước ④ trước đây đòi `UC-###.bpmn` vẽ bằng **Camunda Modeler**, một app desktop phải cài.
Đọc lại thì cái giá đó gần như không mua được gì:

- `gate-check.sh` **chỉ kiểm file có tồn tại**. `.bpmn` là XML nén, script không đọc nổi.
- Checklist DoR đòi *"số error boundary event = số E#"* — một phép **đếm**, và đó mới là
  giá trị thật của bước này: nó ép tìm cho đủ ngoại lệ. Phép đếm ấy **chưa bao giờ chạy
  bằng máy**, chỉ là một dòng trong checklist.
- `git diff` trên `.bpmn` không đọc được, và phải nhớ export thêm `.bpmn.svg`.

Mermaid đảo cả ba: là text nên gõ bằng bàn phím, `git diff` đọc được, Claude sửa được,
VS Code (`Cmd+Shift+V`) và GitHub render sẵn. Và vì là text nên **cổng DoR đếm được E# thật**.

- **`UC-###.flow.md`** — artifact mới, mermaid `flowchart`, nằm trong thư mục UC.
  Template ở `.sdd/templates/use-case/UC-000.flow.md`.
- **`gate-check.sh` đối chiếu E# cả hai chiều**: E# khai trong `## Exceptions` mà sơ đồ
  không có nhánh → đỏ; nhãn `E#` trong sơ đồ mà UC không có Exception đó → cũng đỏ.
  Chiều ngược là bài học của #12 và #15: nhãn bịa đi qua mọi cổng nếu không ai đối chiếu.
  Thêm hai cảnh báo mềm: không có khối mermaid `flowchart`; không có node kết `([...])`.
- Không đếm lane/actor và Postcondition bằng máy — hai mục đó là văn xuôi tự do, đếm bằng
  regex sẽ đỏ oan. Bài học #16: file người viết tay trình bày tự do vẫn phải parse được.
- **Camunda Modeler xuống hàng tuỳ chọn** trong `deps-check.sh` — chỉ còn cần khi muốn
  chạy RULE bằng DMN engine, hoặc mở `.bpmn` cũ (`https://demo.bpmn.io` mở được trên
  trình duyệt, không phải cài).

**Không phá vỡ.** `.bpmn` vẫn được cổng DoR chấp nhận, chỉ không đếm được gì. Repo đang
dùng `.bpmn` không phải sửa gì.

### Sửa

- `.sdd/templates/use-case/UC-000.md` — dòng metadata trỏ `../../diagrams/UC-000.bpmn.svg`,
  sai từ 2.0.0 (bản đó đã dời diagram vào trong thư mục UC) mà không ai để ý. Nay là
  `**Flow:** UC-000.flow.md`.
- `skills/start/SKILL.md` liệt kê **đích danh** ba file để copy khi tạo UC mới, nên một
  template mới thêm vào `.sdd/templates/use-case/` sẽ không bao giờ tới tay dự án. Đã thêm
  `UC-000.flow.md` vào danh sách — chỗ này đáng nhớ cho mọi lần thêm template UC sau.

### Cách nâng

```
/plugin marketplace update sdd-solo
/plugin update sdd-solo
/sdd-solo:init --update          # template mới nằm trong templates/, không tự lan
```
UC đang dùng `.bpmn` cứ để nguyên. UC mới sẽ có sẵn `UC-###.flow.md`.

## 3.0.1 — 2026-09-08

### Sửa

- `close-check.sh` — bớt nhiễu ở bước soi số literal, theo số đo của phiên `runxops`
  trên một file 18 dòng viết theo lối thường: 4 dòng bị nêu, 2 đúng 2 sai. Hai ca sai
  đều là dạng máy loại được:
  - `+= n` / `-= n` — phép tăng giảm, lọt vào vì có dấu `=` ngay trước số. Gần như
    không bao giờ là ngưỡng nghiệp vụ.
  - `substring(0, 8)` / `slice(a, b)` / `padStart` / `padEnd` / `charAt` / `toFixed` —
    tham số chỉ số chuỗi, cùng họ với `[0]` đã loại từ trước.

  Dòng nào chứa chuỗi `số * số` thì **giữ trước khi xét hai luật đó**: `timeout += 30 * 60 * 1000`
  là tham số nghiệp vụ chứ không phải phép đếm, và luật `+=` một mình sẽ nuốt mất nó.
  Trên cùng file thử: từ 4 dòng (2 đúng 2 sai) còn 3 dòng, cả ba đều là tham số thật.

  Không đo được trên code sản xuất: `runxops` chưa có dòng code ứng dụng nào, `src/`
  chỉ có README stub. Con số trên là file viết cho giống code thường, không phải bằng
  chứng từ repo thật — ghi rõ ở đây để lần sau không ai trích nó như thể là.

### Không đổi

- Hồi quy 3.0.0 trên `runxops`: cổng Phase 5 đúng cả bốn mục, không mở issue nào.
  Một CHG do người viết tay (delta viết văn xuôi tự do, không theo dạng template) vẫn
  parse chuẩn — `✓ sửa AC-1 · ✓ sửa AC-4 · ✓ thêm AC-5`. Đây là rủi ro lớn nhất của
  3.0.0 (cổng chỉ được thử trên change do chính tác giả viết đúng template) và nó không
  xảy ra. Bốn dòng ✗ mà change đó rớt đều là lỗi thật của người viết.

## 3.0.0 — 2026-09-08

**Nâng cấp có phá vỡ.** Repo đang có `CHG-###` dở dang phải chạy `/sdd-solo:change CHG-###`
một lần cho mỗi change, nếu không githook sẽ chặn commit code gắn `(CHG-###)`.
Xem mục *Cách nâng* cuối bản này.

### Thêm — cổng Phase 5 (#16)

Phase 3 có 22 kiểm cơ học ở `gate-check.sh`. Phase 5 — chỗ **đổi hành vi đã giao cho
khách** — trước bản này có **không một kiểm nào**: không script, không skill. Một change
vào được repo với `proposal.md` nguyên xi template, không nói đụng UC nào, không nói lật
AC nào, và không gì chặn. Rủi ro của Phase 5 cao hơn Phase 3 mà hàng rào thì thấp hơn.

- **`/sdd-solo:change CHG-###`** — skill mới, cổng của Phase 5.
- **`change-check.sh`** kiểm, trong đó ba nhóm đáng kể:
  - *Có đúng là Phase 5 không.* Mọi UC trong `## Scope` phải có thật, phải `implemented`,
    phải có `.sdd/gate/UC-###.ok`. UC còn `draft` → đây là Phase 3, đóng change lại.
    Và phải có ít nhất một mục `MODIFIED`/`REMOVED`: chỉ thêm AC mới thì cũng là Phase 3.
  - *Delta có nói đúng về baseline không.* `REMOVED AC-7` khi baseline không có `AC-7`,
    `ADDED AC-1` khi baseline đã có `AC-1` — hai kiểu này trước đây không ai bắt, và
    chúng có nghĩa là delta đang mô tả một baseline khác với baseline thật.
  - *Có phải template không.* `<...>` còn sót, chuỗi `CHG-000`, `delta/UC-000.delta.md`,
    và mục chỉ chứa `...`. Bản thử đầu để lọt đúng cái cuối: `- ...` trong
    `## Rủi ro và cách lùi` đi qua cổng như một câu trả lời hợp lệ, vì nó *không rỗng*.
  - Cùng luật ngủ-qua-đêm với cổng DoR: `docs(CHG-###)` phải commit từ một buổi khác.
- **`change-pass.sh`** đặt `Status: applying`, thêm dòng History, ghi `.sdd/gate/CHG-###.ok`.
- `/sdd-solo:status` liệt kê change đang mở kèm status và dấu cổng.

### Đổi quy tắc

- **`commit-msg`: commit code gắn `(CHG-###)` giờ đòi `.sdd/gate/CHG-###.ok`**, không chỉ
  đòi thư mục tồn tại. Đây là phần phá vỡ. Nó làm cho `CHG-` đối xứng với `UC-`: cả hai
  đều phải qua cổng trước khi được đụng vào code.

### Sửa

- `close-check.sh` bỏ sót chuỗi nhân giữa các hằng số: `15 * 60 * 1000`, `24 * 60 * 60`,
  `1024 * 1024`. Toán tử nhân không nằm trong nhóm toán tử của bản trước, mà một chuỗi
  như vậy gần như luôn là khoảng thời gian hoặc kích thước — tức tham số nghiệp vụ. Ca
  thật do phiên `runxops` đo được: spec ghi `thời gian khoá = ___` còn code chạy
  `15 * 60 * 1000` và bước soi số literal không hề nêu nó ra. Chỉ nới cho `số * số`,
  không nới sang `+` `-` (`i + 1` nhiều vô kể).

### Cách nâng

```
/plugin marketplace update sdd-solo
/plugin update sdd-solo
/sdd-solo:init --update          # bắt buộc: hook và template nằm trong templates/
```
Rồi với **mỗi** change đang dở (`Status` chưa phải `verified`/`archived`):
```
/sdd-solo:change CHG-###
```
Change nào đã `archived` thì bỏ qua — không còn commit code nào gắn ID đó nữa.

## 2.1.2 — 2026-09-08

### Sửa

- **`commit-msg` chỉ kiểm ID có thật với tiền tố `UC-`** (#15, nặng). Bốn tiền tố còn
  lại — `CHG-` `ADR-` `BR-` `RULE-` — chỉ bị kiểm *hình dạng*: đúng regex là qua.
  `feat(CHG-999): …` với ID bịa hoàn toàn commit được, `feat(ADR-777)`, `feat(BR-888)`,
  `feat(RULE-666)` cũng vậy. Đây là đường vòng ba ký tự quanh lời hứa "không có cờ bỏ
  qua": không cần cờ, chỉ cần đổi `UC` thành `CHG` trong message. Giờ mỗi tiền tố phải
  chứng minh ID tồn tại — `CHG` cần `specs/changes/<ID>-*/`, `ADR` cần file trong
  `specs/internal/adr/`, `RULE` và `BR` cần heading tương ứng trong `specs/rules.md` /
  `specs/br.md`. Không tìm thấy thì chặn và nói rõ chỗ phải tạo.
- **`ls a* b*` trả lỗi nếu *bất kỳ* glob nào không khớp** — nên nhánh `CHG-`/`ADR-`
  vừa viết ở trên chặn nhầm cả ID thật: `specs/changes/CHG-001-…/` có thật, nhưng
  glob đường dẫn 1.x (`changes/CHG-001-*`) không khớp là `ls` exit 1 và hook kết luận
  "ID bịa". Tách thành hai phép thử nối bằng `||`. Cùng họ với bẫy `grep -c || echo 0`
  và command substitution dưới `set -e`: **lệnh thành công một phần vẫn là lệnh thất bại**.
- **`trace-ratio.sh` đếm mọi thứ trông giống ID** (#16, một phần). Chỉ số "commit có
  trace" vì thế đếm luôn cả nhãn dán. Giờ chỉ đếm ID `id_exists()` xác nhận có thật,
  và cảnh báo riêng số commit mang ID không tồn tại ở đâu trong repo.
- `specs/changes/README.md` trỏ `_template/` — đường dẫn 1.x, đã đổi từ 2.0.0. Sửa
  thành `.sdd/templates/change/`.

### Thêm

- `id_exists <ID> <root>` trong `lib.sh` — một chỗ định nghĩa "ID có thật". Githook
  chạy bash trần không nạp `lib.sh` được nên vẫn phải chép logic; hai bản phải đi cùng nhau.

## 2.1.1 — 2026-09-08
Đóng #14 — **2.0.3 chặn sạch `/sdd-solo:init` trên repo trắng, chết im lặng.**

`PV="$(cat "$ROOT/.sdd/version" 2>/dev/null)"` — chốt chặn hạ cấp thêm ở 2.0.3. Dưới `set -e`, một command substitution thất bại ở **vế phải của phép gán** làm thoát ngay. Repo trắng chưa có `.sdd/version` — chính `scaffold` mới là thứ tạo ra nó — nên:

```
2.0.2:  exit=0 · 49 dòng output · 55 file
2.1.0:  exit=1 ·  0 dòng output ·  0 file      ← không một dòng ✗, stderr rỗng
```

Người dùng thấy con trỏ nhảy về và `ls` chỉ có `.git`. Thêm `|| true`.

**Vì sao nó lọt qua khâu kiểm của cả hai bên:** chỉ dính repo **trắng**. Mọi bàn thử đều đã có `.sdd/version` từ bản trước nên `init --update` chạy bình thường; runxops-93 vấp phải vì đang dựng repo trắng để kiểm #13, không phải vì đi tìm nó. Ba bản 2.0.3 → 2.1.0 đều được kiểm trên repo đã cài sẵn.

Quét cả ba script có `set -e` tìm chỗ cùng dạng: `close-pass.sh:8,10,15` và `scaffold.sh:45,62` đều an toàn — chúng là pipeline (mã thoát của `head`/`tr`/`tail`) hoặc đọc file luôn tồn tại trong plugin. Chỉ có đúng một chỗ hỏng.

Kèm: `uc-ready.sh` được chép vào `.sdd/scripts/` cho đủ bộ — runxops-93 hỏi đúng, tuy `gate-check` không gọi nó nên chưa lặp lại #10.

## 2.1.0 — 2026-09-08
Đóng #11 #12 #13 — cả ba do runxops-93 tìm ra khi chạy `/sdd-solo:adversarial` thật. Chủ đề chung: **chốt đo cấu trúc chứ không đo nội dung**.

- **#11 — tiền điều kiện adversarial là chốt tuỳ lượt.** Bốn điều kiện ở `skills/adversarial` bước 2 đếm cấu trúc (có bước Main Flow, có AC, có E#, có dòng Screens) nên **template rỗng qua hết** — mà `/sdd-solo:start` copy chính template đó, nên mọi UC vừa tạo đều lọt. Thêm `scripts/uc-ready.sh`: giữ bốn kiểm cũ, thêm **đếm placeholder** (`<...>`, `___`) và in ra tối đa 8 chỗ. Skill gọi script thay vì tự đánh giá — biến chốt do model thi hành thành kiểm cơ học, đúng như README hứa "chặn cứng".
- **#12 — lời khai `→ spec` không kiểm được.** UC ghi `Q3 … → spec` mà không tạo RULE/AC/E# nào, gate vẫn `✓ adversarial pass đã chạy` rồi QUA CỔNG. Chỗ này **do chính adversarial pass bắt ra** — hai vai độc lập cùng chỉ vào nó. Giờ `→ spec` phải kèm ID (`→ spec: RULE-003`, `→ spec: E4, AC-5`) và `gate-check` kiểm ID đó có thật trong `rules.md` hoặc trong file UC. Thiếu ID cũng là ✗ — lời khai không kiểm được thì không tính là đã làm.
- **#13 — placeholder RULE của template trả lời thay.** `rules.md` phát sẵn `## RULE-001:` và `## RULE-002:` — đúng hai ID dự án đầu tiên chắc chắn dùng tới, nên UC trích `RULE-001` **qua cổng dù chưa ai viết rule nào**; viết rồi thì file có hai heading cùng ID mà gate vẫn `✓`. Đổi ID mẫu sang `RULE-000`/`RULE-000b` cho nhất quán với `UC-000`/`ADR-000`, và `gate-check` giờ bắt cả **ID trùng heading** lẫn **heading còn placeholder**.

Một lỗi tự bắt khi thử: `C="$(grep -cE … || echo 0)"` — `grep -c` in `0` **rồi mới** exit 1, nên `|| echo 0` tạo chuỗi hai dòng và phá cả hai phép so sánh phía sau, khiến ca "không có heading" lại báo `✓`. Fallback đặt sai chỗ còn tệ hơn không có.

## 2.0.3 — 2026-09-08
Đóng #10, và một lỗ cùng họ tự lộ ra khi thử.

- **`deps-check --fix` chết ở bản sao `.sdd/scripts/`** (#10, runxops-93 báo). Nó suy đường dẫn `scaffold.sh` cạnh chỗ nó nằm, mà bản sao **cố ý** không chứa `scaffold.sh` — nên bản sao, đúng thứ README 2.0.0 dạy dùng cho CI, đổ ra `No such file or directory`. Thêm `plugin_script()` trong `lib.sh`: tìm cạnh mình → **bản đang cài theo `installed_plugins.json`** → cùng lắm mới quét cache và lấy version cao nhất. Không thấy thì in `✗` kèm câu nhắc, thoái lui tử tế thay vì để lỗi shell lòi ra.
- **Chặn hạ cấp.** Thử #10 lộ ra: bản vá đầu vơ bừa `scaffold.sh` **1.3.0** trong cache và chạy nó lên một repo đã 2.0 — nó dựng lại nguyên cây 1.x (`checklists/ prompts/ .githooks/ .gitmessage`) cạnh cây 2.x, đúng trạng thái "hai cây" mà 2.0.1 vừa đi chặn. Chốt chặn 2.0.1 chỉ canh chiều tiến (plugin mới trên repo cũ). Giờ `scaffold` cũng từ chối khi `.sdd/version` **mới hơn** version plugin đang chạy.

runxops-93 ghi nhận một chỗ đáng giữ: phần "Kiểm lại sau khi cài" của `deps-check --fix` **không nói dối** — nó chạy lại từ đầu và báo `✗ spec-template vẫn là bản gốc` kèm lệnh sửa, nên #10 chỉ gây phiền chứ không thành một ca hỏng im lặng nữa. Đúng lời hứa "không tin bộ đếm" ở 1.1.0.

## 2.0.2 — 2026-09-08
Đóng #9 — bộ lọc literal của 1.6.0 lọc theo **độ dài chữ số** nên nuốt mất ngưỡng nghiệp vụ một chữ số.

`[0-9]{2,}` quét sạch `graceDays: 7` · `maxRetries: 3` · `otpLength: 6` · `maxDevices: 1` — loại phổ biến nhất. Và nó không im lặng bỏ qua mà **khẳng định sạch**: `✓ không thấy số literal lạ` cộng `ĐÓNG ĐƯỢC (0 cảnh báo)`. Cùng họ với #5, khác ở chỗ nguyên nhân nằm trong bộ lọc chứ không trong phạm vi quét.

Ca do runxops-93 dựng nói đúng vấn đề: dự án test có **RULE-001 "một license một thiết bị"**, con số của rule đó là `1`, code viết `maxDevices: 1` — `close-check` không nhìn thấy con số của chính cái rule nó đi soi.

Lọc theo ngữ cảnh thay vì độ dài: bắt mọi số đứng ngay sau so sánh, `:`, `=`, `,` hoặc `(`; loại chỉ số mảng, biến đếm vòng lặp (`i j k n idx index`), số version. **Bỏ hẳn bộ lọc chuỗi** — pattern vốn không khớp số nằm sau dấu nháy (`log("đã nạp 3 mục")` không dính), và thà dương tính giả: đây là bước ngồi soi cùng user, không phải cổng chặn.

Đo trên mẫu chỉ có số một chữ số: bắt `!== 6` `graceDays: 7` `maxDevices: 1`, vẫn bỏ `list[0]`, `for (let i = 0; i < list.length; i++)`, `n * 2`, `VERSION = "1.4.2"`.

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

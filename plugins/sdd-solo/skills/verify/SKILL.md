---
name: verify
description: Đọc lại tài liệu bằng subagent chưa bị neo để tìm chỗ spec tự mâu thuẫn hoặc khai điều không có thật. UC-### là bước ⑧ — cửa duy nhất của cổng DoR từ 6.0.0; CHG-### là cửa của cổng Phase 5; không tham số là quét cả cây specs/. Dùng khi sắp qua cổng, hoặc khi tài liệu vừa đổi nhiều và cần biết còn chỗ nào nói ngược nhau.
disable-model-invocation: true
argument-hint: "[UC-### | CHG-###] [--since <commit>] [--no-commit]"
allowed-tools: Bash Read Write Edit Grep Glob Agent AskUserQuestion
---

Verify pass cho `$1`.

Có `UC-###` → **phần A** (bước ⑧). Có `CHG-###` → **phần A** với năm khác biệt ở **A′**. Có `--since` → **A″**
(chỉ đọc phần đổi từ lần đọc lại trước). Không tham số → **phần B** (quét cây).

**Vì sao skill này tồn tại:** người viết không đọc được cái mình vừa viết — mắt đọc *ý định*, không
đọc *chữ*. Bước ⑦ đã giải đúng nhu cầu đó bằng session mới cho ba vai. Bước ⑧ cần **cùng một thứ**,
và trước 3.5.0 nó mua bằng một đêm lịch. Một đêm đo **thời gian trôi qua**, không đo **việc đọc có
xảy ra không** — cùng người, cùng cái neo, sáng mai lướt 30 giây vẫn qua cổng. Từ 3.5.0 tới 5.2.0 hai
cửa sống cạnh nhau; **6.0.0 (#38) bỏ cửa qua đêm** — verify là bắt buộc ở cả DoR lẫn Phase 5, vì cửa rẻ
hơn vẫn là cửa được đi.

---

## A. `/sdd-solo:verify UC-###` — bước ⑧

1. Tìm UC: `find specs -path "*/br-*/use-cases/$1-*/$1.md"`. Không có → dừng, báo.
2. Kiểm đã chạy bước ⑦ chưa: mục `## Adversarial pass` phải có nội dung thật. Chưa có → dừng, bảo
   chạy `/sdd-solo:adversarial $1` trước. Đọc lại trước khi soi là đọc lại một bản sắp đổi.
3. **Chạy verify bằng subagent riêng** (Agent tool). Đây là chỗ không được rút gọn: subagent
   **không có context của buổi viết**, nên nó không bị neo **do cấu tạo**, chứ không phải do ai
   khai là mình không bị neo. Prompt = nội dung `.sdd/prompts/verify-pass.md`, kèm:
   - output của `"${CLAUDE_PLUGIN_ROOT}/scripts/context.sh" $1 --brief` — UC (bỏ ba mục dấu vết), flow,
     RULE/CON/ADR được trích, BR cha, architecture (Cấm · Ranh giới · Nơi chạy), entity/glossary. `--brief`
     (6.5.0) cắt ADR còn đoạn đầu Decision và bỏ Ngăn xếp/Ai gọi — verify soi hành vi; dòng kích thước từng
     nguồn cuối output cho biết còn nguồn nào phình. **Cộng thêm** `$1.sequence.md` nếu
     có, và **toàn bộ `specs/rules.md` cùng `specs/<nghề>/rules.md` của nghề UC thuộc về** (verify soi cả
     rule UC *không* trích mà lẽ ra phải trích — đó là loại sai #4, context.sh cố ý không in rule không
     được trích). UC ở `core` thì chỉ đưa `specs/rules.md` gốc: lõi không được trích rule của nghề, nên
     một rule nghề "lẽ ra phải trích" ở đó là phát hiện ngược — ghi thành `F#`, đừng đưa vào làm đầu vào.
   - `git log --oneline -20 -- <thư mục UC>` để soi được loại sai #2 (commit khai một đằng, file một nẻo —
     so **nội dung** khai với diff, không so danh sách file; thiếu file bên cạnh chỉ là cảnh báo, #42)

   **Lượt verify kết thúc bằng commit đọc lại, không kết thúc bằng báo cáo (#40).** Ca thật runxops
   UC-014: subagent trả 19 phát hiện, agent chính in *"Báo cáo về: 19 phát hiện. Đọc nguyên văn để đối
   chiếu từng cái trước khi ghi."* rồi về idle — `## Đọc lại` vẫn `Ngày chạy: ___`, phải gõ thêm một lượt
   mới có commit. Chạy bằng agent tự động theo lời giao (không có người gõ tiếp) thì *"dừng chờ"* nghĩa là
   **dừng hẳn**, và cổng ⑨ đỏ dù đã đọc lại. Bước 4 → 5 → 6 → 7 là **một lượt**: báo cáo về là đi tiếp ngay
   sang bước 4 rồi 5, không dừng để *"đối chiếu trước"* — đối chiếu **là** bước 4, và kết quả đối chiếu ghi
   thẳng vào dòng `F#` (bác thì `→ không phải lỗi vì`). Không có ngoại lệ "để user xem báo cáo đã": muốn xem
   trước thì dùng `--no-commit` (bước 7), mục `## Đọc lại` vẫn phải được ghi trong lượt này.

   **Nếu spec có con số mô tả dữ liệu thật** (đếm dòng, tỉ lệ) thì subagent phải được phép **chạy
   lệnh đo lại** — đó là loại sai #7, và nó là loại duy nhất không thể phát hiện bằng cách đọc.
   Không có lệnh đo trong spec thì bản thân việc thiếu đó **đã là một phát hiện**; đừng tự bịa
   lệnh rồi coi như đã đối chiếu.
4. Trình từng `F#` bằng `AskUserQuestion`, **một phát hiện một lượt**, kèm **nguyên văn cả hai chỗ
   đang cãi nhau** như subagent đã trích. Bốn đầu ra hợp lệ:
   - → sửa spec (kèm ID chỗ sửa: `UC-009 Main 7` · `RULE-001` · `AC-6`)
   - → `Open Question` kèm quyết định tạm
   - → `không phải lỗi vì <lý do>` — **bác phải rẻ**, một dòng là đủ; nhưng **lý do phải được ghi
     lại**, để lần chạy sau không moi lại đúng câu đó
   - → `Chưa quyết` — luôn hiện sẵn

   **Không có người trả lời** — lượt chạy theo lời giao của agent điều phối, hoặc user đã bảo *"tự chạy,
   đừng hỏi"* — thì **không mở `AskUserQuestion`** (nó sẽ treo lượt vô hạn). Agent chính tự đối chiếu
   nguyên văn hai phía của từng `F#`: bác được → `→ không phải lỗi vì <lý do>`; bác không được → `→ Chưa
   quyết (chờ <ai>: <câu hỏi một dòng>)`. Cả hai đều là đầu ra hợp lệ của cổng, và **vẫn ghi + commit** ở
   bước 5–7. Người quyết đọc `## Đọc lại` sau; sửa spec theo đó là một lượt verify nữa (`--since`, #49).
5. Ghi vào mục `## Đọc lại` của file UC, **đúng dạng này vì cổng đọc nó bằng máy**:
```
## Đọc lại
- Ngày chạy: YYYY-MM-DD · Đầu chưa neo: subagent
- F1 <phát hiện> [neo: Main 7 · RULE-003] → sửa UC-009 Main 7
- F2 <phát hiện> [neo: AC-6] → không phải lỗi vì <lý do>
```
   Cổng đòi **ít nhất một** dòng `F#` có **cả `[neo: ...]` lẫn đầu ra khác `___`**. Đó là toàn bộ
   chốt chống khai gian: bịa một dòng như vậy tốn đúng bằng đọc thật.
6. Sửa những chỗ user chọn sửa. **Rồi QUÉT LẠI CẢ CÂY trước khi commit — bắt buộc, không bỏ:**

```bash
# với MỖI con số / quyết định vừa đổi, tìm giá trị CŨ trên cả cây
grep -rn '<giá trị cũ>' specs/ scripts/ *.md
```
   Còn hit nào **ngoài** `## History` và **ngoài** câu dạng `<cũ> → <mới>` thì **chưa xong**. Chỗ anh em hay
   sót nhất (đo #48: 14/18): `glossary.md` gốc và của nghề · file entity UC nhắc tên · `$1.sequence.md` ·
   dòng `Áp dụng cho` của RULE (cả `specs/rules.md` lẫn `specs/<nghề>/rules.md`) · `$1.flow.md` · ADR được trích ·
   bảng `## Related Use Cases` trong `br.md` của lát. `gate-check.sh --pre $1` cảnh báo ba loại lệch đó bằng máy — chạy nó trước khi commit.

   **Quét cả giá trị MỚI, không chỉ giá trị cũ.** Bước sửa **tự sinh lỗi mới**: đổi sang một
   `RULE-###` chưa có heading, đổi rồi đổi lại, gõ nhầm một `AC-#`. Quét giá trị cũ không thấy
   những cái đó — chúng là giá trị *mới* nằm sai chỗ.

   **Và mục `## Đọc lại` KHÔNG được miễn.** Nó ghi lại việc sửa, nên nó **trôi như mọi chỗ khác**,
   và trôi ngay trong chính lượt đang sửa. Ca thật (`runxops`): sửa `RULE-006 → RULE-007`, thấy
   `RULE-007` chưa có heading nên đổi lại — **thân sửa xong, dòng `F#` ghi lại việc sửa thì
   không**. Cổng bắt, verify không, vì verify đã chạy xong từ trước. **Chỗ ghi lại việc sửa cũng
   là một chỗ phải sửa.** (`gate-check` nay kiểm mọi ID khai trong `## Đọc lại` có thật — cùng
   luật §7 dành cho adversarial, #12.)

   **Vì sao phép quét này nằm ở đây chứ không ở `verify-pass.md`:** luật quét chỉ có nghĩa **sau**
   khi sửa — trước khi sửa thì chưa có "giá trị cũ" nào để quét theo. Mà hai vai verify chạy
   **trước** khi sửa. Đặt luật ấy trong prompt của họ là đặt nó vào một cơ chế **cấu tạo không
   chạy được nó** — và đó không phải chuyện ai quên, mà là **đặt sai bước**.

   Ca thật (`runxops`): cặp số cũ nằm ở **bốn** chỗ — một file entity · `br.md` của lát · docstring một
   script · và prompt của chính plugin. **Hai vai verify đọc rất kỹ vẫn bỏ sót chỗ thứ tư.** Thứ
   bắt được nó là một `grep -rn` chạy **sau** khi sửa. Người đọc không thấy chỗ mình không nghĩ tới
   là có; `grep` không cần nghĩ.

7. Rồi commit **riêng, đúng tiêu đề này** — cổng nhận diện bằng nó:
```bash
git add specs/ && git commit -m "docs($1): đọc lại — <n> phát hiện, <m> phải sửa"
```
   Có `--no-commit` → **vẫn ghi** `## Đọc lại` ở bước 5 (đó là sản phẩm của lượt), chỉ bỏ commit này; nói
   rõ với user: cổng ⑨ **chưa mở** cho tới khi chính commit đó tồn tại và là commit spec mới nhất. Không có
   cờ nào bỏ được bước 5.
8. Nói với user: giờ chạy `/sdd-solo:gate $1` được ngay. Nếu lần đọc này không ra dòng `F#` nào có
   đầu ra thật thì cổng **không mở** — từ 6.0.0 không còn cửa qua đêm để rơi về. Nói thẳng điều đó,
   và nói luôn cái đúng phải làm: *"không thấy gì"* là bằng chứng yếu (Giới hạn 3) — mở rộng phạm vi
   (rule UC *không* trích, `sequence.md`, entities, số liệu đo lại) rồi chạy lại, chứ **không** bịa
   một dòng `F#` cho qua. Một dòng `→ không phải lỗi vì <lý do>` sau khi đọc thật là đầu ra hợp lệ.

### A″. `/sdd-solo:verify UC-### --since [<commit>]` — đọc lại phần đổi (6.3.0, #49)

Ca thật runxops UC-014: **sáu lần đọc lại** (19 → 23 → 11 → 7 → 7 → 10 phát hiện) vì mỗi đợt áp 1–2 chỗ
hành vi lại lộ 1–2 chỗ chữ/nhãn ở file bên cạnh, và cổng đòi commit đọc lại là mới nhất nên mọi sửa chữ
kéo theo một lượt verify **trọn** (phiên mới, ~200 KB, ~10 phút). Đọc lại trọn còn diễn đạt lại phát hiện
cũ thành "mới". Chủ dự án chốt: *lặp tới khi chặn = 0*, và luật dừng nằm ở `verify-pass.md` (chặn = mâu
thuẫn hai chỗ · AC không test được; còn lại là nợ chữ).

Cùng phần A, khác bốn chỗ:
1. Mốc: `<commit>` nếu có; không có thì **commit đọc lại gần nhất** —
   `git log -1 --format=%H --grep="^docs($1): đọc lại" -- <thư mục UC> specs/rules.md specs/<nghề>/rules.md <các file entity UC nhắc tên>`.
   Không có mốc nào → đây là lần đầu, chạy phần A trọn.
2. Đầu vào cho subagent **thay vì** `context.sh` trọn: `git diff <mốc>..HEAD -- specs/` (nguyên văn), cộng **các
   mục bị chạm** ở dạng hiện tại (mục `## …` của UC chứa dòng đổi, RULE có dòng đổi, file entity có dòng đổi)
   và **mọi chỗ khác trong `specs/` nhắc tới cùng khái niệm vừa đổi** (`grep -rn` giá trị mới và giá trị cũ) — vì
   loại sai #3 và #8 nằm giữa chỗ đổi và chỗ chưa đổi theo. Phạm vi này in ra đầu báo cáo. `verify-pass.md`
   áp nguyên; mục *Luật dừng* của nó quyết dòng nào là chặn.
3. Ghi vào `## Đọc lại` **một khối mới**, không xoá khối cũ:
```
- Ngày chạy: YYYY-MM-DD · Đầu chưa neo: subagent · --since <hash ngắn>
- F12 <phát hiện> [neo: …] → …
```
   Số `F#` tiếp nối khối trước (cổng đếm mọi dòng `- F#` trong mục, không phân biệt khối).
4. Commit `docs($1): đọc lại --since <hash ngắn> — <n> phát hiện, <m> chặn, <k> nợ chữ`. Cổng nhận tiền tố
   `docs($1): đọc lại`, nên commit này là mốc mới. Từ 6.3.0 cổng **cho qua commit áp chữ/nhãn sau lần đọc lại**
   (vân tay hành vi không đổi: Main/Alt/Exceptions/Postconditions/AC · flow · phát biểu RULE · mermaid entities);
   đổi hành vi thì cổng đỏ và tự in lệnh `--since` với đúng mốc.

### A′. `/sdd-solo:verify CHG-###` — cửa của cổng Phase 5 (6.0.0, #38)

Cùng phần A, khác năm chỗ:
1. Tìm: `ls -d specs/changes/$1-*/` — có `proposal.md` · `delta/` · `design.md`. Không có → dừng, báo.
2. Không đòi bước ⑦ — Phase 5 không có adversarial.
3. Đầu vào cho subagent: `proposal.md` + toàn bộ `delta/*.delta.md` + `design.md`, **cộng** output
   `context.sh UC-###` cho **mỗi** UC delta đụng (baseline — để soi delta khai MODIFIED/REMOVED một AC
   mà baseline nói khác), toàn bộ `specs/rules.md` cùng `specs/<nghề>/rules.md` của các nghề UC delta đụng, và `git log --oneline -20 -- specs/changes/$1-*/`.
4. Ghi `## Đọc lại` vào **`proposal.md`** (không vào UC baseline — baseline chưa đổi cho tới khi
   archive), cùng dạng phần A bước 5; neo trỏ `delta/UC-009 MODIFIED AC-3` · `proposal Scope` ·
   `UC-009 AC-3`.
5. Commit riêng `docs($1): đọc lại — <n> phát hiện, <m> phải sửa`, rồi `/sdd-solo:change $1`.
   `change-check` §8 đòi commit này là commit `docs($1)` **mới nhất** trong thư mục change — sửa
   proposal/delta sau đó thì đọc lại lần nữa.

---

## B. `/sdd-solo:verify` — quét cây

Dùng khi tài liệu vừa đổi nhiều và cần biết còn chỗ nào nói ngược nhau. Không gắn với cổng nào.

1. **Chọn phạm vi trước, đừng đọc thưa cả cây.** Cây nhỏ (< ~3.000 dòng) thì đọc hết. Lớn hơn:
   lấy `git diff --name-only <lần verify trước>..HEAD -- specs/` cộng **mọi file mà đám đó trích ID
   tới** (`RULE-###` → `specs/rules.md` hoặc `specs/<nghề>/rules.md`, `CON-###`/`BR-###` → `br.md` của
   lát đó, `UC-###` → file UC đó, tên entity → file entity đó). Đọc thưa
   cả cây là cách chắc chắn nhất để bỏ sót loại sai #3 và #4, vốn là hai loại hay gặp nhất.
2. Chạy **subagent** với `.sdd/prompts/verify-pass.md` trên phạm vi đó. Cây lớn thì chia theo
   tầng — một agent vision↔BR, một agent BR↔RULE, một agent UC↔AC↔flow, một agent entity↔glossary — nhưng
   **mỗi agent vẫn phải thấy cả hai phía** của cặp nó soi, nếu không nó chỉ đọc được một nửa cuộc cãi.
   Thêm một phép soi chỉ có ở cây 7.0: **gốc `specs/*.md`, `specs/adr/` và `specs/core/` có trích ID của
   nghề nào không** — `bash .sdd/scripts/layer-check.sh` đếm bằng máy, rẻ hơn đọc.
3. Trình từng `F#` như phần A bước 4.
4. Ghi kết quả vào `notes/soat/verify-<YYYY-MM-DD>.md` (vết quá trình, ngoài `specs/`): phạm vi đã đọc, từng `F#` kèm nguyên
   văn hai phía, đầu ra. **Cả những dòng bị bác cũng ghi, kèm lý do bác** — đó là thứ làm lần chạy
   sau rẻ đi, và là thứ duy nhất còn lại sau khi đóng terminal.
5. Sửa những chỗ user chọn, rồi `git commit -m "docs: verify pass <ngày> — <n> phát hiện"`.

---

## Giới hạn — nói với user, không giấu

1. **Lý do bác phải đến từ người ĐỌC phát hiện, không từ người VIẾT spec.** Đừng đưa trước cho
   subagent một danh sách *"ngữ cảnh giúp bác nhanh"* do tác giả spec soạn — nó sẽ bác đúng những
   chỗ tác giả tin là mình không sai, tức lấy mất chỗ đứng của cả lượt verify.
2. **Nó sinh dương tính giả.** Đó là giá của việc đọc nghĩa thay vì đếm — và là lý do skill này
   **không phải** một script trong cổng: một phép kiểm báo đỏ oan sẽ bị học cách phớt lờ, rồi kéo
   theo cả những dòng đỏ thật.
3. **"Không thấy gì" là bằng chứng yếu.** Không được nói *"tài liệu nhất quán"* hay *"đã kiểm toàn
   bộ"*. Câu đúng: *"lần đọc này không tìm ra gì trong phạm vi đã đọc"* — **kèm liệt kê phạm vi**.
4. **Không thay bước ⑦.** Ba vai hỏi *"spec chưa trả lời gì"*; verify hỏi *"spec có tự mâu thuẫn
   không"*. Chạy verify rồi bỏ adversarial là bỏ mất câu hỏi đắt nhất của cả quy trình.

Không viết code. Không tự sửa spec khi user chưa chọn.

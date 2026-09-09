# Verify pass — đọc tài liệu bằng một cái đầu chưa bị neo

Prompt này chạy trong **subagent riêng**, không dùng context của session đang viết spec. Đó là
toàn bộ giá trị của nó: người viết không đọc được cái mình vừa viết, vì mắt đọc **ý định**, không
đọc **chữ**.

Cùng nhu cầu với ba vai ở bước ⑦. Khác chỗ: ba vai hỏi *"spec chưa trả lời gì"*; verify pass hỏi
*"spec có tự mâu thuẫn không, và có khai điều không có thật không"*.

## Luật

1. **Chỉ báo, không sửa.** Không sửa file, không đề xuất code, không viết lại giúp. Sửa là việc
   của người quyết, sau khi đọc phát hiện.
2. **Mỗi phát hiện phải trích NGUYÊN VĂN hai chỗ đang cãi nhau**, kèm đường dẫn và số dòng. Tóm
   tắt không được — tóm tắt là chỗ lén thêm giả định vào, và một phát hiện không trích nguyên văn
   thì người đọc không kiểm lại được, nên chỉ còn cách tin. (Cùng luật với #25.)
3. **Mỗi phát hiện phải có đầu ra mang ID**: `→ sửa UC-009 Main 7` · `→ sửa RULE-001` ·
   `→ Open Question` · `→ không phải lỗi vì <lý do>`. Không có "để đó". (Cùng luật với #12.)
4. **Phạm vi là cả cây, không phải một file.** Phần lớn loại sai này nằm **giữa** các file — một
   file đọc riêng thì hoàn toàn hợp lý. Kiểm từng file riêng sẽ không thấy gì.

## Các loại sai phải soi

*(Tiêu đề này cố ý **không đếm**. Bản 3.6.0 thêm một dòng vào bảng dưới mà quên sửa chữ "Sáu"
cách đó hai dòng — một cái nhãn mang số thì mỗi lần thêm dòng là một lần nó có thể mục.)*

| # | Loại | Câu hỏi |
|---|---|---|
| 1 | **Khai điều không có thật** | Tài liệu nói *"X chưa tồn tại"* / *"đã thêm Y"* — X, Y có thật không? Mở file ra xem, đừng tin câu văn. |
| 2 | **Commit khai một đằng, file một nẻo** | Thông điệp commit khai đã thêm khối nội dung nào — khối đó có trong file không? `git show` rồi so. |
| 3 | **Hai tầng nói ngược nhau** | BR ↔ RULE ↔ UC ↔ AC. Một quyết định đổi ở tầng dưới mà tầng trên còn câu cũ là ca hay gặp nhất. |
| 4 | **Đã bác nhưng còn dạy** | Một phương án bị loại ở Q#/CON-###/History mà chỗ khác vẫn hướng dẫn làm theo nó. Ai đọc chỗ đó sẽ dựng lại đúng cái vừa bị loại. |
| 5 | **Thứ tự nói ngược nội dung** | Bước đánh số 1→N đọc xuôi có ra đúng trình tự không? Đổi nội dung mà giữ số thì mọi phép kiểm cơ học đều xanh. |
| 6 | **Hứa mà không có đường** | AC/Postcondition hứa hệ thống *biết* hoặc *không đổi* một thứ — có bước nào thật sự đi lấy hoặc thật sự không ghi không? |
| 7 | **Con số đã mục** | Số mô tả **dữ liệu thật** (đếm dòng, tỉ lệ, "427 dòng", "10/1986") — đo lại hôm nay có ra đúng thế không? |
| 8 | **Nhãn không đi theo nội dung** | Tiêu đề, câu tóm tắt, số đếm trong tiêu đề — có còn đúng với thân bên dưới không? Ai sửa thân thường không sửa nhãn. |

Loại #8 đáng tách riêng khỏi #3 vì nó có **chữ ký riêng và chỗ nấp riêng**: cái sai do chính lần
sửa trước gây ra, và nó nằm cách chỗ sửa vài dòng tới vài trăm dòng nên không lọt vào mắt người
vừa sửa. Ba ca đo được trong một ngày ở `runxops` và trong plugin này, ba người khác nhau, cùng
một hình: *"Sáu loại sai"* trên bảng bảy dòng · một `AC` có tiêu đề nói một đằng thân nói một nẻo ·
`entities.md` sửa `7 → 10` trong bảng và History nhưng bỏ sót câu văn xuôi cách đó **190 dòng**.

Cách soi: với mỗi lần một con số hoặc một quyết định vừa đổi, **quét cả cây tìm mọi chỗ khác nhắc
tới nó** — đừng sửa theo chỗ mình nhớ là có. Trí nhớ của người vừa sửa là thứ dở nhất để dựa vào,
vì nó nhớ **ý định** chứ không nhớ **chữ**.

**PHÂN LOẠI hit, đừng chỉ tìm hit** — và đừng bỏ qua chỗ nào. Luật này kéo ngược luật 9 của loại
#7 (*giữ số cũ kèm lý do lệch*): càng tuân thủ luật 9 thì cây càng đầy số cũ **hợp lệ**, nên quét
số cũ sẽ ra càng nhiều hit đúng-mà-phải-bác. Sau vài tháng, mỗi số đổi kéo theo hàng chục hit lịch
sử, và lúc đó *"bác một phát hiện phải rẻ"* không còn đủ — **cái rẻ phải là không phải bác.**

Cách giải: chia hit làm hai loại ngay khi tìm ra, **máy tự dán nhãn**, và chỉ loại thứ hai mới
thành `F#`:

| Hit nằm ở | Xử lý |
|---|---|
| Mục `## History`, hoặc một câu có dạng `<số cũ> → <số mới>` / *"số cũ … vì …"* | **hit lịch sử hợp lệ** — liệt kê gọn thành một dòng đếm, không thành `F#` |
| Bất kỳ chỗ nào khác — văn xuôi sống, bảng, tiêu đề, `RULE`, `AC` | **`F#`** — đây là số chết nằm trong câu sống |

Không **loại bỏ** loại một khỏi phép quét, chỉ **hạ nó xuống một dòng đếm**: *"12 hit ở History và
các câu `cũ → mới` — hợp lệ theo luật 9"*. Loại bỏ hẳn thì một câu văn xuôi sống vô tình mang dấu
`→` sẽ tàng hình vĩnh viễn, và đó lại đúng là loại lỗi cả tài liệu này sinh ra để bắt.

**Câu định tính đứng thay một con số cũng là hit.** *"sẽ nhiều hơn 1986 dòng"* không sai — nhưng
số thật là **2523**, tức **+27%**, và *"nhiều hơn"* che mất đúng cái phần khiến người ta phải quyết
khác đi. Cùng hình với `13/13` ở luật 10: câu không sai, chỉ là không đủ để ai quyết được gì.

## Vai thứ hai: đối chiếu tài liệu với DỮ LIỆU THẬT

Mọi loại trên đều đọc tài liệu so với tài liệu. Loại #7 khác hẳn và cần một vai riêng, vì **con số là
chỗ mục nhanh nhất trong cả spec**: nó đúng lúc viết, không ai sửa nó khi dữ liệu đổi, và một con
số đã mục **trông y hệt** một con số đúng. Không phép kiểm cấu trúc nào phân biệt được.

Ca thật (`runxops`, 2026-09-09): `entities.md` ghi *"427 dòng đang có trục nằm kẹt trong
`Product Name`"*. Câu đó **qua adversarial pass và ba lượt cổng**. Thứ bắt được nó không phải
script nào, mà là một câu của người biết dữ liệu: *"dữ liệu chưa chuẩn"*. Đo lại — và chú ý ca mẫu
này cố ý trưng **hai tầng**, vì mỗi tầng dạy một thứ:

```
ĐƠN VỊ = Ô          (phân rã, các nhóm rời nhau, cộng lại phải đúng)
  ô có nội dung ngoài tên + link      982
    chỉ mang định danh                513
    chỉ mang trục biến thể            454
    mang CẢ HAI                        15
    không rơi vào nhóm nào              0
                              cộng →  982  ✓

ĐƠN VỊ = MÃ / DÒNG  (KHÔNG phân rã — lớn hơn số ô, vì một ô chứa được nhiều)
  mã định danh                        545
  dòng trục biến thể                  601
  giá trị biến thể                   1006
```

**Ba con số trong cùng một câu có thể mang ba đơn vị khác nhau, và không có gì trong văn bản nói
ra điều đó.** Câu cũ *"982 ô — 545 định danh và 601 trục"* đọc như một phép chia đôi; ai thử cộng
sẽ ra `545 + 601 − 982 = 164` ô mang cả hai, mà **số thật là 15**. Sai hơn mười lần, chỉ vì ba
đơn vị đứng cạnh nhau không ai khai.

Phân rã theo ô thì cộng đúng, nên nó **tự chứng minh đã phân hết** — và còn khớp chéo được:
`454 + 15 = 469`, đúng bằng số ô *"có biến thể"* đo được ở một lần đếm khác.

Ca mẫu này từng mang đúng cái lỗi nó dạy cách bắt. Bản 3.6.0–3.11.0 ghi `536 / 525`, hai con số ra
từ **script khảo sát đầu tiên** — chạy trước khi bỏ ký tự vô hình `U+200E` và trước khi bắt được
32 giá trị biến thể không mang tên trục. Sai **cùng một chiều, cùng một nguyên nhân**, đúng chữ ký
mà đoạn này đang mô tả. `/sdd-solo:verify` tìm ra nó ở lần chạy thật đầu tiên — còn `536 + 525 ≠
982` thì **đáng lẽ đã bắt được nó sáu bản trước, không cần verify.**

Chính ca mẫu này từng mang đúng cái lỗi nó dạy cách bắt: bản 3.6.0–3.11.0 ghi `536 / 525`, hai con
số ra từ **script khảo sát đầu tiên** — chạy trước khi bỏ ký tự vô hình `U+200E` và trước khi bắt
được 32 giá trị biến thể không mang tên trục. Sai **cùng một chiều, cùng một nguyên nhân**, đúng
chữ ký mà đoạn này đang mô tả. `/sdd-solo:verify` tìm ra nó ở lần chạy thật đầu tiên.

Và `601 dòng` đứng cạnh `1006 giá trị` là ca *hai mẫu số cho cùng một thứ*: một ô ghi
`Color: Brown | Dark Grey` là **một** dòng trục nhưng **hai** giá trị. Dán nhầm số nọ vào câu của
số kia thì cả hai đều là số thật, câu vẫn trôi chảy, và không phép so nào bắt được — **luôn nói rõ
đang đếm ĐƠN VỊ nào.**

Cách làm:

**Một con số kiểm lại được cần BA thứ, thiếu một là mục lặng:** *dữ liệu nào* (vân tay) ·
*lệnh nào* (luật 5b) · *lệnh đó còn đúng với hình dạng hiện tại không* (chốt cấu trúc, dưới đây).
**Hai thứ đầu bắt được số sai; chỉ thứ ba bắt được số đúng-trên-thế-giới-cũ.**

1. **Tìm mọi con số mô tả dữ liệu thật** trong phạm vi đọc. Số nghiệp vụ đã chốt (ngưỡng, thời
   hạn trong `RULE-###`) **không** thuộc loại này — đó là quyết định, không phải phép đo.
2. **Mỗi con số đó phải có một lệnh đo lại được.** Không có → **đó đã là một phát hiện**:
   `F# con số <X> không có cách đo lại → sửa <file> ghi kèm lệnh đo`. Đừng tự bịa lệnh rồi coi
   như xong; lệnh do mình nghĩ ra không phải lệnh tác giả đã dùng.
3. **Chạy lệnh, so kết quả.** Khớp → im. Lệch → `F#` với hai phía: **A** là nguyên văn dòng trong
   spec kèm `đường dẫn:dòng`, **B** là **lệnh vừa chạy và đầu ra của nó hôm nay**. Đây đúng là
   luật "trích nguyên văn hai phía", chỉ khác chỗ phía B là một lệnh chứ không phải một dòng file.
4. **Lệch không có nghĩa là spec sai.** Có thể dữ liệu đã đổi, có thể lệnh cũ đếm hụt. Báo cả hai
   số, **đừng kết luận bên nào đúng** — người biết dữ liệu quyết.

   **Lệnh đo nên in dấu vân tay của chính dữ liệu nó đọc**, và spec ghi lại vân tay đó cạnh bảng số:

   ```
   Nguồn: itemsell-flat.csv · 1986 dòng · sha256 70daf43f · sửa lần cuối 2026-09-09 22:22
   Đo lúc: 2026-09-09 22:26
   ```

   Có vân tay thì câu *"lệch không có nghĩa spec sai"* thôi là một luật người phải nhớ và trở
   thành **một dòng máy in ra**: vân tay khác → dữ liệu đã đổi; vân tay khớp mà số khác → spec
   sai hoặc lệnh sai. Không có vân tay thì mọi lần lệch đều phải đoán lại từ đầu.

   Chỗ vân tay **không** bịt được, nói thẳng ra trong `F#` nếu gặp: nó bắt được **dữ liệu** đổi,
   **không** bắt được **lệnh** đổi. Sửa chính lệnh đo cho nó đếm sai đi thì vân tay vẫn khớp và cả
   bảng số vẫn mục cùng một chiều — lần này còn khó thấy hơn, vì tài liệu trông như *đã được kiểm*.
   **Có lệnh đo làm số kiểm lại được, không làm số đúng.**
4b. **Chốt cấu trúc: lệnh đo phải khai hình dạng nó đang giả định, và kiểm trước khi đếm.**
   Đây là loại mục thứ ba, khác hẳn hai loại kia: không phải *dữ liệu đổi*, không phải *lệnh sai*,
   mà là **lệnh đúng với thế giới cũ**. Nó chạy trơn và ra một con số hoàn toàn hợp lý — nên không
   phép so số nào bắt được. Ca thật: một phép đếm ra `132` thay vì `249` vì nó chỉ thấy dấu `|`
   nằm cùng dòng với `Color:`; regex không sai, **cấu trúc nó đang đếm chưa tồn tại lúc ấy**.

   Cách chặn được **một nửa**: bắt lệnh khai ra giả định của nó (tên cột phải có · dấu ngăn trục là
   gì · ô có còn xuống dòng không), kiểm trước khi đếm, và **không khớp thì DỪNG, không in con số
   nào**:

   ```
   itemsell-flat.csv không còn hình dạng mà lệnh này giả định — KHÔNG đếm,
   vì một con số đếm trên cấu trúc đã đổi trông y hệt một con số đúng:
     ✗ không ô Variant nào chứa ' ; ' — dấu ngăn trục có thể đã đổi
   EXIT = 1
   ```

   Đây là nguyên tắc mở đầu của cả repo áp vào chỗ hẹp nhất: **báo xanh sai tệ hơn không có phép
   kiểm**, nên một lệnh đo không chắc mình đang đo đúng thứ thì việc đúng đắn là **im, không phải
   đoán**.

   Nửa còn hở, khai cho đủ: chốt cấu trúc bắt được **cấu trúc dữ liệu** đổi. Nó **không** bắt được
   người sửa cả lệnh lẫn phần khai giả định cùng lúc cho khớp nhau — lúc đó nó lại là một lệnh
   đúng với thế giới cũ, chỉ khác là thế giới cũ vừa được viết lại cho hợp. **Ba tầng, tầng nào
   cũng chỉ đẩy chỗ mù lùi một bậc chứ không xoá được.** Nói ra chỗ mù còn lại, đừng hứa nó đã hết.

5. **Soi kỹ chỗ phép đếm không thấy được.** Đây là chỗ ca thật ở trên trượt: phép đếm cũ **không
   sai công thức**, nó grep `Color:`/`Size:` và đếm đúng thứ nó grep. Nó trượt vì hai thứ nằm
   ngoài tầm với của mọi phép grep:
   - **ký tự vô hình** (`U+200E`, `U+FEFF`, khoảng trắng không ngắt) dính vào giá trị — một ISBN
     có `U+200E` ở đầu **nhìn y hệt** một dãy số bình thường;
   - **giá trị không có nhãn** — `Paperback`, `M | L | XL` là giá trị biến thể mà không mang tên
     trục nào, nên mọi phép đếm theo `<tên trục>:` đều không thấy.

   Khi số đo lại khác số trong spec, hỏi trước hết: *phép đếm này không nhìn thấy cái gì?*

6. **Nhiều số cùng một nguồn thiếu lệnh đo → gộp thành MỘT `F#`, không tách thành năm.** Năm dòng
   đỏ giống hệt nhau là thứ người ta học cách phớt lờ nhanh nhất, và phớt lờ xong thì phớt lờ luôn
   dòng thứ sáu khác hẳn. Dạng đúng: *"5 con số trong `entities.md` (1459 tên · 281 nhóm · 7 lệch
   cờ · 427 biến thể · 1559 thoái hoá) đều dẫn từ `itemsell-flat.csv` và không số nào có lệnh đo"*.
   Cụm khoanh đúng vùng, và **khoanh đúng vùng đã đủ để người biết dữ liệu đi kiểm** — vai này
   không cần tự tìm ra con số đúng.

7. **Xem HƯỚNG lệch, không chỉ xem có lệch không.** Nhiều số cùng lệch **một chiều** là chữ ký của
   một nguồn chung đã mục, không phải của nhiều sai sót rời rạc. Ca thật (`runxops`): cả năm số
   đều đếm **thiếu**, và đều thiếu theo hướng làm vấn đề trông **nhẹ hơn** thực tế — `7 nhóm lệch
   cờ tồn` là con số dùng để lập luận phải tách một entity, và nó nhỏ hơn sự thật 43%. Nói rõ
   chiều lệch trong `F#`: một lập luận đứng trên số đếm thiếu vẫn có thể đúng, nhưng người quyết
   phải biết nó đang đứng trên cái gì.

8. **Một con số trông vô lý là một phát hiện, kể cả khi nó CÓ lệnh đo.** Lệnh sai vẫn chạy trơn.
   Ca thật: ghép mọi dòng biến thể bằng ` | ` trong khi ` | ` đã mang nghĩa *"nhiều giá trị cùng
   một trục"* — `Color: Brown | Dark Grey` (một trục) đọc ra thành hai, và phép đếm ra `437 dòng
   không tên trục` thay vì `32`. Thứ bắt được nó là **con số trông vô lý**, không phải phép kiểm
   nào. Nên: thấy số lệch một bậc độ lớn so với chỗ khác trong cùng tài liệu thì hỏi, đừng chép.

9. **Sửa số thì GIỮ số cũ kèm lý do lệch, đừng xoá.** *"1459 → 1388 (số cũ nhóm theo `Product
   Name` khi cột đó còn dính trục biến thể, nên một sản phẩm hai màu đếm thành hai tên)"* dạy được
   nhiều hơn `1388` trơ trọi: nó nói phép đo cũ hỏng ở đâu, nên lần sau khỏi hỏng lại. Đây cũng là
   thứ duy nhất còn lại sau khi đóng terminal.

10. **Một con số ĐÚNG vẫn là phát hiện, nếu nó là mẫu số đã lọc mà không nói đã lọc gì.** Chín
   dòng trên đều đi tìm số **sai**; dòng này khác hẳn, và nó là dòng duy nhất mà bước 3
   (*"khớp → im"*) sẽ **bỏ sót**, vì chạy lại vẫn ra đúng con số đó.

   Ca thật (`runxops`): `RULE-004` khai *"phân định được 13/13 nhóm"*. Đo lại: **đúng 13/13**.
   Nhưng mẫu số thô là **16** — ba nhóm bị loại vì khoá là chữ giữ chỗ (`Does not apply`, thứ eBay
   tự điền khi người bán bỏ trống). Loại chúng ra là **quyết định đúng**. Vấn đề là `13` một mình
   giấu mất **9 listing không nhóm được bằng bất cứ khoá nào** — mà đúng chín cái đó là phần việc
   gán khoá tay của `UC-009`, tức chỗ đau chính của cả BR.

   Hỏi hai câu: *phép đếm này bỏ ra bao nhiêu?* và *cái bị bỏ ra có phải chính là thứ tài liệu
   đang bàn không?* Nếu có → `F#`, dù con số không sai một chữ.

   **Hệ quả cho lệnh đo:** in **mẫu số thô và mẫu số đã lọc cùng lúc**, kèm cái gì bị lọc và vì
   sao — đừng chỉ in kết quả. Một tỉ lệ `13/13` trông hoàn hảo; `16 thô → loại 3 giữ chỗ → 13` nói
   thật. Cùng họ với ca `437 / 32`: thứ bắt được nó là **một con số thứ hai đứng cạnh**. Khác ở
   chỗ ca kia con số trông vô lý, còn ca này **cả hai đều hợp lý** — nên không có con số thứ hai
   thì không có gì để mà nghi.

11. **Lệnh đo phải THẬT SỰ in ra con số nó được gắn vào.** Kiểm bằng cách chạy lệnh rồi tìm con
   số đó trong đầu ra. Không thấy → **nhãn sai**, và một **nhãn xác thực sai tệ hơn không có
   nhãn**: không có nhãn thì con số trông như chưa ai kiểm, đúng như nó vốn thế; dán nhãn sai thì
   nó trông **như đã được kiểm**.

   Ca thật (`runxops`): hai con số được gắn `python3 scripts/measure-catalog.py` làm lệnh đo, mà
   lệnh đó **không in ra con số nào trong hai**. Người dán nhãn chính là người vừa dành cả ngày
   thuyết phục rằng mọi số phải kèm lệnh đo.

   **Vế thứ hai:** con số nào **tự nhận là phân rã** của một con số khác thì **phải cộng lại
   đúng**, và chỗ trình bày nó phải **trưng ra phép cộng**. Cộng không ra → hoặc thiếu một nhóm,
   hoặc các nhóm chồng nhau, hoặc — hay gặp nhất — **chúng không cùng đơn vị**. Kiểm được bằng máy,
   và rẻ hơn mọi thứ khác trong danh sách này.

   Luật này đóng chỗ hở mà **ba tầng kia không với tới**: vân tay hỏi *dữ liệu nào* · luật 5b hỏi
   *lệnh nào* · chốt cấu trúc hỏi *lệnh còn đúng hình dạng không* — cả ba đều **giả định lệnh và
   số là một cặp đúng**, và không tầng nào kiểm chính cái cặp đó. Nó rẻ và kiểm được bằng máy.

## Đầu ra

Một danh sách `F#`, xếp theo hậu quả (tiền · quyền · dữ liệu khách trước). Mỗi dòng:

```
F1 <phát hiện một câu>
   A: <đường dẫn:dòng> "<nguyên văn>"
   B: <đường dẫn:dòng> "<nguyên văn>"
   [neo: Main 7 · RULE-003]
   → đầu ra: ___
```

`đầu ra: ___` để **người quyết** điền, không tự điền.

## Giới hạn — nói thẳng, không giấu

1. **Lý do bác phải đến từ người ĐỌC phát hiện, không từ người VIẾT spec.** Đưa trước cho verify
   một danh sách *"ngữ cảnh giúp bác nhanh"* do tác giả spec soạn là lấy mất chỗ đứng của nó: nó
   sẽ bác đúng những phát hiện mà tác giả đã có sẵn câu trả lời — tức đúng những chỗ tác giả tin
   là mình không sai. Ca thật: một danh sách như vậy bị từ chối, và **hai mục trong đó tự rơi vào
   nhóm "khớp / đã bác" bằng phép đo riêng của verify** — bằng chứng đó chỉ tồn tại **vì** nó
   không nghe.

2. **Nó sinh dương tính giả.** Đó là cái giá của việc đọc nghĩa thay vì đếm. Nên **bác một phát
   hiện phải rẻ** — một dòng `→ không phải lỗi vì <lý do>` là đủ, và **lý do đó được ghi lại**,
   để lần chạy sau không moi lại đúng câu đó.
3. **"Không thấy gì" là bằng chứng yếu.** Không được in ra câu nào nghe như bảo chứng — không
   *"tài liệu nhất quán"*, không *"đã kiểm toàn bộ"*. Đúng câu được phép nói là: *"lần đọc này
   không tìm ra gì trong phạm vi đã đọc"*, kèm **liệt kê phạm vi đã đọc**.
4. **Chi phí tăng theo cây.** Cây 2.000 dòng đọc hết được; 20.000 dòng thì không. Khi cây lớn,
   thu phạm vi theo **thứ vừa đổi** (`git diff` từ lần verify trước) cộng mọi file mà nó trích ID
   tới — chứ đừng đọc thưa cả cây, vì đọc thưa là cách chắc chắn nhất để bỏ sót loại 3 và loại 4.

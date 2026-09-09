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

## Vai thứ hai: đối chiếu tài liệu với DỮ LIỆU THẬT

Sáu loại đầu đọc tài liệu so với tài liệu. Loại 7 khác hẳn và cần một vai riêng, vì **con số là
chỗ mục nhanh nhất trong cả spec**: nó đúng lúc viết, không ai sửa nó khi dữ liệu đổi, và một con
số đã mục **trông y hệt** một con số đúng. Không phép kiểm cấu trúc nào phân biệt được.

Ca thật (`runxops`, 2026-09-09): `entities.md` ghi *"427 dòng đang có trục nằm kẹt trong
`Product Name`"*. Câu đó **qua adversarial pass và ba lượt cổng**. Đo lại: **982** ô nhiều dòng —
536 trục biến thể **và 525 định danh**. Thứ bắt được nó không phải script nào, mà là một câu của
người biết dữ liệu: *"dữ liệu chưa chuẩn"*.

Cách làm:

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

## Ba giới hạn — nói thẳng, không giấu

1. **Nó sinh dương tính giả.** Đó là cái giá của việc đọc nghĩa thay vì đếm. Nên **bác một phát
   hiện phải rẻ** — một dòng `→ không phải lỗi vì <lý do>` là đủ, và **lý do đó được ghi lại**,
   để lần chạy sau không moi lại đúng câu đó.
2. **"Không thấy gì" là bằng chứng yếu.** Không được in ra câu nào nghe như bảo chứng — không
   *"tài liệu nhất quán"*, không *"đã kiểm toàn bộ"*. Đúng câu được phép nói là: *"lần đọc này
   không tìm ra gì trong phạm vi đã đọc"*, kèm **liệt kê phạm vi đã đọc**.
3. **Chi phí tăng theo cây.** Cây 2.000 dòng đọc hết được; 20.000 dòng thì không. Khi cây lớn,
   thu phạm vi theo **thứ vừa đổi** (`git diff` từ lần verify trước) cộng mọi file mà nó trích ID
   tới — chứ đừng đọc thưa cả cây, vì đọc thưa là cách chắc chắn nhất để bỏ sót loại 3 và loại 4.

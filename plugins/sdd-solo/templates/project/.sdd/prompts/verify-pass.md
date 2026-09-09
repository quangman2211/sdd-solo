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

## Sáu loại sai phải soi

| # | Loại | Câu hỏi |
|---|---|---|
| 1 | **Khai điều không có thật** | Tài liệu nói *"X chưa tồn tại"* / *"đã thêm Y"* — X, Y có thật không? Mở file ra xem, đừng tin câu văn. |
| 2 | **Commit khai một đằng, file một nẻo** | Thông điệp commit khai đã thêm khối nội dung nào — khối đó có trong file không? `git show` rồi so. |
| 3 | **Hai tầng nói ngược nhau** | BR ↔ RULE ↔ UC ↔ AC. Một quyết định đổi ở tầng dưới mà tầng trên còn câu cũ là ca hay gặp nhất. |
| 4 | **Đã bác nhưng còn dạy** | Một phương án bị loại ở Q#/CON-###/History mà chỗ khác vẫn hướng dẫn làm theo nó. Ai đọc chỗ đó sẽ dựng lại đúng cái vừa bị loại. |
| 5 | **Thứ tự nói ngược nội dung** | Bước đánh số 1→N đọc xuôi có ra đúng trình tự không? Đổi nội dung mà giữ số thì mọi phép kiểm cơ học đều xanh. |
| 6 | **Hứa mà không có đường** | AC/Postcondition hứa hệ thống *biết* hoặc *không đổi* một thứ — có bước nào thật sự đi lấy hoặc thật sự không ghi không? |

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

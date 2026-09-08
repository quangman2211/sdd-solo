# Adversarial pass — chạy trong một session MỚI, không phải session đang viết spec

Hai bộ vai: **tầng UC** hỏi về hành vi, **tầng BR** hỏi về lý do tồn tại. Đừng dùng lẫn.

Dán glossary + rules liên quan + UC. Chạy ba vai, mỗi vai một lượt. AI chỉ được HỎI.

---
Bạn đọc use case dưới đây với vai **<VAI>**. Nhiệm vụ duy nhất: liệt kê những câu hỏi mà spec chưa trả lời,
những rule "đương nhiên với người làm nghiệp vụ" mà spec chưa ghi, và những chỗ thông điệp cho khách khó hiểu.

Ràng buộc:
- Không đề xuất code. Không đề xuất kiến trúc. Không sửa spec.
- Mỗi câu hỏi một dòng, kèm bước/E#/AC mà nó liên quan.
- Không lặp lại thứ spec đã nói. Không khen.
- Tối đa 12 câu, xếp theo mức hậu quả nếu bỏ qua (tiền / quyền / dữ liệu khách → trước).

Vai:
1. **Khách cuối** — người kinh doanh hoặc marketing, không rành kỹ thuật, đang vội. Hỏi: chỗ nào tôi không biết làm gì tiếp? thông báo nào tôi đọc không ra? tôi tìm cái đó ở đâu?
2. **Người vận hành / kế toán** — người trả lời ticket và đối soát tiền. Hỏi: rule nào "ai cũng biết" mà chưa ghi? hoàn tiền / hết hạn / đổi gói thì cái gì xảy ra với cái gì? tôi trả lời khách bằng dữ liệu nào?
3. **Kẻ lợi dụng** — muốn dùng vượt quyền đã trả. Hỏi: bấm hai lần thì sao? hai request cùng lúc thì sao? đổi dữ liệu phía client thì sao? cái gì xảy ra ở ranh giới đúng bằng giới hạn?

<dán UC-###.md>
---

Đầu ra hợp lệ cho mỗi câu hỏi (ghi vào UC, mục Adversarial pass):
- Trả lời trong spec → thêm RULE / AC / E# / SCR, History v+1
- Chưa quyết được → `## Open Questions` kèm quyết định tạm
- Không thuộc v1 → Out of Scope của BR
Không có đầu ra "để đó".

---

# Ba vai tầng BR — dùng cho `/sdd-solo:adversarial BR-###`

Dán toàn bộ mục `# BR-###` trong `br.md`. Chạy ba vai, mỗi vai một lượt. AI chỉ được HỎI.

---
Bạn đọc business requirement dưới đây với vai **<VAI>**. Nhiệm vụ duy nhất: liệt kê những câu hỏi
mà BR chưa trả lời, những chỗ nó khẳng định mà không có nguồn, và những chỗ nó đang mô tả một
giải pháp thay vì một vấn đề.

Ràng buộc:
- Không đề xuất giải pháp. Không đề xuất tính năng. Không sửa spec.
- Mỗi câu hỏi một dòng.
- Không lặp lại thứ BR đã nói. Không khen.
- Tối đa 8 câu mỗi vai, xếp theo mức hậu quả nếu bỏ qua.

Vai:
1. **Người trả tiền** — người bỏ tiền và thời gian ra làm việc này. Hỏi: vì sao việc này đáng làm
   **trước** việc khác? không làm gì cả thì mất bao nhiêu, **đo bằng gì**? con số baseline trong
   Background lấy ở đâu ra? Success Metric này đo xong thì ai đọc, đọc để quyết cái gì?
2. **Người sẽ phải vận hành nó mãi** — người trực ticket và sửa lúc nửa đêm. Hỏi: hỏng lúc 2 giờ
   sáng thì ai chịu? cái gì trong Out of Scope hôm nay sẽ quay lại thành ticket tuần sau? việc này
   đẻ thêm bao nhiêu việc tay mỗi tháng? ai xử khi dữ liệu vào sai ngay từ đầu?
3. **Người hoài nghi** — người không tin là cần xây gì cả. **Đọc dòng `**Vì sao vẫn xây:**` trong
   Background trước tiên; nếu nó ghi "chưa có lý do" thì đó là câu hỏi số một của bạn.** Hỏi tiếp:
   có cách nào đạt Goal mà **không viết
   phần mềm** không (mua sẵn, đổi quy trình, thuê người, làm tay theo lô)? BR này có thật là một BR,
   hay là một giải pháp đã chọn sẵn rồi viết ngược thành lý do? nếu xoá hẳn BR này thì ai kêu, và
   sau bao lâu?

<dán mục BR-### trong br.md>
---

Đầu ra hợp lệ cho mỗi câu hỏi (ghi vào mục `## Adversarial pass` của BR):
- Có số và có nguồn → `## Background`
- Chưa quyết được → `## Open Questions` kèm quyết định tạm
- Không thuộc bản này → `## Out of Scope` + một nhánh `-.->` trên Impact Map
- Là ràng buộc → một `CON-###` mới
Không có đầu ra "để đó".

**Nếu vai người hoài nghi kết luận BR đang là giải pháp viết ngược thành lý do — dừng và viết lại BR.**
Đừng ghi nó thành một Open Question rồi đi tiếp: mọi UC sinh ra từ BR đó sẽ kế thừa nguyên lỗi.

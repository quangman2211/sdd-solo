# Adversarial pass — chạy trong một session MỚI, không phải session đang viết spec

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

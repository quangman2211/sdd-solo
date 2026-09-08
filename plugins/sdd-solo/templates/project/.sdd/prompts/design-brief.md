# Design brief cho Claude Design — sinh từ UC, không sinh từ cảm hứng

Dán Design System (link canvas) + UC + state diagram của entity liên quan.

---
Dựng các màn hình cho use case dưới đây, dùng Design System đã có. Quy tắc ràng:

1. Mỗi bước trong Main Flow có "Hệ thống hiển thị" → một màn hình SCR-###-#.
2. Mỗi Alternative Flow có UI → một trạng thái của màn hình liên quan.
3. Mỗi Exception E# → một trạng thái màn hình, thông điệp lỗi viết bằng tiếng của khách (người kinh doanh, không phải dev), và nói khách làm gì tiếp.
4. Mỗi trạng thái trên state diagram của entity phải nhìn thấy được ở đâu đó trên UI (nhãn, badge, hoặc màn hình riêng).
5. Không thêm màn hình, nút hay trường nào không có nguồn trong UC. Nếu thấy cần → ghi thành câu hỏi cho spec, không tự vẽ.
6. Đặt tên artboard đúng ID: SCR-###-# và SCR-###-#-E# cho trạng thái lỗi.

Trả về kèm bảng đối chiếu: Nguồn trong spec | Màn hình / trạng thái | Khách thấy gì | Hành động.
Ô nào không điền được → đó là chỗ spec thiếu, ghi rõ.

<dán UC-###.md + state diagram>
---

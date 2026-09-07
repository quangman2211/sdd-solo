# Self-review — năm câu (mục 6.4 của sách, bản một người)

Làm trước khi commit feat. Đọc spec trước, code sau.

1. **Spec trước:** Flow đã rõ? AC test được? Exception có thiếu case hiển nhiên?
2. **Trace:** Commit có UC ID? Commit docs cùng UC đứng trước?
3. **Test ↔ AC:** Mỗi AC có test? AC quan trọng không có test thì lý do ghi đâu?
4. **Rule ngầm:** Có số, enum, điều kiện nào trong code mà spec không nói? (grep)
5. **AI quyết hay mình quyết?** Đoạn logic phức tạp này nguồn gốc từ đâu? Quyết định kỹ thuật đáng nhớ → một dòng `docs/decisions.md`; đủ nặng → ADR.

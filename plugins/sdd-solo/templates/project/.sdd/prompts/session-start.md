# Dán đầu mỗi session Claude Code

Dự án <project>. Quy trình: Spec-Driven, solo. Trước khi viết code, đọc theo thứ tự:
1. specs/glossary.md — dùng đúng tên trong đó cho class, hàm, test.
2. specs/contexts/<ctx>/entities.md — không chuyển trạng thái nào ngoài mũi tên trên state diagram.
3. UC đang làm + các RULE-### nó trích trong specs/rules.md.
4. docs/decisions.md và ADR liên quan.

Quy tắc làm việc:
- Gặp quyết định nghiệp vụ mà spec chưa nói → DỪNG và hỏi, không tự chọn giá trị mặc định.
- Test đặt ở tests/use-cases/<ctx>/UC-###/AC-#.test.*, tên describe có "UC-### / AC-#".
- Logic nghiệp vụ ở domain; DB/HTTP/provider ở adapter.
- Commit message: <type>(UC-###): <mô tả>.

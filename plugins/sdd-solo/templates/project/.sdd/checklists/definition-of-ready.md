# Definition of Ready — cổng trước khi mở Claude Code

UC được coi là ready khi **tất cả** đúng:

- [ ] Actor, Trigger, Preconditions, Main Flow, Exceptions rõ nhất, Postconditions — đủ.
- [ ] Mọi rule trích RULE-### có sẵn trong `specs/rules.md`; không có rule ngầm trong AC.
- [ ] ≥ 1 AC cho Main Flow; ≥ 1 AC cho mỗi Exception. Dạng Given/When/Then.
- [ ] BPMN đã vẽ; số error boundary event = số E#; số end event có tên = số Postcondition.
- [ ] Mọi entity UC chạm tới có trong `entities.md`; chuyển trạng thái chỉ theo mũi tên có trên state diagram.
- [ ] Mọi E# có ≥ 1 trạng thái màn hình SCR; mọi SCR trỏ về một bước hoặc E#.
- [ ] Adversarial pass đã chạy trong session mới; mọi câu hỏi có đầu ra (spec / Open Question / Out of Scope).
- [ ] Spec đã được đọc lại ở một buổi khác buổi viết.
- [ ] Đã commit `docs(UC-###): spec vN — reviewed`.

Thiếu một dòng → không mở Claude Code. UC nhỏ thì checklist chạy nhanh, không phải bỏ.

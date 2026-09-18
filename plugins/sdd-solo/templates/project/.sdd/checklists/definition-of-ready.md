# Definition of Ready — cổng trước khi mở Claude Code

UC được coi là ready khi **tất cả** đúng:

- [ ] Actor, Trigger, Preconditions, Main Flow, Exceptions rõ nhất, Postconditions — đủ.
- [ ] Mọi rule trích RULE-### có sẵn trong `specs/rules.md` hoặc `specs/<nghề>/rules.md`; không có rule ngầm trong AC.
- [ ] ≥ 1 AC cho Main Flow; ≥ 1 AC cho mỗi Exception. Dạng Given/When/Then.
- [ ] Flow đã vẽ (`UC-###.flow.md`, mermaid); mỗi E# có một nhánh dẫn tới node kết đặt tên; mỗi Postcondition có một node kết. Hai vế đầu `/sdd-solo:gate` kiểm bằng máy.
- [ ] Mọi entity UC chạm tới có file trong `specs/core/entities/` hoặc `specs/<nghề>/entities/`; chuyển trạng thái chỉ theo mũi tên có trên state diagram.
- [ ] Mọi E# có ≥ 1 trạng thái màn hình SCR; mọi SCR trỏ về một bước hoặc E#.
- [ ] Đã ghi `**Giả định triển khai:** <chạy ở đâu · ai gọi · ngăn xếp>`. Bốn tầng BR/UC/Entity/AC
      không có ngăn nào cho câu này. Nói ra ở đây thì `/sdd-solo:design` (bước ⑩) có cái để đối chiếu
      với `specs/architecture.md`; không nói thì lệch chỉ lộ ra khi code đã viết. `gate` nhắc, không chặn.
- [ ] Adversarial pass đã chạy trong session mới; mọi câu hỏi có đầu ra (spec / Open Question / Out of Scope).
- [ ] Spec đã được đọc lại bằng một cái đầu chưa bị neo — `/sdd-solo:verify UC-###` (subagent). Từ 6.0.0 đây là cửa **duy nhất**, không còn "để sang buổi khác". `/sdd-solo:gate` kiểm bằng máy: ≥ 1 dòng `F#` có `[neo: ...]` và có đầu ra, và commit `docs(UC-###): đọc lại — …` là commit spec mới nhất.
- [ ] Đã commit `docs(UC-###): đọc lại — …` (verify) là commit spec cuối; sửa spec sau đó thì đọc lại lần nữa.

Thiếu một dòng → không mở Claude Code. UC nhỏ thì checklist chạy nhanh, không phải bỏ.

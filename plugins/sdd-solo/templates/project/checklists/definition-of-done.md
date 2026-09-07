# Definition of Done — bản solo

- [ ] Mỗi AC có ≥ 1 file test đúng tên `tests/use-cases/<ctx>/UC-###/AC-#.test.*`; test kiểm hành vi ở tầng domain, không chỉ mock HTTP.
- [ ] Không có rule trong code mà spec không nói (grep số, enum, điều kiện `if`). Có → đã dừng, sửa spec, commit docs.
- [ ] Self-review 5 câu đã làm; câu 5 → `docs/decisions.md` nếu có.
- [ ] `## History` có dòng mới nếu spec đổi trong lúc code.
- [ ] UC `Status: implemented`; `specs/traceability.md` có dòng của UC.
- [ ] Commit `feat(UC-###): ...` đứng SAU commit `docs(UC-###)` trong git log.
- [ ] `STATE.md` cập nhật.

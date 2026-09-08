<!-- sdd-solo: bản mỏng. Spec thật nằm ở specs/. File này chỉ trích ID để /speckit-plan có chỗ đọc. -->
# Feature: [UC-###] <tên>

## Nguồn
- **UC:** `specs/contexts/<ctx>/use-cases/UC-###-<slug>/UC-###.md` ← đọc file này, đây là spec.
- **BR:** BR-###
- **RULE:** RULE-###, RULE-###  (nội dung ở `specs/rules.md`)
- **Entities:** `specs/contexts/<ctx>/entities.md`
- **ADR / CON:** ADR-###, CON-###
- **Gate:** `.sdd/gate/UC-###.ok` phải tồn tại trước khi /speckit-plan

## Acceptance Criteria (chỉ ID, nội dung ở file UC)
- AC-1 · AC-2 · AC-3 · ...

## Screens
- SCR-###-1 ... (export ở `.../UC-###-<slug>/screens/`)

## Ghi chú cho /speckit-plan
- Kiểm RULE trước khi tạo record. Logic RULE ở domain, không ở adapter.
- Chuyển trạng thái chỉ theo state diagram trong entities.md.
- Mỗi AC → một file test `tests/use-cases/<ctx>/UC-###/AC-#.test.*`.

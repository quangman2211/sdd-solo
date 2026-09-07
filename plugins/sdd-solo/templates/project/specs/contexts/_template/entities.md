# Entity Model — <Context>

Không phải ERD. Chỉ tên, ý nghĩa, quan hệ, trạng thái. Mỗi entity có `status` phải có state diagram.

## Domain Model
```mermaid
classDiagram
  direction LR
  class EntityA {
    fieldOne
    fieldTwo — RULE-###
    status — s1 / s2 / s3
  }
  class EntityB {
    fieldOne
  }
  EntityA "1" --> "*" EntityB : <quan hệ>
```

## EntityA
- **Đại diện:** <một câu>
- **Trường đáng chú ý:** `fieldTwo` — giá trị theo RULE-###, không phải default.
- **Trạng thái:** s1 → s2 → s3 (xem state diagram)

```mermaid
stateDiagram-v2
  [*] --> s1 : <UC-### tạo>
  s1 --> s2 : <UC-### · điều kiện>
  s2 --> s3 : <UC-### · điều kiện>
  s3 --> [*]
  note right of s3
    Không có mũi tên ra khỏi s3.
    Đây là quyết định — RULE-###.
  end note
```

## EntityB
- ...

## History
- v1 (YYYY-MM-DD): initial

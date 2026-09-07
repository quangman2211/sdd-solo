# Context Map

Tạo khi có ≥ 2 bounded context. Mũi tên ghi thứ đi qua ranh giới. Từ nào đổi nghĩa khi qua ranh giới → ghi vào glossary.

```mermaid
flowchart LR
  A["<b>Context A</b><br/>Entity · Entity<br/><i>Từ X = nghĩa 1</i>"]
  B["<b>Context B</b><br/>Entity · Entity<br/><i>Từ X = nghĩa 2</i>"]
  A -->|"<sự kiện / dữ liệu đi qua>"| B
```

## Quan hệ
| Từ | Context | Nghĩa |
|---|---|---|
| ... | A | ... |
| ... | B | ... |

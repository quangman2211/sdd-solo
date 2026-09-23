# Order

- **Đại diện:** một đơn khách đã trả tiền
- **Thuộc:** orders
- **Trạng thái:** new → shipped

```mermaid
stateDiagram-v2
  [*] --> new : UC-001 báo đơn
  new --> shipped
```

## History
- v1 (2026-01-01): initial

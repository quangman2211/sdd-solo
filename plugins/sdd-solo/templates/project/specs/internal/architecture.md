# Architecture — C4 Context/Container + Hexagonal

Tạo khi có ADR đầu tiên chạm kiến trúc tổng. Cập nhật khi ADR đổi.

```mermaid
flowchart LR
  K["Khách / agent"] --> API["<project> API"]
  API --> D["Domain core<br/>use cases · entities"]
  D --> P1["Port: LicenseRepository"] --> A1["Adapter: <DB>"]
  D --> P2["Port: TokenSigner"] --> A2["Adapter: <ký token — ADR-002>"]
```

Quy tắc: domain không biết DB/HTTP/provider. AI được viết lại adapter; đổi domain phải có UC/RULE.

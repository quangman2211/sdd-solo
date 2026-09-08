# contexts/

Mỗi context nghiệp vụ một thư mục: `checkout/`, `billing/`, `identity/`…
Ranh giới là **khách cảm nhận được** — không phải ranh giới kỹ thuật.

Tạo context mới: chép `.sdd/templates/context/` vào đây và đổi tên.
`/sdd-solo:start UC-### <ctx> <slug>` làm việc đó giúp bạn.

Trong mỗi context:
```
entities.md      E# của context, kèm stateDiagram
use-cases.md     danh sách UC và trạng thái
diagrams/        chỉ diagram cấp context (context map, domain model)
use-cases/UC-###-slug/
    UC-###.md  UC-###.flow.md  UC-###.sequence.md  screens/
```
Artifact của một UC nằm trọn trong thư mục UC đó — kể cả sơ đồ luồng.

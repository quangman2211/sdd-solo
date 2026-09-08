# sdd-solo — Spec-Driven Development cho một dev + AI

Plugin Claude Code đóng gói quy trình SDD-Solo: giữ nguyên bốn tầng yêu cầu của Spec-Driven Development (BR → Use Case → Entity → Acceptance Criteria), thêm biểu đồ chuẩn ở mỗi tầng (BPMN 2.0, DMN, UML, Impact Map, Story Map), chèn Claude Design thành một bước chính thức, và thay mọi cơ chế cần người thứ hai bằng cơ chế một người làm được: adversarial pass ba vai, cổng Definition of Ready trước khi mở Spec Kit, `STATE.md` thay standup, git hook thay reviewer.

Nền: ebook *Spec Driven Development* (Nguyễn Thế Huy) · AI Unified Process · GitHub Spec Kit · OpenSpec.

## Cài

```
/plugin marketplace add quangman2211/sdd-solo
/plugin install sdd-solo@sdd-solo
```

Rồi trong repo dự án: `/sdd-solo:init` — hoặc `/sdd-solo:init --with-deps` để nó cài giúp Spec Kit và AIUP theo đúng thứ tự. Không có cờ thì nó chỉ kiểm và in lệnh, không đụng vào máy.

Đi kèm (cài riêng, plugin không tự cài thay bạn):
- **GitHub Spec Kit** — `specify init --here` trong repo → cho `/speckit-specify /speckit-plan /speckit-tasks /speckit-implement`
- **AIUP** — `/plugin marketplace add ai-unified-process/marketplace` · `/plugin install aiup-core` → cho `/requirements /entity-model /use-case-diagram /use-case-spec`
- **Camunda Modeler** (BPMN 2.0, DMN) · **Claude Design** (Design System, màn hình SCR)

## Dùng

Trong repo dự án:

| Lúc nào | Lệnh |
|---|---|
| Lần đầu / sau khi update plugin | `/sdd-solo:init` · `/sdd-solo:init --update` · `--with-deps` để cài luôn Spec Kit + AIUP |
| Mở session | hook tự đọc `STATE.md`, nói đang ở bước nào |
| Bắt đầu một use case | `/sdd-solo:start UC-### [ctx] [slug]` rồi `/use-case-spec UC-###` (AIUP) |
| Sau khi viết RULE, AC, vẽ BPMN, vẽ màn hình | `/sdd-solo:adversarial UC-###` → **đóng máy** |
| Buổi sau, đọc lại xong | `/sdd-solo:gate UC-###` → xanh thì `/speckit-specify` → `/speckit-plan` → `/speckit-tasks` → `/speckit-implement` |
| Code xong | `/sdd-solo:close UC-###` |
| Cuối buổi | `/sdd-solo:state` |
| Đang tới đâu · có đang chạy bản cũ không | `/sdd-solo:status` |
| Có bản mới | `/sdd-solo:update` — chạy trọn ba khe, rồi mở session mới |

Bốn câu để nhớ: **Viết xong chưa? Vẽ xong chưa? Soi xong chưa? Qua cổng chưa?**

## Cái gì nằm ở đâu

Từ 2.0.0, repo dự án chỉ còn **hai thư mục của quy trình**:

```
.sdd/     bộ máy — config, gate/, scripts/, hooks/, checklists/, prompts/, templates/
specs/    toàn bộ nội dung — br.md rules.md contexts/ internal/ changes/
STATE.md  CLAUDE.md  <code>/  <tests>/
```

- **`.sdd/`** giữ bộ máy, kể cả **một bản sao script kiểm** — nên `bash .sdd/scripts/gate-check.sh UC-###` chạy được ở CI và trên máy người clone repo, không cần cài plugin. Lệch version so với plugin thì hook và `status` cảnh báo.
- **`specs/`** giữ mọi thứ mô tả hệ thống. Ranh giới spec↔doc không mất, nó tụt một tầng: khách cảm nhận được → `contexts/`, chỉ người xây quan tâm → `internal/`. Đang sửa dở → `changes/`.
- Artifact của một UC nằm **trọn trong thư mục UC**, kể cả `.bpmn`.
- Plugin không bao giờ ghi đè file bạn đã sửa — `init --update` để bản mới cạnh dưới tên `.new`.

## Repo của bạn đặt code ở đâu

`.sdd/config` — sinh một lần lúc `init` bằng cách dò repo, và `init --update` **không bao giờ ghi đè**:

```
code_paths=src app lib
test_paths=tests
uc_test_dir=tests/use-cases
```

Githook và mọi script kiểm đều đọc file này. Trước 1.5.0 hai đường dẫn viết chết là `src`/`tests`, nên repo đặt code ở `app/` thì hook **cho qua mọi commit code không ID mà không nói một lời** — chặn cứng thành không chặn gì. Giờ commit có file nguồn mà không thư mục nào trong `code_paths` tồn tại thì hook **chặn** và chỉ vào `.sdd/config`; `/sdd-solo:status` cũng kiểm lại.

## Đang chạy bản nào

Bốn chỗ giữ version, lệch chỗ nào thì lệnh sửa khác nhau:

```
GitHub ─①─▶ marketplace đã tải ─②─▶ bản đã cài ─③─▶ .sdd/ của dự án
                                        └───④─▶ phiên Claude Code đang mở
```

| Khe | Lệnh |
|---|---|
| ③ `.sdd/` cũ hơn bản đã cài | `/sdd-solo:init --update` |
| ② bản đã cài cũ hơn bản đã tải | `/plugin update sdd-solo` |
| ① GitHub có bản mới | `/plugin marketplace update sdd-solo` |
| ④ phiên đang mở còn chạy bản cũ | **không lệnh nào sửa được** — mở session mới |

Khe ④ là khe nguy hiểm nhất: vừa `/plugin update` xong, `.sdd/` đã mới, mọi thứ trên đĩa đều đúng, nhưng phiên đang mở vẫn chạy code cũ nạp lúc mở — gõ `/sdd-solo:gate` là nhận logic cũ. Chỉ hook SessionStart biết được phiên nạp bản nào, nên nó ghi lại để `version-check` đọc.

`/sdd-solo:status` tự kiểm cả ba (hỏi GitHub tối đa 3 giây, nhớ 24 tiếng) và chỉ nói khi lệch. `/sdd-solo:update` chạy đúng những khe đang lệch trong một lệnh — nhưng **bản mới chỉ có hiệu lực ở session sau**, giống hệt cách Claude Code tự update chính nó. Hook mở session cũng cảnh báo, nhưng **chỉ so cục bộ, không gọi mạng** — nên khe ① chỉ lộ ra khi chạy `status`.

## Mức chặn — nói thật

- **Chặn cứng**: git hook `commit-msg` từ chối commit code không có ID hoặc UC chưa qua cổng; `pre-commit` từ chối trộn spec và code. Không có cờ bỏ qua.
- **Chặn mềm**: `/speckit-specify` `/speckit-plan` là lệnh của Spec Kit, plugin không đứng giữa được. Khối `CLAUDE.md` và hook SessionStart dạy session từ chối khi chưa có marker `.sdd/gate/UC-###.ok`; AI tuân, người thì có thể ép.

## Báo lỗi · yêu cầu sửa

Mở issue tại [github.com/quangman2211/sdd-solo/issues/new/choose](https://github.com/quangman2211/sdd-solo/issues/new/choose) — có sẵn hai form:

- **Báo lỗi** — plugin cài không được, lệnh chạy sai, script hoặc git hook chặn nhầm. Cần: lệnh đã chạy, output nguyên văn, cách tái hiện, môi trường.
- **Yêu cầu sửa / thêm** — đổi một quy tắc, thêm kiểm tra, thêm lệnh. Mô tả *vấn đề đang gặp* trước, giải pháp sau.

Ba loại yêu cầu bị từ chối theo thiết kế, đọc phần Ranh giới trong [CLAUDE.md](CLAUDE.md) trước khi mở issue: thêm cờ bỏ qua cho gate/hook, cho plugin ghi đè file dự án đã sửa tay, hook vào lệnh của Spec Kit.

## Tài liệu

- `plugins/sdd-solo/docs/playbook-example-khoskill.html` — playbook đầy đủ với ví dụ xuyên suốt (luồng license của một dự án mẫu).
- `plugins/sdd-solo/skills/sdd-process/SKILL.md` — kiến thức nền, cũng là thứ AI đọc khi làm việc trong repo.

## Cấu trúc

```
sdd-solo/
├── .claude-plugin/marketplace.json
└── plugins/sdd-solo/
    ├── .claude-plugin/plugin.json
    ├── skills/  sdd-process · init · start · adversarial · gate · close · state · status
    ├── hooks/hooks.json            SessionStart → scripts/session-start.sh
    ├── scripts/                    scaffold · gate-check/pass · close-check/pass · status · trace-ratio · ac-coverage
    ├── templates/
    │   ├── project/                specs/ docs/ changes/ checklists/ prompts/ STATE.md .gitmessage
    │   ├── CLAUDE.md.tmpl          khối quy tắc, ghép vào CLAUDE.md của repo
    │   ├── speckit/spec-template.md   bản mỏng chỉ trích ID
    │   └── githooks/               commit-msg · pre-commit
    └── docs/
```

MIT.

# sdd-solo — Spec-Driven Development cho một dev + AI

Plugin Claude Code đóng gói quy trình SDD-Solo: giữ nguyên bốn tầng yêu cầu của Spec-Driven Development (BR → Use Case → Entity → Acceptance Criteria), thêm biểu đồ chuẩn ở mỗi tầng (BPMN 2.0, DMN, UML, Impact Map, Story Map), chèn Claude Design thành một bước chính thức, và thay mọi cơ chế cần người thứ hai bằng cơ chế một người làm được: adversarial pass ba vai, cổng Definition of Ready trước khi mở Spec Kit, `STATE.md` thay standup, git hook thay reviewer.

Nền: ebook *Spec Driven Development* (Nguyễn Thế Huy) · AI Unified Process · GitHub Spec Kit · OpenSpec.

## Cài

```
/plugin marketplace add quangman2211/sdd-solo
/plugin install sdd-solo@sdd-solo
```

Đi kèm (cài riêng, plugin không tự cài thay bạn):
- **GitHub Spec Kit** — `specify init --here` trong repo → cho `/speckit-specify /speckit-plan /speckit-tasks /speckit-implement`
- **AIUP** — `/plugin marketplace add ai-unified-process/marketplace` · `/plugin install aiup-core` → cho `/requirements /entity-model /use-case-diagram /use-case-spec`
- **Camunda Modeler** (BPMN 2.0, DMN) · **Claude Design** (Design System, màn hình SCR)

## Dùng

Trong repo dự án:

| Lúc nào | Lệnh |
|---|---|
| Lần đầu / sau khi update plugin | `/sdd-solo:init` · `/sdd-solo:init --update` |
| Mở session | hook tự đọc `STATE.md`, nói đang ở bước nào |
| Bắt đầu một use case | `/sdd-solo:start UC-### [ctx] [slug]` rồi `/use-case-spec UC-###` (AIUP) |
| Sau khi viết RULE, AC, vẽ BPMN, vẽ màn hình | `/sdd-solo:adversarial UC-###` → **đóng máy** |
| Buổi sau, đọc lại xong | `/sdd-solo:gate UC-###` → xanh thì `/speckit-specify` → `/speckit-plan` → `/speckit-tasks` → `/speckit-implement` |
| Code xong | `/sdd-solo:close UC-###` |
| Cuối buổi | `/sdd-solo:state` |
| Đang tới đâu | `/sdd-solo:status` |

Bốn câu để nhớ: **Viết xong chưa? Vẽ xong chưa? Soi xong chưa? Qua cổng chưa?**

## Cái gì nằm ở đâu

- **Plugin** (`plugins/sdd-solo/`) giữ *hành vi*: skill, hook, script kiểm, template gốc, prompt, checklist. Update một chỗ.
- **Dự án** giữ *nội dung*: `specs/`, `docs/`, `changes/`, `STATE.md`, `CLAUDE.md`. Plugin không bao giờ ghi đè file bạn đã sửa — `init --update` để bản mới cạnh dưới tên `.new`.

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

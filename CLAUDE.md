# sdd-solo — hướng dẫn cho session làm việc TRONG repo plugin này

Repo này là **plugin Claude Code** (đồng thời là marketplace một plugin). Nó chứa *hành vi* của quy trình SDD-Solo; *nội dung* (spec, STATE) nằm ở từng repo dự án. Khi sửa ở đây, đừng bao giờ đụng tới bản đã cài trong `~/.claude/plugins/` — sửa ở đây, bump version, push, rồi `/plugin update` ở dự án.

## Cấu trúc
```
.claude-plugin/marketplace.json      version phải khớp plugin.json
plugins/sdd-solo/
  .claude-plugin/plugin.json         version
  skills/<name>/SKILL.md             lệnh /sdd-solo:<name> — init · intake · start · adversarial · verify · gate · design · change · close · state · status
  skills/sdd-process/SKILL.md        kiến thức nền, AI tự gọi khi user viết spec (không phải lệnh)
  hooks/hooks.json                   SessionStart → scripts/session-start.sh (đọc STATE.md của dự án)
  scripts/                           bash 3.2-compatible (macOS): lib.sh · scaffold · br-check · gate-check (có --pre) · design-check · change-check · close-check · pass (gate|close|change) · status · metrics · decisions · uc-steps · version-check · update · migrate · deps-check · session-start
  templates/project/                 được copy vào dự án bởi scaffold.sh, có manifest sha ở .sdd/manifest
  templates/CLAUDE.md.tmpl           khối chèn vào CLAUDE.md của dự án giữa <!-- sdd-solo:begin/end -->
  templates/githooks/                commit-msg · pre-commit — chặn cứng
  docs/playbook-example-khoskill.html
CHANGELOG.md                         mỗi bản một mục — đây là ## History của plugin
```

## Ranh giới — quyết định đã chốt, không mở lại tuỳ tiện
- **Plugin giữ NGUỒN của hành vi; dự án giữ một bản sao có đánh version của phần hành vi cần chạy được khi không có plugin** (githook, script kiểm ở `.sdd/scripts/`). Bản sao do `init --update` phát; lệch version thì hook SessionStart và `/sdd-solo:status` cảnh báo. Đổi từ 2.0.0 — giá phải trả là bản sao có thể trôi, đổi lại cổng DoR chạy được ở CI và trên máy người clone repo, chứ không dừng ở máy tác giả.
- **Dự án giữ nội dung.** `scaffold.sh` chỉ ghi đè file có sha khớp manifest (user chưa sửa tay); file đã sửa → tạo `.new`, không ghi đè. Không đổi quy tắc này.
- **Không có cờ bỏ qua** cho `gate-check.sh`, `commit-msg`, `pre-commit`. Đây là tính năng. Nếu một quy tắc sai thật, sửa quy tắc và ghi CHANGELOG — không thêm `--skip`.
- **Không gọi tên lệnh của plugin khác trong quy tắc cứng** (từ 4.0.0). Quy tắc nói về *trạng thái repo* — `.sdd/gate/UC-###.ok` có chưa, `design.md` có chưa — chứ không nói `/speckit-*`. Lý do đo được: bốn repo trên cùng máy có 10 / 24 / 25 / 35 lệnh `speckit-*`; một quy tắc gọi tên lệnh người khác thì hỏng theo lịch release của người khác. Spec Kit vẫn là nguồn tham khảo tốt — chỉ cần nó ghi vào `.speckit/`, không ghi vào `specs/`.
- **`speckit-decompose` để ngoài** plugin này (quyết định 09/2026).
- Không bịa số liệu trong template hay skill: chỗ chưa có dữ liệu để `___`.

## Quy trình sửa
1. Sửa file trong repo này.
2. Test:
   - script: `cd <repo dự án> && bash <đường dẫn repo này>/plugins/sdd-solo/scripts/gate-check.sh UC-###`
   - skill/hook: `cd <repo dự án> && claude --plugin-dir <đường dẫn repo này>/plugins/sdd-solo`
   - smoke test đầy đủ: tạo repo tạm, chạy scaffold → viết UC giả → gate (đỏ) → điền đủ, commit docs lùi ngày → gate (xanh) → gate-pass → commit feat (hook phải chặn khi thiếu marker, cho qua khi có) → close-check/-pass. Xem CHANGELOG 1.0.0 cho kịch bản gốc.
3. `claude plugin validate .` và `claude plugin validate plugins/sdd-solo` — cả hai phải pass.
4. **Bump version — bắt buộc, không có ngoại lệ.** Sửa ở **hai** file: `plugins/sdd-solo/.claude-plugin/plugin.json` và `.claude-plugin/marketplace.json`. Hai số phải khớp nhau. Thêm một mục CHANGELOG.
5. Commit `fix(sdd-solo): …` / `feat(sdd-solo): …`, push.
6. Ở dự án: `/plugin marketplace update sdd-solo` → `/plugin update sdd-solo`; nếu đụng `templates/` → `/sdd-solo:init --update`.

### Vì sao không được quên bump
Claude Code cache plugin theo **thư mục tên version**:

```
~/.claude/plugins/cache/sdd-solo/sdd-solo/1.0.0/
                                        └── version ở đây
```

Push mà không bump → `/plugin update` thấy version trùng, **không tải lại gì cả**. Dự án vẫn chạy code cũ trong khi git đã có code mới. Không có thông báo lỗi — đây là loại hỏng im lặng tốn nhiều giờ nhất để tìm ra.

Kiểm bằng script (1.2.0+), nó so cả bốn mắt xích và chỉ đúng lệnh cho từng chỗ lệch:
```bash
bash plugins/sdd-solo/scripts/version-check.sh --remote
```
Chuỗi là `GitHub → marketplace clone → plugin đã cài → .sdd/ của dự án`; mỗi khe một lệnh sửa khác nhau, đừng gõ cả ba. Không có `--remote` thì nó thuần cục bộ — và **cục bộ không bao giờ thấy được khe ①**, vì máy chỉ biết có bản mới sau khi hỏi GitHub.

**Khi nào KHÔNG cần bump:** chỉ khi thay đổi nằm hoàn toàn ngoài `plugins/sdd-solo/` — `README.md`, `CLAUDE.md` gốc, `.github/`, `LICENSE`. Đụng bất cứ file nào **trong** `plugins/sdd-solo/` (skill, hook, script, template, docs của plugin) → bump.

Quy tắc bump: sửa lỗi → patch (1.0.0 → 1.0.1) · thêm lệnh, thêm kiểm tra, đổi template → minor (1.0.0 → 1.1.0) · đổi quy tắc khiến dự án đang chạy phải sửa tay → major.

## Cái gì lan tới dự án bằng cách nào
| Sửa | Sau `/plugin update` | Cần thêm |
|---|---|---|
| skills/ hooks/ scripts/ | có hiệu lực ngay | — |
| templates/project/* | chưa | `/sdd-solo:init --update` |
| templates/CLAUDE.md.tmpl | chưa | `init --update` thay khối giữa marker |
| templates/githooks/* | chưa | `init --update` ghi đè `.githooks/` |

Cả bảng này chỉ đúng khi đã bump version. Chưa bump thì `/plugin update` không tải gì, mọi dòng trên thành vô nghĩa.

## Khi viết script
- bash 3.2: không dùng mảng kết hợp, `mapfile`, `${var,,}`. `sed -i.bak` rồi `rm .bak`. `shasum -a 256` có fallback `sha256sum` trong `lib.sh`.
- **Không đặt biến sát ký tự nhiều byte.** `echo "$VAR…"` trong bash 3.2 (macOS) dưới locale UTF-8 nuốt mất nội dung biến và byte đầu của ký tự theo sau — không riêng `…`, mà cả `→`, `✓`, chữ có dấu. Dùng `printf '…%s…\n' "$VAR"`, hoặc chèn một ký tự ASCII vào giữa. Bảng đo ở CHANGELOG 1.6.2 và issue #6. Mọi script ở đây đều bash và mọi thông điệp đều tiếng Việt, nên bẫy này còn lặp lại.
- Mọi kiểm cơ học in `✓ / ✗ / !` qua `ok/bad/warn` của `lib.sh`; exit 1 nếu có ✗.
- Commit từ script dùng `git commit --only -- <file>` để không kéo theo thứ user đang stage.
- Đường dẫn dự án lấy từ `project_root()` (`$CLAUDE_PROJECT_DIR` → `git rev-parse --show-toplevel` → `pwd`).

## Khi viết skill
- Skill lệnh: `disable-model-invocation: true`, có `argument-hint`, gọi script qua `${CLAUDE_PLUGIN_ROOT}/scripts/…` và kèm fallback `find ~/.claude/plugins -name <script> -path '*sdd-solo*'`.
- Skill không được tự sửa spec thay user trừ khi user bảo; không đề xuất viết code ở các bước spec.
- Văn tiếng Việt, xưng "anh"/"em" như user quen; tên file, ID, slug tiếng Anh.

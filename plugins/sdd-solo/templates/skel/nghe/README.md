# Nghề: <tên>

Một thư mục cho một nghề (eBay · Khải Kids · …). Ngang hàng với `specs/core/` (lõi dùng chung).
`glossary.md` · `rules.md` · `adr/` · `entities/` ở đây là **riêng của nghề**; thứ xuyên suốt nằm
ở gốc `specs/`. Mỗi lát của nghề là một `br-###/` (`br.md` · `evidence.md` · `use-cases/`).

Khi làm UC của nghề này, session AI đọc: gốc (`vision.md` · `glossary.md` · `rules.md`) → nghề
(`glossary.md` · `rules.md`) → entity UC nhắc tên (`core/entities/` + `<nghề>/entities/`) → UC.
`context.sh UC-###` gom sẵn đúng thứ tự đó.

Luật ranh giới: nghề **được** trích gốc và `core`; gốc và `core` **không** trích nghề.

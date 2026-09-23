# Craft: <name>

One folder per craft (eBay · Khai Kids · …). A sibling of `specs/core/` (the shared core).
The `glossary.md` · `rules.md` · `adr/` · `entities/` in here belong **to this craft only**;
anything cross-cutting lives at the root of `specs/`. Each slice of the craft is one `br-###/`
(`br.md` · `evidence.md` · `use-cases/`).

Working on a UC of this craft, an AI session reads: root (`vision.md` · `glossary.md` ·
`rules.md`) → craft (`glossary.md` · `rules.md`) → the entities the UC names
(`core/entities/` + `<craft>/entities/`) → the UC. `context.sh UC-###` gathers exactly that order.

Boundary rule: a craft **may** cite the root and `core`; the root and `core` **may not** cite a craft.

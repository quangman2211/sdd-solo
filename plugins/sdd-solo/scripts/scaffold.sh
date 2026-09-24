#!/usr/bin/env bash
# scaffold.sh <plugin_root> <project_root> [--update]
# Copy templates/project into the repo. Records the sha in a manifest so the next update only overwrites files nobody edited.
set -e
PLUGIN="$1"; ROOT="$2"; MODE="${3:-}"
# Called by hand without the positional arguments, `source` on an empty path dumps "invalid option" — unguessable.
if [ -z "$PLUGIN" ] || [ -z "$ROOT" ] || [ ! -f "$PLUGIN/scripts/lib.sh" ]; then
  echo "Usage: scaffold.sh <plugin directory> <project directory> [--update]" >&2
  echo "  example: bash ~/.claude/plugins/cache/sdd-solo/sdd-solo/<ver>/scripts/scaffold.sh <that plugin directory> \"\$(git rev-parse --show-toplevel)\" --update" >&2
  exit 2
fi
. "$PLUGIN/scripts/lib.sh"
VER="$(node "$PLUGIN/scripts/js/util.mjs" json "$PLUGIN/.claude-plugin/plugin.json" version 2>/dev/null || true)"
[ -z "$VER" ] && VER="$(grep -oE '"version": *"[^"]+"' "$PLUGIN/.claude-plugin/plugin.json" | head -1 | sed -E 's/.*"([^"]+)"$/\1/')"
# The other direction: an OLD plugin running on a NEW repo. A 1.x scaffold into a 2.x repo would rebuild
# the whole 1.x tree (checklists/ prompts/ .githooks/) next to the 2.x one — and the next migration would
# then find "both trees present". Block the downgrade right here.
# The `|| true` is MANDATORY: under set -e a failing command substitution on the right-hand side of an
# assignment exits immediately. A blank repo has no .sdd/version yet — scaffold is what creates it — so
# 2.0.3 blocked /sdd-solo:init on every blank repo, exit 1, with not one line of output. See #14.
PV="$(cat "$ROOT/.sdd/version" 2>/dev/null || true)"
if [ -n "$PV" ] && [ "$(vcmp "$PV" "$VER")" = "1" ]; then
  bad "the project is at $PV and the running plugin is $VER — the project layout is not downgraded"
  info "update the plugin and run again: /plugin marketplace update sdd-solo → /plugin update sdd-solo"
  exit 1
fi
# A repo with sdd-solo installed that still carries traces of the 1.x layout → it MUST migrate first.
# Running scaffold before the migration builds the whole destination tree out of empty templates, and then
# the migration sees the destination already there and skips everything — the real content stays in the old
# place, every file is duplicated, and not one error line appears. See #8.
if [ -f "$ROOT/.sdd/version" ]; then
  OLD1X=""
  for m in checklists/definition-of-ready.md prompts/adversarial-pass.md \
           specs/contexts/_template changes/_template .githooks/commit-msg .gitmessage; do
    [ -e "$ROOT/$m" ] && OLD1X="$OLD1X $m"
  done
  if [ -n "$OLD1X" ]; then
    bad "the repo still has the 1.x layout:$OLD1X"
    info "MIGRATE FIRST, then init — the other way round leaves the real content stuck in the old place:"
    info "  the 1.x layout has had no conversion script since 4.0.0 — see the README section on the 1.x layout"
    info "  and only then /sdd-solo:init --update"
    exit 1
  fi
fi
# 7.0: a 6.x repo WITH CONTENT (specs/contexts/ holds UCs, or specs/br.md holds a real BR) that has not
# migrated → blocked, for the same reason as #8 above: scaffold would build specs/core/br-000/ + vision.md
# next to the old tree, and then `layout` would see vision.md and think it was 7.0 — two trees at once, with
# no red line. A 6.x repo still holding only templates (no BR, no UC) can be scaffolded: the old templates whose sha matches the manifest are cleaned up by RETIRED_TPL below.
if [ -f "$ROOT/.sdd/version" ] && [ "$(layout "$ROOT")" = v6 ]; then
  HAS_UC="$(find "$ROOT/specs/contexts" -type f -path '*/use-cases/UC-*/UC-*.md' 2>/dev/null | head -1)"
  HAS_BR=""; grep -qE '^# BR-[0-9]+: *[^ <]' "$ROOT/specs/br.md" 2>/dev/null && ! br_untouched "$ROOT" && HAS_BR=1
  if [ -n "$HAS_UC" ] || [ -n "$HAS_BR" ]; then
    bad "the repo is on the 6.x layout with content (specs/contexts/ · specs/br.md) — 7.0 changes the tree to core|craft × br-###"
    info "MIGRATE FIRST, then init: write .sdd/migrate-v7.map, then  bash .sdd/scripts/migrate.sh --layout v7 --dry-run  →  drop --dry-run  →  commit"
    info "  (the 7.0 migrate.sh is in the plugin: ${PLUGIN}/scripts/migrate.sh — the repo .sdd/scripts/ still holds the old one until init --update has run)"
    info "and only then /sdd-solo:init --update — it cleans up the leftover 6.x templates and copies the 7.0 ones (vision.md, core/br-000/, adr/, layer-check.sh)"
    exit 1
  fi
fi
# 8.1.1 (P-45): the plugin has had ONLY ENGLISH templates since 7.8.0. That release promised a running repo
# would "not change by one byte", and for .sdd/config and the scripts it held — but templates/project is content,
# and `init --update` applied the translation to it: measured at runxops, 3 files overwritten outright
# (the CLAUDE.md block, specs/adr/_adr-template.md, specs/core/br-000/br.md) and 11 `.new` files that were empty
# English skeletons with nothing to merge. Measured on the plugin side, the whole 7.7.0 → 8.1.0 templates diff
# is TRANSLATION: 0 new files, 0 new sections, and the CLAUDE.md block is 29 lines before and after, 23 swapped
# for 23. So there was nothing to gain and a repo full of Vietnamese to lose.
# From here: doc_lang != en → a file that already exists is LEFT ALONE. No overwrite, no .new. Files that are
# MISSING are still created (English beats absent, and the line below says so). Setting doc_lang=en in
# .sdd/config takes the English templates on the next update — that is the opt-in, and there is no other flag.
DL="$(doc_lang "$ROOT")"
MAN="$ROOT/.sdd/manifest"; mkdir -p "$ROOT/.sdd/gate"; touch "$MAN"
TPL="$PLUGIN/templates/project"
COPIED=0; KEPT=0; NEW=0
echo "sdd-solo $VER → $ROOT ${MODE}"
if [ "$DL" != en ]; then
  warn "doc_lang=$DL — the plugin templates have been English only since 7.8.0, so a file that is already there is left exactly as it is: no overwrite, no .new. Only MISSING files are created, and those come in English. To take the English templates instead, put doc_lang=en in .sdd/config."
fi
cd "$TPL"
find . -type f | sed 's#^\./##' | sort | while read -r rel; do
  src="$TPL/$rel"; dst="$ROOT/$rel"; tsha="$(sha "$src")"
  mkdir -p "$(dirname "$dst")"
  esc="$(printf '%s' "$rel" | sed 's/[.[\*^$/]/\\&/g')"
  line="$(grep -E "^$esc " "$MAN" | tail -1)"
  rec_inst="$(echo "$line" | awk '{print $2}')"; rec_tpl="$(echo "$line" | awk '{print $3}')"
  if [ ! -f "$dst" ]; then
    cp "$src" "$dst"; echo "$rel $(sha "$dst") $tsha" >> "$MAN"; ok "create  $rel"
  elif [ "$rec_tpl" = "$tsha" ]; then
    : # the template has not changed since it was installed → leave it alone
  elif [ "$DL" != en ]; then
    # P-45: the template moved but the only template there is is English. Record the new template sha so the
    # same question is not asked again, and touch nothing in the repo.
    echo "$rel $(sha "$dst") $tsha" >> "$MAN"; info "keep    $rel — yours (doc_lang=$DL)"
  else
    cur="$(sha "$dst")"
    # 7.0: NO manifest line and the file exists → it is the user's (or a real file just migrated onto a template
    # name: specs/architecture.md from internal/). The old version copied over it here — real case: the runxops
    # architecture.md was replaced by the template, with not one red line. Only overwrite when the current sha MATCHES the one recorded at install (nobody edited it).
    if [ "$rec_inst" = "$cur" ]; then
      cp "$src" "$dst"; echo "$rel $(sha "$dst") $tsha" >> "$MAN"; ok "update  $rel"
    elif [ -z "$rec_inst" ] && [ "$cur" = "$tsha" ]; then
      echo "$rel $cur $tsha" >> "$MAN"; ok "record  $rel — already present, identical to the template"
    elif [ -z "$rec_inst" ]; then
      cp "$src" "$dst.new"; echo "$rel $cur $tsha" >> "$MAN"; warn "keep  $rel — the file was already there and has no manifest line, so it counts as yours; the template is at $rel.new (look at it, then delete the .new)"
    else
      cp "$src" "$dst.new"; echo "$rel $rec_inst $tsha" >> "$MAN"; warn "keep  $rel — you edited it; the new version is at $rel.new (merge it yourself, then delete the .new)"
    fi
  fi
done

# Clean up TEMPLATES renamed in an older release — the same reason as RETIRED for the scripts at the end of
# this file: copying the new name in without removing the old one leaves the upgraded repo still holding the old path.
# The 4.2.0 case: `specs/internal/adr/ADR-000-template.md` matched the `ADR-000*` glob of `id_exists()`, so a
# `design.md` quoting `ADR-000` was passed GREEN by `design-check` in every freshly scaffolded repo — nobody had
# to write anything wrong, only to install. Renaming inside the plugin while leaving the old file in the project
# fixes nothing at all.
#
# ONE difference from RETIRED for the scripts: a file under `specs/` is the project CONTENT, not a copy of
# behaviour. The boundary "the project holds the content" outranks tidying up, so only delete when the user has
# NOT touched it (the sha matches the manifest). Edited by hand → warn and leave it — better a loud error than
# deleting somebody else's writing.
RETIRED_TPL="specs/internal/adr/ADR-000-template.md
  specs/internal/adr/_adr-template.md specs/internal/architecture.md specs/internal/decisions.md specs/br.md
  specs/context-map.md specs/story-map.md specs/internal/design-system.md
  specs/internal/onboarding.md specs/internal/runbooks/README.md specs/changes/README.md
  specs/contexts/README.md specs/internal/README.md README.md
  .sdd/checklists/definition-of-done.md .sdd/checklists/feedback-triage.md
  .sdd/prompts/session-start.md .sdd/gate/README.md
  .sdd/templates/change/delta/UC-000.delta.md .sdd/templates/change/design.md
  .sdd/templates/change/proposal.md .sdd/templates/change/tasks.md
  .sdd/templates/context/README.md .sdd/templates/context/diagrams/README.md
  .sdd/templates/context/entities.md .sdd/templates/context/use-cases.md
  .sdd/templates/use-case/UC-000.design.md .sdd/templates/use-case/UC-000.flow.md
  .sdd/templates/use-case/UC-000.md .sdd/templates/use-case/UC-000.sequence.md
  .sdd/templates/use-case/UC-000.tasks.md .sdd/templates/use-case/screens/README.md"
# 5.0.0: 13 "empty drawers" (measured twice: no script or skill read them, and at runxops they were still
# byte-identical after several weeks) + the 13 templates of .sdd/templates/ (read only by a skill, and a skill
# only runs when the plugin is there — the copy in the project serves neither CI nor whoever clones the repo, so
# the reason .sdd/scripts/ exists does not apply to them; they now live in templates/skel/ of the plugin).
# Templates 43 → 16 files. See CHANGELOG 5.0.0.
for rel in $RETIRED_TPL; do
  # safety latch: never delete a path THIS release is shipping
  [ -f "$TPL/$rel" ] && continue
  dst="$ROOT/$rel"; [ -f "$dst" ] || continue
  esc="$(printf '%s' "$rel" | sed 's/[.[\*^$/]/\\&/g')"
  rec_inst="$(grep -E "^$esc " "$MAN" | tail -1 | awk '{print $2}')"
  if [ -n "$rec_inst" ] && [ "$rec_inst" = "$(sha "$dst")" ]; then
    rm -f "$dst"; ok "clean  $rel — no longer in the templates (CHANGELOG 4.2.0 / 5.0.0)"
  else
    warn "keep  $rel — you edited it by hand so it is NOT deleted; the 5.0.0 templates no longer have this file (see the CHANGELOG)"
  fi
done
# Directories left empty after the cleanup — git does not track empty directories, but whoever opens Finder
# sees them, and an empty directory looks exactly like "not done yet".
for d in .sdd/templates/use-case/screens .sdd/templates/use-case .sdd/templates/context/diagrams \
         .sdd/templates/context .sdd/templates/change/delta .sdd/templates/change .sdd/templates \
         specs/internal/runbooks specs/internal/adr specs/internal specs/contexts; do
  [ -d "$ROOT/$d" ] && rmdir "$ROOT/$d" 2>/dev/null && ok "clean  $d/ (empty)"
done

# CLAUDE.md: the block between the markers
CL="$ROOT/CLAUDE.md"; B='<!-- sdd-solo:begin -->'; E='<!-- sdd-solo:end -->'
BLOCK="$(cat "$PLUGIN/templates/CLAUDE.md.tmpl")"
if [ -f "$CL" ] && grep -q "$B" "$CL" && [ "$DL" != en ]; then
  # P-45: same reason as the template loop — replacing the block would swap a Vietnamese block for an English
  # one carrying no new rule. The block is what the project own agent reads every session; it is not ours to
  # translate on the project behalf.
  info "CLAUDE.md — the sdd-solo block left as it is (doc_lang=$DL)"
elif [ -f "$CL" ] && grep -q "$B" "$CL"; then
  node "$PLUGIN/scripts/js/util.mjs" marker "$CL" "$B" "$E" "$BLOCK"
  ok "CLAUDE.md — the sdd-solo block replaced"
else
  { [ -f "$CL" ] && printf '\n'; printf '%s\n%s\n%s\n' "$B" "$BLOCK" "$E"; } >> "$CL"; ok "CLAUDE.md — the sdd-solo block added"
fi
# 4.0.0: .specify/templates/spec-template.md is NO LONGER patched. That thin version existed only so
# /speckit-plan had something to read — a shim producing no new information (#35). And it forced an init
# order that breaks silently when reversed: `specify init --force` run AFTERWARDS overwrites the thin
# version without a word. Step ⑩ is now /sdd-solo:design.
# git hooks
if [ -d "$ROOT/.git" ]; then
  mkdir -p "$ROOT/.sdd/hooks"
  for h in "$PLUGIN/templates/githooks/"*; do [ -f "$h" ] && cp "$h" "$ROOT/.sdd/hooks/" && chmod +x "$ROOT/.sdd/hooks/$(basename "$h")"; done
  # #50: pre-commit.d/ · commit-msg.d/ — the repo own rules. Only the README and the .example are refreshed;
  # the user executable files in there are project CONTENT, the plugin does not touch them.
  for d in pre-commit.d commit-msg.d; do
    mkdir -p "$ROOT/.sdd/hooks/$d"
    for h in "$PLUGIN/templates/githooks/$d/"*; do [ -f "$h" ] && cp "$h" "$ROOT/.sdd/hooks/$d/"; done
    chmod +x "$ROOT/.sdd/hooks/$d/"*.sh 2>/dev/null || true   # set -e: pre-commit.d may hold no *.sh
  done
  # 7.2: the role boundary moved from pre-commit.d/10-role-boundary (by branch) to commit-msg.d/10-vai.sh (by .sdd/roles).
  # The old .example template belongs to the plugin → clean it up. A version the user enabled (10-role-boundary.sh) is a
  # repo file → not deleted, only flagged: two pieces blocking at once means D/T are blocked twice with two different messages.
  rm -f "$ROOT/.sdd/hooks/pre-commit.d/10-role-boundary.sh.example"
  [ -f "$ROOT/.sdd/hooks/pre-commit.d/10-role-boundary.sh" ] && \
    warn "pre-commit.d/10-role-boundary.sh (blocking by branch, up to 7.1) is still there — 7.2 blocks by .sdd/roles in commit-msg.d/10-vai.sh; remove the old one: git rm .sdd/hooks/pre-commit.d/10-role-boundary.sh"
  git -C "$ROOT" config core.hooksPath .sdd/hooks
  [ -f "$ROOT/.sdd/gitmessage" ] && git -C "$ROOT" config commit.template .sdd/gitmessage
  ok "git hooks: commit-msg, pre-commit (core.hooksPath=.sdd/hooks) + pre-commit.d/ commit-msg.d/ (10-vai.sh: the role boundary from .sdd/roles, 7.2)"
else
  warn "there is no .git yet — run git init and run again to install the hooks"
fi
# .sdd/config — generated once, probed from the repo. NOT part of templates/project so init --update never
# overwrites it: this is project content, not behaviour.
if [ ! -f "$ROOT/.sdd/config" ]; then
  D="$(detect_paths "$ROOT")"; DC="${D%%|*}"; DT="${D##*|}"
  [ -z "$DC" ] && DC="$CFG_DEFAULT_CODE"; [ -z "$DT" ] && DT="$CFG_DEFAULT_TEST"
  UCT="$(printf '%s' "$DT" | awk '{print $1}')/use-cases"
  {
    echo "# sdd-solo — the code/test paths of this repo."
    echo "# The githooks and the checking scripts all read this file. A wrong path makes a hook"
    echo "# miss silently, so /sdd-solo:status checks it again for you."
    echo "# Lists are separated by spaces. Edit it freely, init --update does not touch it."
    echo "code_paths=$DC"
    echo "test_paths=$DT"
    echo "uc_test_dir=$UCT"
    echo "# tool_paths: REAL code that belongs to no UC and cannot — a script that measures"
    echo "# data, a one-off conversion script, a repo utility. Exempt from IDs at the"
    echo "# githook and not counted in the trace-ratio denominator. Empty behaves as before."
    echo "tool_paths="
    echo "# brief_path: the source brief file specs/br.md was converted from."
    echo "# /sdd-solo:intake writes this line. It puts the brief into the MANDATORY READING"
    echo "# ORDER — without it the brief becomes a write-only file right after intake (#34)."
    echo "brief_path="
    echo "# nghe_paths: the craft names — the directories specs/<craft>/ and src/<craft>/ (7.0). core is not listed. Empty means"
    echo "# the scripts probe specs/*/ (a directory holding br-###/, glossary.md or entities/). migrate --layout v7 fills it in for you."
    echo "nghe_paths="
    echo "# doc_lang: the language the scripts WRITE documents in — en | vi (7.7.0). It only affects the"
    echo "# WRITE direction; reading accepts both, so a gate returns the same verdict either way."
    echo "# A NEW project gets en because the templates are English. A repo from before 7.7.0 has no"
    echo "# such line, doc_lang falls back to vi, and its behaviour does not change by one byte."
    echo "doc_lang=en"
    echo "# rr_max: the ceiling on re-read rounds — how many times /sdd-solo:verify may run on one UC or one"
    echo "# change proposal while findings are still Undecided (8.0.0). At the ceiling the gate goes red until"
    echo "# every leftover becomes an Open Question or a ticket; under it nothing changes. Measured: rounds and"
    echo "# leftovers rise together (13 rounds / 105 Undecided in the worst case), so another round is not an"
    echo "# answer to the previous one. 0 switches the ceiling off and then nothing counts the rounds."
    echo "rr_max=2"
  } > "$ROOT/.sdd/config"
  ok ".sdd/config — code_paths=$DC · test_paths=$DT (probed from the repo; fix it if wrong)"
  # tests/ · __tests__/ · spec/ are three entirely different conventions. A wrong guess makes
  # ac-coverage blind with nobody knowing, so say it now instead of writing it silently.
  [ -d "$ROOT/$(printf '%s' "$DT" | awk '{print $1}')" ] || \
    warn ".sdd/config: uc_test_dir=$UCT is a GUESS — the test directory does not exist yet. Fix it to match this repo convention (tests/ · __tests__/ · spec/)."
else
  info ".sdd/config is already there — code_paths=$(code_paths "$ROOT")"
  # 7.0: an older repo without the nghe_paths key → add it (touching no other config line)
  if ! grep -qE '^nghe_paths=' "$ROOT/.sdd/config" 2>/dev/null; then
    NG="$(nghe_list "$ROOT")"
    printf '# nghe_paths: the craft names — the directories specs/<craft>/ and src/<craft>/ (7.0). core is not listed. Empty means the scripts probe specs/*/.\nnghe_paths=%s\n' "$NG" >> "$ROOT/.sdd/config"
    ok ".sdd/config — nghe_paths=${NG:-(empty)} added (7.0)"
  fi
fi
if ! has_code_path "$ROOT"; then
  if repo_has_code "$ROOT"; then
    bad ".sdd/config: no directory in code_paths=$(code_paths "$ROOT") exists while the repo already has source files → the githook is missing things. Fix .sdd/config."
  else
    info "no code directory yet — normal for a new repo; remember to fix .sdd/config once you place the code"
  fi
fi
# 2.0.0: the checking scripts are copied into the project so the DoR gate can run on a machine without the
# plugin installed (CI, whoever clones the repo). The price: the copy can drift in version — .sdd/version is
# compared with the plugin version, and session-start and status warn about a mismatch.
mkdir -p "$ROOT/.sdd/scripts"
KEEP="lib.sh mermaid.sh numbers.sh role.sh stop-ketqua.sh phieu.sh queue.sh hoi-check.sh layer-check.sh br-scope-diff.sh br-check.sh gate-check.sh change-check.sh close-check.sh design-check.sh pass.sh status.sh metrics.sh decisions.sh context.sh version-check.sh deps-check.sh migrate.sh uc-steps.sh"
for f in $KEEP; do
  [ -f "$PLUGIN/scripts/$f" ] && cp "$PLUGIN/scripts/$f" "$ROOT/.sdd/scripts/$f"
done
# 7.6.0: js/ — the node code of the plugin (mermaid.mjs · mermaid-real.mjs …). The whole directory is copied, for
# the same reason as KEEP: the gate must run in CI and on the machine of whoever clones the repo, where there is no plugin.
[ -f "$PLUGIN/scripts/kw.tsv" ] && cp "$PLUGIN/scripts/kw.tsv" "$ROOT/.sdd/scripts/kw.tsv"
if [ -d "$PLUGIN/scripts/js" ]; then
  mkdir -p "$ROOT/.sdd/scripts/js"
  for f in "$PLUGIN/scripts/js/"*.mjs; do [ -f "$f" ] && cp "$f" "$ROOT/.sdd/scripts/js/"; done
fi
chmod +x "$ROOT/.sdd/scripts/"*.sh 2>/dev/null
ok ".sdd/scripts/ — a copy of $VER, runnable without the plugin (CI uses .sdd/scripts/gate-check.sh)"

# Clean up scripts an older release folded in or dropped. Copying the new file in WITHOUT removing the old one
# leaves the upgraded repo still holding a working OLD PATH: `gate-pass.sh` can still stamp the gate, standing
# beside `pass.sh gate`; `uc-ready.sh` still measures the four things `gate-check.sh --pre` measures. Folding
# them together in the plugin so the two measurements cannot drift apart, and then leaving both copies in the
# project, is not folding anything together.
#
# LIST BY NAME every name the plugin HAS EVER shipped — do not delete by the rule "every .sh not in the copy
# list". The user may have put their own script here; a rule-based cleanup can delete the wrong thing, a
# list by name cannot.
RETIRED="ac-coverage.sh trace-ratio.sh gate-pass.sh close-pass.sh change-pass.sh uc-ready.sh migrate-1to2.sh"
RM=""
for f in $RETIRED; do
  # safety latch: never delete something THIS release is shipping
  case " $KEEP " in *" $f "*) continue;; esac
  [ -f "$ROOT/.sdd/scripts/$f" ] && { rm -f "$ROOT/.sdd/scripts/$f"; RM="$RM $f"; }
done
[ -n "$RM" ] && ok ".sdd/scripts/ — cleaned up the folded-in older versions:$RM"
# 7.6.0: mermaid.py (7.5.0) became js/mermaid.mjs. An old copy left in place gives the repo TWO parsers, and
# the one no longer being updated still runs — the same reason as RETIRED above, so it is listed by name too.
for f in mermaid.py; do
  [ -f "$ROOT/.sdd/scripts/$f" ] && { rm -f "$ROOT/.sdd/scripts/$f"; ok ".sdd/scripts/ — cleaned up $f (7.6.0: the mermaid parser runs on node)"; }
done
echo "$VER" > "$ROOT/.sdd/version"
echo; echo "Xong. Commit: git add -A && git commit -m \"chore(sdd): init sdd-solo $VER\""
# This line is the FIRST direction the user reads, before knowing anything else. Up to 3.2.0 it still said
# "/requirements (AIUP) or write specs/br.md yourself" — while /requirements read a vision.md nobody had
# created, and "write br.md yourself" was exactly where people got stuck. See #20.
echo "NEXT STEP — Phase 1: type /sdd-solo:intake"
echo "  Step 0: the owner states the direction (specs/vision.md) in plain words; then 7 questions (what hurts · who hurts · what it costs · ...)"
echo "  and intake writes the first BR into specs/<core|craft>/br-001/br.md."
echo "  Already holding a brief from another agent: /sdd-solo:intake path/to/brief.md"
echo "  Want to write it yourself: read the BR-000 sample in specs/core/br-000/br.md, or specs/_intake.md to question yourself."

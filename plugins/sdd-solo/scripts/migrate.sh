#!/usr/bin/env bash
# migrate.sh [--dry-run] — 3.x → 4.0.0: split the Spec Kit tree out of specs/.
# migrate.sh --evidence BR-### [--dry-run] — 5.0.0: split the ## Background body into br.evidence.md;
#   5.1.0: also split the ## Adversarial pass body, leaving a counting line with an ___ number up front.
# migrate.sh --layout v7 [--map <file>] [--dry-run] — 7.0.0: specs/contexts/<ctx>/ · specs/br.md · specs/internal/
#   → specs/{vision,architecture,decisions}.md · specs/adr/ · specs/<core|craft>/{entities/,br-###/{br.md,evidence.md,
#   use-cases/}} · notes/{hoi-dap,soat,ban-do}/. Reads a map file (default .sdd/migrate-v7.map), uses git mv to keep
#   the history, and prints a "moved" and a "needs hands" table. See the `--layout v7` block below.
#
#   specs/00N-<slug>/  →  .speckit/work/00N-<slug>/
#
# Why: `speckit-specify/SKILL.md` tells the agent IN PROSE that specs live under `specs/`, and that the
# next number is taken by scanning the directories currently in `specs/` — which means that count is
# counting br.md, contexts/ and changes/ of sdd-solo too. Two ID systems (`001-` and `UC-###`), two spec
# trees, one directory, neither side aware of the other.
# (There is a `create-new-feature.sh` that does the right thing, but NO skill calls it — measured on
#  1.0.6.dev0 and on the older copy at runxops. The prose in the skill is what actually runs, and prose
#  cannot be reconfigured.)
#
# DOES NOT COMMIT. It moves the files and prints what changed; the reader commits.
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"
DRY=0; EV=""; LAYOUT=""; MAPF=""; TRACE=0
PREV=""
for a in "$@"; do
  case "$PREV" in --layout) LAYOUT="$a"; PREV=""; continue;; --map) MAPF="$a"; PREV=""; continue;; esac
  case "$a" in
    --dry-run) DRY=1;;
    --evidence) EV="_";;
    --trace) TRACE=1;;
    --layout|--map) PREV="$a";;
    BR-[0-9]*) [ "$EV" = "_" ] && EV="$a";;
  esac
done

# ── --trace : the evidence trail out of the body, into UC-###.trace.md (8.0.0) ──
# What it moves: `## Adversarial pass` · `## Re-read` · `## History` out of every UC-###.md and every
# specs/changes/CHG-###/proposal.md, into <base>.trace.md beside it, leaving a `## Evidence` pointer.
# Nothing is deleted and nothing is rewritten — the sections are appended to the side file verbatim.
#
# IDEMPOTENT, and that is the whole design constraint. A migration of a live repo gets interrupted, gets
# run from two worktrees, gets run again because nobody remembers whether it ran. So the decision is made
# per FILE and from the file's own content: a body with no trail section is already migrated and is not
# touched, and a side file that already ends with the very block being appended does not get a second copy.
# Running it five times leaves the repo byte-identical to running it once.
#
# DOES NOT COMMIT — like every other mode here. Read the diff, then commit.
if [ "$TRACE" = "1" ]; then
  echo "=== The evidence trail beside the UC, not inside it (8.0.0) ==="
  [ "$DRY" = "1" ] && info "--dry-run: NOTHING is touched on disk, it only prints what it would do"
  need_node "migrate.sh --trace"
  N=0; M=0
  for f in $(all_uc_files "$ROOT") $(ls -d "$ROOT"/specs/changes/CHG-[0-9]*/proposal.md 2>/dev/null); do
    [ -f "$f" ] || continue
    N=$((N+1))
    ID="$(basename "$(dirname "$f")" | grep -oE '^(UC|CHG)-[0-9]+')"
    [ -z "$ID" ] && ID="$(basename "${f%.md}")"
    node "$HERE/js/migrate.mjs" trace "$f" "$(trace_of "$f")" "$ID" "$DRY" "$(today)" "$(doc_lang "$ROOT")" && M=$((M+1))
  done
  printf -- '--- %s file(s) looked at, %s moved ---\n' "$N" "$M"
  [ "$M" = 0 ] && ok "every file already keeps its trail beside it — nothing to move"
  [ "$DRY" = "1" ] && info "run again WITHOUT --dry-run to do it"
  [ "$DRY" = "0" ] && [ "$M" != 0 ] && info "read the diff, then commit: git commit -m 'docs(sdd): the evidence trail moves to UC-###.trace.md (8.0.0)'"
  exit 0
fi

# ── --layout v7 : the context tree → core|craft × br-### (7.0.0, #54 #55) ───
# All the logic is in js/migrate.mjs: splitting files by heading, building the UC table, fixing paths by the
# real name just moved (the same rule as the Spec Kit part below — list by name, no general regex). Bash only
# finds the templates: running from the plugin, `templates/` is next door; running from the .sdd/scripts/ copy
# it asks the installed plugin; without either, js/migrate.mjs uses a minimal skeleton and records it in "needs hands".
if [ -n "$LAYOUT" ]; then
  [ "$LAYOUT" = "v7" ] || { echo "Usage: migrate.sh --layout v7 [--map <file>] [--dry-run]" >&2; exit 2; }
  if [ "$(layout "$ROOT")" = v7 ] && [ ! -d "$ROOT/specs/contexts" ] && [ ! -f "$ROOT/specs/br.md" ]; then
    ok "the repo is already on the 7.0 layout (specs/vision.md or specs/*/br-###/ present, specs/contexts/ and specs/br.md gone) — nothing to move"; exit 0
  fi
  [ -z "$MAPF" ] && MAPF="$ROOT/.sdd/migrate-v7.map"
  case "$MAPF" in /*) ;; *) MAPF="$ROOT/$MAPF";; esac
  TPLD=""
  for cand in "$HERE/../templates" "${CLAUDE_PLUGIN_ROOT:-/nonexistent}/templates" "$(installed_path sdd-solo 2>/dev/null)/templates"; do
    [ -f "$cand/skel/br/br.md" ] && { TPLD="$cand"; break; }
  done
  [ -z "$TPLD" ] && warn "cannot find the plugin templates/ — the br.md/rules/glossary/vision skeletons will be minimal"
  echo "=== Moving to the 7.0 layout — core|craft × br-### ==="
  [ "$DRY" = "1" ] && info "--dry-run: NOTHING is touched on disk, it only prints what it would do"
  info "map: ${MAPF#$ROOT/}"
  need_node "migrate.sh --layout v7"
  node "$HERE/js/migrate.mjs" layout "$ROOT" "$DRY" "$MAPF" "${TPLD:+$TPLD/skel}" "${TPLD:+$TPLD/project}" "$(uc_test_dir "$ROOT")" "$(today)" "$(code_paths "$ROOT")" "$(test_paths "$ROOT")"
  exit $?
fi

# ── --evidence BR-### : split the ## Background body into specs/br.evidence.md ─
# 5.0.0. Measured at runxops: BR-001 was 73 KB of which ## Background was 31.8 KB — 15 ### sections of
# evidence measured from real data ("982 of 1986 cells hold more than one line"). Evidence is what makes
# a BR stand up AT WRITING TIME; after that it is what every reading has to wade through, and a September
# 2026 measurement is a trace a year later, no longer something in force.
# Kept in br.md: every `### heading` (the table of contents) + every paragraph starting with `**`
# (`**Why still build:**`, `**Brief source:**` — br-check reads those). The body goes.
if [ -n "$EV" ]; then
  [ "$EV" = "_" ] && { echo "Usage: migrate.sh --evidence BR-### [--dry-run]" >&2; exit 2; }
  # 7.0: paths via lib — 6.x specs/br.md · specs/br.evidence.md; 7.0 the slice br.md · evidence.md. The counting line
  # left behind points at `→ <the evidence file name relative to br.md>` (br-check accepts `→ .*evidence\.md`).
  need_node "migrate.sh --evidence"
  node "$HERE/js/migrate.mjs" evidence "$(br_file "$EV" "$ROOT")" "$(evidence_file "$EV" "$ROOT")" "$EV" "$DRY" "$(today)"
  exit $?
fi

DIRS="$(find "$ROOT/specs" -maxdepth 1 -type d -name '[0-9][0-9][0-9]-*' 2>/dev/null | sort)"
if [ -z "$DIRS" ]; then
  ok "specs/ has no 00N-* directory — nothing to split out"
  exit 0
fi

echo "=== Splitting the Spec Kit tree out of specs/ ==="
[ "$DRY" = "1" ] && info "--dry-run: NOTHING is touched on disk, it only prints what it would do"

DEST="$ROOT/.speckit/work"
N=0; NAMES=""
for d in $DIRS; do
  b="$(basename "$d")"; NAMES="$NAMES $b"
  CNT="$(find "$d" -type f 2>/dev/null | wc -l | tr -d ' ')"
  printf '  specs/%s  →  .speckit/work/%s   (%s file)\n' "$b" "$b" "$CNT"
  if [ "$DRY" = "0" ]; then
    mkdir -p "$DEST"
    # git mv keeps the history; if the repo does not track it, fall back to a plain mv.
    if git -C "$ROOT" ls-files --error-unmatch "specs/$b" >/dev/null 2>&1; then
      git -C "$ROOT" mv "specs/$b" ".speckit/work/$b" 2>/dev/null || mv "$d" "$DEST/$b"
    else
      mv "$d" "$DEST/$b"
    fi
  fi
  N=$((N+1))
done

# Paths inside files: left unfixed, plan.md points at a place where nothing is left.
#
# Search and fix by THE REAL DIRECTORY NAME JUST MOVED, not by the shape `specs/00N-`.
# The 4.0.0 version used a general regex, so it rewrote an EXAMPLE SENTENCE inside the Spec Kit vendor
# documentation (`.claude/skills/speckit-specify/SKILL.md`: *"for example, `specs/003-user-auth`"*) —
# `003-user-auth` did not exist in the repo at all, and after the sed pass the vendor file described its
# own tool incorrectly. The same rule already used for `strip_markup()`: listing by name makes a wrong
# hit IMPOSSIBLE, not merely unlikely. When it misses, it misses on the safe side.
echo
echo "=== Paths pointing at the old place ==="
# DO NOT use `grep -r`. Whether grep recurses is decided by the user machine, not by us: on this machine
# the interactive `grep` is ugrep, and ugrep RESPECTS .gitignore.
# The case that matters: `.specify/feature.json` — a file the migration MUST fix — sits inside
# `.specify/.gitignore`. A grep that reads .gitignore (ripgrep, ugrep, git grep) returns empty there, and
# the migration silently leaves a dead pointer behind. A miss like that has no red line: a shorter list
# looks exactly like "there was nothing to fix".
# `find | xargs` removes the dependency on grep recursion semantics entirely.
# `/dev/null` is an operand that is always there: it forces grep to print the file name even when only one
# file is left, and stops grep from reading stdin when find returns nothing.
FILES="$(find "$ROOT" -type f \( -name '*.md' -o -name '*.json' -o -name '*.yml' -o -name '*.yaml' \) \
         -not -path '*/.git/*' -not -path '*/node_modules/*' 2>/dev/null)"
HITS=""
for b in $NAMES; do
  H="$(printf '%s\n' "$FILES" | grep -v '^$' | tr '\n' '\0' \
       | xargs -0 grep -nF "specs/$b" /dev/null 2>/dev/null)"
  [ -n "$H" ] && HITS="$(printf '%s\n%s' "$HITS" "$H")"
done
HITS="$(printf '%s' "$HITS" | grep -v '^$' | head -40)"
if [ -z "$HITS" ]; then
  ok "no file points at a moved directory"
else
  printf '%s\n' "$HITS" | sed 's/^/  /'
  if [ "$DRY" = "0" ]; then
    printf '%s\n' "$HITS" | cut -d: -f1 | sort -u | while IFS= read -r f; do
      [ -f "$f" ] || continue
      for b in $NAMES; do
        sed -i.bak "s#specs/$b#.speckit/work/$b#g" "$f" && rm -f "$f.bak"
      done
    done
    ok "fixed the paths to the moved directories in the files above"
  else
    info "--dry-run: no file was edited"
  fi
fi

echo
if [ "$DRY" = "1" ]; then
  printf 'Would split out %s directories. Run again WITHOUT --dry-run to do it.\n' "$N"
  exit 0
fi
printf 'Split out %s directories. specs/ now holds only the sdd-solo tree.\n' "$N"
echo "Read git status and commit yourself — the script deliberately does not commit for you:"
echo "  git add -A && git commit -m 'chore(sdd): split the Spec Kit tree into .speckit/work (4.0.0)'"

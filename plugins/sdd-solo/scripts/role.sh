#!/usr/bin/env bash
# role.sh — the roles of the agent team (7.2). The mechanism is in the plugin; the policy (which roles exist, who writes where) is in the project .sdd/roles.
#
#   role.sh <role>                      set the role marker for THIS WORKTREE (.git[/worktrees/<name>]/sdd-role) and print the contract
#   role.sh --xem                       the current role (SDD_ROLE → the worktree marker → the branch pattern) + the write/deny areas
#   role.sh --worktree <role> [UC-###]  create a worktree for the role on a branch from <V>.nhanh, set the marker, remind about merging main
#   role.sh <role> <ticket file> [--luot N]  print the SIX-PART BRIEF from a ticket — no free-form string accepted
#   role.sh --don UC-### [--dry-run]     clean the lanes of one UC: remove its role worktrees, prune, delete its <V>.nhanh branches
#   role.sh --ketqua <key> ket=xong|chan|do neo=<hash|marker|file> [kiem=…] [hoi=…] [con=…]
#                                       write one KETQUA line into $(git-common-dir)/sdd-ketqua/<key>.txt — shared by every worktree
#   role.sh --ketqua <key>              read it
#   role.sh --staged                    check the staged files against the current role (the githook calls it via --commit)
#   role.sh --commit <msg file>         like --staged, plus inferring the role from a `Vai: <V>` trailer and writing that trailer into the message
#   role.sh --kiem-lich-su <range>      read-only: run the write-area rule over the history, counting commits no role was allowed to write in full
#
# Why the role marker is per worktree: three spec agents and three review agents running in parallel on one checkout
# swept up each other files twice in one day (P-29) and collided on ticket numbers four times (P-21). A branch is not
# enough: the spec/review/arbiter roles all sit on main.
# `git rev-parse --git-path sdd-role` returns a path private to each worktree, outside git and independent of the branch.
HERE="$(cd "$(dirname "$0")" && pwd)"; . "$HERE/lib.sh"
ROOT="$(project_root)"
usage() { sed -n '3,15p' "$0" | sed 's/^# \{0,3\}//'; exit 2; }
[ $# -eq 0 ] && usage
RF="$(roles_file "$ROOT")"

need_roles() { [ -n "$RF" ] || { bad "there is no .sdd/roles yet — copy the template: /sdd-solo:init --update (7.2), then adjust the roles for this repo"; exit 1; }; }
check_role() { role_known "$1" "$ROOT" || { bad "the role '$1' is not in .sdd/roles (vai=$(role_list "$ROOT"))"; exit 1; }; }
contract() { # print the role contract
  local v="$1"
  printf 'Vai %s · %s\n' "$v" "$(role_name "$v" "$ROOT")"
  printf '  may write: %s\n' "$(role_paths "$v" "$ROOT")"
  printf '  KHÔNG ghi: %s\n' "$(role_deny "$v" "$ROOT")"
  [ -n "$(role_branch "$v" "$ROOT")" ] && printf '  branch: %s\n' "$(role_branch "$v" "$ROOT")"
  role_may_commit "$v" "$ROOT" && printf '  commit: yes — <type>(ID) listing the files by name, trailer Vai: %s\n' "$v" || printf '  commit: NO — A commits instead\n'
  [ -n "$(role_checks "$v" "$ROOT")" ] && printf '  checks before committing: %s\n' "$(role_checks "$v" "$ROOT")"
}
# check a file list against a role → print ✗ per file; return 1 if there was a violation
check_files() { # check_files <role> <file list, one per line>
  local v="$1" f bad=0 who
  role_may_commit "$v" "$ROOT" || { bad "the role $v may not commit (.sdd/roles: $v.commit=khong) — A commits instead"; bad=1; }
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    role_allows "$v" "$f" "$ROOT" && continue
    who="$(role_of_path "$f" "$ROOT")"
    if [ -n "$who" ]; then bad "$f — this belongs to role $who, not to $v. Write an ASK/ticket and the other role fixes it next round"
    else bad "$f — no role in .sdd/roles may write here"; fi
    bad=1
  done
  return $bad
}

case "$1" in
--xem)
  need_roles
  V="$(role_current "$ROOT")"
  if [ -z "$V" ]; then info "the role could not be inferred (no SDD_ROLE, no worktree marker, the branch matches no pattern). Set it: role.sh <role>"; exit 0; fi
  contract "$V"
  M="$(role_marker_file "$ROOT")"; [ -f "$M" ] && info "role marker: ${M#$ROOT/}"
  ;;
--worktree)
  need_roles; V="$2"; U="$3"; [ -n "$V" ] || usage; check_role "$V"
  P="$(role_branch "$V" "$ROOT")"
  [ -n "$P" ] || { bad "the role $V has no branch pattern ($V.nhanh is empty) — this role works in the main checkout (spec keeps main so that what it writes is shared truth, readable at once by the other roles)"; exit 1; }
  case "$P" in
    *\**) [ -n "$U" ] || { bad "the branch pattern $P needs a UC-###: role.sh --worktree $V UC-###"; exit 1; }
          BR="$(printf '%s' "$P" | sed "s#\*#$(printf '%s' "$U" | tr 'A-Z' 'a-z')#")";;
    *) BR="$P";;
  esac
  D="$(dirname "$ROOT")/$(basename "$ROOT")-$(printf '%s' "$V" | tr 'A-Z' 'a-z')${U:+-$(printf '%s' "$U" | tr 'A-Z' 'a-z')}"
  [ -e "$D" ] && { bad "$D already exists"; exit 1; }
  if git -C "$ROOT" show-ref --verify --quiet "refs/heads/$BR"; then git -C "$ROOT" worktree add -q "$D" "$BR" || exit 1
  else git -C "$ROOT" worktree add -q -b "$BR" "$D" || exit 1; fi
  printf '%s\n' "$V" > "$(role_marker_file "$D")"
  ok "worktree $D · branch $BR · role marker $V"
  info "the hooks in a worktree are the branch copy from when it was split — open a round with: git -C $D merge main"
  info "committing there: git commit --only -m '<type>(ID): …' -- <file> ; the hook adds the trailer 'Vai: $V'"
  info "the stash is NOT private to this worktree — 'git stash' here goes into the one list the whole repository shares, and it stays there after --don removes the worktree. Commit instead of stashing, or write down which entry is yours"
  ;;
--don)
  # 8.2.0 (P-48): the reverse of --worktree. Measured at runxops on 2026-09-24: 4 workspaces and 18 code/ · test/
  # branches of UC-016…030 were still there after close, and the owner found them, not a check. --worktree had no
  # opposite and the standard sequence in orchestrate §4 ended at /sdd-solo:close.
  #
  # It never forces. `git worktree remove` refuses a worktree with uncommitted or untracked files, and `git branch -d`
  # refuses a branch that is not merged — both refusals are kept and reported, because the thing being cleaned up is
  # the only copy of somebody work. There is no --force here, on purpose: a lane you cannot delete is a lane with
  # something in it, and that is a fact to look at, not an obstacle to get past.
  need_roles; U="$2"; shift 2 2>/dev/null || shift $#
  DRY=0
  for a in "$@"; do case "$a" in
    --dry-run) DRY=1;;
    # 8.6.0 (P-57): say it out loud rather than ignore it. A lane that will not delete is a lane with something in
    # it — the only copy of somebody work. That is a fact to look at, not an obstacle to get past.
    --force|-f) bad "role.sh --don has no --force, on purpose: git refuses to remove a worktree with uncommitted or untracked files, and that refusal is the point. Go and look at the lane, commit or throw the work away yourself, then run --don again"; exit 2;;
  esac; done
  case "$U" in UC-[0-9]*|CHG-[0-9]*) ;; *) bad "role.sh --don takes a UC-### (or CHG-###): role.sh --don UC-012 [--dry-run]"; exit 2;; esac
  LU="$(printf '%s' "$U" | tr 'A-Z' 'a-z')"
  N=0; LEFT=0
  for v in $(role_list "$ROOT"); do
    P="$(role_branch "$v" "$ROOT")"; [ -n "$P" ] || continue
    # A pattern with no `*` is one branch shared by every UC (spec keeps main) — cleaning "the lane of this UC"
    # must not delete it.
    case "$P" in *\**) ;; *) continue;; esac
    BR="$(printf '%s' "$P" | sed "s#\*#$LU#")"
    D="$(git -C "$ROOT" worktree list --porcelain 2>/dev/null | awk -v b="branch refs/heads/$BR" '/^worktree /{p=substr($0,10)} $0==b{print p; exit}')"
    HAS=0; git -C "$ROOT" show-ref --verify --quiet "refs/heads/$BR" && HAS=1
    [ -z "$D" ] && [ "$HAS" = 0 ] && continue
    N=$((N+1))
    if [ -n "$D" ]; then
      if [ "$DRY" = 1 ]; then info "would remove the worktree $D (role $v, branch $BR)"
      elif git -C "$ROOT" worktree remove "$D" 2>/dev/null; then ok "worktree removed: $D (role $v)"
      else bad "cannot remove the worktree $D — it has uncommitted or untracked files; look at it, commit or throw them away, then run --don again"; LEFT=$((LEFT+1)); continue; fi
    fi
    # The stash is ONE list for the whole repository, shared by every worktree — removing the worktree and the
    # branch leaves any stash made on that branch behind, invisible, and `git stash list` in the main checkout shows
    # it with a branch name that no longer exists. Name them and print the command; dropping a stash is not
    # recoverable, so --don never does it. (8.6.0, P-57)
    ST="$(git -C "$ROOT" stash list --format='%gd|%gs' 2>/dev/null | grep -E "\|(WIP on|On) $(printf '%s' "$BR" | sed 's/[.[\*^$]/\\&/g'):" || true)"
    if [ -n "$ST" ]; then
      warn "the lane $BR leaves $(printf '%s' "$ST" | grep -c .) stash entr$(printf '%s' "$ST" | grep -c . | sed 's/^1$/y/; s/^[02-9].*/ies/') behind — the stash list is shared by the whole repository, it does not go away with the worktree:"
      printf '%s\n' "$ST" | while IFS='|' read -r r m; do printf '      %s  %s\n' "$r" "$m"; done
      info "look at one:  git -C $ROOT stash show -p $(printf '%s' "$ST" | head -1 | cut -d'|' -f1)"
      info "drop it yourself when you are sure:  git -C $ROOT stash drop $(printf '%s' "$ST" | head -1 | cut -d'|' -f1)   (--don never drops a stash: it cannot be undone)"
    fi
    if [ "$HAS" = 1 ]; then
      if [ "$DRY" = 1 ]; then info "would delete the branch $BR (role $v)"
      elif git -C "$ROOT" branch -d "$BR" >/dev/null 2>&1; then ok "branch deleted: $BR (role $v, merged)"
      else warn "branch $BR kept — not merged into $(git -C "$ROOT" symbolic-ref --quiet --short HEAD 2>/dev/null). Merge it, or delete it yourself with: git branch -D $BR"; LEFT=$((LEFT+1)); fi
    fi
  done
  [ "$DRY" = 1 ] || git -C "$ROOT" worktree prune
  if [ "$N" = 0 ]; then info "$U has no lane to clean — no worktree and no <role>.nhanh branch of this UC"; exit 0; fi
  [ "$LEFT" != 0 ] && exit 1
  exit 0
  ;;
--ketqua)
  K="$2"; shift 2
  printf '%s' "$K" | grep -qE '^[a-z0-9][a-z0-9._-]{1,39}$' || { bad "the key '$K' — only [a-z0-9][a-z0-9._-]{1,39}, no spaces, no |"; exit 2; }
  KD="$(ketqua_dir "$ROOT")"; KF="$KD/$K.txt"
  if [ $# -eq 0 ]; then [ -f "$KF" ] && cat "$KF" || { info "there is no KETQUA for $K yet ($KF)"; exit 1; }; exit 0; fi
  KET=""; NEO=""; KIEM="-"; HOI="-"; CON="-"
  for a in "$@"; do case "$a" in ket=*) KET="${a#ket=}";; neo=*) NEO="${a#neo=}";; kiem=*) KIEM="${a#kiem=}";; hoi=*) HOI="${a#hoi=}";; con=*) CON="${a#con=}";; *) bad "cannot read '$a' (ket= neo= kiem= hoi= con=)"; exit 2;; esac; done
  case "$KET" in xong|chan|do) ;; *) bad "ket= must be xong · chan · do (got '$KET')"; exit 1;; esac
  if [ "$KET" = xong ]; then
    [ -n "$NEO" ] && [ "$NEO" != "-" ] || { bad "ket=xong requires neo= (a commit hash · the marker .sdd/gate/… · a file path) — time passing is not evidence"; exit 1; }
    if printf '%s' "$NEO" | grep -qE '^[0-9a-f]{7,40}$'; then
      git -C "$ROOT" cat-file -e "$NEO^{commit}" 2>/dev/null || { bad "neo=$NEO is not a real commit in this repo"; exit 1; }
    elif [ ! -e "$ROOT/$NEO" ]; then bad "neo=$NEO — not a hash and no such file/marker under $ROOT"; exit 1; fi
  fi
  [ "$KET" = chan ] && { [ -n "$HOI" ] && [ "$HOI" != "-" ] || { bad "ket=chan requires hoi=<ticket number | ASK-X#> — a block with no question is one nobody can clear"; exit 1; }; }
  mkdir -p "$KD"
  L="KETQUA key=$K ket=$KET neo=${NEO:--} kiem=$KIEM hoi=$HOI con=$CON vai=$(role_current "$ROOT") luc=$(date +%Y-%m-%dT%H:%M)"
  printf '%s\n' "$L" >> "$KF"
  printf '%s\n' "$L"
  info "written to ${KF} — send exactly the line above back to the coordinator (as the first line of the message)"
  ;;
--staged|--commit)
  [ -n "$RF" ] || exit 0
  [ -f "$(cd "$ROOT" && git rev-parse --git-path MERGE_HEAD)" ] && exit 0
  V="$(role_norm "$SDD_ROLE")"
  if [ -z "$V" ] && [ "$1" = --commit ] && [ -f "$2" ]; then V="$(grep -E "^($(kw c_role)): *[A-Za-z0-9_-]+ *\$" "$2" | head -1 | sed -E "s/^($(kw c_role)): *//; s/ *\$//")"; fi
  [ -z "$V" ] && V="$(role_current "$ROOT")"
  REQ="$(role_required "$ROOT")"
  if [ -z "$V" ]; then
    [ "$REQ" = moi ] && { bad "the role could not be inferred (vai_bat_buoc=moi): set SDD_ROLE, a 'Vai: <V>' trailer in the message, the worktree marker (role.sh <role>) or a branch matching a pattern"; exit 1; }
    exit 0
  fi
  role_known "$V" "$ROOT" || { bad "the role '$V' is not in .sdd/roles (vai=$(role_list "$ROOT"))"; [ "$REQ" != khong ] && exit 1; exit 0; }
  ST="${SDD_STAGED:-$(cd "$ROOT" && git diff --cached --name-only)}"
  if ! check_files "$V" <<EOS
$ST
EOS
  then
    if [ "$REQ" != khong ]; then bad "role $V: the commit touches outside its write area — blocked (vai_bat_buoc=$REQ)"; exit 1
    else warn "role $V: the commit touches outside its write area — a reminder only (vai_bat_buoc=khong; to block: vai_bat_buoc=nhanh-vai in .sdd/roles)"; fi
  fi
  # the Vai: trailer — the only channel git can record; `git log --grep '^Vai: '` measures how well it is followed
  if [ "$1" = --commit ] && [ -f "$2" ] && ! grep -qE "^($(kw c_role)): " "$2"; then printf '\n%s: %s\n' "$(kw_w c_role "$ROOT")" "$V" >> "$2"; fi
  exit 0
  ;;
--kiem-lich-su)
  need_roles; RANGE="${2:-HEAD~300..HEAD}"
  N=0; NONE=0; VIO=0; LIST=""
  # the role trailer reads BOTH sides (kw c_role) — git accepts only one key per %(trailers:key=…), so one atom per side,
  # and the value comes out after the ASCII prefix '##' to tell it apart from a --name-only file line
  TFMT=""; for k in $(kw c_role | tr '|' ' '); do TFMT="$TFMT%(trailers:key=$k,valueonly=true)"; done
  # per non-merge commit: the files touched + the Vai trailer if present → which role was allowed to write ALL of them
  while IFS= read -r line; do
    case "$line" in
      @@*) 
        if [ -n "$H" ]; then
          N=$((N+1)); OKR=""
          for v in $(role_list "$ROOT"); do
            allok=1; for f in $FILES; do role_allows "$v" "$f" "$ROOT" || { allok=0; break; }; done
            [ "$allok" = 1 ] && OKR="$OKR $v"
          done
          [ -z "$OKR" ] && { NONE=$((NONE+1)); LIST="$LIST
  $H $S"; }
          if [ -n "$TV" ]; then case " $OKR " in *" $TV "*) ;; *) VIO=$((VIO+1)); LIST="$LIST
  $H $S — declares Vai: $TV but that role may not write all of them";; esac; fi
        fi
        H="$(printf '%s' "$line" | cut -c3-9)"; S="$(printf '%s' "$line" | cut -c11- | cut -c1-70)"; TV=""; FILES="";;
      "##"*) TV="${line#\#\#}";;
      "") ;;
      *) FILES="$FILES $line";;
    esac
  done <<EOS
$(git -C "$ROOT" log --no-merges --format="@@%h %s%n##$TFMT" --name-only $RANGE 2>/dev/null)
@@
EOS
  echo "The .sdd/roles write-area rule run over $N commits ($RANGE)"
  printf '  %s commits no role was allowed to write in full (they would have been blocked with vai_bat_buoc on)\n' "$NONE"
  printf '  %s commits declaring a Vai: trailer for a role that may not write all of them\n' "$VIO"
  [ -n "$LIST" ] && printf '%s\n' "$LIST" | head -40
  exit 0
  ;;
--*) usage;;
*)
  need_roles; V="$1"; check_role "$V"
  if [ -z "$2" ]; then
    M="$(role_marker_file "$ROOT")"; printf '%s\n' "$V" > "$M"
    ok "role marker $V for the worktree $ROOT (${M#$ROOT/} — not in git)"
    contract "$V"; exit 0
  fi
  # ── the six-part brief from a ticket ──────────────────────────────────────────────────────────
  PF="$2"; LUOT="1"; shift 2
  while [ $# -gt 0 ]; do case "$1" in --luot) LUOT="$2"; shift 2;; *) shift;; esac; done
  [ -f "$PF" ] || { bad "role.sh <role> takes ONE TICKET FILE, not a free-form string — the expensive part of a brief is the anchor, and the anchor only exists in a ticket ('$PF' is not a file)"; exit 1; }
  export SDD_COMMIT="$(role_may_commit "$V" "$ROOT" && echo co || echo khong)"
  export SDD_HOIDAP="$(hoi_dap_file "$ROOT" | sed "s#^$ROOT/##")"
  export SDD_V="$V" SDD_VN="$(role_name "$V" "$ROOT")" SDD_DENY="$(role_deny "$V" "$ROOT")" SDD_CHECKS="$(role_checks "$V" "$ROOT")" SDD_BRANCH="$(role_branch "$V" "$ROOT")" SDD_LUOT="$LUOT" SDD_ROOT="$ROOT"
  # the reading pack: every ID on the ticket first line → a path through lib (no find/grep straight at specs/)
  HDR="$(grep -m1 -E '^###? *#[0-9]+' "$PF")"
  PK=""
  for id in $(printf '%s' "$HDR" | grep -oE '\b(UC|BR|CHG|RULE|ADR)-[0-9]+\b' | sort -u); do
    case "$id" in
      UC-*)  f="$(find_uc "$id" "$ROOT")"; [ -n "$f" ] && { PK="$PK ${f#$ROOT/}"; [ -f "$(dirname "$f")/design.md" ] && PK="$PK $(dirname "${f#$ROOT/}")/design.md"; };;
      BR-*)  f="$(br_file "$id" "$ROOT")"; [ -f "$f" ] && PK="$PK ${f#$ROOT/}";;
      CHG-*) d="$(find_chg "$id" "$ROOT")"; [ -n "$d" ] && PK="$PK ${d#$ROOT/}/proposal.md";;
      RULE-*) f="$(rule_file "$id" "$ROOT")"; [ -n "$f" ] && PK="$PK ${f#$ROOT/}:## $id";;
      ADR-*) f="$(adr_file "$id" "$ROOT")"; [ -n "$f" ] && PK="$PK ${f#$ROOT/}";;
    esac
  done
  export SDD_PK="$PK"
  node "$HERE/js/brief.mjs" "$PF"
  ;;
esac

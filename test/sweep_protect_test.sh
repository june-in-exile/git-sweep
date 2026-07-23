#!/usr/bin/env bash
#
# sweep_protect_test.sh — verify branch protection (--keep flag + sweep.protect
# config) inside throwaway repos. All branches are made ancestors of a local
# origin/main so classification never needs the network or gh.
# Run: ./test/sweep_protect_test.sh
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SWEEP="$ROOT/git-sweep"

pass=0; fail=0
ok()  { printf '  \033[32mok\033[0m   %s\n' "$1"; pass=$((pass+1)); }
bad() { printf '  \033[31mFAIL\033[0m %s\n' "$1"; fail=$((fail+1)); }

# A repo on `main` with dev/feat/chore all merged (same commit as origin/main).
new_repo() {
  local d; d="$(mktemp -d)"
  git -C "$d" init -q -b main
  git -C "$d" config user.email t@example.com
  git -C "$d" config user.name  tester
  git -C "$d" commit -q --allow-empty -m base
  git -C "$d" branch dev
  git -C "$d" branch feat
  git -C "$d" branch chore
  git -C "$d" update-ref refs/remotes/origin/main "$(git -C "$d" rev-parse HEAD)"
  printf '%s' "$d"
}

has_branch() { git -C "$1" rev-parse --verify --quiet "refs/heads/$2" >/dev/null; }

sweep() { ( cd "$1"; shift; "$SWEEP" "$@" >/dev/null 2>&1 ); }

echo "git-sweep branch protection"

# 1. sweep.protect config keeps a merged branch
d="$(new_repo)"
git -C "$d" config --add sweep.protect dev
sweep "$d" -y --no-fetch
has_branch "$d" dev && ok "sweep.protect dev keeps dev" || bad "sweep.protect dev keeps dev"
! has_branch "$d" feat && ok "unprotected feat is deleted" || bad "unprotected feat is deleted"
rm -rf "$d"

# 2. --keep flag keeps a merged branch for this run
d="$(new_repo)"
sweep "$d" -y --no-fetch --keep feat
has_branch "$d" feat && ok "--keep feat keeps feat" || bad "--keep feat keeps feat"
! has_branch "$d" dev && ok "un-kept dev is deleted" || bad "un-kept dev is deleted"
rm -rf "$d"

# 3. --keep accepts a comma-separated list
d="$(new_repo)"
sweep "$d" -y --no-fetch --keep dev,feat
has_branch "$d" dev  && ok "--keep dev,feat keeps dev"  || bad "--keep dev,feat keeps dev"
has_branch "$d" feat && ok "--keep dev,feat keeps feat" || bad "--keep dev,feat keeps feat"
! has_branch "$d" chore && ok "--keep list still deletes chore" || bad "--keep list still deletes chore"
rm -rf "$d"

# 4. config and --keep combine
d="$(new_repo)"
git -C "$d" config --add sweep.protect dev
sweep "$d" -y --no-fetch --keep feat
has_branch "$d" dev  && ok "config+flag keeps config's dev"  || bad "config+flag keeps config's dev"
has_branch "$d" feat && ok "config+flag keeps flag's feat"   || bad "config+flag keeps flag's feat"
! has_branch "$d" chore && ok "config+flag deletes chore"    || bad "config+flag deletes chore"
rm -rf "$d"

echo
printf 'passed %d, failed %d\n' "$pass" "$fail"
[ "$fail" -eq 0 ]

#!/usr/bin/env bash
#
# worktree_test.sh — a merged branch that is checked out in ANOTHER worktree
# cannot be deleted (git refuses). Verify git-sweep skips it with a clear
# message instead of a generic failure. No network / gh needed.
# Run: ./test/worktree_test.sh
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SWEEP="$ROOT/git-sweep"

pass=0; fail=0
ok()  { printf '  \033[32mok\033[0m   %s\n' "$1"; pass=$((pass+1)); }
bad() { printf '  \033[31mFAIL\033[0m %s\n' "$1"; fail=$((fail+1)); }

has_branch() { git -C "$1" rev-parse --verify --quiet "refs/heads/$2" >/dev/null; }

echo "git-sweep worktree handling"

# repo on `main`; `feat` is merged (same commit as origin/main) but checked out
# in a second worktree.
d="$(mktemp -d)"
git -C "$d" init -q -b main
git -C "$d" config user.email t@example.com
git -C "$d" config user.name  tester
git -C "$d" commit -q --allow-empty -m base
git -C "$d" branch feat
git -C "$d" branch chore
git -C "$d" update-ref refs/remotes/origin/main "$(git -C "$d" rev-parse HEAD)"

wt="$(mktemp -d)/wt"
git -C "$d" worktree add -q "$wt" feat

out="$( cd "$d"; "$SWEEP" -y --no-fetch 2>&1 )"

has_branch "$d" feat && ok "worktree branch feat is NOT deleted" \
  || bad "worktree branch feat is NOT deleted"
printf '%s' "$out" | grep -qi worktree && ok "output explains the worktree skip" \
  || bad "output explains the worktree skip"
! has_branch "$d" chore && ok "free merged branch chore is still deleted" \
  || bad "free merged branch chore is still deleted"

git -C "$d" worktree remove --force "$wt" 2>/dev/null || true
rm -rf "$d" "$(dirname "$wt")"

echo
printf 'passed %d, failed %d\n' "$pass" "$fail"
[ "$fail" -eq 0 ]

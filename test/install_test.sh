#!/usr/bin/env bash
#
# install_test.sh — exercise install.sh inside a throwaway $HOME so the real
# shell config is never touched. install.sh puts the repo dir on PATH (no
# symlink), so we assert the rc file gains a line pointing at the repo.
# Run: ./test/install_test.sh
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INSTALL="$ROOT/install.sh"

pass=0; fail=0
ok()  { printf '  \033[32mok\033[0m   %s\n' "$1"; pass=$((pass+1)); }
bad() { printf '  \033[31mFAIL\033[0m %s\n' "$1"; fail=$((fail+1)); }

# PATH with the repo dir stripped out — simulates a machine where git-sweep is
# not installed yet, even when these tests run from a shell that already has it.
CLEAN_PATH="$(printf '%s' "$PATH" | tr ':' '\n' | grep -vFx "$ROOT" | paste -sd: -)"

# Run install.sh with a fresh fake HOME (so the repo dir is not yet on PATH).
# Args pass straight to install.sh. Echoes the temp HOME path.
run_install() {
  local home; home="$(mktemp -d)"
  HOME="$home" SHELL="/bin/zsh" PATH="$CLEAN_PATH" \
    "$INSTALL" "$@" </dev/null >/dev/null 2>&1 || true
  printf '%s' "$home"
}

# Count rc lines that add the repo dir to PATH.
count_repo_line() { grep -cF "$ROOT" "$1" 2>/dev/null || printf '0'; }

echo "install.sh"

# 1. --yes adds a PATH line pointing at the repo to ~/.zshrc
h="$(run_install --yes)"
if [ "$(count_repo_line "$h/.zshrc")" -eq 1 ] && grep -qF 'export PATH' "$h/.zshrc"; then
  ok "--yes adds a repo PATH line to ~/.zshrc"
else
  bad "--yes adds a repo PATH line to ~/.zshrc"
fi

# 2. --yes is idempotent (second run does not duplicate the line)
HOME="$h" SHELL="/bin/zsh" PATH="$CLEAN_PATH" "$INSTALL" --yes </dev/null >/dev/null 2>&1 || true
if [ "$(count_repo_line "$h/.zshrc")" -eq 1 ]; then
  ok "--yes twice leaves a single PATH line"
else
  bad "--yes twice leaves a single PATH line"
fi
rm -rf "$h"

# 3. the repo's git-sweep is left executable
h="$(run_install --yes)"
if [ -x "$ROOT/git-sweep" ]; then
  ok "git-sweep is executable"
else
  bad "git-sweep is executable"
fi
rm -rf "$h"

# 4. non-interactive without --yes must NOT modify ~/.zshrc
h="$(run_install)"
if [ ! -f "$h/.zshrc" ] || [ "$(count_repo_line "$h/.zshrc")" -eq 0 ]; then
  ok "no --yes (non-interactive) leaves ~/.zshrc untouched"
else
  bad "no --yes (non-interactive) leaves ~/.zshrc untouched"
fi
rm -rf "$h"

# 5. when the repo dir is already on PATH, ~/.zshrc is not modified
h="$(mktemp -d)"
HOME="$h" SHELL="/bin/zsh" PATH="$ROOT:$PATH" \
  "$INSTALL" --yes </dev/null >/dev/null 2>&1 || true
if [ ! -f "$h/.zshrc" ] || [ "$(count_repo_line "$h/.zshrc")" -eq 0 ]; then
  ok "already-on-PATH skips modifying ~/.zshrc"
else
  bad "already-on-PATH skips modifying ~/.zshrc"
fi
rm -rf "$h"

echo
printf 'passed %d, failed %d\n' "$pass" "$fail"
[ "$fail" -eq 0 ]

#!/usr/bin/env bash
#
# install.sh — symlink git-sweep into ~/bin so `git sweep` works everywhere.

set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)/git-sweep"
DEST="$HOME/bin/git-sweep"

mkdir -p "$HOME/bin"
ln -sf "$SRC" "$DEST"
chmod +x "$SRC"
echo "linked $DEST -> $SRC"

if command -v jq >/dev/null 2>&1; then :; else echo "warning: jq not found — install with 'brew install jq'"; fi
if command -v gh >/dev/null 2>&1; then :; else echo "warning: gh not found — install from https://cli.github.com"; fi

case ":$PATH:" in
  *":$HOME/bin:"*) echo "~/bin is on your PATH — run: git sweep" ;;
  *) echo 'add ~/bin to your PATH: echo '\''export PATH="$HOME/bin:$PATH"'\'' >> ~/.zshrc && source ~/.zshrc' ;;
esac

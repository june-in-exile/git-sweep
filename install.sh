#!/usr/bin/env bash
#
# install.sh — put this repo on your PATH so `git sweep` runs the script here
# directly (no symlink). git treats any `git-sweep` on PATH as `git sweep`.
#
# Usage:
#   ./install.sh        # prompt before touching your shell config
#   ./install.sh --yes  # add the repo to PATH without prompting (-y works too)

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

ASSUME_YES=0
case "${1:-}" in
  -y|--yes) ASSUME_YES=1 ;;
  "") ;;
  *) echo "unknown option: $1 (use --yes)" >&2; exit 1 ;;
esac

chmod +x "$REPO_DIR/git-sweep"

command -v jq >/dev/null 2>&1 || echo "warning: jq not found — install with 'brew install jq'"
command -v gh >/dev/null 2>&1 || echo "warning: gh not found — install from https://cli.github.com"

# Write $HOME as a literal in the rc file when the repo lives under it — keeps
# the line readable and portable rather than baking in an absolute path.
case "$REPO_DIR" in
  "$HOME"/*) PATH_ENTRY="\$HOME/${REPO_DIR#"$HOME"/}" ;;
  *)         PATH_ENTRY="$REPO_DIR" ;;
esac
PATH_LINE="export PATH=\"$PATH_ENTRY:\$PATH\""

# The shell rc file to add PATH to, based on the user's login shell.
rc_file() {
  case "${SHELL##*/}" in
    zsh)  echo "$HOME/.zshrc" ;;
    bash) [ -f "$HOME/.bash_profile" ] && echo "$HOME/.bash_profile" || echo "$HOME/.bashrc" ;;
    *)    echo "$HOME/.profile" ;;
  esac
}

# Already active in this shell — nothing to do.
case ":$PATH:" in
  *":$REPO_DIR:"*)
    echo "$REPO_DIR is already on your PATH — run: git sweep"
    exit 0 ;;
esac

RC="$(rc_file)"

# Configured in the rc file but not loaded into this shell yet.
if [ -f "$RC" ] && grep -qF "$PATH_LINE" "$RC"; then
  echo "PATH is set in $RC but not loaded yet — run: source $RC"
  exit 0
fi

# Not on PATH and not in the rc file — offer to add it.
if [ "$ASSUME_YES" -eq 1 ]; then
  reply="y"
elif [ -t 0 ]; then
  printf 'add %s to your PATH in %s? [Y/n] ' "$REPO_DIR" "$RC"
  read -r reply || reply=""
else
  reply="skip"
fi

case "$reply" in
  ""|[Yy]*)
    printf '\n%s\n' "$PATH_LINE" >> "$RC"
    echo "added the repo to $RC — run: source $RC   (then: git sweep)"
    ;;
  *)
    echo "skipped — add this line to $RC to enable git sweep:"
    echo "  $PATH_LINE"
    echo "then: source $RC"
    ;;
esac

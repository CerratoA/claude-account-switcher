#!/usr/bin/env bash
# Install claude-acct to ~/.local/bin (or a directory of your choice).
#
# Usage:
#   ./install.sh             # symlinks to ~/.local/bin/claude-acct
#   PREFIX=/usr/local ./install.sh   # install to /usr/local/bin (may need sudo)

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SOURCE="$SCRIPT_DIR/claude-acct"
PREFIX="${PREFIX:-$HOME/.local}"
TARGET_DIR="$PREFIX/bin"
TARGET="$TARGET_DIR/claude-acct"

[[ -f "$SOURCE" ]] || {
  printf 'error: %s not found\n' "$SOURCE" >&2
  exit 1
}

mkdir -p "$TARGET_DIR"
chmod +x "$SOURCE"
ln -sf "$SOURCE" "$TARGET"

printf 'installed: %s -> %s\n' "$TARGET" "$SOURCE"

case ":$PATH:" in
  *":$TARGET_DIR:"*) ;;
  *)
    printf '\nwarning: %s is not on your PATH\n' "$TARGET_DIR" >&2
    # shellcheck disable=SC2016 # $PATH is intentionally literal — user copies this line into their shell rc
    printf 'add this to your shell rc:\n  export PATH="%s:$PATH"\n' "$TARGET_DIR" >&2
    ;;
esac

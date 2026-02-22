#!/usr/bin/env bash
# Install git hooks so installed files stay in sync after git pull.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOKS_SRC="$REPO_ROOT/hooks"
HOOKS_DEST="$REPO_ROOT/.git/hooks"

cp "$HOOKS_SRC/post-merge" "$HOOKS_DEST/post-merge"
chmod +x "$HOOKS_DEST/post-merge"
echo "Installed post-merge hook. Files will sync to install locations on each git pull."

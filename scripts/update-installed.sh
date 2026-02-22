#!/usr/bin/env bash
# Sync repo files to install locations. Safe to run after git pull.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT_SRC="$REPO_ROOT/scripts/hyperdeck_to_r2.sh"
ENV_SRC="$REPO_ROOT/config/example.env"
PLIST_SRC="$REPO_ROOT/launchd/com.hopecc.hyperdeck-to-r2.plist"

echo "Updating installed files from $REPO_ROOT ..."

# Script → /usr/local/bin (requires sudo)
sudo cp "$SCRIPT_SRC" /usr/local/bin/hyperdeck_to_r2.sh
sudo chmod +x /usr/local/bin/hyperdeck_to_r2.sh
echo "  ✓ /usr/local/bin/hyperdeck_to_r2.sh"

# Env template → .env.example only (never overwrite user's .env)
sudo mkdir -p /usr/local/etc
sudo cp "$ENV_SRC" /usr/local/etc/hyperdeck-to-r2.env.example
echo "  ✓ /usr/local/etc/hyperdeck-to-r2.env.example (template; merge new vars into hyperdeck-to-r2.env if needed)"

# Plist → LaunchAgents
mkdir -p "$HOME/Library/LaunchAgents"
cp "$PLIST_SRC" "$HOME/Library/LaunchAgents/"
echo "  ✓ $HOME/Library/LaunchAgents/com.hopecc.hyperdeck-to-r2.plist"

# Reload launchd to pick up plist changes
launchctl unload -w "$HOME/Library/LaunchAgents/com.hopecc.hyperdeck-to-r2.plist" 2>/dev/null || true
launchctl load -w "$HOME/Library/LaunchAgents/com.hopecc.hyperdeck-to-r2.plist"
echo "  ✓ launchd agent reloaded"

echo "Done."

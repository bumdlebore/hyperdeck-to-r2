#!/usr/bin/env bash
set -euo pipefail

# Load env if present (keeps host paths, destination, etc out of the script)
ENV_FILE="${ENV_FILE:-/usr/local/etc/hyperdeck-to-r2.env}"
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

: "${HYPERDECK_HOST:?Missing HYPERDECK_HOST}"
: "${HYPERDECK_USER:=guest}"
: "${RCLONE_BIN:=/opt/homebrew/bin/rclone}"
: "${R2_DEST:=r2:sermons/dt/raw_recordings}"
: "${LOG:=/var/log/hyperdeck-to-r2/rclone.log}"
mkdir -p "$(dirname "$LOG")"

# Only run and transfer on Sunday (files recorded on Sunday)
[[ $(date +%u) -eq 7 ]] || { echo "Today is not Sunday, skipping." >> "$LOG"; exit 0; }

# rclone FTP backend needs an obscured pass value even if HyperDeck ignores it
FTP_PASS_OBS="$("$RCLONE_BIN" obscure "${FTP_DUMMY_PASS:-dummy}")"

# Order matters: first matching rule wins. Exclude resource forks, include mov/mp4, then exclude rest.
FILTER_ARGS=( --filter "- ._*" --filter "+ *.mov" --filter "+ *.mp4" --filter "- *" )

# Only transfer files recorded today (Sunday) - modified since midnight.
# Set DISABLE_MAX_AGE=1 if HyperDeck FTP doesn't report modification times (common);
# then Sunday-only behavior relies on the launchd schedule.
MAX_AGE_ARGS=()
if [[ "${DISABLE_MAX_AGE:-0}" != "1" ]]; then
  SECONDS_SINCE_MIDNIGHT=$(($(date +%s) - $(date -v0H -v0M -v0S +%s)))
  MAX_AGE_ARGS=( --max-age "${SECONDS_SINCE_MIDNIGHT}s" )
fi

COMMON_ARGS=(
  --ignore-existing
  "${MAX_AGE_ARGS[@]}"
  --transfers 1
  --checkers 2
  --retries 10
  --retries-sleep 10s
  --timeout 20m
  --contimeout 30s
  --ftp-concurrency 1
  --log-file "$LOG"
  --stats 30s
)

copy_card () {
  local card="$1"
  echo "==== $(date) | Checking ${card} ====" >> "$LOG"

  "$RCLONE_BIN" copy ":ftp:/${card}" "${R2_DEST}/${card}" \
    --ftp-host "$HYPERDECK_HOST" \
    --ftp-user "$HYPERDECK_USER" \
    --ftp-pass "$FTP_PASS_OBS" \
    "${FILTER_ARGS[@]}" \
    "${COMMON_ARGS[@]}"
}

copy_card "sd1" || echo "WARN: sd1 copy failed at $(date)" >> "$LOG"
copy_card "sd2" || echo "WARN: sd2 copy failed at $(date)" >> "$LOG"

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

# rclone FTP backend needs an obscured pass value even if HyperDeck ignores it
FTP_PASS_OBS="$("$RCLONE_BIN" obscure "${FTP_DUMMY_PASS:-dummy}")"

# Order matters: last matching rule wins. Exclude all, then include mov/mp4.
FILTER_ARGS=( --filter "- *" --filter "+ *.mov" --filter "+ *.mp4" )

COMMON_ARGS=(
  --ignore-existing
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

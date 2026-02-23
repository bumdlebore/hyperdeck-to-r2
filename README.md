# HyperDeck → Cloudflare R2 Automation

Uploads new HyperDeck recordings from both SD cards (`sd1` + `sd2`) to
Cloudflare R2 on a schedule using rclone.

Destination path:

-   `r2:sermons/dt/raw_recordings/sd1`
-   `r2:sermons/dt/raw_recordings/sd2`

This runs safely in upload-only mode and never deletes anything from R2.

------------------------------------------------------------------------

## Requirements

-   macOS (Apple Silicon tested)
-   Homebrew
-   rclone installed
-   rclone configured with an `r2:` remote (Cloudflare R2)
-   HyperDeck reachable via FTP on the network

------------------------------------------------------------------------

## Install

### 1) Install rclone

```bash
brew install rclone
```

------------------------------------------------------------------------

### 2) Copy the script into place

```bash
sudo cp scripts/hyperdeck_to_r2.sh /usr/local/bin/hyperdeck_to_r2.sh
sudo chmod +x /usr/local/bin/hyperdeck_to_r2.sh
```

------------------------------------------------------------------------

### 3) Create environment config

```bash
sudo mkdir -p /usr/local/etc
sudo cp config/example.env /usr/local/etc/hyperdeck-to-r2.env
sudo nano /usr/local/etc/hyperdeck-to-r2.env
```

Edit values as needed (HyperDeck IP, destination path, etc).

------------------------------------------------------------------------

### 4) Create log directory

```bash
sudo mkdir -p /var/log/hyperdeck-to-r2
sudo chown $(whoami) /var/log/hyperdeck-to-r2
```

------------------------------------------------------------------------

### 5) Install launchd agent

```bash
cp launchd/com.hopecc.hyperdeck-to-r2.plist ~/Library/LaunchAgents/

launchctl unload -w ~/Library/LaunchAgents/com.hopecc.hyperdeck-to-r2.plist 2>/dev/null || true
launchctl load -w ~/Library/LaunchAgents/com.hopecc.hyperdeck-to-r2.plist
```

------------------------------------------------------------------------

### 6) Install git hook (optional, keeps installed files in sync on git pull)

```bash
./scripts/install-hooks.sh
```

After this, every `git pull` will copy the script, env template, and plist to their install locations and reload the launchd agent. Your `hyperdeck-to-r2.env` is never overwritten; new variables from `example.env` are written to `hyperdeck-to-r2.env.example` for you to merge if needed.

------------------------------------------------------------------------

## Test Manually

Run once to confirm everything works (on a Sunday; on other days the script exits without transferring):

```bash
/usr/local/bin/hyperdeck_to_r2.sh
```

View logs:

```bash
tail -n 100 /var/log/hyperdeck-to-r2/rclone.log
```

------------------------------------------------------------------------

## How It Works

-   Connects to HyperDeck via FTP
-   Checks both `sd1` and `sd2`
-   Only transfers files recorded on Sunday (by modification time)
-   Uploads only new `.mov` and `.mp4` files
-   Uses `--ignore-existing` to prevent re-uploads
-   Never deletes anything from R2
-   Runs every 5 minutes on Sundays between 10am and 2pm via launchd
-   If files aren't transferring, add `DISABLE_MAX_AGE="1"` to your env—HyperDeck FTP often doesn't report modification times

------------------------------------------------------------------------

## Updating After Pull

If you installed the git hook (step 6), updates run automatically on `git pull`. To sync manually:

```bash
./scripts/update-installed.sh
```

------------------------------------------------------------------------

## Changing File Filters

In `hyperdeck_to_r2.sh`, modify:

```bash
FILTER_ARGS=( --filter "+ *.mov" --filter "+ *.mp4" --filter "- *" )
```

Add extensions if needed (e.g. `.mxf`).

------------------------------------------------------------------------

## Logs

All logs are in `/var/log/hyperdeck-to-r2/`:

-   `rclone.log` – rclone copy output
-   `hyperdeck_to_r2.stdout.log` – script stdout
-   `hyperdeck_to_r2.stderr.log` – script stderr

------------------------------------------------------------------------

## Notes

-   The FTP password is a dummy value to satisfy rclone's FTP backend.
-   Cloudflare R2 credentials are stored in rclone's config, not in this
    repo.
-   Script uses `rclone copy` (upload-only) rather than `sync` for
    safety.
-   Safe to run frequently; only new files upload.

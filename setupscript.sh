#!/usr/bin/env bash
set -Eeuo pipefail
BASE="/home/avi/backups"
MANIFEST="$BASE/backup-paths.sh"
BACKUP_ROOT="/home/avi/backups"
DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true
[[ -f "$MANIFEST" ]] || { echo "ERROR: manifest not found"; exit 1; }
[[ -d "$BACKUP_ROOT" ]] || { echo "ERROR: backup directory not found"; exit 1; }
count=0; skipped=0; failed=0
while IFS="|" read -r source destination; do
    [[ -z "${source// }" || "$source" == \#* || -z "${destination// }" ]] && continue
    [[ "$destination" == "$BACKUP_ROOT"/* ]] || { echo "ERROR: invalid backup destination: $destination"; failed=$((failed+1)); continue; }
    if [[ ! -e "$destination" && ! -L "$destination" ]]; then echo "SKIP  $destination"; skipped=$((skipped+1)); continue; fi
    echo "RESTORE $destination -> $source"
    if [[ "$DRY_RUN" == true ]]; then count=$((count+1)); continue; fi
    if [[ "$source" == /etc/* ]]; then sudo mkdir -p "$(dirname "$source")"; sudo rm -rf "$source"; sudo cp -a "$destination" "$source"; else mkdir -p "$(dirname "$source")"; rm -rf "$source"; cp -a "$destination" "$source"; fi
    count=$((count+1))
done < "$MANIFEST"
systemctl --user daemon-reload 2>/dev/null || true
echo "Restored: $count | Skipped: $skipped | Failed: $failed"
(( failed == 0 ))

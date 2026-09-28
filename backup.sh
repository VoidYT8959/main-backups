#!/usr/bin/env bash
set -Eeuo pipefail
BASE="/home/avi/backups"
MANIFEST="$BASE/backup-paths.sh"
BACKUP_ROOT="/home/avi/backups"
DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true
[[ -f "$MANIFEST" ]] || { echo "ERROR: manifest not found"; exit 1; }
mkdir -p "$BACKUP_ROOT"
count=0; skipped=0; failed=0
while IFS="|" read -r source destination; do
    [[ -z "${source// }" || "$source" == \#* || -z "${destination// }" ]] && continue
    [[ "$destination" == "$BACKUP_ROOT"/* ]] || { echo "ERROR: destination outside backup root: $destination"; failed=$((failed+1)); continue; }
    [[ "$source" == "$BACKUP_ROOT" || "$source" == "$BACKUP_ROOT"/* ]] && { echo "ERROR: recursive backup source: $source"; failed=$((failed+1)); continue; }
    if [[ ! -e "$source" && ! -L "$source" ]]; then echo "SKIP  $source"; skipped=$((skipped+1)); continue; fi
    echo "BACKUP $source -> $destination"
    if [[ "$DRY_RUN" == true ]]; then count=$((count+1)); continue; fi
    mkdir -p "$(dirname "$destination")"
    rm -rf "$destination"
    if [[ "$source" == /etc/* ]]; then sudo cp -a "$source" "$destination"; sudo chown -R "$USER:$USER" "$destination"; else cp -a "$source" "$destination"; fi
    count=$((count+1))
done < "$MANIFEST"
echo "Completed: $count | Skipped: $skipped | Failed: $failed"
(( failed == 0 ))

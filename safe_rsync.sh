#!/usr/bin/env bash

# Usage: safe-rsync.sh SRC DEST
# Example: safe-rsync.sh /data/src/ /data/dest/

set -u  # fail on unset vars
# don't use `set -e` here, we want to handle rsync's exit code ourselves

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 SRC DEST"
    exit 1
fi

SRC="$1"
DEST="$2"

# trailing slash behavior is up to you; keep it as passed-in
ts=$(date +%Y%m%d_%H%M%S)
LOG="/tmp/rsync_${ts}.log"
TMPDIR=$(mktemp -d "/tmp/rsync_check_${ts}_XXXX")

echo "Running rsync..."
echo "  From: $SRC"
echo "  To:   $DEST"
echo "  Log:  $LOG"
echo ""

# run rsync, log output, capture exit status even with tee
rsync -avh --partial --info=progress2 "$SRC" "$DEST" 2>&1 | tee "$LOG"
status=${PIPESTATUS[0]}

echo ""
echo "rsync finished with exit code: $status"

if [ "$status" -eq 0 ]; then
    echo "SUCCESS: all files transferred with no reported errors."
    # clean up tmp dir; keep the log because it may be useful
    rm -rf "$TMPDIR"
    exit 0
fi

echo "WARNING: rsync reported problems. Checking for missing files..."
echo "Working directory for checks: $TMPDIR"

# build file lists for source and destination
(
    cd "$SRC" || exit 1
    find . -type f -print | sort > "$TMPDIR/src_files.txt"
)

(
    cd "$DEST" || exit 1
    find . -type f -print | sort > "$TMPDIR/dest_files.txt"
)

# files present in source but not in destination
comm -23 "$TMPDIR/src_files.txt" "$TMPDIR/dest_files.txt" > "$TMPDIR/missing_files.txt"

if [ -s "$TMPDIR/missing_files.txt" ]; then
    count=$(wc -l < "$TMPDIR/missing_files.txt")
    echo ""
    echo "INCOMPLETE TRANSFER: $count file(s) are present in source but missing in destination."
    echo "Full list: $TMPDIR/missing_files.txt"
    echo ""
    echo "First few missing files:"
    head -n 30 "$TMPDIR/missing_files.txt"
    if [ "$count" -gt 30 ]; then
        echo "(... and $((count - 30)) more; see $TMPDIR/missing_files.txt)"
    fi
else
    echo ""
    echo "No missing files found when comparing trees."
    echo "Errors may be about permissions, IO, or files that appeared/disappeared during transfer."
fi

echo ""
echo "rsync log: $LOG"
exit "$status"

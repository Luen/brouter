#!/bin/bash

# BRouter Docker entrypoint script
# Starts cron daemon and then runs the server

set -e

# Create log directory
mkdir -p /var/log

# Create a lock file to prevent duplicate execution
LOCK_FILE="/tmp/brouter-entrypoint.lock"
LOCK_TIMEOUT=30  # Maximum seconds to wait for lock

if [ -f "$LOCK_FILE" ]; then
    OLD_PID=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
    # Check if the process that created the lock is still running
    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
        echo "Entrypoint already running (PID: $OLD_PID), waiting for lock to be released..."
        WAIT_COUNT=0
        while [ -f "$LOCK_FILE" ] && [ $WAIT_COUNT -lt $LOCK_TIMEOUT ]; do
            sleep 1
            WAIT_COUNT=$((WAIT_COUNT + 1))
            # Re-check if the process is still running
            if [ -n "$OLD_PID" ] && ! kill -0 "$OLD_PID" 2>/dev/null; then
                echo "Previous entrypoint process (PID: $OLD_PID) is no longer running, removing stale lock..."
                rm -f "$LOCK_FILE"
                break
            fi
        done
        # If lock still exists after timeout, remove it (stale lock)
        if [ -f "$LOCK_FILE" ]; then
            echo "Lock timeout reached, removing stale lock file..."
            rm -f "$LOCK_FILE"
        fi
    else
        echo "Removing stale lock file (process $OLD_PID not running)..."
        rm -f "$LOCK_FILE"
    fi
fi

# Create lock file
echo $$ > "$LOCK_FILE"

# Function to cleanup lock file on exit
cleanup() {
    rm -f "$LOCK_FILE"
    exit 0
}

# Set trap to cleanup on script exit
trap cleanup EXIT INT TERM

# Create cron jobs directly
echo "Creating cron jobs..."
(cat << 'EOF'
# BRouter segments download cron job
# Run every Sunday at 2:00 AM
0 2 * * 0 /bin/download_segments.sh
EOF
) | crontab -

# Start cron daemon in background
echo "Starting cron daemon..."
cron

# Wait a moment for cron to start
sleep 3

# Check if cron is running (using ps instead of pgrep)
if ps aux | grep -v grep | grep cron > /dev/null; then
    echo "Cron daemon started successfully"
    echo "Cron jobs configured:"
    crontab -l
else
    echo "Warning: Cron daemon failed to start"
    echo "Attempting to start cron manually..."
    service cron start || echo "Manual start failed"
fi

# Run initial download in background (with 2-minute delay)
echo "Scheduling initial segment download in 2 minutes..."
(sleep 120 && /bin/download_segments.sh) &

# Run the original server command
echo "Starting BRouter server..."
echo "Command: $@"
echo "Working directory: $(pwd)"
echo "Java version:"
java -version 2>&1 || echo "Java not found in PATH"

# Execute the server command
exec "$@"

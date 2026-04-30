#!/bin/bash

out_dir="/segments4"
profiles_dir="/profiles2"
log_file="/var/log/brouter-download.log"
lookup_url="http://brouter.de/brouter/segments4/lookups.dat"
lookup_file="$profiles_dir/lookups.dat"

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$log_file"
}

log "Starting BRouter segments download"

mkdir -p "$out_dir"
mkdir -p "$profiles_dir"

# Update lookups.dat first so profile metadata stays in sync with downloaded rd5 files.
tmp_lookup_file="${lookup_file}.tmp"
if curl -fsS "$lookup_url" --output "$tmp_lookup_file"; then
    if [ -f "$tmp_lookup_file" ] && [ -s "$tmp_lookup_file" ]; then
        if [ -f "$lookup_file" ]; then
            old_lookup_version=$(grep -m1 '^---lookupversion:' "$lookup_file" | cut -d: -f2 | tr -d '[:space:]')
        else
            old_lookup_version="none"
        fi
        new_lookup_version=$(grep -m1 '^---lookupversion:' "$tmp_lookup_file" | cut -d: -f2 | tr -d '[:space:]')
        mv -f "$tmp_lookup_file" "$lookup_file"
        log "Updated lookups.dat (lookupversion: ${old_lookup_version} -> ${new_lookup_version:-unknown})"
    else
        rm -f "$tmp_lookup_file"
        log "Failed to update lookups.dat (empty download)"
    fi
else
    rm -f "$tmp_lookup_file"
    log "Failed to download lookups.dat from $lookup_url"
fi

# Get list of .rd5 files from the directory listing
curl http://brouter.de/brouter/segments4/ --silent | grep "[EW][0-9]*_[NS][0-9]*\.rd5" -o | uniq > segments

log "Found $(wc -l < segments) segments to download"

SECONDS=0

# Download segments with parallel processing, only if they don't exist or have changed
<segments xargs -I{} -P8 sh -c "
    filename={}
    local_file=\"$out_dir/\$filename\"
    remote_url=\"http://brouter.de/brouter/segments4/\$filename\"
    log_file=\"$log_file\"
    
    # Simple log function for subshell
    log() {
        echo \"\$(date '+%Y-%m-%d %H:%M:%S') - \$1\" | tee -a \"\$log_file\"
    }
    
    # Check if file exists and get its size
    if [ -f \"\$local_file\" ]; then
        local_size=\$(stat -c%s \"\$local_file\" 2>/dev/null || echo \"0\")
    else
        local_size=\"0\"
    fi
    
    # Get remote file size using HEAD request
    remote_size=\$(curl -sI \"\$remote_url\" | grep -i content-length | awk '{print \$2}' | tr -d \"\\r\")
    
    # If remote size is empty or we can't get it, assume we need to download
    if [ -z \"\$remote_size\" ] || [ \"\$remote_size\" = \"0\" ]; then
        remote_size=\"unknown\"
    fi
    
    # Download if file doesn't exist or sizes differ
    if [ ! -f \"\$local_file\" ] || [ \"\$local_size\" != \"\$remote_size\" ]; then
        log \"Downloading \$filename (local: \${local_size}, remote: \${remote_size})\"
        if curl -s \"\$remote_url\" --remote-time --output \"\$local_file\"; then
            log \"Successfully downloaded \$filename\"
        else
            log \"Failed to download \$filename\"
        fi
    else
        log \"Skipping \$filename (already up to date)\"
    fi
"

log "All segments downloaded in ${SECONDS}s"

rm segments

log "BRouter segments download finished"

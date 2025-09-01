#!/bin/bash

out_dir="/segments4"
log_file="/var/log/brouter-download.log"

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$log_file"
}

log "Starting BRouter segments download"

mkdir -p $out_dir

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

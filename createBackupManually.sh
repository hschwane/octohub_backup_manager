#!/bin/bash

usage() {
    echo "Usage: $0 <backup_path> <main_drive (optional)>"
    exit 1
}

if [ "$#" -lt 1 ]; then
    echo "Error: At least one positional argument is required."
    usage
fi

backup_path=$1
main_drive=${2:-"/dev/disk/by-id/e838b373-87da-4135-bf99-65d47d29192b"}
backup_file="${backup_path}/octohub_backup_$(date +"%Y-%m-%d_%H-%M-%S").gz"
size=$(blockdev --getsize64 $main_drive)
sudo dd if=$main_drive bs=16M conv=noerror,sparse | pv -s $size -F '%t %b %a %e %p' | pigz -c > $backup_file && sync

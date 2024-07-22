#!/bin/bash

usage() {
    echo "Usage: $0 <backup_file> <main_drive (optional)>"
    exit 1
}

if [ "$#" -lt 1 ]; then
    echo "Error: At least one positional argument is required."
    usage
fi

backup_file=$1
main_drive=${2:-"/dev/disk/by-id/e838b373-87da-4135-bf99-65d47d29192b"}
size=$(stat -c%s "$backup_file")
pigz -cdk $backup_file | pv -s $size -F '%t %b %a %e %p' | sudo dd of=$main_drive bs=16M && sync


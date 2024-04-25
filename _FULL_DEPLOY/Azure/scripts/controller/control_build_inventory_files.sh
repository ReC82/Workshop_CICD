#!/bin/bash

# Check if an argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <vm_list>"
    exit 1
fi

vms="$1"
filename="$2"
invfile="/home/rooty/inventory.$2.host"
rm -f "$invfile"


echo "[$2]" >> "$invfile"
echo "$1" >> "$invfile"


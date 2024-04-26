#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <vm_list> <vms_ips> <hosts_categories>"
    exit 1
fi

filename="$1"
vms_ips="$2" # IPs in the format: "10.0.1.1;10.0.1.2#10.0.1.3;10.0.1.4#10.0.1.5#10.0.1.6"
hosts_categories="$3" # Categories for Ansible, e.g., "web;database;api"

invfile="/home/rooty/inventory.${filename}.host"
rm -f "$invfile"

# Split the categories into an array
IFS=';' read -ra categories <<< "$hosts_categories"

# Split the IPs into an array based on '#'
IFS=';' read -ra ip_groups <<< "$vms_ips"

# Ensure we have the same number of categories and IP groups
if [ "${#categories[@]}" -ne "${#ip_groups[@]}" ]; then
    echo "Error: The number of categories(${#categories[@]}) must match the number of IP groups(${#ip_groups[@]})."
    exit 1
fi

for i in "${!categories[@]}"; do
  category="${categories[$i]}"
  ips="${ip_groups[$i]}"

  # Write the category header
  echo "[$category]" >> "$invfile"

  # Split IPs by ';' and write each one on a new line
  IFS='#' read -r -a ip_list <<< "$ips"
  for ip in "${ip_list[@]}"; do
    echo "$ip" >> "$invfile"
  done

  # Add a newline for separation
  echo >> "$invfile"
done

echo "Inventory file created at $invfile"

#!/bin/bash

# Check if an argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <agent_list>"
    exit 1
fi

agents="$1"
invfile="/home/rooty/inventory.agents.host"
rm -f "$invfile"

IFS=';' read -ra agentslist <<< "$agents"
for agent in "${agentslist[@]}"; do
    echo "Processing IP address: $agent"

    IFS=',' read -ra aginfo <<< "$agent"

    agent_nic_name="${aginfo[0]}"
    agent_nic_ip="${aginfo[1]}"
    echo "[$agent_nic_name]" >> "$invfile"
    echo "$agent_nic_ip" >> "$invfile"
done

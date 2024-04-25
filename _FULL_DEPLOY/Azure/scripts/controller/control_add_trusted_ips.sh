#!/bin/bash

# Check if an argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <vm_list>"
    exit 1
fi

# Variables
allips="$1"
jenkins_ssh_folder="/var/lib/jenkins/.ssh"
known_hosts_file="$jenkins_ssh_folder/known_hosts"

# Function to add SSH keys to known_hosts
add_ssh_keys() {
    local ip="$1"
    echo "Processing IP address: $ip"

    # Add SSH key to the user's known_hosts
    if ! ssh-keyscan -H "$ip" >> /home/rooty/.ssh/known_hosts; then
        echo "Failed to add SSH key for $ip to the user's known_hosts file"
        exit 11
    fi

    # Add SSH key to the root's known_hosts
    if ! ssh-keyscan -H "$ip" >> ~/.ssh/known_hosts; then
        echo "Failed to add SSH key for $ip to the root's known_hosts file"
        exit 111
    fi    

    # Add SSH key to Jenkins' known_hosts
    if ! sudo -u jenkins bash -c "ssh-keyscan -H \"$ip\" >> \"$known_hosts_file\""; then
        echo "Failed to add SSH key for $ip to Jenkins VarLibPath' known_hosts file"
        exit 12
    fi

    # Add SSH key to Jenkins' known_hosts
    if ! sudo -u jenkins bash -c "ssh-keyscan -H \"$ip\" >> /home/jenkins/.ssh/known_hosts; then
        echo "Failed to add SSH key for $ip to Jenkins Home Path' known_hosts file"
        exit 12
    fi
}

# Add SSH keys to known_hosts for each IP address
for ip in $(echo "$allips" | tr ";" "\n"); do
    add_ssh_keys "$ip"
done

# Set ownership of the Jenkins' SSH folder
if ! sudo chown -R jenkins:jenkins "$jenkins_ssh_folder"; then
    echo "Failed to set ownership of Jenkins' SSH folder"
    exit 99
fi

echo "SSH keys added and ownership set successfully"

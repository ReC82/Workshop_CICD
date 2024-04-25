#!/bin/bash

# Check the number of arguments
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <username> <git_key_name>" >&2
  exit 1
fi

# Required Args
# $1 = username
# $2 = git_key_name

# Function to handle errors
handle_error() {
  echo "Error: $1" >&2
  exit 1
}

# Check if git key file exists
if [ ! -f "/home/$1/.ssh/$2" ]; then
  handle_error "Git key file not found: $2"
fi

# Check if git key file has correct permissions
if [ ! -r "/home/$1/.ssh/$2" ] || [ ! -f "/home/$1/.ssh/$2" ]; then
  handle_error "Git key file does not have correct permissions: $2"
fi

# Check if the destination directory already exists
destination_directory="/home/$1/Workshop_CICD"  # Set the destination directory
if [ -d "$destination_directory" ]; then
  echo "Destination directory already exists: $destination_directory. Skipping clone operation."
  exit 0
else
  # Approve Github.com as a trusted host
  ssh-keyscan -H github.com >> "/home/$1/.ssh/known_hosts" || handle_error "Failed to add Github.com to known_hosts"

  # Clone the Ansible Files
  if ! git clone -c "core.sshCommand=ssh -i /home/$1/.ssh/$2 -F /dev/null" git@github.com:ReC82/Workshop_CICD.git "$destination_directory"; then
    handle_error "Failed to clone Ansible Files"
  else
    # Keep only ansible files
    rm -rf /home/$1/ansible
    mv $destination_directory/ansible /home/$1/
    rm -rf $destination_directory
  fi
fi
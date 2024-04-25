#!/bin/bash

# Variables
USERNAME="ReC82"
GIT_KEY_LOCATION="/home/rooty/.ssh/git_global_key"
GITHUB_REPO="ReC82/JenkinsBackup"
GITHUB_BRANCH="main"
RESTORE_DIR="/var/lib/jenkins"

# Directory to clone the repository
REPO_DIR="/tmp/JenkinsBackup"

# Add github.com to known_hosts (for root user)
ssh-keyscan -H "github.com" >> ~/.ssh/known_hosts
# Add github.com to known_hosts (for rooty)
ssh-keyscan -H "github.com" >> /home/rooty/.ssh/known_hosts

# Clone GitHub repository with error handling
echo "Cloning GitHub repository..."
if [ -d "$REPO_DIR" ]; then
    echo "Repository directory already exists. Removing it."
    rm -rf "$REPO_DIR" || { echo "Failed to remove existing repository directory."; exit 3; }
fi

GIT_SSH_COMMAND="ssh -i $GIT_KEY_LOCATION" git clone "git@github.com:$GITHUB_REPO.git" "$REPO_DIR" || { echo "Failed to clone repository."; exit 4; }

# Navigate to the cloned repository directory
cd "$REPO_DIR" || { echo "Failed to navigate to repository directory."; exit 5; }

# Check if 'backup' directory exists
if [ ! -d "backup" ]; then
    echo "Backup directory not found. Exiting."
    exit 0
fi

# Identify the latest backup file
latest_backup=$(ls -t backup/jenkins_backup_*.tar.gz 2>/dev/null | head -n 1)

if [ -z "$latest_backup" ]; then
    echo "No backup file found. Exiting."
    exit 0
fi

# Stop Jenkins service before restoring
echo "Stopping Jenkins service..."
sudo systemctl stop jenkins || { echo "Failed to stop Jenkins service."; exit 10; }

# Extract the latest backup file with error handling
echo "Restoring from backup: $latest_backup"
sudo -u jenkins bash -c "tar -zxvf '$latest_backup' -C '$RESTORE_DIR'" || { echo "Failed to restore from backup."; exit 15; }

# Restart Jenkins service after restoring
echo "Starting Jenkins service..."
sudo systemctl start jenkins || { echo "Failed to start Jenkins service."; exit 20; }

echo "Restore completed successfully."

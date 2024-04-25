#!/bin/bash

# Variables
USERNAME="ReC82"
GIT_KEY_LOCATION="/var/lib/jenkins/backup/git_global_key"
GITHUB_REPO="ReC82/JenkinsBackup"
GITHUB_BRANCH="main"
BACKUP_SCRIPT="/var/lib/jenkins/backup/jenkins_backup_script.sh"
CRONJOB_SCHEDULE="*/15 * * * *"

sudo mkdir "/var/lib/jenkins/backup/"
sudo chown jenkins:jenkins "/var/lib/jenkins/backup/"

# Backup script content
cat > "$BACKUP_SCRIPT" << EOF
#!/bin/bash

# Exit if any command fails
set -e

# Ensure SSH agent is running
if [ -z "$SSH_AGENT_PID" ]; then
  eval "$(ssh-agent -s)"  # Start SSH agent if not already running
fi

# Variables
USERNAME="$USERNAME"  # GitHub username passed as an argument
GIT_KEY_LOCATION="$GIT_KEY_LOCATION"  # SSH key location passed as an argument
GITHUB_REPO="JenkinsBackup"  # Repository name
BACKUP_DIR="/var/lib/jenkins"  # Jenkins directory to back up

# Check if SSH key exists and ensure permissions
if [ ! -f "$GIT_KEY_LOCATION" ]; then
  echo "SSH key not found at $GIT_KEY_LOCATION"
  exit 1
fi
chmod 600 "$GIT_KEY_LOCATION"
ssh-add "$GIT_KEY_LOCATION"

# Check if repository exists before cloning
if [ ! -d "$GITHUB_REPO" ]; then
  echo "Repository not found. Cloning GitHub repository..."
  if ! git clone "git@github.com:$USERNAME/$GITHUB_REPO.git"; then
    echo "Failed to clone GitHub repository"
    exit 2
  fi
else
  echo "Repository already exists. Skipping clone."
fi

cd "$GITHUB_REPO"

# List of important Jenkins files and directories to copy
BACKUP_CONTENTS=(
  "$BACKUP_DIR/config.xml"
  "$BACKUP_DIR/jobs/"
  "$BACKUP_DIR/plugins/"
  "$BACKUP_DIR/users/"
  "$BACKUP_DIR/secrets"
  "$BACKUP_DIR/nodes"
)

# Copy Jenkins files to GitHub repository
echo "Copying Jenkins files to repository..."
for item in "${BACKUP_CONTENTS[@]}"; do
  if [ -e "$item" ]; then
    cp -r "$item" .
  else
    echo "Warning: $item not found"
  fi
done

# Add, commit, and push changes to GitHub
echo "Committing changes to GitHub..."
git config user.name "ReC82"
git config user.email "lloyd.malfliet@gmail.com"  # Set to your Jenkins-related email
git add .
git commit -m "Jenkins backup $(date +%Y-%m-%d)"
if ! git push origin "main"; then
  echo "Failed to push to GitHub"
  exit 3
fi

echo "Backup and push to GitHub completed successfully."
EOF

# Make backup script executable
chmod +x "$BACKUP_SCRIPT"

# Schedule cronjob
(crontab -l 2>/dev/null; echo "$CRONJOB_SCHEDULE $BACKUP_SCRIPT") | crontab -

echo "Cronjob for Jenkins backup created successfully."

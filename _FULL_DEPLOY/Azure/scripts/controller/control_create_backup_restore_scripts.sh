#!/bin/bash

# Allow jenkins users to use the jenkins service 

# Ensure the /etc/sudoers.d/ directory exists
if [ ! -d "/etc/sudoers.d" ]; then
  sudo mkdir -p /etc/sudoers.d
fi

# Add Jenkins permissions to start, stop, and restart Jenkins without password
sudo bash -c 'echo "jenkins ALL=(ALL) NOPASSWD: /bin/systemctl start jenkins, /bin/systemctl stop jenkins, /bin/systemctl restart jenkins" > /etc/sudoers.d/jenkins'

# Set proper permissions on the sudoers file (read-only for all, write only by root)
sudo chmod 644 /etc/sudoers.d/jenkins

# Reload system configuration to apply changes
sudo systemctl daemon-reload
echo "Jenkins sudo permissions updated successfully."

# VARIABLES
USERNAME="ReC82"
GIT_KEY_LOCATION="/var/lib/jenkins/backup/git_global_key"
GITHUB_REPO="JenkinsBackup"
GITHUB_BRANCH="main"
SCRIPT_FINAL_LOCATION="/usr/local/bin/"
SCRIPT_LOCATION="/var/lib/jenkins/backup/"
DIR_TO_BACKUP="/var/lib/jenkins/"
BACKUP_SCRIPT="/var/lib/jenkins/backup/jenkins_backup_script.sh"
RESTORE_SCRIPT="/var/lib/jenkins/backup/jenkins_restore_script.sh"
CRONJOB_SCHEDULE="*/15 * * * *"

BACKUP_RESTORE_CONTENTS=(
  "*.xml"
  "jobs/"
  "plugins/"
  "users/"
  "secrets/"
  "fingerprints"
  "jenkins.install.InstallUtil.lastExecVersion"
  "jenkins.install.UpgradeWizard.state"
)

sudo mkdir -p "$SCRIPT_LOCATION"
sudo chown jenkins:jenkins "$SCRIPT_LOCATION"
sudo cp "/home/rooty/.ssh/git_global_key" "$SCRIPT_LOCATION"
sudo chown jenkins:jenkins "$GIT_KEY_LOCATION"
sudo chmod 600 "$GIT_KEY_LOCATION"
ssh-add "$GIT_KEY_LOCATION"

### BACKUP SCRIPT CONTENT ###
BACKUP_SCRIPT_CONTENT=$(cat <<EOF
#!/bin/bash

# Exit if any command fails
set -e

# Ensure SSH agent is running
if [ -z "$SSH_AGENT_PID" ]; then
  eval "\$(ssh-agent -s)"  # Start SSH agent if not already running
fi


# Check if SSH key exists and ensure permissions
if [ ! -f "$GIT_KEY_LOCATION" ]; then
  echo "SSH key not found at $GIT_KEY_LOCATION"
  exit 1
fi
chmod 600 "$GIT_KEY_LOCATION"
ssh-add "$GIT_KEY_LOCATION"

rm -rf  $GITHUB_REPO

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
rm -rf *

# List of important Jenkins files and directories to copy

# Copy Jenkins files to GitHub repository
echo "Copying Jenkins files to repository..."
for item in ${BACKUP_RESTORE_CONTENTS[@]}; do
  if [ -e "\$item" ]; then
    echo "copying \$item "
    cp -r "$DIR_TO_BACKUP\$item" .
  else
    echo "Warning: $item not found"
  fi
done

cp ${DIR_TO_BACKUP}*.xml .

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
)

### RESTORE SCRIPT CONTENT ###
RESTORE_SCRIPT_CONTENT=$(cat <<EOF
#!/bin/bash

# Exit if any command fails
set -e

# Ensure SSH agent is running
if [ -z "$SSH_AGENT_PID" ]; then
  eval "\$(ssh-agent -s)"  # Start SSH agent if not already running
fi

# Check if SSH key exists and ensure permissions
if [ ! -f "$GIT_KEY_LOCATION" ]; then
  echo "SSH key not found at $GIT_KEY_LOCATION"
  exit 1
fi

chmod 600 "$GIT_KEY_LOCATION"
ssh-add "$GIT_KEY_LOCATION"
cd $SCRIPT_LOCATION
# Clone the repository if it doesn't exist
if [ ! -d "$GITHUB_REPO" ]; then
  echo "Repository directory not found. Cloning GitHub repository..."
  if ! git clone "git@github.com:$USERNAME/$GITHUB_REPO.git"; then
    echo "Failed to clone GitHub repository"
    exit 2
  fi
else
  echo "Repository already exists. Navigating to repository..."
fi

cd "$GITHUB_REPO"

# Stop Jenkins service
echo "Stopping Jenkins service..."
if ! sudo systemctl stop jenkins; then
  echo "Failed to stop Jenkins service"
  exit 3
fi

echo "Restoring Jenkins files from repository..."
for item in ${BACKUP_RESTORE_CONTENTS[@]}; do
  if [ -e "\$item" ]; then
    if ! cp -rf "\$item" "$DIR_TO_BACKUP"; then
      echo "Failed to restore \$item"
      exit 4
    fi
  else
    echo "Warning: \$item not found in repository"
  fi
done

# Start Jenkins service
echo "Starting Jenkins service..."
if ! sudo systemctl start jenkins; then
  echo "Failed to start Jenkins service"
  exit 6
fi

echo "Jenkins restore completed successfully."
EOF
)

sudo -u jenkins bash -c "ssh-keyscan -H \"github.com\" > ~/.ssh/known_hosts"

echo "$BACKUP_SCRIPT_CONTENT" > /tmp/backup_script_content.tmp
sudo chown jenkins:jenkins /tmp/backup_script_content.tmp
sudo -u jenkins mv /tmp/backup_script_content.tmp $BACKUP_SCRIPT
sudo -u jenkins chmod +x $BACKUP_SCRIPT

echo "$RESTORE_SCRIPT_CONTENT" > /tmp/restore_script_content.tmp
sudo chown jenkins:jenkins /tmp/restore_script_content.tmp
sudo -u jenkins mv /tmp/restore_script_content.tmp $RESTORE_SCRIPT
sudo -u jenkins chmod +x $RESTORE_SCRIPT

# Make backup script executable
sudo chmod +x "$BACKUP_SCRIPT"
sudo chmod +x "$RESTORE_SCRIPT"
sudo chown jenkins:jenkins "$BACKUP_SCRIPT"
sudo chown jenkins:jenkins "$RESTORE_SCRIPT"

# Schedule cronjob
# (crontab -l 2>/dev/null; echo "$CRONJOB_SCHEDULE $BACKUP_SCRIPT") | crontab -

# Rooty can be jenkins to run the restore
echo "rooty ALL=(jenkins) NOPASSWD: /var/lib/jenkins/backup/jenkins_restore_script.sh" | sudo tee /etc/sudoers.d/rooty > /dev/null
sudo chmod 0440 /etc/sudoers.d/rooty


echo "Cronjob for Jenkins backup created successfully."

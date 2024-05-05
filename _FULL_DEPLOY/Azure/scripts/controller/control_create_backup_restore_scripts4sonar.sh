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
  "nodes/"
  "fingerprints"
  "jenkins.install.InstallUtil.lastExecVersion"
  "jenkins.install.UpgradeWizard.state"
  "backup/sonarqube_db_backup.sql"
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
#
# Backup a Postgresql database into a daily file.
#

BACKUP_DIR=/pg_backup
DAYS_TO_KEEP=14
FILE_SUFFIX=_pg_backup.sql
DATABASE=
USER=postgres

FILE=`date +"%Y%m%d%H%M"`${FILE_SUFFIX}

OUTPUT_FILE=${BACKUP_DIR}/${FILE}

# do the database backup (dump)
# use this command for a database server on localhost. add other options if need be.
pg_dump -U ${USER} ${DATABASE} -F p -f ${OUTPUT_FILE}

# gzip the mysql database dump file
gzip $OUTPUT_FILE

# show the user the result
echo "${OUTPUT_FILE}.gz was created:"
ls -l ${OUTPUT_FILE}.gz

# prune old backups
find $BACKUP_DIR -maxdepth 1 -mtime +$DAYS_TO_KEEP -name "*${FILE_SUFFIX}.gz" -exec rm -rf '{}' ';'
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

echo "Cronjob for Jenkins backup created successfully."

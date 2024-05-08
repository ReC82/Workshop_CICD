#!/bin/bash


# Ensure the /etc/sudoers.d/ directory exists
if [ ! -d "/etc/sudoers.d" ]; then
  sudo mkdir -p /etc/sudoers.d
fi

# VARIABLES
USERNAME="ReC82"
GIT_KEY_LOCATION="/var/lib/jenkins/backup/git_global_key"
GITHUB_REPO="JenkinsBackup"
GITHUB_BRANCH="main"
SCRIPT_LOCATION="/opt/sonarqube/backup/"
BACKUP_SCRIPT="/opt/sonarqube/backup/sonarqube_backup.sh"
RESTORE_SCRIPT="/opt/sonarqube/backup/sonarqube_restore.sh"


sudo mkdir -p "$SCRIPT_LOCATION"
sudo chown sonar:sonar "$SCRIPT_LOCATION"
sudo cp "/home/rooty/.ssh/git_global_key" "$SCRIPT_LOCATION"
sudo chown sonar:sonar "$GIT_KEY_LOCATION"
sudo chmod 600 "$GIT_KEY_LOCATION"
ssh-add "$GIT_KEY_LOCATION"

### BACKUP SCRIPT CONTENT ###
BACKUP_SCRIPT_CONTENT=$(cat <<EOF
#!/bin/bash
#
# Backup a Postgresql database into a daily file.
#

BACKUP_DIR=/opt/sonarqube/backup
DAYS_TO_KEEP=14
FILE_SUFFIX=_pg_backup.sql
DATABASE=sonarqube
USER=sonar

FILE=sonarqube_$(date +"%Y%m%d%H%M")${FILE_SUFFIX}

OUTPUT_FILE=${BACKUP_DIR}/${FILE}

mkdir -p ${BACKUP_DIR}

# do the database backup (dump)
# use this command for a database server on localhost. add other options if need be.
pg_dump -c ${DATABASE} > ${BACKUP_DIR}/${FILE}

# Restore Command : psql -U sonar sonarqube < pgl.sql

# gzip the mysql database dump file
#gzip $OUTPUT_FILE

# show the user the result
#echo "${OUTPUT_FILE}.gz was created:"
#ls -l ${OUTPUT_FILE}.gz

# prune old backups
#find ${BACKUP_DIR} -maxdepth 1 -mtime +${DAYS_TO_KEEP} -name "*${FILE_SUFFIX}.gz" -exec rm -rf '{}' ';'
)
EOF

### RESTORE SCRIPT CONTENT ###
RESTORE_SCRIPT_CONTENT=$(cat <<EOF

//SONARQUBE RESTORE SCRIPT HERE

EOF
)

sudo -u sonar bash -c "ssh-keyscan -H \"github.com\" > ~/.ssh/known_hosts"

echo "$BACKUP_SCRIPT_CONTENT" > /tmp/backup_script_content.tmp
sudo chown sonar:sonar /tmp/backup_script_content.tmp
sudo -u sonar mv /tmp/backup_script_content.tmp $BACKUP_SCRIPT
sudo -u sonar chmod +x $BACKUP_SCRIPT

echo "$RESTORE_SCRIPT_CONTENT" > /tmp/restore_script_content.tmp
sudo chown sonar:sonar /tmp/restore_script_content.tmp
sudo -u sonar mv /tmp/restore_script_content.tmp $RESTORE_SCRIPT
sudo -u sonar chmod +x $RESTORE_SCRIPT

# Make backup script executable
sudo chmod +x "$BACKUP_SCRIPT"
sudo chmod +x "$RESTORE_SCRIPT"
sudo chown sonar:sonar "$BACKUP_SCRIPT"
sudo chown sonar:sonar "$RESTORE_SCRIPT"


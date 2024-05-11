#!/bin/bash
set -x

# Path to the secondary script
RESTORE_SCRIPT_PATH="/var/lib/jenkins/backup/jenkins_restore_script.sh"

# Run the secondary script as the 'jenkins' user
sudo -u jenkins "$RESTORE_SCRIPT_PATH"
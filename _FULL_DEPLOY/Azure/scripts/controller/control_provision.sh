#!/bin/bash
set -x
exec > >(tee -a /tmp/control_provision_output.log) 2>&1

# 1 # 
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
sudo echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get -y update
sudo apt-get -y install ansible dos2unix git openjdk-17-jdk jq
sudo apt-get -y install jenkins

# 2 bis #
# Prepare Jenkins Backup Folder
jenkins_backup_folder="/var/lib/jenkins/backup"
sudo mkdir -p $jenkins_backup_folder
sudo chown jenkins:jenkins $jenkins_backup_folder
cd $jenkins_backup_folder
git clone https://github.com/ReC82/JenkinsBackup.git

# 2 #
# Add github.com as known_hosts#
# Add know host for user rooty
sudo ssh-keyscan -H "github.com" >> /home/rooty/.ssh/known_hosts
# Add known hosts for user root as the script is running as root
sudo ssh-keyscan -H "github.com" >> ~/.ssh/known_hosts
# Add known hosts for user root as the script is running as root
sudo ssh-keyscan -H "github.com" >> /var/lib/jenkins/.ssh/known_hosts

# 3 #
# Create Jenkins SSH Folder
jenkins_ssh_folder="/var/lib/jenkins/.ssh"
sudo -u jenkins mkdir -p $jenkins_ssh_folder
sudo -u jenkins bash -c "ssh-keyscan \"github.com\" >> known_hosts"
sudo cp /home/rooty/.ssh/git_global_key $jenkins_ssh_folder
sudo chown jenkins:jenkins $jenkins_ssh_folder/git_global_key
sudo chown -R jenkins:jenkins $jenkins_ssh_folder 

# 4 #
#Set TimeZone
sudo timedatectl set-timezone Europe/Brussels

# 5 #
# Install Docker
echo "########### Install Docker #############"
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt install -y docker-ce
sudo systemctl start docker
sudo systemctl enable docker

# 6 #
# Install Gitlab runner
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash
sudo apt-get install -y gitlab-runner
sudo gitlab-runner register  --non-interactive --url https://gitlab.com  --token glrt-Yy2qDp6vtfxCvWXDrcRf --executor docker --docker-image python:3.10.14-bullseye

# 7 #
# Install npm and nodejs
# sudo apt-get install -y nodejs npm
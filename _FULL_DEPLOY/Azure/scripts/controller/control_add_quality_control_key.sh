echo "$1" > ~/.ssh/qc.pem
chmod 600 ~/.ssh/qc.pem

sudo su root bash -c "echo \"$1\" > /var/lib/jenkins/.ssh/qc.pem"
sudo su root bash -c "chmod 600 /var/lib/jenkins/.ssh/qc.pem"
sudo su root bash -c "chown jenkins:jenkins /var/lib/jenkins/.ssh/qc.pem"
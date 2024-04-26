# ENV
environment="prod"
# WEB
web_ip_prod="10.0.1.10"
web_ip_preprod="10.0.2.10"
web_ip_ci="10.0.3.10"
# DATABASE
db_ip_prod="10.0.1.11"
db_ip_preprod="10.0.2.11"
db_ip_ci="10.0.3.11"
# API
api_ip_prod="10.0.1.12"
api_ip_preprod="10.0.2.12"
api_ip_ci="10.0.3.12"



sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
sudo echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get -y update
sudo apt-get install -y ansible nano iputils-ping vim git openjdk-17-jdk fontconfig

sudo touch /home/vagrant/.ssh/known_hosts
sudo chown vagrant:vagrant /home/vagrant/.ssh/known_hosts
ssh-keyscan -H "${web_ip_prod}" >> /home/vagrant/.ssh/known_hosts
ssh-keyscan -H "${db_ip_prod}" >> /home/vagrant/.ssh/known_hosts
ssh-keyscan -H "${api_ip_prod}" >> /home/vagrant/.ssh/known_hosts
eval "$(ssh-agent -s)"
ssh-keyscan -H github.com >> /home/vagrant/.ssh/known_hosts
ssh-add /home/vagrant/.ssh/infrakey

# Cleanup Directory
sudo rm -r /home/vagrant/Workshop_CICD/

#sudo -u vagrant git clone git@github.com:ReC82/Workshop_CICD.git /home/vagrant/repository
sudo -u vagrant git clone -c "core.sshCommand=ssh -i /home/vagrant/.ssh/infrakey -F /dev/null" git@github.com:ReC82/Workshop_CICD.git
# Create Inventory File
cat << EOF > inventory.${environment}.host
[ehealth_app_${environment}]
${web_ip_prod}
[ehealth_db_${environment}]
${db_ip_prod}
[ehealth_api_${environment}]
${api_ip_prod}
EOF

# CREATE AND INVENTORY FILE FOR AGENTS
cat << EOF > inventory.agents.host
[agent-01]
10.0.50.150
[agent-02]
10.0.50.151
EOF

# sudo apt-get update
sudo apt-get -y install jenkins
sudo cat /var/lib/jenkins/secrets/initialAdminPassword > /home/vagrant/jenkinspwd.txt

# Prepare Agent Configuration in Jenkins
jenkins_home="/var/lib/jenkins"
sudo mkdir $jenkins_home/.ssh
sudo chown jenkins:jenkins $jenkins_home/.ssh
touch known_hosts $jenkins_home/.ssh
sudo chown $username:$username $jenkins_home/.ssh/known_hosts
ssh-keyscan -H "10.0.50.150" >> $jenkins_home/.ssh/known_hosts

# Install JMETER -- DO IT WITH ANSIBLE LATER
wget -P /tmp https://dlcdn.apache.org//jmeter/binaries/apache-jmeter-5.6.3.tgz
sudo tar -xvzf /tmp/apache-jmeter-5.6.3.tgz --directory=/tmp
mv /tmp/apache-jmeter-5.6.3 /var/lib/apache-jmeter
echo "export JMETER_HOME=/var/lib/apache-jmeter/bin/" >> /etc/profile
echo "export PATH=\$JMETER_HOME/bin:\$PATH" >> /etc/profile

# ANSIBLE AGENT
# 
# ANSIBLE PROD - Provide a complete YAML : APP - API - DB
# sudo -u vagrant ansible-playbook -i inventory.${environment}.host --key-file /home/vagrant/.ssh/infrakey /home/vagrant/Workshop_CICD/ansible/_complete/pb-prod.yaml
# ANSIBLE PREPROD
# sudo -u vagrant ansible-playbook -i inventory.${environment}.host --key-file .ssh/infrakey /home/vagrant/Workshop_CICD/ansible/app/pre-production.yaml
# ANSIBLE CIa
# sudo -u vagrant ansible-playbook -i inventory.${environment}.host --key-file .ssh/infrakey /home/vagrant/Workshop_CICD/ansible/app/ci.yaml
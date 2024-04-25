#!/bin/bash
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
#sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt-get -y install ansible dos2unix git openjdk-17-jdk jenkins

mkdir -p /home/rooty/.ssh
#echo "${priv_key}" > /home/rooty/.ssh/infrakey
chmod 600 /home/rooty/.ssh/infrakey

# Create Inventory File
cat << EOF > inventory.${environment}.host
[ehealth_app_${environment}]
${web_ip_prod}
[ehealth_db_${environment}]
${db_ip_prod}
[ehealth_api_${environment}]
${api_ip_prod}
EOF

ssh-keyscan -H "${web_ip_prod}" >> /home/rooty/.ssh/known_hosts
ssh-keyscan -H "${db_ip_prod}" >> /home/rooty/.ssh/known_hosts
ssh-keyscan -H "${api_ip_prod}" >> /home/rooty/.ssh/known_hosts
eval "$(ssh-agent -s)"
ssh-keyscan -H github.com >> /home/rooty/.ssh/known_hosts
ssh-add /home/rooty/.ssh/infrakey

dos2unix ip_list.txt
while IFS= read -r ip; do ssh-keyscan -H $ip >> /home/rooty/.ssh/known_hosts; done < ip_list.txt
git clone -c "core.sshCommand=ssh -i /home/rooty/.ssh/infrakey -F /dev/null" git@github.com:ReC82/Workshop_CICD.git
ansible-playbook -i inventory.${environment}.host --key-file .ssh/infrakey /home/rooty/Workshop_CICD/ansible/_complete/pb-prod.yaml
#sudo sed -i 's/^;host_key_checking=True/host_key_checking = False/' /home/rooty/ansible.cfg
#sudo cp -f private_nodes.txt /etc/ansible/hosts

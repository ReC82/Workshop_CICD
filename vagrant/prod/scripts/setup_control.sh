# ENV
environment="PROD"
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


sudo apt-get -y update
sudo apt-get install -y ansible nano iputils-ping vim git

ssh-keyscan -H "${web_ip_prod}" >> /home/vagrant/.ssh/known_hosts
ssh-keyscan -H "${db_ip_prod}" >> /home/vagrant/.ssh/known_hosts
ssh-keyscan -H "${$api_ip_prod}" >> /home/vagrant/.ssh/known_hosts
eval "$(ssh-agent -s)"
ssh-keyscan -H github.com >> /home/vagrant/.ssh/known_hosts
ssh-add /home/vagrant/.ssh/infrakey
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
# ANSIBLE PROD - Provide a complete YAML : APP - API - DB
sudo -u vagrant ansible-playbook -i inventory.${environment}.host --key-file .ssh/infrakey /home/vagrant/Workshop_CICD/ansible/app/app_prod.yaml
# ANSIBLE PREPROD
# sudo -u vagrant ansible-playbook -i inventory.${environment}.host --key-file .ssh/infrakey /home/vagrant/Workshop_CICD/ansible/app/pre-production.yaml
# ANSIBLE CI
# sudo -u vagrant ansible-playbook -i inventory.${environment}.host --key-file .ssh/infrakey /home/vagrant/Workshop_CICD/ansible/app/ci.yaml
hosts=$1
key=$2
ansible-playbook -i /home/rooty/inventory.${hosts}.host --key-file /home/rooty/.ssh/$key /home/rooty/ansible/_final/${hosts}/main.yaml
hosts=$1
key=$2
ansible-playbook -i /home/rooty/inventory.${hosts}.host --key-file /home/rooty/keys/$key /home/rooty/ansible/_final/${hosts}/main.yaml >  /tmp/ansible_${hosts}_output.log
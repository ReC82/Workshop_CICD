#!/bin/bash

set -x
exec > >(tee -a /tmp/generate_key_output.log) 2>&1

# Output file path
FILE_PATH="/home/rooty/keys.json"
AUTHORIZE_KEYS_FILE_PATH="/home/rooty/generated_authorized_keys"
IP_TO_SCAN="/home/rooty/ip_to_scan.txt"
KNOWN_HOSTS_FILE_PATH="/home/rooty/generated_known_hosts"
ETC_HOSTS_FILE_PATH="/home/rooty/generated_hosts"
KEYS_FILES_PATH="/home/rooty/keys"

# Create or clear the output file
> "$FILE_PATH"
> "$AUTHORIZE_KEYS_FILE_PATH"
> "$IP_TO_SCAN"
> "$KNOWN_HOSTS_FILE_PATH"
> "$ETC_HOSTS_FILE_PATH"

# Create a directory for the keys
mkdir -p "$KEYS_FILES_PATH"

full_json="$@"

# Loop through each script argument
for arg in "$@"; do
  # Validate the JSON structure
  if ! echo "$arg" | jq '.' > /dev/null 2>&1; then
    echo "Error: Invalid JSON input: $arg"
    exit 1111
  fi

  # Extract the keyname
  keyname=$(echo "$arg" | jq -r '.keyname')

  # Extract the keys
  private_key=$(echo "$arg" | jq -r '.private_key')
  public_key=$(echo "$arg" | jq -r '.public_key')

  # Extract the IPs
  EXTRACTED_IPS=$(echo "$arg" | jq -r 'to_entries | map(select(.key | startswith("nic_"))) | .[] | .value')

  # Process the keyname and write to the output file
  echo "Keyname: $keyname" >> "$FILE_PATH"
  echo "Private Key: $private_key" >> "$FILE_PATH"
  echo "Public Key: $public_key" >> "$FILE_PATH"
  echo "---" >> "$FILE_PATH"  # Separator for clarity

  # GENERATE THE AUTHORIZED_KEYS
  echo "$public_key $keyname" >> $AUTHORIZE_KEYS_FILE_PATH

  # GENERATE THE PRIVATE KEY
  KEY_FILE_PATH="$KEYS_FILES_PATH/$keyname.pem"
  echo "$private_key" >> $KEY_FILE_PATH
  chmod 600 $KEY_FILE_PATH

  # GENERATE KNOWN_HOSTS FILE
  for ip in $EXTRACTED_IPS; do
    echo "$ip ${keyname}_host" >> "$ETC_HOSTS_FILE_PATH"
    ssh-keyscan -H "$ip" | while read -r line; do
        echo "$line $keyname" >> "$KNOWN_HOSTS_FILE_PATH"
    done
    ssh-keyscan -H "github.com" >> "$KNOWN_HOSTS_FILE_PATH"
  done

  # GENERATE IP LIST TO USE LATER WITH SCP
  echo "$EXTRACTED_IPS" >> $IP_TO_SCAN
  
done

echo " ------ CONFIG DONE ------ "

GLOBAL_KNOWN_HOST_FILE="/etc/ssh/ssh_known_hosts"
KNOWN_HOSTS_CONTENT="$(cat $KNOWN_HOSTS_FILE_PATH)"

# Create global ssh config
#sudo touch /etc/ssh/ssh_known_hosts
#sudo chmod 666 /etc/ssh/ssh_known_hosts

my_ip=$(hostname -I | awk '{print $1}')

for arg in "$@"; do

  # Validate the JSON structure
  if ! echo "$arg" | jq '.' > /dev/null 2>&1; then
    echo "Error: Invalid JSON input: $arg"
    exit 2222
  fi

  key_filename="$(echo "$arg" | jq -r '.keyname').pem"
  EXTRACTED_IPS=$(echo "$arg" | jq -r 'to_entries | map(select(.key | startswith("nic_"))) | .[] | .value')
  

  for ip in $EXTRACTED_IPS; do

    # FOR EACH IP
    echo "ADD ${ip} to global and root known_hosts"
    #sudo su root bash -c "ls -ahl /root/.ssh/known_hosts"
    sudo su root bash -c "echo \"\$(ssh-keyscan -H ${ip})\" \"${key}\" >> /root/.ssh/known_hosts"
    sudo su root bash -c "echo \"\$(ssh-keyscan -H ${ip})\" \"${key}\" >> /etc/ssh/ssh_known_hosts"
    
    if [[ "$ip" == "$my_ip" ]]; then
        
        echo "Skipping other operations for IP ${ip}, matches server IP (${my_ip})"
        continue
    fi
    
    # Help to identify IPS
    echo "IP : ${ip} - KeyName : ${key_filename}"

    # COPY THE KNOWN_HOSTS TO EACH
    echo "A) SCP known_host to ${ip} for user rooty"
    scp -i "$KEYS_FILES_PATH/${key_filename}" $KNOWN_HOSTS_FILE_PATH rooty@${ip}:/home/rooty/.ssh/known_hosts
    echo "STEP A -- OK"
    # COPY THE KNOWN_HOSTS TO GLOBAL
    echo "B) SCP known_host to ${ip} to global user"
    echo "step 1 - create temporary file"
    scp -i "$KEYS_FILES_PATH/${key_filename}" $KNOWN_HOSTS_FILE_PATH "rooty@${ip}:/tmp/known_hosts_tmp"
    echo "step 2 - mv the file as sudo"
    ssh -i "$KEYS_FILES_PATH/${key_filename}" "rooty@${ip}" "sudo mv /tmp/known_hosts_tmp /etc/ssh/ssh_known_hosts"
    echo "STEP B -- OK"
    # COPY THE AUTHORIZED_KEYS TO EACH
    echo "C) SCP authorized_keys to ${ip} to rooty"
    scp -i "$KEYS_FILES_PATH/${key_filename}" $AUTHORIZE_KEYS_FILE_PATH rooty@${ip}:/home/rooty/.ssh/authorized_keys
    echo "STEP C -- OK"
    # COPY THE PRIVATE KEYS FOLDER TO EACH
    echo "D) SCP private keys folder to ${ip} to rooty"
    scp -i "$KEYS_FILES_PATH/${key_filename}" -r $KEYS_FILES_PATH rooty@${ip}:/home/rooty/.ssh/
    echo "STEP D -- OK"   
    
    # CREATE JENKINS USER IF DOESN'T EXIST
    echo "Create user jenkins if not exist"
    USER_EXISTS=$(ssh -i "$KEY_FILE_PATH" "rooty@$ip" 'id -u jenkins' 2>/dev/null)

    if [ -z "$USER_EXISTS" ]; then
        # If the user doesn't exist, create the user and set up the home directory with .ssh
        ssh -i "$KEYS_FILES_PATH/${key_filename}" "rooty@$ip" <<EOF
        # Create the user with a home directory and .ssh
        sudo useradd -m -s /bin/bash jenkins
        sudo mkdir -p /home/jenkins/.ssh
        sudo chmod 700 /home/jenkins/.ssh
        sudo chown jenkins:jenkins /home/jenkins/.ssh
EOF
    else
        echo "User 'jenkins' already exists on $ip"
    fi

    # COPY AUTHORIZED_KEYS TO JENKINS HOME
    echo "scp Authorized_keys to jenkins home on ${ip}"
    scp -i "$KEYS_FILES_PATH/${key_filename}" $AUTHORIZE_KEYS_FILE_PATH rooty@${ip}:/tmp/authorized_keys_tmp
    ssh -i "$KEYS_FILES_PATH/${key_filename}" "rooty@${ip}" "sudo mv /tmp/authorized_keys_tmp /home/jenkins/.ssh/authorized_keys"
    ssh -i "$KEYS_FILES_PATH/${key_filename}" "rooty@${ip}" "sudo chown jenkins:jenkins /home/jenkins/.ssh/authorized_keys"
    echo "scp -- OK"
  done
done

# sudo -u root bash -c "mkdir -p /var/lib/jenkins/.ssh"
# sudo -u root bash -c "cp /etc/ssh/ssh_known_hosts /var/lib/jenkins/.ssh/known_hosts"
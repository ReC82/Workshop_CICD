jenkins_ip=$1
node_name=$2
node_descritpion=$3
labels=$4
node_ip=$5

# Variables
jenkins_url="http://$jenkins_ip:8080"

# Create Credentials First

# Configure Slave
java -jar jenkins-cli.jar -s $jenkins_url create-node "${node_name}" \
--username "lloyd" --password "d3h2dz9x" \
--description "${node_description}" \
--labels "$labels" \
--executors 2 \
--mode NORMAL \
--launcher "ssh" \
--sshHost "${node_ip}" \
--sshPort 22 \
--sshUser jenkins \
--sshCredentialsId "JenkinsAgent0" \
--workDir /home/jenkins/workingdir

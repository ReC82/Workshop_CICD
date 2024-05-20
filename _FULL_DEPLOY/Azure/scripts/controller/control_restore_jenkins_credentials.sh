#!/bin/bash
url="http://jenkins-lodydjango.centralus.cloudapp.azure.com:8080"
wget ${url}/jnlpJars/jenkins-cli.jar

for pem_file in /home/rooty/keys/*.pem; do

    if [ -f "$pem_file" ]; then

        filename=$(basename "$pem_file" .pem)

        echo "Processing file: $filename"

        key_content=$(<"$pem_file")

        # Escape special characters in the key content
        escaped_key_content=$(echo "$key_content" | sed 's/"/\\"/g')

        # Generate the XML content
        xml_content=$(cat <<EOF
        <com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey plugin="ssh-credentials@337.v395d2403ccd4">
        <scope>GLOBAL</scope>
        <id>$(basename "$pem_file")</id>
        <description>Private Key For $(basename "$pem_file")</description>
        <username>rooty</username>
        <usernameSecret>false</usernameSecret>
        <privateKeySource class="com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey\$DirectEntryPrivateKeySource">
            <privateKey>${escaped_key_content}</privateKey>
        </privateKeySource>
        </com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey>
EOF
        )

        # Print the XML content
        echo "$xml_content" > credential_$(basename "$pem_file").xml
        # Delete the creds
        java -jar jenkins-cli.jar -auth lloyd:11eeee4e2b172c803fc026b715d7e6d532 -s ${url} delete-credentials system::system::jenkins _ $(basename "$pem_file")
        # Add the credentials
        java -jar jenkins-cli.jar -auth lloyd:11eeee4e2b172c803fc026b715d7e6d532 -s ${url} create-credentials-by-xml system::system::jenkins _ < credential_$(basename "$pem_file").xml

        rm -f credential_$(basename "$pem_file").xml

        # Generate the XML content
        xml_content=$(cat <<EOF
        <com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey plugin="ssh-credentials@337.v395d2403ccd4">
        <scope>GLOBAL</scope>
        <id>jenkins-$(basename "$pem_file")</id>
        <description>Jenkins User $(basename "$pem_file")</description>
        <username>jenkins</username>
        <usernameSecret>false</usernameSecret>
        <privateKeySource class="com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey\$DirectEntryPrivateKeySource">
            <privateKey>${escaped_key_content}</privateKey>
        </privateKeySource>
        </com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey>
EOF
        )

        # Print the XML content for jenknis user
        echo "$xml_content" > credential_$(basename "$pem_file")_jenkins.xml
        # Delete the creds
        java -jar jenkins-cli.jar -auth lloyd:11eeee4e2b172c803fc026b715d7e6d532 -s ${url} delete-credentials system::system::jenkins _ jenkins-$(basename "$pem_file")
        # Add the credentials
        java -jar jenkins-cli.jar -auth lloyd:11eeee4e2b172c803fc026b715d7e6d532 -s ${url} create-credentials-by-xml system::system::jenkins _ < credential_$(basename "$pem_file")_jenkins.xml        

        rm -f credential_$(basename "$pem_file")_jenkins.xml
    fi
done

# Restore Agent Maven
java -jar jenkins-cli.jar -auth lloyd:11eeee4e2b172c803fc026b715d7e6d532 -s ${url} create-node AgentMaven < /var/lib/jenkins/agent-maven.xml || true
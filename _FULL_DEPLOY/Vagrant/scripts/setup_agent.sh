sudo echo "10.0.50.100 controller" >> /etc/hosts

# TO DO WITH ANSIBLE !!!!
sudo apt-get update -y
sudo apt-get install -y maven git

# TO BE ABLE TO ADD REPO ==> https://itsfoss.com/add-apt-repository-command-not-found/
sudo apt-get install -y software-properties-common

# Install Java 17 = Same as Jenkins

jdk_tar_file="openjdk-17+35_linux-x64_bin.tar.gz"
jdk_dir="/usr/lib/jvm/jdk-17"

if [ ! -f "$jdk_tar_file" ]; then
    sudo wget -O "$jdk_tar_file" "https://download.java.net/openjdk/jdk17/ri/openjdk-17+35_linux-x64_bin.tar.gz"   
    if [ ! -d "$jdk_dir" ]; then
        sudo tar xvf "$jdk_tar_file"
        sudo mv -n jdk-17/ /usr/lib/jvm
        sudo update-alternatives --install "/usr/bin/javac" "javac" "/usr/lib/jvm/jdk-17/bin/javac" 3
        sudo update-alternatives --install "/usr/bin/java" "java" "/usr/lib/jvm/jdk-17/bin/java" 3
        sudo update-alternatives --set "javac" "/usr/lib/jvm/jdk-17/bin/javac"
        sudo update-alternatives --set "java" "/usr/lib/jvm/jdk-17/bin/java"
    else
        echo "Directory '$jdk_dir' already exists. Skipping extraction."
    fi
else
    echo "File '$jdk_tar_file' already exists. Skipping download."
fi


# Create Jenkins User
username="jenkins"
password=$username
if ! id "$username" &>/dev/null; then
    sudo useradd -m -s /bin/bash "$username"
    if [ ! -d '/home/"$username"/.ssh' ]; then
        sudo -u "$username" mkdir -p /home/"$username"/.ssh
        sudo chown "$username":"$username" /home/"$username"/.ssh
        sudo chmod 700 /home/"$username"/.ssh
    fi
    echo "$username:$password" | sudo chpasswd
else
    echo "User '$username' already exists."
fi

# Set default path for the SSH key
ssh_key_path="/home/${username}/.ssh/jenkins"

# Generate SSH key pair without passphrase
if [ ! -f "$ssh_key_path" ]; then
    #sudo mkdir -p "$ssh_key_path"
    echo "Keyfile doesn't exist : Create a new One"
    ssh-keygen -f ssh2key -m RFC4716 -t rsa -b 4096 -C "JenkinsAgent" -f "$ssh_key_path" -N "" -q
    echo "Change owner of the key pair"
    sudo chown "$username":"$username" "$ssh_key_path"*
    if [ ! -d "/vagrant/shared_folder/" ]; then
        echo "shared_folder doesn't exists : create it"
        mkdir -p /vagrant/shared_folder/
    fi
    if [ ! -f "/vagrant/shared_folder/jenkins" ]; then
        echo "Key Doesn't exist in the shared folder : Copy it"
        cp -f /home/"$username"/.ssh/jenkins* /vagrant/shared_folder/ 2>/dev/null
    fi
else
    echo "SSH key already exists at $ssh_key_path. Skipping key generation."
    if [ ! -f "/vagrant/shared_folder/jenkins.pub" ]; then
        if [ ! -d "/vagrant/shared_folder/" ]; then
            mkdir -p /vagrant/shared_folder/
        fi
        if [ ! -f "/vagrant/shared_folder/" ]; then
            cp -f /home/"$username"/.ssh/jenkins* /vagrant/shared_folder/ 2>/dev/null
        fi
    fi
fi



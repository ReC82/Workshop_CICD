
mkdir -p /home/vagrant/.ssh/
sudo chown -R vagrant:vagrant /home/vagrant/.ssh/
cd /home/vagrant/.ssh
if [ ! -f "/home/vagrant/shared/infrakey.pub" ]; then
    sudo -u vagrant ssh-keygen -t rsa -N "" -C "InfraKey" -f /home/vagrant/.ssh/infrakey # -N "" stands for no password
    cp /home/vagrant/.ssh/infrakey* /home/vagrant/shared
else
    echo "The Key Exists"
    cp /home/vagrant/shared/infrakey* .
    sudo chown vagrant:vagrant /home/vagrant/.ssh/infrakey
    sudo chmod 600 /home/vagrant/.ssh/infrakey 
    cat /home/vagrant/.ssh/infrakey.pub >> /home/vagrant/.ssh/authorized_keys
fi
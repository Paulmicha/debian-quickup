#!/bin/bash

##
# Setup local dev VM Debian 8 for Docker projects.
#
# Tested on 2017/02/05 19:18:10 in Debian 8 as root.
# Replace '192.168.0.36' with desired VM LAN IP + adapt 'lan-0-36.io'.
#

# Prereq. when cloning from a barebone VM backup.
# I usually create those for every major version of Debian or Ubuntu in
# VirtualBox, so when I need to quickly spin up a new local VM, I just make
# an integral clone (and reset its MAC address).
apt-get update
apt-get upgrade -y

# Pin down a local IP address for permanent shortcuts from host machine.
# Note: when working from another place, this IP must be changed to match
# current LAN subnet.
hostnamectl set-hostname lan-0-36.io
mv /etc/network/interfaces /etc/network/interfaces.bak
cat > /etc/network/interfaces <<'EOF'
source /etc/network/interfaces.d/*
auto lo
iface lo inet loopback
allow-hotplug eth0
iface eth0 inet static
    address 192.168.0.36
    netmask 255.255.255.0
    network 192.168.0.0
    broadcast 192.168.0.255
    gateway 192.168.0.1
EOF
reboot

# Samba setup.
apt-get install samba samba-common -y
mv /etc/samba/smb.conf /etc/samba/smb.conf.bak
echo -n "[root]
path = /
create mask = 0755
force user = root
browsable = Yes
writeable = Yes
read only = No
" > /etc/samba/smb.conf
/etc/init.d/samba restart
smbpasswd -a $USER

# SSH manual setup :
# Avoid having to re-add new SSH keys in Gitlab / Github / Bitbucket / etc.
# everytime I create a new local VM : I just copy/paste my ".ssh" folder
# in Samba (this is insecure : don't do it).
# e.g. from Windows host machine, manually entering \\192.168.0.36\root\root
# in explorer address bar.
chmod 750 ~/.ssh
chmod 400 ~/.ssh/id_rsa
chmod 400 ~/.ssh/id_rsa.pub
chmod 750 ~/.ssh/environment
chmod 750 ~/.ssh/known_hosts
# Otherwise (normally), generate a new SSH key.

# Setup ssh-agent auto-start.
# See http://stackoverflow.com/a/18915067/2592338
cat > ~/.bash_profile <<'EOF'
#!/bin/bash
SSH_ENV="$HOME/.ssh/environment"
function start_agent {
    echo "Initialising new SSH agent..."
    /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
    echo succeeded
    chmod 600 "${SSH_ENV}"
    . "${SSH_ENV}" > /dev/null
    /usr/bin/ssh-add;
}
if [ -f "${SSH_ENV}" ]; then
    . "${SSH_ENV}" > /dev/null
    ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
        start_agent;
    }
else
    start_agent;
fi
EOF

# Docker setup.
apt-get install curl -y
apt-get install apt-transport-https ca-certificates software-properties-common -y
curl -fsSL https://yum.dockerproject.org/gpg | apt-key add -
add-apt-repository "deb https://apt.dockerproject.org/repo/ debian-$(lsb_release -cs) main"
apt-get update
apt-get install docker-engine -y

# Docker-compose setup.
curl -L "https://github.com/docker/compose/releases/download/1.10.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
curl -L https://raw.githubusercontent.com/docker/compose/$(docker-compose version --short)/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose

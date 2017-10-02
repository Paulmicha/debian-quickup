#!/bin/bash

##
# Commonly installed stuff on my local VMs.
#
# Tested on Debian 9 "Stretch".
# @timestamp 2017/07/02 11:59:40
#
# Run as root or sudo.
#
# Sources :
# http://www.aboutlinux.info/2007/05/using-netselect-apt-tip-to-select.html
# https://wiki.debian.org/UnattendedUpgrades
#

cd ~

# [optional] Get fastest local mirror for APT.
# apt install -y netselect-apt
# netselect-apt stretch
# Read the generated file sources.list to update /etc/apt/sources.list if needed.

# Making sure everything is up to date.
apt update
apt upgrade -y

# Pin down a local IP address for permanent shortcuts from host machine.
# Note: when working from another place, this IP must be changed to match
# current LAN subnet.
hostnamectl set-hostname lan-0-40.io
mv /etc/network/interfaces /etc/network/interfaces.bak
cat > /etc/network/interfaces <<'EOF'
source /etc/network/interfaces.d/*
auto lo
iface lo inet loopback
allow-hotplug enp0s3
iface enp0s3 inet static
    address 192.168.0.40
    netmask 255.255.255.0
    network 192.168.0.0
    broadcast 192.168.0.255
    gateway 192.168.0.1
EOF
reboot

# Samba setup.
apt install samba samba-common -y
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
# e.g. from Windows host machine, manually entering \\192.168.0.40\root\root
# in explorer address bar.
chmod 750 ~/.ssh
chmod 400 ~/.ssh/id_rsa
chmod 400 ~/.ssh/id_rsa.pub
chmod 750 ~/.ssh/known_hosts
chmod 750 ~/.ssh/environment
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

# Unattended security upgrades.
apt install unattended-upgrades apt-listchanges -y
sed -e 's,\/\/Unattended-Upgrade::Mail "root";,Unattended-Upgrade::Mail "root";,g' -i /etc/apt/apt.conf.d/50unattended-upgrades

# Usual utilities.
# Don't forget to REPLACE_WITH_YOUR_USERNAME + REPLACE_WITH_YOUR_EMAIL below.
apt install git curl -y

git config --global user.name "REPLACE_WITH_YOUR_USERNAME"
git config --global user.email "REPLACE_WITH_YOUR_EMAIL"
git config --global push.default simple

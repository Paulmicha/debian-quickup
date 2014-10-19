#!/bin/bash
# -*- coding: UTF8 -*-

##
#   Antivirus ClamAV installation
#
#   Tested in :
#   Ubuntu 14.04 LTS "trusty"
#
#   Sources :
#   http://howto.biapy.com/fr/debian-gnu-linux/systeme/securite/installer-lantivirus-clamav-sur-debian
#

#  (as root)
sudo su

apt-get install clamav clamav-freshclam -y
apt-get install clamav-unofficial-sigs -y

#  update base (several minutes)
freshclam

#  Optional : schedulge entire check every week (resource-heavy)
echo "# Weekly antivirus scan.
# m h dom mon dow user command
34 1  * * 7  root   test -x /usr/bin/clamscan && /usr/bin/clamscan --infected --recursive / 2>/dev/null" \
    > "/etc/cron.d/clamscan-weekly"


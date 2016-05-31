#!/bin/bash
CMRPM_PATH=/vagrant/$1
PARCEL_PATH=/vagrant/$2
FQDN=$3

CM_LOCAL_REPO=/var/www/html/cmrepo
PARCEL_LOCAL_REPO=/var/www/html/parcelrepo

# HTTP Repo
#yum makecache fast
# Seriously, for more than 10 years, these jokers are trying to get it right
# with their stupid network manager... It just doesn't work!
systemctl stop NetworkManager.service 
systemctl disable NetworkManager.service 
service network restart
yum install -y createrepo httpd
mkdir $CM_LOCAL_REPO
cp -r $CMRPM_PATH/* $CM_LOCAL_REPO
createrepo $CM_LOCAL_REPO
# TBD: come up with a function so it is modular and will either scp or vboxsf-mount-copy 
# TBD: chmod -R 777  /var/www/html/parcelrepo
mkdir $PARCEL_LOCAL_REPO
cp $PARCEL_PATH/* $PARCEL_LOCAL_REPO
chmod -R 777 $PARCEL_LOCAL_REPO
# This is necessary on RHEL 7. Otherwise it will listen on tcp6 only
sed -i "s/Listen.*80/Listen 0.0.0.0:80/" /etc/httpd/conf/httpd.conf
chkconfig httpd on
service httpd start

# Add Cloudera Repo
# it can either be the internet repo or a local one (local is just much faster for rapid redeploys)
cat << EOF > /etc/yum.repos.d/cloudera-manager.repo
[cloudera-manager]
# Packages for Cloudera Manager, Version 
name=Cloudera Manager
baseurl=http://$FQDN/`basename $CM_LOCAL_REPO`
gpgcheck=0
EOF

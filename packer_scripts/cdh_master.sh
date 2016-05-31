#!/bin/bash

# HTTP Repo
#yum makecache fast
# Seriously, for more than 10 years, these jokers are trying to get it right
# with their stupid network manager... It just doesn't work!
systemctl stop NetworkManager.service 
systemctl disable NetworkManager.service 
service network restart
yum install -y createrepo httpd
mkdir /var/www/html/cmrepo
#rm -rf /var/www/html && ln -s /vagrant/html /var/www/html
createrepo /cmrepo
# TBD: variable to check if fetch via scp or mountpoint
# TBD: variable of the host where to scp from
# TBD: ln -sf /cmrepo /var/www/cmrepo
# TBD: ln -sf /parcelrepo /var/www/parcelrepo
# TBD: chmod -R 777  /var/www/html/parcelrepo
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
baseurl=$CMRPM_URL
gpgcheck=0
EOF

# Install Cloudera Manager & Parcel repository
#TODO which java version matches which CDH version... install the appropriate one
if [ -e /tmp/jdk.rpm ]
then
    yum install -y /tmp/jdk.rpm
else
    yum install -y java-1.7.0-openjdk-devel
fi

yum install -y cloudera-manager-server
#cp /cdhbuilder/provision/files/parcels/* /opt/cloudera/parcel-repo/
#chown cloudera-scm:cloudera-scm /opt/cloudera/parcel-repo/*

# We don't want to use host network for http, so we don't clober forwarded ports
# instead use x forwarding
#yum install -y xauth firefox
#mkdir -p /opt/X11/bin
#ln -sf /usr/bin/xauth /opt/X11/bin/xauth

# Install & setup PostgreSQL
# TBD: change this to mysql
yum install -y postgresql-server
service postgresql initdb
sed -i "/# TYPE.*/a host all all 127.0.0.1/32 trust" /var/lib/pgsql/data/pg_hba.conf
chkconfig postgresql on
service postgresql start
/usr/share/cmf/schema/scm_prepare_database.sh postgresql -upostgres scm scm scm

#TBD: change this to mysql

psql -U postgres -h 127.0.0.1 <<EOF
CREATE ROLE amon LOGIN PASSWORD 'amon';
CREATE DATABASE amon OWNER amon ENCODING 'UTF8';
CREATE ROLE rman LOGIN PASSWORD 'rman';
CREATE DATABASE rman OWNER rman ENCODING 'UTF8';
CREATE ROLE hive LOGIN PASSWORD 'hive';
CREATE DATABASE hive OWNER hive ENCODING 'UTF8';
ALTER DATABASE hive SET standard_conforming_strings = off;
CREATE ROLE oozie LOGIN PASSWORD 'oozie';
CREATE DATABASE oozie OWNER oozie ENCODING 'UTF8';
CREATE ROLE smon LOGIN PASSWORD 'smon';
CREATE DATABASE smon OWNER smon ENCODING 'UTF8';
CREATE ROLE hmon LOGIN PASSWORD 'hmon';
CREATE DATABASE hmon OWNER hmon ENCODING 'UTF8';
CREATE ROLE sentry LOGIN PASSWORD 'sentry';
CREATE DATABASE sentry OWNER sentry ENCODING 'UTF8';
CREATE ROLE navaud LOGIN PASSWORD 'navaud';
CREATE DATABASE navaud OWNER navaud ENCODING 'UTF8';
CREATE ROLE navmeta LOGIN PASSWORD 'navmeta';
CREATE DATABASE navmeta OWNER navmeta ENCODING 'UTF8';
EOF

sed -i "s#host all all 127.0.0.1/32 trust#host all all 127.0.0.1/32 md5#" /var/lib/pgsql/data/pg_hba.conf
echo "listen_addresses = '*'" >> /var/lib/pgsql/data/postgresql.conf
service postgresql reload

service cloudera-scm-server start


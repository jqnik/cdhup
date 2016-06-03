#!/bin/bash
# (c) copyright 2014 martin lurie sample code not supported

JCE_POL_ZIP=$1


os_env() {
  OS_NAME=$(python -c "import platform;print(platform.linux_distribution(full_distribution_name=0)[0].lower())")
  OS_VERSION=$(python -c "import platform;print(platform.linux_distribution()[1])")
  OS_MAJOR_VERSION=`echo $OS_VERSION | cut -d'.' -f1`
  OS_ID=$(python -c "import platform;print(platform.linux_distribution()[2])")
  echo "INFO: Operating system: ${OS_NAME} ${OS_VERSION} ${OS_ID}"

  if ( [ "$OS_NAME" == "redhat" ] || [ "$OS_NAME" == "centos" ] ) ; then
    if [[ $OS_MAJOR_VERSION == "7" ]]; then
      KERB_START_COMMAND="sudo systemctl start krb5kdc kadmin"
      KERB_STOP_COMMAND="sudo systemctl stop krb5kdc kadmin"
      KERB_ENABLE_COMMAND="sudo systemctl enable krb5kdc kadmin"
      KDC_STATUS_COMMAND="sudo systemctl is-active krb5kdc| grep active"
      KADMIN_STATUS_COMMAND="sudo systemctl is-active kadmin| grep active"
      KERB_PACKAGES="krb5-server openldap-clients krb5-workstation"
    else
      KERB_START_COMMAND="sudo service krb5kdc start && sudo systemctl kadmin start"
      KERB_STOP_COMMAND="sudo service krb5kdc start && sudo systemctl kadmin start"
      KERB_ENABLE_COMMAND="sudo chkconfig krb5kdc on && sudo chkconfig kadmin on"
      KDC_STATUS_COMMAND="sudo service krb5kdc status| grep running"
      KADMIN_STATUS_COMMAND="sudo service kadmin status| grep running"
      KERB_PACKAGES="krb5-server openldap-clients krb5-workstation"
    fi
  else
    KERB_START_COMMAND="sudo service start krb5kdc && sudo systemctl start kadmin"
    KERB_STOP_COMMAND="sudo service start krb5kdc && sudo systemctl start kadmin"
    KERB_ENABLE_COMMAND="sudo chkconfig krb5kdc on && sudo chkconfig kadmin on"
    KDC_STATUS_COMMAND="sudo service krb5kdc status| grep running"
    KADMIN_STATUS_COMMAND="sudo service kadmin status| grep running"
    KERB_PACKAGES="krb5-server openldap-clients krb5-workstation"
  fi

}

os_env

sudo yum install -y $KERB_PACKAGES

# update the config files for the realm name and hostname
# in the quickstart VM
# notice the -i.xxx for sed will create an automatic backup
# of the file before making edits in place
# 
# set the Realm
sudo sed -i.orig 's/EXAMPLE.COM/CLOUDERA/g' /etc/krb5.conf
# on RHEL7/Centos7 the relevant lines seem to be commented out... whyyyy?
sudo sed -i 's/#//g' /etc/krb5.conf
# also some default krb5.conf's may dictacte a keyring based ticket cache
# we're not going to entertain such nonsense
sudo sed -i 's/default_ccache_name.*//' /etc/krb5.conf
# set the hostname for the kerberos server
sudo sed -i.m1 "s/kerberos.example.com/`hostname`/g" /etc/krb5.conf
# change domain name to cloudera 
sudo sed -i.m2 's/example.com =/cloudera =/g' /etc/krb5.conf

# download UnlimitedJCEPolicyJDK7.zip from Oracle into
# the /root directory
# we will use this for full strength 256 bit encryption

#sudo yum install -y unzip
#sudo mkdir jce
#cd jce
#sudo cp $JCE_POL_ZIP .
#sudo unzip ./*.zip
# save the original jar files
#sudo cp /usr/java/jdk1.7.0_67-cloudera/jre/lib/security/local_policy.jar local_policy.jar.orig
#sudo cp /usr/java/jdk1.7.0_67-cloudera/jre/lib/security/US_export_policy.jar US_export_policy.jar.orig
# copy the new jars into place
#sudo cp ./UnlimitedJCEPolicy/local_policy.jar /usr/java/jdk1.7.0_67-cloudera/jre/lib/security/local_policy.jar
#sudo cp ./UnlimitedJCEPolicy/US_export_policy.jar /usr/java/jdk1.7.0_67-cloudera/jre/lib/security/US_export_policy.jar
#cd -

# now create the kerberos database
sudo kdb5_util create -s <<EOF
cloudera
cloudera
EOF

# update the kdc.conf file
sudo sed -i.orig 's/EXAMPLE.COM/CLOUDERA/g' /var/kerberos/krb5kdc/kdc.conf
# this will add a line to the file with ticket life
sudo sed -i.m1 '/dict_file/a max_life = 1d' /var/kerberos/krb5kdc/kdc.conf
# add a max renewable life
sudo sed -i.m2 '/dict_file/a max_renewable_life = 7d' /var/kerberos/krb5kdc/kdc.conf
# indent the two new lines in the file
sudo sed -i.m3 's/^max_/  max_/' /var/kerberos/krb5kdc/kdc.conf

# the acl file needs to be updated so the */admin
# is enabled with admin privileges 
sudo sed -i 's/EXAMPLE.COM/CLOUDERA/' /var/kerberos/krb5kdc/kadm5.acl

# The kerberos authorization tickets need to be renewable
# if not the Hue service will show bad (red) status
# and the Hue “Kerberos Ticket Renewer” will not start
# the error message in the log will look like this:
#  kt_renewer   ERROR    Couldn't renew # kerberos ticket in 
#  order to work around Kerberos 1.8.1 issue.
#  Please check that the ticket for 'hue/quickstart.cloudera' 
#  is still renewable

# update the kdc.conf file to limit to weak crypto
sudo sed -i.m4 's/supported_enctypes =.*/supported_enctypes = aes128-cts:normal/' /var/kerberos/krb5kdc/kdc.conf
# update the kdc.conf file to allow renewable
sudo sed -i.m3 '/supported_enctypes/a default_principal_flags = +renewable, +forwardable' /var/kerberos/krb5kdc/kdc.conf
# fix the indenting
sudo sed -i.m5 's/^default_principal_flags/  default_principal_flags/' /var/kerberos/krb5kdc/kdc.conf

# start up the kdc server and the admin server
$KERB_START_COMMAND

# There is an addition error message you may encounter
# this requires an update to the krbtgt principal

# 5:39:59 PM 	ERROR 	kt_renewer 	
#
#Couldn't renew kerberos ticket in order to work around 
# Kerberos 1.8.1 issue. Please check that the ticket 
# for 'hue/quickstart.cloudera' is still renewable:
#  $ kinit -f -c /tmp/hue_krb5_ccache
#If the 'renew until' date is the same as the 'valid starting' 
# date, the ticket cannot be renewed. Please check your 
# KDC configuration, and the ticket renewal policy 
# (maxrenewlife) for the 'hue/quickstart.cloudera' 
# and `krbtgt' principals.
#

sudo kadmin.local <<eoj
modprinc -maxrenewlife 1week krbtgt/CLOUDERA@CLOUDERA
eoj

sudo kadmin.local <<eoj
cpw -randkey krbtgt/CLOUDERA@CLOUDERA
eoj
# now just add a few user principals 
#kadmin:  addprinc -pw <Password>
# cloudera-scm/admin@YOUR-LOCAL-REALM.COM

# add the admin user that CM will use to provision
# kerberos in the cluster
sudo kadmin.local <<eoj
addprinc -pw cloudera cloudera-scm/admin@CLOUDERA
modprinc -maxrenewlife 1week cloudera-scm/admin@CLOUDERA
eoj

#The files will look like this:

# make the kerberos services autostart
$KERB_ENABLE_COMMAND

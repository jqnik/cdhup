#!/bin/bash
# (c) copyright 2014 martin lurie sample code not supported

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
      KERB_PACKAGES="openldap-clients krb5-workstation"
    else
      KERB_START_COMMAND="sudo service krb5kdc start && sudo systemctl kadmin start"
      KERB_STOP_COMMAND="sudo service krb5kdc start && sudo systemctl kadmin start"
      KERB_ENABLE_COMMAND="sudo chkconfig krb5kdc on && sudo chkconfig kadmin on"
      KDC_STATUS_COMMAND="sudo service krb5kdc status| grep running"
      KADMIN_STATUS_COMMAND="sudo service kadmin status| grep running"
      KERB_PACKAGES="openldap-clients krb5-workstation"
    fi
  else
    KERB_START_COMMAND="sudo service start krb5kdc && sudo systemctl start kadmin"
    KERB_STOP_COMMAND="sudo service start krb5kdc && sudo systemctl start kadmin"
    KERB_ENABLE_COMMAND="sudo chkconfig krb5kdc on && sudo chkconfig kadmin on"
    KDC_STATUS_COMMAND="sudo service krb5kdc status| grep running"
    KADMIN_STATUS_COMMAND="sudo service kadmin status| grep running"
    KERB_PACKAGES="openldap-clients krb5-workstation"
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
sudo sed -i.m1 "s/kerberos.example.com/forge-master/g" /etc/krb5.conf
# change domain name to cloudera 
sudo sed -i.m2 's/example.com =/cloudera =/g' /etc/krb5.conf

# download UnlimitedJCEPolicyJDK7.zip from Oracle into
# the /root directory
# we will use this for full strength 256 bit encryption

#mkdir jce
#cd jce
# unzip ../UnlimitedJCEPolicyJDK7.zip 
# save the original jar files
#cp /usr/java/jdk1.7.0_67-cloudera/jre/lib/security/local_policy.jar local_policy.jar.orig
#cp /usr/java/jdk1.7.0_67-cloudera/jre/lib/security/US_export_policy.jar US_export_policy.jar.orig

# copy the new jars into place
#cp /root/jce/UnlimitedJCEPolicy/local_policy.jar /usr/java/jdk1.7.0_67-cloudera/jre/lib/security/local_policy.jar
#cp /root/jce/UnlimitedJCEPolicy/US_export_policy.jar /usr/java/jdk1.7.0_67-cloudera/jre/lib/security/US_export_policy.jar

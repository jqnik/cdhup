cores=3
memory=10240
disk_size=20480
jdk_path=jdk-8u60-linux-x64.rpm
cmrpm_path=cmrpms
parcel_path=parcels
iso_path=/Users/jkunigk/centos_isos
# choose a DVD image. min images don't have kernel-devel, which fails the build of guest additions
iso_url=http://mirror.cuegee.de/centos/7/isos/x86_64/CentOS-7-x86_64-DVD-1511.iso
iso_checksum=4c6c65b5a70a1142dadb3c65238e9e97253c0d3a
iso_checksum_type=sha1
kickstart=ks7.cfg
fqdn=cdhup.fq.dn
ip_on_host_network="10.0.0.4"
db_type=mysql
db_pass=test
forge_cm_provision_script=vagrant_scripts/forge_cm.sh
forge_cdh_provision_script=vagrant_scripts/forge_cdh.sh
#forge base is absolute path in fs root of target system
forge_base=/vagrant/forge
#provisionator base is absolute path in fs root of target system
provisionator_base=/vagrant/provisionator
#cluster conf is absolute path in fs root of target system
cluster_conf=/vagrant/provisionator/my2.json

run_packer=true

vm_name=`echo $fqdn | cut -f1 -d '.'`
domain=`echo $fqdn | cut -f2- -d '.'`
iso_name=`basename $iso_url`

if [ $run_packer == "true" ]
then
    vagrant destroy -f
    packer build \
    -var "iso_path=$iso_path" \
    -var "iso_name=$iso_name" \
    -var "iso_url=$iso_url" \
    -var "kickstart=$kickstart" \
    -var "cpus=$cores" \
    -var "memory=$memory" \
    -var "disk_size=$disk_size" \
    -var "vm_name=$vm_name" \
    -var "iso_checksum=$iso_checksum" \
    -var "iso_checksum_type=$iso_checksum_type" \
    centos_cloudera.json
    vagrant box add --force --name $vm_name `pwd`/box/virtualbox/$vm_name*
fi

# These parameters need to be pushed into the Vagrantfile directly,
# so that commands like 'vagrant up', 'vagrant ssh' work after provisioning time
# When required, we use alternate regex delimiter '~', since $vars may contain slashes
sed -i -e "s/options\[:fqdn\] =.*/options\[:fqdn\] = \"$fqdn\"/" Vagrantfile
sed -i -e "s/options\[:vm_name\] =.*/options\[:vm_name\] = \"$vm_name\"/" Vagrantfile
sed -i -e "s/options\[:domain\] =.*/options\[:domain\] = \"$domain\"/" Vagrantfile
sed -i -e "s/options\[:cores\] =.*/options\[:cores\] = $cores/" Vagrantfile
sed -i -e "s/options\[:memory\] =.*/options\[:memory\] = $memory/" Vagrantfile
sed -i -e "s~options\[:jdk_path\] =.*~options\[:jdk_path\] = \"$jdk_path\"~" Vagrantfile
sed -i -e "s~options\[:cmrpm_path\] =.*~options\[:cmrpm_path\] = \"$cmrpm_path\"~" Vagrantfile
sed -i -e "s~options\[:parcel_path\] =.*~options\[:parcel_path\] = \"$parcel_path\"~" Vagrantfile
sed -i -e "s/options\[:ip_on_host_network\] =.*/options\[:ip_on_host_network\] = \"$ip_on_host_network\"/" Vagrantfile
sed -i -e "s/options\[:db_type\] =.*/options\[:db_type\] = \"$db_type\"/" Vagrantfile
sed -i -e "s/options\[:db_pass\] =.*/options\[:db_pass\] = \"$db_pass\"/" Vagrantfile
sed -i -e "s~options\[:forge_cm_provision_script\] =.*~options\[:forge_cm_provision_script\] = \"$forge_cm_provision_script\"~" Vagrantfile
sed -i -e "s~options\[:forge_cdh_provision_script\] =.*~options\[:forge_cdh_provision_script\] = \"$forge_cdh_provision_script\"~" Vagrantfile
sed -i -e "s~options\[:forge_base\] =.*~options\[:forge_base\] = \"$forge_base\"~" Vagrantfile
sed -i -e "s~options\[:provisionator_base\] =.*~options\[:provisionator_base\] = \"$provisionator_base\"~" Vagrantfile
sed -i -e "s~options\[:cluster_conf\] =.*~options\[:cluster_conf\] = \"$cluster_conf\"~" Vagrantfile

# run vagrant ssh at the end to log in
# run vagrant provision to run the vm-internal provision scripts again
# run vagrant destroy to re-provision the vm image completely anew
# run ./cdhup.sh again with run_packer!=true to re-populate the Vagrantfile again
# run ./cdhup.sh again with run_packer=true to start over with everything

vagrant up

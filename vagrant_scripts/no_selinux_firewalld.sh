for i in /etc/sysconfig/selinux /etc/selinux/config
do
    if [ -e $i ]
    then
        sed -i 's/permissive/disabled/g'  $i
    fi
done
systemctl stop firewalld.service && systemctl disable firewalld.service

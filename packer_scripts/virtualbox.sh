#!/bin/bash -eux

SSH_USER=${SSH_USERNAME:-vagrant}
SSH_USER_HOME=${SSH_USER_HOME:-/home/${SSH_USER}}

# on some versions of RHEL the packages are called kernel-*-$(uname -r) on some simply kernel-*
yum install -y kernel-headers kernel-devel
yum install -y bzip2 kernel-headers-$(uname -r) kernel-devel-$(uname -r)
yum install -y bzip2 gcc make perl curl wget dkms patch net-tools git

    

if [[ $PACKER_BUILDER_TYPE =~ virtualbox ]]; then
    echo "==> Installing VirtualBox guest additions"
    # Assume that we've installed all the prerequisites:
    # kernel-headers-$(uname -r) kernel-devel-$(uname -r) gcc make perl
    # from the install media via ks.cfg

    VBOX_VERSION=$(cat $SSH_USER_HOME/.vbox_version)
    mount -o loop $SSH_USER_HOME/VBoxGuestAdditions_$VBOX_VERSION.iso /mnt
    sh /mnt/VBoxLinuxAdditions.run --nox11
    umount /mnt
    #rm -rf $SSH_USER_HOME/VBoxGuestAdditions_$VBOX_VERSION.iso
    rm -f $SSH_USER_HOME/.vbox_version

    if [[ $VBOX_VERSION = "4.3.10" ]]; then
        ln -s /opt/VBoxGuestAdditions-4.3.10/lib/VBoxGuestAdditions /usr/lib/VBoxGuestAdditions
    fi


    # don't ask me why, but vboxsf is not getting loaded after booting...
    echo "exec /sbin/modprobe vboxsf" >> /etc/sysconfig/modules/vboxsf.modules
    chmod +x /etc/sysconfig/modules/vboxsf.modules

    #echo "==> Removing packages needed for building guest tools"
    #yum -y remove gcc cpp libmpc mpfr kernel-devel kernel-headers perl
fi

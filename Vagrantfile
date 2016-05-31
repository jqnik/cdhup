### parameters section. this is modified by cdhup.sh ##########
options = {}
options[:fqdn] =
options[:vm_name] =
options[:domain] =
options[:cores] =
options[:memory] =
options[:ip_on_host_network] =
options[:cmrpm_path] =
options[:parcel_path] =
options[:jdk_path] =
options[:db_type] =
options[:db_pass] =
options[:forge_cm_provision_script] =
options[:forge_base] =
options[:forge_cdh_provision_script] =
options[:provisionator_base] =
options[:cluster_conf] =

###############################################################
VAGRANTFILE_API_VERSION = "2"

################## main Vagrantfile section ###################
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.hostmanager.enabled = true

  config.vm.box = options[:vm_name]
  config.ssh.password = "vagrant"

  config.vm.define options[:vm_name], primary: true do |master|
    master.vm.network "private_network", ip: options[:ip_on_host_network]
    #master.vm.provision :hostmanager
    master.vm.provision :shell, :path => "vagrant_scripts/cdh_common.sh"
    master.vm.provision :shell, :path => "vagrant_scripts/cdh_repos.sh",
        :args =>
        options[:cmrpm_path].to_s + " " +
        options[:parcel_path].to_s + " " +
        options[:fqdn].to_s
    # TODO: also pass fqdn to adapt scm-agent's config.ini
    master.vm.provision :shell, :path => options[:forge_cm_provision_script],
        :args =>
        options[:forge_base].to_s + " " +
        options[:db_type].to_s + " " +
        options[:db_pass].to_s
    master.vm.provision :shell, :path => options[:forge_cdh_provision_script],
        :args =>
        options[:provisionator_base].to_s + " " +
        options[:cluster_conf].to_s
    master.vm.provider :virtualbox do |v|
      v.name = options[:vm_name]
      v.customize ["modifyvm", :id, "--memory", options[:memory]]
      v.customize ["modifyvm", :id, "--cpus", options[:cores]]
    end 
    master.vm.hostname = options[:fqdn]
    master.hostmanager.aliases = options[:vm_name]
    master.vm.provision :hostmanager
  end

end

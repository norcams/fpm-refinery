# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure('2') do |config|

  # Strings identifying Bento baseboxes from https://github.com/opscode/bento
  %w{
    centos-6.6
    centos-7.0
    debian-7.8
    fedora-21
    ubuntu-14.04
  }.each do |basebox|
    # Easier instance naming without dots or dashes
    instance = basebox.delete('-.')
    config.vm.define instance do |c|
      c.vm.box = "#{instance}"
      c.vm.hostname = "#{instance}.fpm-refinery.local"
      c.vm.box_url = "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_#{basebox}_chef-provisionerless.box"
      if ENV.key?('FPM_REFINERY_SCRIPT')
        $provision = ENV['FPM_REFINERY_SCRIPT']
      else
        $provision = 'provision.sh'
      end
      c.vm.provision :shell, :path => $provision, args: "#{instance}"
    end
  end

  config.vm.provider :virtualbox do |vb|
    vb.customize [
      'modifyvm', :id,
      '--memory', '1536',
      '--cpus', '2'
    ]
  end

  config.vm.synced_folder '../', '/vagrant'

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :machine
  end

end

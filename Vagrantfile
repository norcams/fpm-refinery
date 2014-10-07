# -*- mode: ruby -*-
# vi: set ft=ruby :

$provision=<<SHELL
wget -qO- https://raw.githubusercontent.com/norcams/omnibus-drop/master/omnibus-drop.sh | \
  bash -s -- -M https://raw.githubusercontent.com/norcams/fpm-refinery/master fpm-refinery 0.1.0-1 --no-verify
SHELL

Vagrant.configure('2') do |config|

  # Strings identifying Bento baseboxes from https://github.com/opscode/bento
  %w{
    centos-6.5
    centos-7.0
    debian-7.6
    fedora-20
    ubuntu-14.04
  }.each do |basebox|
    # Easier instance naming without dots or dashes
    instance = basebox.delete('-.')
    config.vm.define instance do |c|
      c.vm.box = "#{instance}"
      c.vm.hostname = "#{instance}.fpm-refinery.local"
      c.vm.box_url = "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_#{basebox}_chef-provisionerless.box"
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
  config.vm.provision :shell, :inline => $provision

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :machine
  end

end

# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure('2') do |config|

  # Strings identifying Bento baseboxes from https://github.com/opscode/bento
  %w{
    centos-6.5
    debian-7.4
    fedora-20
    ubuntu-12.04
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
  config.vm.provision :shell, :path => 'provision/01-install_ruby-install.sh'
  config.vm.provision :shell, :path => 'provision/02-install_ruby.sh'
  config.vm.provision :shell, :path => 'provision/03-install_fpm-cookery.sh'

end

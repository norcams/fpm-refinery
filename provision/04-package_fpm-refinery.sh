#!/bin/bash



cd /vagrant/fpm-refinery
version=$(cat bootstrap.rb | grep version | cut -d\' -f 2)

if [ -z $(ls pkg/fpm-refinery-$version*) ]
then
    /opt/fpm-refinery/embedded/bin/fpm-cook package bootstrap.rb
    /opt/fpm-refinery/embedded/bin/fpm-cook package ruby-install.rb
fi

 

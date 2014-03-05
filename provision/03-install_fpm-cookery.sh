#!/bin/bash

if [ ! -f "${omnibus_prefix}/embedded/bin/fpm-cook" ]
then
    /opt/fpm-refinery/embedded/bin/gem install fpm-cookery --no-ri --no-rdoc
fi


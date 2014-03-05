#!/bin/bash
# Installs ruby from source mirrors using ruby-install
#
match_version=2.0.0-p451
mirror=https://ftp.ruby-lang.org/pub/ruby
omnibus_prefix=/opt/fpm-refinery

if [ ! -f "${omnibus_prefix}/embedded/bin/ruby" ]
then
    # Only for centos/rhel: if package exists, use it
    if [ $(ls -t ../pkg/fpm-refinery-*.rpm | head -n 1) ]; then
        yum install -y $(ls -t ../pkg/ruby-install-*.rpm | head -n 1)
        exit 0
    fi
    sudo /usr/local/bin/ruby-install \
        -i $omnibus_prefix/embedded \
        -M $mirror ruby $match_version \
        -- --disable-install-doc --enable-shared
    # Shrink!
    rm -f "${omnibus_prefix}/embedded/lib/libruby-static.a"
    find "${omnibus_prefix}/embedded" -name '*.so' -o -name '*.so.*' | xargs strip
fi


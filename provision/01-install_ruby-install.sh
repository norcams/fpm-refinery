#!/bin/bash
# Installs ruby-install from github archive
#
version=0.4.1
archive_url="https://github.com/postmodern/ruby-install/archive/v${version}.tar.gz"

# Check whether a command exists - returns 0 if it does, 1 if it does not
exists() {
    if command -v $1 >/dev/null 2>&1
    then
        return 0
    else
        return 1
    fi
}

if ! ((exists ruby-install) || (exists /usr/local/bin/ruby-install));
then
    tmp_dir="$(mktemp -d -t tmp.XXXXXXXX || echo "/tmp")"
    wget -O "${tmp_dir}/ruby-install-${version}.tar.gz" "${archive_url}"
    if [ -f "${tmp_dir}/ruby-install-${version}.tar.gz" ]; then
        cd "${tmp_dir}"
        tar -xzvf "ruby-install-${version}.tar.gz"
        cd "ruby-install-${version}" && sudo make install
    fi
fi


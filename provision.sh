#!/bin/bash

project="fpm-refinery"
version="0.1.0-1"

projectdir="/vagrant/fpm-refinery"
prefix="/opt/$project"

box="$1"
packagedir="$projectdir/pkg/$box"

baseurl="http://folk.uio.no/beddari/pkg"
case "$box" in
  fedora*|centos*) filename="${project}-${version}.x86_64.rpm" ;;
  debian*|ubuntu*) filename="${project}_${version}_amd64.deb" ;;
esac
url="${baseurl}/${box}/${filename}"

case "$box" in
  fedora21)
    checksum=a71cf9f65dc6e5512174c5407eee3a7863a826d111dd978f6004b88c598a95e7
    ;;
  centos66)
    checksum=94871f04046fb51f572e46412be301c03fa3e8954a68e822eac9ccac013bfd1e
    ;;
  centos70)
    checksum=607e7b1535f1e9e04d974edd98cc4e0448c7c583ad45db2bba1db1a58e0069a2
    ;;
  debian78)
    checksum=c1b5c3afc2ebf018e9b75308c45a537189e157ca50e0168a0de9506f08ab23fa
    ;;
  ubuntu1404)
    checksum=548c2448388befbc25ff062e5ef1ce7111c29ee91af371b21d4c654fbe5857a7
    ;;
esac

#
# Prints a log message.
#
log()
{
  if [[ -t 1 ]]; then
    echo -e "\x1b[1m\x1b[32m>>>\x1b[0m \x1b[1m$1\x1b[0m"
  else
    echo ">>> $1"
  fi
}

#
# Prints a warn message.
#
warn()
{
  if [[ -t 1 ]]; then
    echo -e "\x1b[1m\x1b[33m***\x1b[0m \x1b[1m$1\x1b[0m" >&2
  else
    echo "*** $1" >&2
  fi
}

#
# Prints an error message.
#
error()
{
  if [[ -t 1 ]]; then
    echo -e "\x1b[1m\x1b[31m!!!\x1b[0m \x1b[1m$1\x1b[0m" >&2
  else
    echo "!!! $1" >&2
  fi
}

#
# Prints an error message and exists with -1.
#
fail()
{
  error "$*"
  exit -1
}

download_and_verify()
{
  if [[ ! -s "$packagedir/$filename" ]]; then
    mkdir -p "$packagedir" || return $?
    log "Downloading $url ..."
    download "$url" "$packagedir/$filename" || return $?
  fi
  verify "$packagedir/$filename" "$checksum" \
    || { error "File checksum verification failed."; return $?; }
}

#
# Downloads a URL.
#
download()
{
  local url="$1"
  local dest="$2"

  [[ -d "$dest" ]] && dest="$dest/${url##*/}"
  [[ -f "$dest" ]] && return

  # Auto-detect the downloader.
  if   exists "curl"; then downloader="curl"
  elif exists "wget"; then downloader="wget"
  fi

  case "$downloader" in
    wget) wget --no-verbose -c -O "$dest.part" "$url" || return $? ;;
    curl) curl -s -f -L -C - -o "$dest.part" "$url" || return $? ;;
    "")
      error "Could not find wget or curl"
      return 1
      ;;
  esac

  mv "$dest.part" "$dest" || return $?
}

#
# Verify a file using a SHA256 checksum
#
verify()
{
  local path="$1"
  local checksum="$2"

  # Auto-detect checksum verification util
  if   exists "sha256sum"; then verifier="sha256sum"
  elif exists "shasum";    then verifier="shasum -a 256"
  fi

  if [[ -z "$verifier" ]]; then
    error "Unable to find the checksum utility."
    return 1
  fi

  if [[ -z "$checksum" ]]; then
    error "No checksum given."
    return 1
  fi

  local match='^'$checksum'\ '
  if [[ ! "$($verifier "$path")" =~ $match ]]; then
    error "$path is invalid!"
    return 1
  else
    log "File checksum verified OK."
  fi
}

#
# Check whether a command exists - returns 0 if it does, 1 if it does not
#
exists()
{
    local cmd="$1"
    if command -v $cmd >/dev/null 2>&1
    then
        return 0
    else
        return 1
    fi
}

install_package()
{
  local package="$packagedir/$filename"

  case "$box" in
    fedora*|centos*|redhat*)
      $sudo yum install -y "$package" || return $?
      ;;
    debian*|ubuntu*)
      $sudo env DEBIAN_FRONTEND=noninteractive dpkg -i "$package" || return $?
      $sudo env DEBIAN_FRONTEND=noninteractive apt-get install -f || return $?
      ;;
    *)
      fail "Sorry, no support yet(?) for "$box" packages"
      ;;
  esac
}


# Main logic
# Install only if /opt/$project does not exist
if [[ ! -d "/opt/$project" ]]; then
  download_and_verify || fail "Error downloading/verifying $project $version"
  install_package  || fail "Installing $project $version failed."
else
  log "/opt/$project already exists - skipping package installation."
fi


#!/bin/bash
shopt -s extglob

ver="0.1.0"

working_dir="$PWD"
source_dir="${BASH_SOURCE[0]%/*}"

#
# Check whether a command exists - returns 0 if it does, 1 if it does not
#
exists() {
    local cmd="$1"
    if command -v $cmd >/dev/null 2>&1
    then
        return 0
    else
        return 1
    fi
}

#
# Auto-detect the downloader.
#
if   exists "curl"; then downloader="curl"
elif exists "wget"; then downloader="wget"
fi

#
# Auto-detect checksum verification util
#
if   exists "sha256sum"; then verifier="sha256sum"
elif exists "shasum";    then verifier="shasum -a 256"
fi

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

#
# Downloads a URL.
#
download()
{
  local url="$1"
  local dest="$2"

  [[ -d "$dest" ]] && dest="$dest/${url##*/}"
  [[ -f "$dest" ]] && return

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
# Downloads a package.
#
download_package()
{
  if [[ -n "$url" ]]; then
    log "Downloading package: $url"
    mkdir -p "$packagedir" || return $?
    download "$url" "$packagedir/$filename" || return $?
  else
    log "No url specified, package download skipped."
  fi
}

#
# Verify a file using a SHA256 checksum
#
verify()
{
  local path="$1"
  local checksum="$2"

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
# Verify downloaded package
#
verify_package()
{
  verify "$packagedir/$filename" "$checksum"
}

#
# Checks if it is possible to install this package type
#
is_supported()
{
  local supp="$1"
  local fmt="$2"

  local match='(^|\ )'$fmt'(\ |$)'
  if [[ ! $supp =~ $match ]]; then
    error "$fmt packages are not supported on this system"
    return 1
  else
    return 0
  fi
}

#
# Check if package is already installed and return 0 if it is
#
installed()
{
  local format="$package_format"
  local package="$packagedir/$filename"

  case "$format" in
    rpm)
      local data="$($sudo rpm -qp "$package" 2>/dev/null)"
      $sudo rpm --quiet -qi "$data"
      return $?
      ;;
    deb)
      local name="$(dpkg -f "$package" Package 2>/dev/null)"
      local vers="$(dpkg -f "$package" Version 2>/dev/null)"
      local inst="$(dpkg-query -W -f '${Version}\n' $name 2>/dev/null)"
      if [[ -n $name && ($vers == $inst) ]]; then
        return 0
      else
        return 1
      fi
      ;;
    *)
      fail "Unknown package type $type: $package"
      ;;
  esac
}

#
# Executes a package install based on package type
#
install_p()
{
  local format="$1"
  local package="$2"

  case "$format" in
    rpm)
      $sudo yum install -y "$package" || return $?
      ;;
    deb)
      $sudo env DEBIAN_FRONTEND=noninteractive dpkg -i "$package" || return $?
      $sudo env DEBIAN_FRONTEND=noninteractive apt-get install -f || return $?
      ;;
    *)
      fail "Sorry, no support yet(?) for "$format" packages"
      ;;
  esac
}

#
# Do the package installation
#
install_package()
{
  log "Installing $project $version from $packagedir/$filename"
  install_p "$package_format" "$packagedir/$filename" || return $?
  log "Successfully installed $project $version from $filename"
}

#
# Parses command-line options
#
package_metadata()
{
  case $box in
    centos*)
      package_url=
      package_filename=
      package_checksum=
      ;;
    ubuntu1404)
      package_url=
      package_filename=
      package_checksum=
      ;;
    *)
      echo "No package metadata defined for $box"
      return 1
      ;;
  esac
}


#
# Main script loop
#
box=$1

echo "We are on $box"
package_metadata || exit 0
download_package || fail "Package download failed."
verify_package   || fail "Package checksum verification failed."

if installed; then
  log "Package $project $version is already installed."
else
  install_package || fail "Installation failed."
fi


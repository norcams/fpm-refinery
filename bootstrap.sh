#!/bin/bash

project="fpm-refinery"
version="0.1.0-1"

projectdir="/vagrant/fpm-refinery"
prefix="/opt/$project"

box="$1"
packagedir="$projectdir/pkg/$box"

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

build()
{
  local cache="$projectdir/cache"
  local builddir="/tmp/$project-builddir"

  case "$box" in
    fedora*|centos*|redhat*)
      yum -y install gcc gcc-c++ make rpm-build || return $?
      ;;
    debian*|ubuntu*)
      apt-get -y install build-essential || return $?
      ;;
  esac

  mkdir -p "$builddir" || { error "Could not create $builddir"; return $?; }

  build_ruby_install "0.5.0" \
    "https://github.com/postmodern/ruby-install/archive/v0.5.0.tar.gz" \
    "aa4448c2c356510cc7c2505961961a17bd3f3435842831e04c8516eb703afd19" \
    || { error "Could not build ruby-install."; return 1; }

  build_libyaml "0.1.6" \
    "http://pyyaml.org/download/libyaml/yaml-0.1.6.tar.gz" \
    "7da6971b4bd08a986dd2a61353bc422362bd0edcc67d7ebaac68c95f74182749" \
    || { error "Could not build libyaml."; return 1; }

  install_ruby "2.1.5" \
    "http://cache.ruby-lang.org/pub/ruby" \
    || { error "Could not build ruby."; return 1; }

  install_gem "fpm-cookery" "0.25.0" \
    || { error "Could not install gem."; return 1; }
}

package()
{
  if [[ -s "$projectdir/build.rb" ]]; then
    mkdir -p "$packagedir"
    "$prefix/embedded/bin/fpm-cook" package \
      --pkg-dir "$packagedir" --tmp-root "/tmp/$project-builddir" \
      "$projectdir/build.rb" || return $?
  else
    error "Missing $projectdir/recipe.rb"
    return 1
  fi
}

build_ruby_install()
{
  local version="$1"
  local url="$2"
  local checksum="$3"
  local filename="ruby-install-${version}.tar.gz"

  if [[ ! -s /usr/local/bin/ruby-install ]]; then
    download_and_verify || { error "Error downloading $url"; return 1; }
    cd "$builddir"
    tar -xvzf "$filename" || return $?
    cd "${filename%.tar.gz}"
    $sudo make install || return $?
  else
    log "$(/usr/local/bin/ruby-install --version) already present, skipping build."
  fi
}

build_libyaml()
{
  local version="$1"
  local url="$2"
  local checksum="$3"
  local filename="yaml-${version}.tar.gz"

  if [[ ! -s $prefix ]]; then
    download_and_verify || return $?
    cd "$builddir"
    tar -xvzf "$filename" || return $?
    cd "${filename%.tar.gz}"
    ./configure --prefix="$prefix/embedded" || return $?
    make || return $?
    $sudo make install || return $?
  else
    log "libyaml already present, skipping build."
  fi
}

install_ruby()
{
  local version="$1"
  local url="$2"
  local filename="ruby-${version}.tar.bz2"
  local no_dl=
  export PATH="$PATH:/usr/local/bin"

  if [[ ! -s "$prefix/embedded/bin/ruby" ]]; then
    [[ $no_download -eq 1 ]] && no_dl="--no-download"
    if [[ -s "$cache/$filename" ]]; then
      cp -n "$cache/$filename" "$builddir"
      no_dl="--no-download"
    fi
    $sudo ruby-install -i "$prefix/embedded" -j2 -M "$url" -s "$builddir" "$no_dl" \
      ruby "$version" -- --disable-install-doc --enable-shared || return $?
    # Shrink!
    $sudo rm -f "$prefix/embedded/lib/libruby-static.a"
    find "$prefix/embedded" -name '*.so' -o -name '*.so.*' | $sudo xargs strip
    cp -n "$builddir/$filename" "$cache" || return $?
  else
    log "$("$prefix/embedded/bin/ruby" -v) already present, skipping build."
  fi
}

install_gem()
{
  local gem="$1"
  local version="$2"
  local gembin="$prefix/embedded/bin/gem"
  local gemdir="$($sudo "$gembin" environment gemdir)" || return $?
  local gemcache="$cache/gems/${gemdir##*/}"

  if [[ ! -d "${gemdir}/gems/${gem}-${version}" ]]; then
    if [[ -s "${gemcache}/${gem}-${version}.gem" ]]; then
      # Install from cache
      log "Cached gem present. Installing $gem $version from cache."
      cd "$gemcache"
      $sudo "$gembin" install --no-document --local "${gem}-${version}.gem" || return $?
    else
      $sudo "$gembin" install --no-document "$gem" -v "$version" || return $?
      # cache gems - copy without overwriting existing files
      mkdir -p "$gemcache" || return $?
      cp -n "$gemdir/cache/"*.gem "$gemcache" || return $?
    fi
  else
    log "$gem $version already present, skipping build."
  fi
}

download_and_verify()
{
  if [[ ! -s "$cache/$filename" ]]; then
    mkdir -p "$cache" || return $?
    if [[ ! $no_download -eq 1 ]]; then
      download "$url" "$cache/$filename" || return $?
    fi
  fi
  if [[ ! -s "$cache/$filename" ]]; then
    error "Missing $cache/$filename, can't continue."
    return 1
  fi
  if [[ ! $no_verify -eq 1 ]]; then
    verify "$cache/$filename" "$checksum" \
      || { error "File checksum verification failed."; return $?; }
  fi
  cp -n "$cache/$filename" "$builddir" || return $?
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
exists() {
    local cmd="$1"
    if command -v $cmd >/dev/null 2>&1
    then
        return 0
    else
        return 1
    fi
}

# Main logic
# Build only if /opt/$project does not exist
if [[ ! -d "/opt/$project" ]]; then
  build   || fail "Building $project $version failed."
else
  log "/opt/$project already exists - skipping build."
fi

if [[ ! -f "$projectdir/pkg/.$box-$project-$version.cookie" ]]; then
  package || fail "Packaging $project $version failed."
  touch "$projectdir/pkg/.$box-$project-$version.cookie"
fi


#!/bin/bash

preinstall()
{
  # Build only if no package exists (for the current platform)
  if [[ ! -s "$packagedir/$filename" ]]; then
    build   || fail "Building components for $project $version failed."
    package || fail "Packaging $project $version failed."
  else
    log "$filename already present, skipping build."
  fi
}

build()
{
  local prefix="/opt/$project"
  local cache="$projectdir/cache"
  local builddir="/tmp/$project-builddir"

  mkdir -p "$builddir" || { error "Could not create $builddir"; return $?; }

  build_ruby_install "0.4.3" \
    "https://github.com/postmodern/ruby-install/archive/v0.4.3.tar.gz" \
    "0ec8c23699aad534dcab549c0f6543e066725a62f5b3d7e8dae311c61df1aef3" \
    || { error "Could not build ruby-install."; return 1; }

  build_libyaml "0.1.6" \
    "http://pyyaml.org/download/libyaml/yaml-0.1.6.tar.gz" \
    "7da6971b4bd08a986dd2a61353bc422362bd0edcc67d7ebaac68c95f74182749" \
    || { error "Could not build libyaml."; return 1; }

  install_ruby "2.1.3" \
    "http://cache.ruby-lang.org/pub/ruby" \
    || { error "Could not build ruby."; return 1; }

  install_gem "fpm-cookery" "0.25.0" \
    || { error "Could not install gem."; return 1; }
}

package()
{
  if [[ ! $no_download -eq 1 && -n "$remote_project" ]]; then
    download "$remote_project/recipe.rb" "$projectdir/recipe.rb"
  fi
  if [[ -s "$projectdir/recipe.rb" ]]; then
    "$prefix/embedded/bin/fpm-cook" package \
      --pkg-dir "$packagedir" --tmp-root "$builddir" \
      "$projectdir/recipe.rb" || return $?
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
    log "$(ruby-install --version) already present, skipping build."
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

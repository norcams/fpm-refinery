#!/bin/bash

preinstall()
{
  # Build only if no package exists (for the current platform)
  if [[ ! -s "$packagedir/$filename" ]]; then
    local prefix="/opt/$project"
    local builddir="/tmp/$project-builddir"
    local cache="$projectdir/cache"

    mkdir -p "$builddir"
    build || fail "Building components for $project $version package failed."
    package || fail "Could create package for $project $version"
    rm -rf "$buildir"
  else
    log "$filename already present, skipping build."
  fi
}

build()
{
  build_ruby_install "0.4.3" "https://github.com/postmodern/ruby-install/archive/v${version}.tar.gz" || return $?
  build_ruby         "2.1.3" "http://cache.ruby-lang.org/pub/ruby" || return $?
  install_gem        "fpm-cookery" "0.25.0" || return $?
}

package()
{
  if [[ -n "$project_mirror" && (! -s "$projectdir/recipe.rb") ]]; then
    download "$project_mirror/recipe.rb" "$projectdir/recipe.rb"
  fi
  "$prefix/embedded/bin/fpm-cook" \
    package --pkg-dir "$packagedir" --tmp-root "$builddir" "$projectdir/recipe.rb" || return $?
}

build_ruby_install()
{
  local version="$1"
  local url="$2"
  local filename="ruby-install-${version}.tar.gz"
  export PATH="$PATH:/usr/local/bin"

  if ! exists "ruby-install"; then
    if [[ ! -s "$cache/$filename" ]]; then
      mkdir -p "$cache" || return $?
      if [[ ! no_download -eq 1 ]]; then
        download "$url" "$cache/$filename" || return $?
      fi
    fi
    if [[ ! -s "$cache/$filename" ]]; then
      error "Missing $cache/$filename, can't continue."
      return 1
    fi
    cp -n "$cache/$filename" "$builddir" || return $?
    cd "$builddir"
    tar -xvzf "$filename" || return $?
    cd "${filename%.tar.gz}"
    $sudo make install || return $?
  else
    log "$(ruby-install --version) already present, skipping build."
  fi
}

build_ruby()
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


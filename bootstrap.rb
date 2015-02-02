class PuppetOmnibus < FPM::Cookery::Recipe
  homepage 'https://github.com/norcams/fpm-refinery'

  name 'fpm-refinery'
  version '0.1.0'
  description 'Tools around fpm, fpm-cookery and omnibus'
  revision 1
  maintainer 'code@beddari.net'
  license 'Apache 2.0 License'

  source '', :with => :noop

  # Build time system package dependencies are managed by 
  # bootstrap.sh and ruby-install

  # Runtime package dependencies below
  platforms [:ubuntu, :debian] do
    depends 'libffi6',
            'libncurses5',
            'libreadline6',
            'libssl1.0.0',
            'libtinfo5',
            'zlib1g',
            'libgdbm3'
  end
  platforms [:ubuntu] do depends.push('libffi6') end
  platforms [:debian] do depends.push('libffi5') end

  platforms [:fedora, :redhat, :centos] do
    depends 'zlib',
            'libffi',
            'gdbm',
            'rpm-build'
  end
  platforms [:fedora] do depends.push('openssl-libs') end
  platforms [:redhat, :centos] do depends.push('openssl') end

  # Do not specify any omnibus_recipes as we are packaging what we built with
  # bootstrap.sh
  omnibus_package true
  omnibus_dir     "/opt/#{name}"

  def build
    # Nothing
  end

  def install
    # Nothing
  end

end


class PuppetOmnibus < FPM::Cookery::Recipe
  homepage 'https://github.com/norcams/fpm-refinery'

  name 'fpm-refinery'
  version '0.1.0'
  description 'Tools around fpm, fpm-cookery and omnibus'
  revision 1
  maintainer 'code@beddari.net'
  license 'Apache 2.0 License'

  source '', :with => :noop

  platforms [:fedora, :redhat, :centos] do
    build_depends 'rpm-build'
    depends 'rpm-build'
  end

  omnibus_package true
  omnibus_dir     "/opt/#{name}"
  # Do not specify any omnibus_recipes as we are packaging what we built from
  # functions.sh

  def build
    # Nothing
  end

  def install
    # Nothing
  end

end


class PuppetOmnibus < FPM::Cookery::Recipe
  homepage 'https://github.com/norcams/fpm-refinery'

  name 'fpm-refinery'
  version '0.1.0'
  description 'Tools around fpm, fpm-cookery and omnibus'
  revision 1
  maintainer 'code@beddari.net'
  license 'Apache 2.0 License'

  source '', :with => :noop

  omnibus_package true
  omnibus_dir     "/opt/#{name}"

  # Do not specify any omnibus_recipes as we are packaging what we already
  # provisioned using Vagrant
  #
  # omnibus_recipes 'ruby-install'
  #                 'ruby',
  #                 'fpm-cookery'

  def build
    # Nothing
  end

  def install
    # Nothing
  end

end


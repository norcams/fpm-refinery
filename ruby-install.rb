class Ruby193 < FPM::Cookery::Recipe
  description 'Installs Ruby, JRuby, Rubinius or MagLev'

  name 'ruby-install'
  version '0.4.1'
  revision 1
  homepage 'https://github.com/postmodern/ruby-install#readme'
  source "https://github.com/postmodern/ruby-install/archive/v#{version}.tar.gz"
  md5 '921ee27b6f97412234a95394d079f6d0'

  maintainer 'code@beddari.net'
  license    'MIT'

  def build
    # Do nothing
  end

  def install
    make :install, 'PREFIX' => "#{prefix}/local"
  end
end

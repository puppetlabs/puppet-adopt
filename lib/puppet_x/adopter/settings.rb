require 'yaml'

class PuppetX::Adopter::Settings

  CLIENT_CERT_DEFAULTS = {
    'private_key'      => Puppet['hostprivkey'],
    'certficate'       => Puppet['hostcert'],
    'ca_certificate'   => Puppet['localcacert'],
    'hostname'         => Puppet['server']
  }

  def initialize(path = nil)
    @path = path || default_config

    load_settings
  end

  def default_config
    File.join( Puppet['confdir'], 'zero_config.yaml' )
  end

  def load_settings

    loaded_settings = Hash.new

    if File.exists? (@path)
      loaded_settings = YAML.load_file(@path)
    else
      # If a config file doesn't exist, use puppet server for
      # puppetdb and classifier hosts
      Puppet.notice "Configuration file #{@path} not found, using defaults."
    end

    defaults = {
      'puppetdb_client'        => CLIENT_CERT_DEFAULTS,
      'node_classifier_client' => CLIENT_CERT_DEFAULTS
    }

    @settings = defaults.merge loaded_settings
  end

  def [](setting)
    @settings[setting]
  end
end

require 'yaml'

class PuppetX::Adopter::Settings

  attr_reader :pdb_host, :nc_host

  def initialize(cf_path)
    @cf = read_settings(cf_path)
  end

  def read_settings(cf_path)
    cf = {}

    if File.exists? (cf_path)
      cf = YAML.load_file(cf_path)
      @pdb_host = cf['pdb_host']
      @nc_host = cf['nc_host']
    else
      # If a config file doesn't exist, use puppet server for
      # puppetdb and classifier hosts
      Puppet.notice "Configuration file #{cf_path} not found, assuming monolithic master"
    end

    return cf
  end

end

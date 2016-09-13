require 'puppet_x'

module PuppetX::Adopter
  require 'puppet_x/adopter/settings'

  def self.set_config_path(path)
    @config_path
  end

  def self.[](setting)
    @settings ||= PuppetX::Adopter::Settings.new(@config_path)
    @settings[setting]
  end
end

require 'puppet_x/adopter/client'
require 'puppet_x/adopter/nodes'
require 'puppet_x/adopter/event'
require 'puppet_x/adopter/processor'
require 'puppet_x/adopter/runner'
require 'puppet_x/adopter/util'


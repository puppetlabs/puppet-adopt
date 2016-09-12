require 'puppetdb'
require 'puppetclassify'
require 'puppet_x/adopter/settings'

module PuppetX::Adopter
  class Client

    @pdb_config = {}
    @nc_config = {}
    # Read settings from configuration file
    settings = PuppetX::Adopter::Settings.new(Puppet[:confdir] + '/adopter.yaml')
    @pdb_host = settings.pdb_host || Puppet['server']
    @nc_host = settings.nc_host || Puppet['server']

    class << self

      def pdb_config=(config)
        @pdb_config = config
      end

      def nc_config=(config)
        @nc_config = config
      end

      def pdb_config
        {
          'key'      => Puppet['hostprivkey'],
          'cert'     => Puppet['hostcert'],
          'ca_file'  => Puppet['localcacert'],
          'hostname' => @pdb_host
        }.merge @pdb_config
      end

      def nc_config
        {
          "ca_certificate_path" => Puppet['localcacert'],
          "certificate_path"    => Puppet['hostcert'],
          "private_key_path"    => Puppet['hostprivkey'],
          "hostname"            => @nc_host
        }.merge @nc_config
      end

      def verify_pdb_client
        # Better connection error checking should be built into the actual puppetdb-ruby lib :(
        begin
          pdb_client.request('nodes', nil)
        rescue
          raise(Puppet::Error,"PuppetDB server #{@pdb_host} cannot be reached")
        end
      end

      def verify_nc_client
        begin
          nc_client.groups.get_groups
        rescue
          raise(Puppet::Error, "Node Classifier #{@nc_host} cannot be reached")
        end
      end

      def build_nc_client
        @nc_client = PuppetClassify.new("https://#{nc_config['hostname']}:4433/classifier-api", nc_config)

        verify_nc_client
        @nc_client
      end

      def build_pdb_client
        @pdb_client = PuppetDB::Client.new({
          :server => "https://#{pdb_config['hostname']}:8081/pdb/query",
          :pem => pdb_config
        },4)

        verify_pdb_client
        @pdb_client
      end

      def nc_client
        @nc_client || build_nc_client
      end

      def pdb_client
        @pdb_client || build_pdb_client
      end
    end
  end
end

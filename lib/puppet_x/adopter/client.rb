require 'puppetdb'
require 'puppetclassify'
require 'puppet_x/adopter/settings'

module PuppetX::Adopter
  class Client

    class << self

      # Map from generalized settings to correct values for client
      def map_pdb_config
        mapping = {'private_key' => 'key', 'certificate' => 'cert', 'ca_certificate' => 'ca_file'}
        PuppetX::Adopter['puppetdb_client'].map {|k, v| [mapping[k] || k, v] }.to_h
      end

      # Map from generalized settings to correct values for client
      def map_nc_config
        mapping = {'private_key' => 'private_key_path', 'certificate' => 'certificate_path', 'ca_certificate' => 'ca_certificate_path'}
        PuppetX::Adopter['node_classifier_client'].map {|k, v| [mapping[k] || k, v] }.to_h
      end

      def verify_pdb_client
        # Better connection error checking should be built into the actual puppetdb-ruby lib :(
        begin
          pdb_client.request('nodes', nil)
        rescue
          raise(Puppet::Error,"PuppetDB server cannot be reached")
        end
      end

      def verify_nc_client
        begin
          nc_client.groups.get_groups
        rescue
          raise(Puppet::Error, "Node Classifier cannot be reached")
        end
      end

      def build_nc_client
        config = map_nc_config
        @nc_client = PuppetClassify.new("https://#{config['hostname']}:4433/classifier-api", config)

        verify_nc_client
        @nc_client
      end

      def build_pdb_client
        config = map_pdb_config
        @pdb_client = PuppetDB::Client.new({
          :server => "https://#{config['hostname']}:8081/pdb/query",
          :pem => config
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

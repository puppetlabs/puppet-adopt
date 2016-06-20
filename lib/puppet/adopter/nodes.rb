require 'puppet'
require 'puppet/adopter/client'

module Puppet::Adopter
  class NodeGroup

    attr_accessor :name, :pdb_client, :nc_client, :id, :nodes, :certnames, :rule

    def initialize(group_name, classifier_client = nil, puppetdb_client = nil)

      @name = group_name
      @pdb_client = puppetdb_client || Puppet::Adopter::Client.pdb_client
      @nc_client = classifier_client || Puppet::Adopter::Client.nc_client
      @nodes = Array.new
      @certnames = Array.new

      load_data
    end

    #Loads details of group
    def load_data
      @id = nc_client.groups.get_group_id(name)

      if exists?
        @data = nc_client.groups.get_group(id)

        rules = nc_client.rules.translate(@data['rule'])["query"]

        result = pdb_client.request('nodes',["extract","certname", rules])

        result.data.each do |node|
          @nodes << Puppet::Adopter::Node.new( node['certname'] )
          @certnames << node['certname']
        end
        @rule = rules
      end
    end

    def reload
      @nodes = Array.new
      @certnames = Array.new
      @data = nil

      load_data
    end

    def exists?
      id ? true : false
    end

    def node_count
      certnames.count
    end
  end

  class Node

    attr_accessor :name, :pdb

    def initialize(certname, pdb_client = nil)

      @name = certname
      @pdb = pdb_client || Puppet::Adopter::Client.pdb_client()
    end

    def report
      response = pdb.request('reports', ["and",["=","certname",name],["=","latest_report?",true]])

      response.data
    end

    def events
      response = pdb.request('events',["and",["=","latest_report?",true],["=","certname",name]])

      response.data
    end
  end
end

require 'pcp/client'
require 'timeout'
require 'ruby-progressbar'

class PuppetX::Adopter::Runner

  def initialize(group, config={})
    @group = group
    @config = config
  end

  def config=(config)
    @config = config
  end

  def config
    {
      server: "wss://#{Puppet['server']}:8142/pcp/v1.0",
      ssl_key: Puppet['hostprivkey'],
      ssl_cert: Puppet['hostcert'],
      ssl_ca_cert: Puppet['localcacert'],
    }.merge @config
  end

  def client
    unless EM.reactor_running?
      Thread.new { EM.run }
      Thread.pass until EM.reactor_running?
    end

    @client ||= PCP::Client.new(config)
  end

  def run(timeout = 60)

    unless client.associated?
      raise 'Failure connecting to PCP broker' unless client.connect
    end

    transaction_id = SecureRandom.uuid
    run_message = prepare_message(@group.certnames, transaction_id)
    completed_list = Array.new

    client.on_message = proc do |message|
      data = JSON.parse message.data

      Puppet.debug "Received a message over PCP - #{data['transaction_id']}"

      if data['transaction_id'] == transaction_id and data['results']
        sender = message[:sender].chomp('/agent').slice(6..-1)
        @group[sender].use_transaction_uuid( data['results']['transaction_uuid'] )

        completed_list << sender
        #tell progress bar to increment
      end
    end

    run_message.expires(10)
    client.send(run_message)

    progressbar = ProgressBar.create(:total => @group.certnames.count, :title => 'Nodes Complete', :length => 80)

    begin
      Timeout::timeout(timeout) {
        until completed_list.count == @group.certnames.count
          progressbar.progress = completed_list.count
          sleep 0.5
        end
      }
      progressbar.finish
    rescue Timeout::Error
      progressbar.finish
      Puppet.debug 'Execution expired while waiting for Puppet Agents to complete run'
    end

    completed_list
  end

  def prepare_message(node_list, uuid = SecureRandom.uuid)

    targets = node_list.map{|node| "pcp://#{node}/agent" }

    message = PCP::Message.new({
                                   message_type: 'http://puppetlabs.com/rpc_non_blocking_request',
      targets: targets
    })

    params = {
        env: [],
      flags: ['--onetime']
    }

    message_data = {
      transaction_id: uuid,
      module: 'pxp-module-puppet',
      action: 'run',
      params: params,
      notify_outcome: true
    }

    message.data = message_data.to_json

    message
  end
end

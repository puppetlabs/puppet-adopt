require 'net/https'
require 'uri'
require 'json'
require 'openssl'

class PuppetX::Orchestrator_api
  require 'puppet_x/orchestrator_api/error'
  require 'puppet_x/orchestrator_api/command'
  require 'puppet_x/orchestrator_api/jobs'
  require 'puppet_x/orchestrator_api/environments'

  attr_accessor :config, :token

  def initialize(config_hash = {})

    @config = { :token_path => File.join(Dir.home, '.puppetlabs', 'token'),
                :server     => 'localhost',
                :port       => '8143',
                :api_url    => '/orchestrator/v1'
    }.merge(config_hash)

    @token = File.read(config[:token_path])
  end

  def make_uri(path)
    uri = URI.parse("https://#{config[:server]}:#{config[:port]}#{path}")
    Puppet.debug "Orchestrator: calling URI #{uri.request_uri}"
    uri
  end

  def create_http(uri)
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    https.ssl_version = :TLSv1
    https.ca_file = Puppet.settings[:localcacert]
    #    https.key = OpenSSL::PKey::RSA.new(File.read(Puppet.settings[:hostprivkey]))
    #    https.cert = OpenSSL::X509::Certificate.new(File.read(Puppet.settings[:hostcert]))
    https.verify_mode = OpenSSL::SSL::VERIFY_PEER
    https
  end

  def get(endpoint)
    uri = make_uri(endpoint)
    https = create_http(uri)

    req = Net::HTTP::Get.new(uri.request_uri)
    req['Content-Type'] = "application/json"
    req.add_field('X-Authentication', token)
    res = https.request(req)

    if res.code != "200"
      Puppet.debug "An Orchestrator API error occured: HTTP #{res.code}, #{res.body}"
      raise PuppetX::Orchestrator_api::Error.make_error_from_response(res)
    end
    res_body = JSON.parse(res.body)

    res_body
  end

  def post(endpoint, body)
    uri = make_uri(endpoint)
    https = create_http(uri)

    req = Net::HTTP::Post.new(uri.request_uri)
    req['Content-Type'] = "application/json"
    req.add_field('X-Authentication', token)
    req.body = body.to_json
    res = https.request(req)

    if res.kind_of? Net::HTTPError
      Puppet.debug "An Orchestrator API error occured: HTTP #{res.code}, #{res.to_hash.inspect}"
      raise PuppetX::Orchestrator_api::Error.make_error_from_response(res)
    end

      JSON.parse(res.body)
  end

  def command
    @command ||= PuppetX::Orchestrator_api::Command.new(self, config[:api_url])
  end

  def environments
    @environments ||= PuppetX::Orchestrator_api::Environments.new(self, config[:api_url])
  end

  def jobs
    @jobs ||= PuppetX::Orchestrator_api::Jobs.new(self, config[:api_url])
  end

  def root
    get(config[:api_url])
  end
end

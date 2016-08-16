
class PuppetX::Orchestrator_api::Error < Exception

  def initialize(data,code)
    @code = code
    @kind = data['kind']
    @details = data['details']
    super(data['msg'])
  end

  def self.make_error_from_response(res)
    data = JSON.parse(res.body)
    code = res.code

    case data['kind']
    when 'puppetlabs.orchestrator/validation-error'
      ValidationError.new(data, code)
    when 'puppetlabs.orchestrator/unknown-job'
      UnknownJob.new(data, code)
    when 'puppetlabs.orchestrator/unknown-environment'
      UnknownEnvironment.new(data, code)
    when 'puppetlabs.orchestrator/empty-environment'
      EmptyEnvironment.new(data, code)
    when 'puppetlabs.orchestrator/empty-target'
      EmptyTarget.new(data, code)
    when 'puppetlabs.orchestrator/dependency-cycle'
      DependencyCycle.new(data, code)
    when 'puppetlabs.orchestrator/puppetdb-error'
      PuppetdbError.new(data, code)
    when 'puppetlabs.orchestrator/query-error'
      QueryError.new(data, code)
    when 'puppetlabs.orchestrator/unknown-error'
      UnknownError.new(data, code)
    end
  end

end

class PuppetX::Orchestrator_api::Error::ValidationError < PuppetX::Orchestrator_api::Error; end
class PuppetX::Orchestrator_api::Error::UnknownJob < PuppetX::Orchestrator_api::Error; end
class PuppetX::Orchestrator_api::Error::UnknownEnvironment < PuppetX::Orchestrator_api::Error; end
class PuppetX::Orchestrator_api::Error::EmptyEnvironment < PuppetX::Orchestrator_api::Error; end
class PuppetX::Orchestrator_api::Error::EmptyTarget < PuppetX::Orchestrator_api::Error; end
class PuppetX::Orchestrator_api::Error::DependencyCycle < PuppetX::Orchestrator_api::Error; end
class PuppetX::Orchestrator_api::Error::PuppetdbError < PuppetX::Orchestrator_api::Error; end
class PuppetX::Orchestrator_api::Error::QueryError < PuppetX::Orchestrator_api::Error; end
class PuppetX::Orchestrator_api::Error::UnknownError < PuppetX::Orchestrator_api::Error; end

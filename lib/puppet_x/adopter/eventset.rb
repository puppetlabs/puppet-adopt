class PuppetX::Adopter::EventSet < Set
  def initialize(events)
    self.validate(events)
    super(events)
  end

  def validate(events)
    validated_events = events.select { |event| event.instance_of? PuppetX::Adopter::Event }
    if events.length != validated_events.length
      raise ArgumentError.new('One of the events passed to EventSet.new is not an instance of PuppetX::Adopter::Event')
    end
  end
end

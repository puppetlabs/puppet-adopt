
class PuppetX::Adopter::Processor

  attr_accessor :group, :variations, :tracker

  def initialize(group)
    @group = group
    @tracker = PuppetX::Adopter::EventTracker.new(group)
  end

  def process
    @variations = Hash.new
    group.nodes.each do |node|
      events = node.events

      event_set = create_event_set(events)

      if variations.has_key?(event_set)
        variations[event_set] << node
      else
        variations[event_set] = [node]
      end
    end

    @finished = true
  end

  def create_event_set(events)
    event_set = Set.new

    events.each do |e|
      event = PuppetX::Adopter::Event.new(e)
      if tracker.is_usable_event?(event)
        event_set.add event
      end
    end

    event_set
  end

  def finished?
    @variations ? true : false
  end

end

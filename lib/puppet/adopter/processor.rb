
class Puppet::Adopter::Processor

  attr_accessor :group, :variations

  def initialize(group)
    @group = group
    @variations = Hash.new
    @tracker = Puppet::Adopter::EventTracker.new(group)
  end

  def process
    group.nodes.each do |node|
      events = node.events

      event_set = create_event_set(events)

      if variations.has_key(event_set)
        variations[event_set] << node.name
      else
        variations[event_set] = [node.name]
      end
    end

    @finished = true
  end

  def create_event_set(events)
    event_set = Set.new

    events.each do |event|
      event.except!(:type, :title, :old_value, :new_value)

      if tracker.is_usable_event?(event)
        event_set.add event
      end
    end

    event_set
  end

  def finished?
    @finished ? true : false
  end

end


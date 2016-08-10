require 'puppet_x/adopter/eventset'
class PuppetX::Adopter::Processor

  attr_accessor :group, :variations, :tracker

  def initialize(group)
    @group = group
    @tracker = PuppetX::Adopter::EventTracker.new(group)
  end

  def process
    @variations = Hash.new
    group.nodes.each do |node|
      events = node.events_to_a
      event_set = generate_event_set(events)

      if variations.has_key?(event_set)
        variations[event_set] << node
      else
        variations[event_set] = [node]
      end
    end

    @finished = true
  end

  # Expects an array of event objects, not the raw hash, see Node#events_to_a
  def generate_event_set(events)
    usable_events = self.find_usable_events(events)
    self.new_event_set(usable_events)
  end

  def new_event_set(events)
    PuppetX::Adopter::EventSet.new(events)
  end

  def is_usable_event?(event)
    tracker.is_usable_event?(event)
  end

  def find_usable_events(events)
    events.select { |event| self.is_usable_event?(event) }
  end

  def finished?
    @variations ? true : false
  end

end

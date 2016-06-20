
class Puppet::Adopter::Processor

  attr_accessor :group, :variations, :tracker

  def initialize(group)
    @group = group
    @tracker = Puppet::Adopter::EventTracker.new(group)
  end

  def process
    @variations = Hash.new
    group.nodes.each do |node|
      events = node.events

      event_set = create_event_set(events)

      if variations.has_key?(event_set)
        variations[event_set] << node.name
      else
        variations[event_set] = [node.name]
      end
    end

    @finished = true
  end

  def create_event_set(events)
    event_set = Set.new

    events.each do |e|
      event = {
        :type => e['resource_type'],
        :title => e['resource_title'],
        :new_value => e['new_value'],
        :old_value => e['old_value']
      }

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


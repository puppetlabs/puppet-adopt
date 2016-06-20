require 'set'

class Puppet::Adopter::EventTracker

  attr_accessor :usable_events, :fuzzy_events, :client, :group

  def initialize(group, pdb_client = nil)

    @group = group
    @client = pdb_client || Puppet::Adopter::Client.pdb_client()
    @usable_events = Set.new
    @fuzzy_events = Set.new
  end

  def known_events
    usable_events.union fuzzy_events
  end

  def known_event?(event_hash)
    known_events.include? event_hash
  end

  def is_fuzzy_event?(event_hash)
    process_event(event_hash) unless known_event?(event_hash)

    fuzzy_events.include? event_hash
  end

  def is_usable_event?(event_hash)
    process_event(event_hash) unless known_event?(event_hash)

    usable_events.include? event_hash
  end

  def process_event(event_hash)
    unless [:type, :title, :old_value, :new_value].all? {|k| details.key? k}
      raise(ArgumentError, 'Insufficient details to process an event')
    end

    catalog_count = client.request('resources',
      ['extract',
        [['function','count']],
        ["and",
          ['=','type',event_hash[:type]],
          ['=','title',event_hash[:title]],
          group.rule
        ]
      ]).data.firsti

    seen_ratio = catalog_count.fdiv(group.node_count)

    if seen_ratio < 0.5
      fuzzy_events.add event_hash
    else
      usable_events.add event_hash
    end

  end
end


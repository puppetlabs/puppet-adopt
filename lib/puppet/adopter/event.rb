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

  def known_event?(event)
    known_events.include? event
  end

  def is_fuzzy_event?(event)
    process_event(event) unless known_event?(event)

    fuzzy_events.include? event
  end

  def is_usable_event?(event)
    process_event(event) unless known_event?(event)

    usable_events.include? event
  end

  def process_event(event)
    unless event.is_a? Puppet::Adopter::Event
      raise(ArgumentError, 'Insufficient details to process an event')
    end

    catalog_count = client.request('resources',
      ['extract',
        [['function','count']],
        ["and",
          ['=','type',event[:resource_type]],
          ['=','title',event[:resource_title]],
          group.rule
        ]
      ]).data.first['count']

    seen_ratio = catalog_count.fdiv(group.node_count)

    if seen_ratio < 0.5
      fuzzy_events.add event
    else
      usable_events.add event
    end

  end
end

class Puppet::Adopter::Event
  def initialize(data)

    if  data.kind_of? Hash
      unless [:resource_type, :resource_title, :old_value, :new_value].all? {|k| data.key? k}
        raise(ArgumentError, 'Insufficient details to process an event')
      end

      @data = Hash[data.map { |k, v| [k.to_sym, v] }]
    else
      raise(ArgumentError, "Must pass a hash to create a new Puppet::Adopter::Event")
  end

  def [](key)
    key = key.intern if key.respond_to? :intern and not key.is_a? Symbol
    @data[key]
  end

  def ==(obj)
    self.hash == obj.hash
  end

  alias_method :eql?, :==

  def hash
    @data[:resource_title].hash ^ @data['resource_type'].hash ^ @data['old_value'].hash
  end
end

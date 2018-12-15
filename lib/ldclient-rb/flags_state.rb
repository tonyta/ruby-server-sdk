require 'json'

module LaunchDarkly
  #
  # A snapshot of the state of all feature flags with regard to a specific user, generated by
  # calling the {LDClient#all_flags_state}. Serializing this object to JSON using
  # `JSON.generate` (or the `to_json` method) will produce the appropriate data structure for
  # bootstrapping the LaunchDarkly JavaScript client.
  #
  class FeatureFlagsState
    def initialize(valid)
      @flag_values = {}
      @flag_metadata = {}
      @valid = valid
    end

    # Used internally to build the state map.
    # @private
    def add_flag(flag, value, variation, reason = nil, details_only_if_tracked = false)
      key = flag[:key]
      @flag_values[key] = value
      meta = {}
      with_details = !details_only_if_tracked || flag[:trackEvents]
      if !with_details && flag[:debugEventsUntilDate]
        with_details = flag[:debugEventsUntilDate] > (Time.now.to_f * 1000).to_i
      end
      if with_details
        meta[:version] = flag[:version]
        meta[:reason] = reason if !reason.nil?
      end
      meta[:variation] = variation if !variation.nil?
      meta[:trackEvents] = true if flag[:trackEvents]
      meta[:debugEventsUntilDate] = flag[:debugEventsUntilDate] if flag[:debugEventsUntilDate]
      @flag_metadata[key] = meta
    end

    # Returns true if this object contains a valid snapshot of feature flag state, or false if the
    # state could not be computed (for instance, because the client was offline or there was no user).
    def valid?
      @valid
    end

    # Returns the value of an individual feature flag at the time the state was recorded.
    # Returns nil if the flag returned the default value, or if there was no such flag.
    def flag_value(key)
      @flag_values[key]
    end

    # Returns a map of flag keys to flag values. If a flag would have evaluated to the default value,
    # its value will be nil.
    #
    # Do not use this method if you are passing data to the front end to "bootstrap" the JavaScript client.
    # Instead, use as_json.
    def values_map
      @flag_values
    end

    # Returns a hash that can be used as a JSON representation of the entire state map, in the format
    # used by the LaunchDarkly JavaScript SDK. Use this method if you are passing data to the front end
    # in order to "bootstrap" the JavaScript client.
    #
    # Do not rely on the exact shape of this data, as it may change in future to support the needs of
    # the JavaScript client.
    def as_json(*) # parameter is unused, but may be passed if we're using the json gem
      ret = @flag_values.clone
      ret['$flagsState'] = @flag_metadata
      ret['$valid'] = @valid
      ret
    end

    # Same as as_json, but converts the JSON structure into a string.
    def to_json(*a)
      as_json.to_json(a)
    end
  end
end

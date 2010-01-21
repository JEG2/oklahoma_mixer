module OklahomaMixer
  class TableDatabase < HashDatabase
    ################################
    ### Getting and Setting Keys ###
    ################################
    
    def store(key, value, mode = nil, &dup_handler)
      if mode == :add and dup_handler.nil?
        super
      else
        Utilities.temp_map do |map|
          map.update(value) { |key_or_value|
            cast_to_bytes_and_length(key_or_value)
          }
          result = super(key, map, mode, &dup_handler)
          result == map ? value : result
        end
      end
    end
    alias_method :[]=, :store

    def fetch(key, *default)
      if value = try( :get, cast_key_in(key),
                      :failure  => lambda { |value| value.address.zero? },
                      :no_error => {22 => nil} )
        cast_value_out(value)
      else
        if block_given?
          warn "block supersedes default value argument" unless default.empty?
          yield key
        elsif not default.empty?
          default.first
        else
          fail IndexError, "key not found"
        end
      end
    end
    #################
    ### Iteration ###
    #################
    
    def each
      try(:iterinit)
      loop do
        begin
          pointer = try( :iternext3,
                         :failure  => lambda { |value| value.address.zero? },
                         :no_error => {22 => nil} )
          return self unless pointer
          map        = HashMap.new(pointer)
          key, value = nil, { }
          map.each do |k, v|
            if k.empty?
              key = v
            else
              value[k] = v
            end
          end
          yield [key, value]
        ensure
          map.free if map
        end
      end
    end
    alias_method :each_pair, :each
    
    #######
    private
    #######
    
    def tune(options)
      super
      if options.values_at(:bnum, :apow, :fpow, :opts).any?
        optimize(options.merge(:tune => true))
      end
      if options.values_at(:rcnum, :lcnum, :ncnum).any?
        setcache(options)
      end
    end
    
    def setcache(options)
      try( :setcache,
           options.fetch(:rcnum, 0).to_i,
           options.fetch(:lcnum, 0).to_i,
           options.fetch(:ncnum, 0).to_i )
    end
    
    def cast_value_in(value)
      value.pointer
    end
    
    def cast_value_out(pointer)
      map = HashMap.new(pointer)
      hash = { }
      map.each do |key, value|
        hash[cast_to_encoded_string(key)] = cast_to_encoded_string(value)
      end
      hash
    ensure
      map.free if map
    end
  end
end

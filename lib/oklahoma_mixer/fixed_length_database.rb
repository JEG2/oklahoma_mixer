module OklahomaMixer
  class FixedLengthDatabase < HashDatabase
    ###################
    ### File System ###
    ###################
    
    def optimize(options)
      try( options[:tune] ? :tune : :optimize,
           options.fetch(:width,  0).to_i,
           options.fetch(:limsiz, 0).to_i  )
    end
    
    def defrag(steps = 0)
      # do nothing:  not needed, but provided for a consistent interface
    end
    
    ################################
    ### Getting and Setting Keys ###
    ################################
    
    def keys(options = { })
      if options.include? :range
        warn "range supersedes prefix" if options[:prefix]
        range = options[:range]
        unless range.respond_to?(:first) and range.respond_to?(:last)
          fail ArgumentError, "Range or two element Array expected"
        end
        start          = cast_key_in(range.first)
        include_start  = !options.fetch(:exclude_start, false)
        finish         = cast_key_in(range.last)
        include_finish = !( range.respond_to?(:exclude_end?) ?
                            range.exclude_end?               :
                            options.fetch(:exclude_end, false) )
      else
        fail ArgumentError, "prefix not supported" if options[:prefix]
        start          = cast_key_in(:min)
        include_start  = true
        finish         = cast_key_in(:max)
        include_finish = true
      end
      limit = options.fetch(:limit, -1)
      Utilities.temp_int do |count|
        begin
          list  = lib.range(@db, start, finish, limit, count)
          array = list.get_array_of_uint64(0, count.get_int(0))
          array.shift if array.first == start  and not include_start
          array.pop   if array.last  == finish and not include_finish
          array
        ensure
          Utilities.free(list) if list
        end
      end
    end
    
    #################
    ### Iteration ###
    #################

    def each_key
      try(:iterinit)
      loop do
        return self unless key = try( :iternext,
                                      :failure  => 0,
                                      :no_error => {22 => nil} )
        yield key
      end
    end
    
    def each
      each_key do |key|
        yield [key, self[key]]
      end
    end
    alias_method :each_pair, :each
    
    #######
    private
    #######
    
    def tune(options)
      if options.values_at(:width, :limsiz).any?
        optimize(options.merge(:tune => true))
      end
    end
    
    def cast_key_in(key)
      case key
      when :min, :max, :prev, :next, "min", "max", "prev", "next"
        C::IDS["FDBID#{key.to_s.upcase}".to_sym]
      else
        key.to_i
      end
    end
  end
end

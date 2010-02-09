module OklahomaMixer
  class BTreeDatabase < HashDatabase
    ###################
    ### File System ###
    ###################
    
    def optimize(options)
      try( options[:tune] ? :tune : :optimize,
           options.fetch(:lmemb,  0).to_i,
           options.fetch(:nmemb,  0).to_i,
           options.fetch(:bnum,   0).to_i,
           options.fetch(:apow,  -1).to_i,
           options.fetch(:fpow,  -1).to_i,
           cast_to_enum_int(options.fetch(:opts, 0xFF), :opt) )
    end
    
    ################################
    ### Getting and Setting Keys ###
    ################################

    def store(key, value, mode = nil)
      if mode == :dup
        if value.is_a? Array
          Utilities.temp_list(value.size) do |list|
            list.push(*value) { |string| cast_value_in(string) }
            try(:putdup3, cast_key_in(key), list.pointer)
          end
        else
          try(:putdup, cast_key_in(key), cast_value_in(value))
        end
        value
      else
        super
      end
    end
    
    def keys(options = { })
      if options.include? :range
        warn "range supersedes prefix" if options[:prefix]
        range = options[:range]
        fail ArgumentError, "Range expected" unless range.is_a? Range
        start          = cast_key_in(range.first)
        include_start  = !options.fetch(:exclude_start, false)
        finish         = cast_key_in(range.last)
        include_finish = !range.exclude_end?
        limit          = options.fetch(:limit, -1)
        begin
          list = ArrayList.new( lib.range( @db,
                                           *[ start,  include_start,
                                              finish, include_finish,
                                              limit ].flatten ) )
          list.map { |key| cast_key_out(key) }
        ensure
          list.free if list
        end
      else
        super
      end
    end

    def values(key = nil)
      if key.nil?
        super()
      else
        begin
          pointer = try( :get4, cast_key_in(key),
                         :failure  => lambda { |ptr| ptr.address.zero? },
                         :no_error => {22 => nil} )
          if pointer.nil?
            [ ]
          else
            list = ArrayList.new(pointer)
            list.map { |value| cast_value_out(value) }
          end
        ensure
          list.free if list
        end
      end
    end
    
    def delete(key, mode = nil, &missing_handler)
      if mode == :dup
        values = values(key)
        if try(:out3, cast_key_in(key), :no_error => {22 => false})
          values
        else
          missing_handler ? missing_handler[key] : values
        end
      else
        super(key, &missing_handler)
      end
    end

    def size(key = nil)
      if key.nil?
        super()
      else
        try(:vnum, cast_key_in(key), :failure => 0, :no_error => {22 => 0})
      end
    end
    alias_method :length, :size
    
    #################
    ### Iteration ###
    #################
    
    def each_key(start = nil)
      cursor_in_loop(start) do |iterator|
        throw(:finish_iteration) unless key = iterator.key
        yield cast_key_out(key)
      end
    end
    
    def each(start = nil)
      cursor_in_loop(start) do |iterator|
        throw(:finish_iteration) unless key_and_value = iterator.key_and_value
        yield [ cast_key_out(key_and_value.first),
                cast_value_out(key_and_value.last) ]
      end
    end
    alias_method :each_pair, :each
    
    def reverse_each(start = nil)
      cursor_in_loop(start, :reverse) do |iterator|
        throw(:finish_iteration) unless key_and_value = iterator.key_and_value
        yield [ cast_key_out(key_and_value.first),
                cast_value_out(key_and_value.last) ]
      end
    end
    
    def each_value(start = nil)
      cursor_in_loop(start) do |iterator|
        throw(:finish_iteration) unless value = iterator.value
        yield cast_value_out(value)
      end
    end
    
    def delete_if(start = nil)
      cursor(start) do |iterator|
        loop do
          break unless key_and_value = iterator.key_and_value
          test = yield( cast_key_out(key_and_value.first),
                        cast_value_out(key_and_value.last) )
          break unless iterator.send(test ? :delete : :next)
        end
      end
    end
    
    #######
    private
    #######
    
    def tune(options)
      super
      if cmpfunc = options[:cmpfunc]
        callback = lambda { |a_pointer, a_size, b_pointer, b_size, _|
          a = a_pointer.get_bytes(0, a_size)
          b = b_pointer.get_bytes(0, b_size)
          cmpfunc[a, b]
        }
        try(:setcmpfunc, callback, nil)
      end
      if options.values_at(:lmemb, :nmemb, :bnum, :apow, :fpow, :opts).any?
        optimize(options.merge(:tune => true))
      end
      if options.values_at(:lcnum, :ncnum).any?
        setcache(options)
      end
    end
    
    def setcache(options)
      try( :setcache,
           options.fetch(:lcnum, 0).to_i,
           options.fetch(:ncnum, 0).to_i )
    end
    
    def cursor(start = nil, reverse = false)
      cursor = Cursor.new(@db, start.nil? ? start : cast_key_in(start), reverse)
      yield cursor
      self
    ensure
      cursor.free if cursor
    end
    
    def cursor_in_loop(start = nil, reverse = false)
      cursor(start, reverse) do |iterator|
        catch(:finish_iteration) do
          loop do
            yield iterator
            break unless iterator.next
          end
        end
      end
    end
  end
end

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
           to_enum_int(options.fetch(:opts, 0xFF), :opt) )
    end
    
    ################################
    ### Getting and Setting Keys ###
    ################################
    
    def keys(options = { })
      if options.include? :range
        warn "range supersedes prefix" if options[:prefix]
        range = options[:range]
        fail ArgumentError, "Range expected" unless range.is_a? Range
        start          = range.first.to_s
        include_start  = !options.fetch(:exclude_start, false)
        finish         = range.last.to_s
        include_finish = !range.exclude_end?
        limit          = options.fetch(:limit, -1)
        begin
          list = ArrayList.new( lib.range( @db,
                                           start,  start.size,  include_start,
                                           finish, finish.size, include_finish,
                                           limit ) )
          list.to_a
        ensure
          list.free if list
        end
      else
        super
      end
    end
    
    #################
    ### Iteration ###
    #################
    
    def each_key(start = nil)
      cursor_in_loop(start) do |iterator|
        throw(:finish_iteration) unless key = iterator.key
        yield key
      end
    end
    
    def each(start = nil)
      cursor_in_loop(start) do |iterator|
        throw(:finish_iteration) unless key_and_value = iterator.key_and_value
        yield key_and_value
      end
    end
    alias_method :each_pair, :each
    
    def reverse_each(start = nil)
      cursor_in_loop(start, :reverse) do |iterator|
        throw(:finish_iteration) unless key_and_value = iterator.key_and_value
        yield key_and_value
      end
    end
    
    def each_value(start = nil)
      cursor_in_loop(start) do |iterator|
        throw(:finish_iteration) unless value = iterator.value
        yield value
      end
    end
    
    def delete_if(start = nil)
      cursor(start) do |iterator|
        loop do
          break unless key_and_value = iterator.key_and_value
          break unless iterator.send(yield(*key_and_value) ? :delete : :next)
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
      cursor = Cursor.new(@db, start.nil? ? start : start.to_s, reverse)
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

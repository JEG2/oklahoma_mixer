module OklahomaMixer
  class HashDatabase
    ###################
    ### File System ###
    ###################
    
    def initialize(path, *args)
      options = args.last.is_a?(Hash)   ? args.last  : { }
      mode    = !args.first.is_a?(Hash) ? args.first : nil
      
      @path                = path
      @db                  = C.new
      self.default         = options[:default]
      @in_transaction      = false
      @abort               = false
      @nested_transactions = options[:nested_transactions]
      
      C.setmutex(@db) if options[:mutex]
      if options.values_at( :bucket_array_size,
                            :record_alignment_power,
                            :max_free_block_power,
                            :options ).any?
        optimize(options.merge(:tune => true))
      end
      if max_cached_records = options[:max_cached_records]
        C.setcache(@db, max_cached_records.to_i)
      end
      if extra_mapped_mem = options[:extra_mapped_mem]
        C.xmsiz(@db, extra_mapped_mem.to_i)
      end
      if auto_defrag_step_unit = options[:auto_defrag_step_unit]
        C.dfunit(@db, auto_defrag_step_unit.to_i)
      end
      
      warn "mode option supersedes mode argument" if mode and options[:mode]
      mode = options.fetch(:mode, mode || "wc")
      unless mode.is_a? Integer
        mode = mode.to_s.downcase.scan(/./m).inject(0) do |int, m|
          case m
          when "r"      then int | C::MODES[:HDBOREADER]
          when "w"      then int | C::MODES[:HDBOWRITER]
          when "c"      then int | C::MODES[:HDBOCREAT]
          when "t"      then int | C::MODES[:HDBOTRUNC]
          when "e", "n" then int | C::MODES[:HDBONOLCK]
          when "f", "b" then int | C::MODES[:HDBOLCKNB]
          when "s"      then int | C::MODES[:HDBOTSYNC]
          else
            warn "skipping unrecognized mode"
            int
          end
        end
      end
      C.open(@db, path, mode)
    end
    
    def optimize(options)
      bnum = options.fetch(:bucket_array_size,       0).to_i
      apow = options.fetch(:record_alignment_power, -1).to_i
      fpow = options.fetch(:max_free_block_power,   -1).to_i
      opts = options.fetch(:options,                 0xFF)
      unless opts.is_a? Integer
        opts = opts.to_s.downcase.scan(/./m).inject(0) do |int, o|
          case o
          when "l" then int | C::OPTS[:HDBTLARGE]
          when "d" then int | C::OPTS[:HDBTDEFLATE]
          when "b" then int | C::OPTS[:HDBTBZIP]
          when "t" then int | C::OPTS[:HDBTTCBS]
          else
            warn "skipping unrecognized option"
            int
          end
        end
      end
      func = options[:tune] ? :tune : :optimize
      C.send(func, @db, bnum, apow, fpow, opts)
    end
    
    attr_reader :path
    
    def file_size
      C.fsiz(@db)
    end
    
    def flush
      C.sync(@db)
    end
    alias_method :sync,  :flush
    alias_method :fsync, :flush
    
    def copy(path)
      C.copy(@db, path)
    end
    alias_method :backup, :copy
    
    def defrag(steps = 0)
      C.defrag(@db, steps.to_i)
    end
    
    def close
      C.del(@db)  # closes before it deletes the object
    end
    
    ################################
    ### Getting and Setting Keys ###
    ################################
    
    def default(key = nil)
      @default[key] if @default
    end
    
    def default=(value_or_proc)
      @default = case value_or_proc
                 when Proc then value_or_proc
                 when nil  then nil
                 else           lambda { |key| value_or_proc }
                 end
    end
    
    def store(key, value, mode = nil)
      k, v   = key.to_s, value.to_s
      result = value
      if block_given?
        warn "block supersedes mode argument" unless mode.nil?
        callback = lambda { |old_value_pointer, old_size, returned_size, _|
          old_value   = old_value_pointer.get_bytes(0, old_size)
          replacement = yield(key, old_value, value).to_s
          returned_size.put_int(0, replacement.size)
          FFI::MemoryPointer.from_string(replacement)
        }
        C.putproc(@db, k, k.size, v, v.size, callback, nil)
      else
        case mode
        when :keep
          result = C.putkeep(@db, k, k.size, v, v.size)
        when :cat
          C.putcat(@db, k, k.size, v, v.size)
        when :async
          C.putasync(@db, k, k.size, v, v.size)
        when :counter
          result = case value
                   when Float then C.adddouble(@db, k, k.size, value)
                   else            C.addint(@db, k, k.size, value.to_i)
                   end
        else
          C.put(@db, k, k.size, v, v.size)
        end
      end
      result
    end
    alias_method :[]=, :store
    
    def fetch(key, *default)
      k        = key.to_s
      if value = C.read_from_func(:get, @db, k, k.size)
        value
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
    
    def [](key)
      fetch(key, &@default)
    rescue IndexError
      nil
    end
    
    def update(hash, &dup_handler)
      hash.each do |key, value|
        store(key, value, &dup_handler)
      end
      self
    end
    
    def values_at(*keys)
      keys.map { |key| self[key] }
    end
    
    def keys(options = { })
      prefix = options.fetch(:prefix, "").to_s
      limit  = options.fetch(:limit,  -1)
      list   = ArrayList.new(C.fwmkeys(@db, prefix, prefix.size, limit))
      list.to_a
    ensure
      list.free if list
    end
    
    def values
      values = [ ]
      each_value do |value|
        values << value
      end
      values
    end
    
    def delete(key, &missing_handler)
      value = fetch(key, &missing_handler)
      k     = key.to_s
      C.out(@db, k, k.size)
      value
    rescue IndexError
      nil
    end
    
    def clear
      C.vanish(@db)
      self
    end
    
    def include?(key)
      fetch(key)
      true
    rescue IndexError
      false
    end
    alias_method :has_key?, :include?
    alias_method :key?,     :include?
    alias_method :member?,  :include?
    
    def size
      C.rnum(@db)
    end
    alias_method :length, :size
    
    #################
    ### Iteration ###
    #################
    
    include Enumerable
    
    def each_key
      C.iterinit(@db)
      loop do
        return self unless key = C.read_from_func(:iternext, @db)
        yield key
      end
    end
    
    def each
      C.iterinit(@db)
      loop do
        Utilities.temp_xstr do |key|
          Utilities.temp_xstr do |value|
            return self unless C.iternext3(@db, key.pointer, value.pointer)
            yield [key.to_s, value.to_s]
          end
        end
      end
    end
    alias_method :each_pair, :each
    
    def each_value
      each do |key, value|
        yield value
      end
    end
    
    def delete_if
      each do |key, value|
        delete(key) if yield key, value
      end
    end
    
    ####################
    ### Transactions ###
    ####################
    
    def transaction
      if @in_transaction
        case @nested_transactions
        when :ignore
          return yield
        when :fail, :raise
          fail "nested transaction"
        end
      end
      
      @in_transaction = true
      @abort          = false
      
      begin
        catch(:finish_transaction) do
          C.tranbegin(@db)
          yield
        end
      rescue Exception
        @abort = true
        raise
      ensure
        C.send("tran#{@abort ? :abort : :commit}", @db)
        @in_transaction = false
      end
    end
    
    def commit
      fail "not in transaction" unless @in_transaction
      throw :finish_transaction
    end
    
    def abort
      fail "not in transaction" unless @in_transaction
      @abort = true
      throw :finish_transaction
    end
  end
end

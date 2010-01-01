module OklahomaMixer
  class HashDatabase
    #################
    ### Constants ###
    #################
    
    MODES = { "r" => :HDBOREADER,
              "w" => :HDBOWRITER,
              "c" => :HDBOCREAT,
              "t" => :HDBOTRUNC,
              "e" => :HDBONOLCK,
              "f" => :HDBOLCKNB,
              "s" => :HDBOTSYNC }
    OPTS  = { "l" => :HDBTLARGE,
              "d" => :HDBTDEFLATE,
              "b" => :HDBTBZIP,
              "t" => :HDBTTCBS }
    
    ###################
    ### File System ###
    ###################
    
    def initialize(path, *args)
      options              = args.last.is_a?(Hash)   ? args.last  : { }
      mode                 = !args.first.is_a?(Hash) ? args.first : nil
      @path                = path
      @db                  = C.new
      self.default         = options[:default]
      @in_transaction      = false
      @abort               = false
      @nested_transactions = options[:nested_transactions]
      
      try(:setmutex) if options[:mutex]
      if options.values_at(:bnum, :apow, :fpow, :opts).any?
        optimize(options.merge(:tune => true))
      end
      {:rcnum => :cache, :xmsiz => nil, :dfunit => nil}.each do |option, func|
        if i = options[option]
          try("set#{func || option}", i.to_i)
        end
      end
      
      warn "mode option supersedes mode argument" if mode and options[:mode]
      try(:open, path, to_enum_int(options.fetch(:mode, mode || "wc"), :mode))
    end
    
    def optimize(options)
      try( options[:tune] ? :tune : :optimize,
           options.fetch(:bnum,  0).to_i,
           options.fetch(:apow, -1).to_i,
           options.fetch(:fpow, -1).to_i,
           to_enum_int(options.fetch(:opts, 0xFF), :opt) )
    end
    
    attr_reader :path
    
    def file_size
      C.fsiz(@db)
    end
    
    def flush
      try(:sync)
    end
    alias_method :sync,  :flush
    alias_method :fsync, :flush
    
    def copy(path)
      try(:copy, path)
    end
    alias_method :backup, :copy
    
    def defrag(steps = 0)
      try(:defrag, steps.to_i)
    end
    
    def close
      try(:del)  # closes before it deletes the object
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
        try(:putproc, k, k.size, v, v.size, callback, nil)
      else
        case mode
        when :keep
          result = try( :putkeep, k, k.size, v, v.size,
                        :no_error => {21 => false} )
        when :cat
          try(:putcat, k, k.size, v, v.size)
        when :async
          try(:putasync, k, k.size, v, v.size)
        when :add
          result = case value
                   when Float then try( :adddouble, k, k.size, value,
                                        :failure => lambda { |n| n.nan? } )
                   else            try( :addint, k, k.size, value.to_i,
                                        :failure => Utilities::INT_MIN )
                   end
        else
          try(:put, k, k.size, v, v.size)
        end
      end
      result
    end
    alias_method :[]=, :store
    
    def fetch(key, *default)
      k        = key.to_s
      if value = try( :read_from_func, :get, k, k.size,
                      :failure => nil, :no_error => {22 => nil} )
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
      try(:out, k, k.size, :no_error => {22 => nil})
      value
    rescue IndexError
      nil
    end
    
    def clear
      try(:vanish)
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
      try(:iterinit)
      loop do
        return self unless key = try( :read_from_func, :iternext,
                                      :failure  => nil,
                                      :no_error => {22 => nil} )
        yield key
      end
    end
    
    def each
      try(:iterinit)
      loop do
        Utilities.temp_xstr do |key|
          Utilities.temp_xstr do |value|
            return self unless try( :iternext3, key.pointer, value.pointer,
                                    :no_error => {22 => false} )
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
          fail Error::TransactionError, "nested transaction"
        end
      end
      
      @in_transaction = true
      @abort          = false
      
      begin
        catch(:finish_transaction) do
          try(:tranbegin)
          yield
        end
      rescue Exception
        @abort = true
        raise
      ensure
        try("tran#{@abort ? :abort : :commit}")
        @in_transaction = false
      end
    end
    
    def commit
      fail Error::TransactionError, "not in transaction" unless @in_transaction
      throw :finish_transaction
    end
    
    def abort
      fail Error::TransactionError, "not in transaction" unless @in_transaction
      @abort = true
      throw :finish_transaction
    end
    
    #######
    private
    #######
    
    def try(func, *args)
      options  = args.last.is_a?(Hash) ? args.pop : { }
      failure  = options.fetch(:failure, false)
      no_error = options.fetch(:no_error, { })
      result   = func == :read_from_func                      ?
                 C.read_from_func(args[0], @db, *args[1..-1]) :
                 C.send(func, @db, *args)
      if (failure.is_a?(Proc) and failure[result]) or result == failure
        error_code = C.ecode(@db)
        if no_error.include? error_code
          no_error[error_code]
        else
          error_message = C.errmsg(error_code)
          fail Error::CabinetError, "#{error_message} (#{error_code})"
        end
      else
        result
      end
    end
    
    def to_enum_int(str_or_int, name)
      return str_or_int if str_or_int.is_a? Integer
      const = "#{name.to_s.upcase}S"
      names = self.class.const_get(const)
      enum  = C.const_get(const)
      str_or_int.to_s.downcase.scan(/./m).inject(0) do |int, c|
        if n = names[c]
          int | enum[n]
        else
          warn "skipping unrecognized #{name}"
          int
        end
      end
    end
  end
end

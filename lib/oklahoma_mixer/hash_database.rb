require "oklahoma_mixer/error"
require "oklahoma_mixer/extensible_string"
require "oklahoma_mixer/array_list"
require "oklahoma_mixer/hash_database/c"

module OklahomaMixer
  class HashDatabase
    #################
    ### Constants ###
    #################
    
    MODES = { "r" => :OREADER,
              "w" => :OWRITER,
              "c" => :OCREAT,
              "t" => :OTRUNC,
              "e" => :ONOLCK,
              "f" => :OLCKNB,
              "s" => :OTSYNC }
    OPTS  = { "l" => :TLARGE,
              "d" => :TDEFLATE,
              "b" => :TBZIP,
              "t" => :TTCBS }
    
    ###################
    ### File System ###
    ###################
    
    def initialize(path, *args)
      options              = args.last.is_a?(Hash)   ? args.last  : { }
      mode                 = !args.first.is_a?(Hash) ? args.first : nil
      @path                = path
      @db                  = lib.new
      self.default         = options[:default]
      @in_transaction      = false
      @abort               = false
      @nested_transactions = options[:nested_transactions]
      
      try(:setmutex) if options[:mutex]
      tune(options)
      
      warn "mode option supersedes mode argument" if mode and options[:mode]
      mode_enum  = cast_to_enum_int(options.fetch(:mode, mode || "wc"), :mode)
      mode_name  = "#{self.class.to_s[/([HBFT])\w+\z/, 1]}DB#{MODES["r"]}"
      @read_only = (mode_enum & lib::MODES[mode_name.to_sym]).nonzero?
      try(:open, path, mode_enum)
    rescue Exception
      close if defined?(@db) and @db
      raise
    end
    
    def optimize(options)
      try( options[:tune] ? :tune : :optimize,
           options.fetch(:bnum,  0).to_i,
           options.fetch(:apow, -1).to_i,
           options.fetch(:fpow, -1).to_i,
           cast_to_enum_int(options.fetch(:opts, 0xFF), :opt) )
    end
    
    attr_reader :path
    
    def read_only?
      @read_only
    end
    
    def file_size
      lib.fsiz(@db)
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
      k      = cast_key_in(key)
      v      = cast_value_in(value) unless mode == :add and not block_given?
      result = value
      if block_given?
        warn "block supersedes mode argument" unless mode.nil?
        callback = lambda { |old_value_pointer, old_size, returned_size, _|
          old_value         = old_value_pointer.get_bytes(0, old_size)
          replacement, size = cast_value_in(yield(key, old_value, value))
          returned_size.put_int(0, size)
          pointer = Utilities.malloc(size)
          pointer.put_bytes(0, replacement) unless pointer.address.zero?
          pointer
        }
        try(:putproc, k, v, callback, nil)
      else
        if mode == :keep
          result = try(:putkeep, k, v, :no_error => {21 => false})
        elsif mode == :cat
          try(:putcat, k, v)
        elsif mode == :async and self.class == HashDatabase
          try(:putasync, k, v)
        elsif mode == :add
          result = case value
                   when Float then try( :adddouble, k, value,
                                        :failure => lambda { |n| n.nan? } )
                   else            try( :addint, k, value.to_i,
                                        :failure => Utilities::INT_MIN )
                   end
        else
          warn "unsupported mode for database type" if mode
          try(:put, k, v)
        end
      end
      result
    end
    alias_method :[]=, :store
    
    def fetch(key, *default)
      if value = try( :read_from_func, :get, cast_key_in(key),
                      :failure => nil, :no_error => {22 => nil} )
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
      list   = ArrayList.new(lib.fwmkeys(@db, prefix, prefix.size, limit))
      list.map { |key| cast_key_out(key) }
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
      try(:out, cast_key_in(key), :no_error => {22 => nil})
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
      lib.rnum(@db)
    end
    alias_method :length, :size
    
    def empty?
      size.zero?
    end
    
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
        yield cast_key_out(key)
      end
    end
    
    def each
      try(:iterinit)
      loop do
        Utilities.temp_xstr do |key|
          Utilities.temp_xstr do |value|
            return self unless try( :iternext3, key.pointer, value.pointer,
                                    :no_error => {22 => false} )
            yield [cast_key_out(key.to_s), cast_value_out(value.to_s)]
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
    
    def to_hash(set_default = true)
      default = @default && lambda { |hash, key| @default[key] } if set_default
      hash    = Hash.new(&default)
      each do |key, value|
        hash[key] ||= value
      end
      hash
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

    def lib
      @c ||= self.class.const_get(:C)
    end
    
    def try(func, *args)
      options  = args.last.is_a?(Hash) ? args.pop : { }
      failure  = options.fetch(:failure, false)
      no_error = options.fetch(:no_error, { })
      result   = func == :read_from_func                                ?
                 lib.read_from_func(args[0], @db, *args[1..-1].flatten) :
                 lib.send(func, @db, *args.flatten)
      if failure.is_a?(Proc) ? failure[result] : result == failure
        error_code = lib.ecode(@db)
        if no_error.include? error_code
          no_error[error_code]
        else
          error_message = lib.errmsg(error_code)
          fail Error::CabinetError,
               "#{error_message} (error code #{error_code})"
        end
      else
        result
      end
    end
    
    def cast_to_enum_int(str_or_int, name)
      return str_or_int if str_or_int.is_a? Integer
      const = "#{name.to_s.upcase}S"
      names = self.class.const_get(const)
      enum  = lib.const_get(const)
      str_or_int.to_s.downcase.scan(/./m).inject(0) do |int, c|
        if n = names[c]
          int | enum["#{self.class.to_s[/([HBFT])\w+\z/, 1]}DB#{n}".to_sym]
        else
          warn "skipping unrecognized #{name}"
          int
        end
      end
    end
    
    def tune(options)
      if self.class == HashDatabase and
         options.values_at(:bnum, :apow, :fpow, :opts).any?
        optimize(options.merge(:tune => true))
      end
      {:rcnum => :cache, :xmsiz => nil, :dfunit => nil}.each do |option, func|
        next if func == :cache and self.class != HashDatabase
        if i = options[option]
          try("set#{func || option}", i.to_i)
        end
      end
    end
    
    def cast_to_bytes_and_length(object)
      bytes = object.to_s
      [bytes, bytes.length]
    end
    alias_method :cast_key_in,   :cast_to_bytes_and_length
    alias_method :cast_value_in, :cast_to_bytes_and_length
    
    def cast_to_encoded_string(string)
      string
    end
    alias_method :cast_key_out,   :cast_to_encoded_string
    alias_method :cast_value_out, :cast_to_encoded_string
  end
end

require "oklahoma_mixer/hash_database/c"
require "oklahoma_mixer/extensible_string"

module OklahomaMixer
  class HashDatabase
    ###########################
    ### Opening and Closing ###
    ###########################
    
    def initialize(path, options = { })
      @path        = path
      @db          = C.new
      self.default = options[:default]
      C.open(@db, path, (1 << 1) | (1 << 2))
    end
    
    def close
      C.close(@db)
      C.del(@db)
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
      k, v = key.to_s, value.to_s
      case mode
      when :keep
        C.putkeep(@db, k, k.size, v, v.size)
      when :cat
        C.putcat(@db, k, k.size, v, v.size)
        value
      when :async
        C.putasync(@db, k, k.size, v, v.size)
        value
      when :counter
        case value
        when Float
          C.adddouble(@db, k, k.size, value)
        else
          C.addint(@db, k, k.size, value.to_i)
        end
      else
        C.put(@db, k, k.size, v, v.size)
        value
      end
    end
    alias_method :[]=, :store
    
    def fetch(key, *default)
      Utilities.temp_int do |size|
        begin
          k     = key.to_s
          value = C.get(@db, k, k.size, size)
          if value.address.zero?
            if block_given?
              unless default.empty?
                warn "block supersedes default value argument"
              end
              yield key
            elsif not default.empty?
              default.first
            else
              fail IndexError, "key not found"
            end
          else
            value.get_bytes(0, size.get_int(0))
          end
        ensure
          Utilities.free(value) if value
        end
      end
    end
    
    def [](key)
      fetch(key, &@default)
    rescue IndexError
      nil
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
    
    def update(hash)
      if block_given?
        hash.each do |key, value|
          unless store(key, value, :keep)
            store(key, yield(key, self[key], value))
          end
        end
      else
        hash.each do |key, value|
          store(key, value)
        end
      end
      self
    end
    
    def values_at(*keys)
      keys.map { |key| self[key] }
    end
    
    #################
    ### Iteration ###
    #################
    
    include Enumerable
    
    def each_key
      C.iterinit(@db)
      loop do
        Utilities.temp_int do |size|
          begin
            key = C.iternext(@db, size)
            return self if key.address.zero?
            yield key.get_bytes(0, size.get_int(0))
          ensure
            Utilities.free(key) if key
          end
        end
      end
    end
    
    def each
      C.iterinit(@db)
      loop do
        Utilities.temp_xstr do |key|
          Utilities.temp_xstr do |value|
            return self unless C.iternext3(@db, key.xstr, value.xstr)
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
  end
end

require "oklahoma_mixer/hash_database/c"

module OklahomaMixer
  class HashDatabase
    def initialize(path, options = { })
      @path        = path
      @db          = C.new
      self.default = options[:default]
      C.open(@db, path, (1 << 1) | (1 << 2))
    end
    
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
      k     = key.to_s
      size  = FFI::MemoryPointer.new(:int)
      value = C.get(@db, k, k.size, size)
      if value.address.zero?
        if block_given?
          warn "block supersedes default value argument" unless default.empty?
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
      size.free     if size
      C.free(value) if value
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
    
    def close
      C.close(@db)
    end
  end
end

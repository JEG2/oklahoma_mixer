require "oklahoma_mixer/hash_map/c"

module OklahomaMixer
  class HashMap  # :nodoc:
    def initialize(pointer = C.new)
      @pointer = pointer
    end
    
    attr_reader :pointer
    
    def update(pairs)
      pairs.each do |key, value|
        C.put(@pointer, *[yield(key), yield(value)].flatten)
      end
    end
    
    def each
      C.iterinit(@pointer)
      loop do
        return self unless key = C.read_from_func(:iternext, :no_free, @pointer)
        yield [key, C.read_from_func(:get, :no_free, @pointer, key, key.size)]
      end
    end
    
    def to_hash
      hash = { }
      each do |key, value|
        hash[yield(key)] = yield(value)
      end
      hash
    end
    
    def replace(pairs, &cast)
      C.clear(@pointer)
      update(pairs, &cast)
    end
    
    def free
      C.del(@pointer)
    end
  end
end

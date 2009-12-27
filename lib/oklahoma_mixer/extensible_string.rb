require "oklahoma_mixer/extensible_string/c"

module OklahomaMixer
  class ExtensibleString
    def initialize(xstr = C.new)
      @xstr = xstr
    end
    
    attr_reader :xstr
    
    def pointer
      C.ptr(@xstr)
    end
    
    def size
      C.size(@xstr)
    end
    alias_method :length, :size
    
    def to_s
      pointer.get_bytes(0, size)
    end
    
    def delete
      C.del(@xstr)
    end
  end
end

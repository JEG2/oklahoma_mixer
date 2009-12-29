require "oklahoma_mixer/extensible_string/c"

module OklahomaMixer
  class ExtensibleString
    def initialize(pointer = C.new)
      @pointer = pointer
    end
    
    attr_reader :pointer
    
    def to_s
      data_pointer.get_bytes(0, data_size)
    end
    
    def free
      C.del(@pointer)
    end
    
    private
    
    def data_pointer
      C.ptr(@pointer)
    end
    
    def data_size
      C.size(@pointer)
    end
  end
end

require "oklahoma_mixer/array_list/c"

module OklahomaMixer
  class ArrayList
    def initialize(pointer = C.new)
      @pointer = pointer
    end
    
    def shift
      C.read_from_func(:shift, @pointer)
    end
    
    include Enumerable
    
    def each
      while value = shift
        yield value
      end
    end

    def free
      C.del(@pointer)
    end
  end
end

module OklahomaMixer
  class ArrayList  # :nodoc:
    def initialize(pointer = C.new)
      @pointer = pointer
    end
    
    def shift
      yield C.read_from_func(:shift, @pointer)
    end
    
    def to_a(&cast)
      values = [ ]
      while value = shift(&cast)
        values << value
      end
      values
    end

    def free
      C.del(@pointer)
    end
  end
end

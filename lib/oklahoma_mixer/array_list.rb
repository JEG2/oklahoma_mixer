module OklahomaMixer
  class ArrayList  # :nodoc:
    def initialize(pointer_or_size)
      @pointer = case pointer_or_size
                 when FFI::Pointer then pointer_or_size
                 else                   C.new2(pointer_or_size.to_i)
                 end
    end
    
    attr_reader :pointer
    
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
    
    def push(*values)
      values.each do |value|
        C.push(@pointer, *yield(value))
      end
    end

    def free
      C.del(@pointer)
    end
  end
end

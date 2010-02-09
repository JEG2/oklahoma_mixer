require "oklahoma_mixer/array_list/c"

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
      value = C.read_from_func(:shift, @pointer)
      block_given? ? yield(value) : value
    end
    
    def map
      values = [ ]
      while value = shift
        values << yield(value)
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

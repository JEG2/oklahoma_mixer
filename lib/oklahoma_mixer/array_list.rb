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
    
    include Enumerable
    
    def each
      (0...C.num(pointer)).each do |i|
        yield C.read_from_func(:val, :no_free, @pointer, i)
      end
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

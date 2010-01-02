module OklahomaMixer
  class Cursor  # :nodoc:
    def initialize(b_tree_pointer, start = nil)
      @pointer = C.new(b_tree_pointer)
      if start
        C.jump(@pointer, start, start.size)
      else
        C.first(@pointer)
      end
    end
    
    def key
      C.read_from_func(:key, @pointer)
    end
    
    def value
      C.read_from_func(:val, @pointer)
    end
    
    def key_and_value
      Utilities.temp_xstr do |key|
        Utilities.temp_xstr do |value|
          if C.rec(@pointer, key.pointer, value.pointer)
            [key.to_s, value.to_s]
          end
        end
      end
    end
    
    def next
      C.next(@pointer)
    end
    
    def delete
      C.out(@pointer)
    end
    
    def free
      C.del(@pointer)
    end
  end
end

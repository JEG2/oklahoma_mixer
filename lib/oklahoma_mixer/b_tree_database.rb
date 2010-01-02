module OklahomaMixer
  class BTreeDatabase < HashDatabase
    #################
    ### Iteration ###
    #################
    
    def each_key(start = nil)
      cursor_in_loop(start) do |iterator|
        throw(:finish_iteration) unless key = iterator.key
        yield key
      end
    end
    
    def each(start = nil)
      cursor_in_loop(start) do |iterator|
        throw(:finish_iteration) unless key_and_value = iterator.key_and_value
        yield key_and_value
      end
    end
    alias_method :each_pair, :each
    
    def each_value(start = nil)
      cursor_in_loop(start) do |iterator|
        throw(:finish_iteration) unless value = iterator.value
        yield value
      end
    end
    
    def delete_if(start = nil)
      cursor(start) do |iterator|
        loop do
          break unless key_and_value = iterator.key_and_value
          break unless iterator.send(yield(*key_and_value) ? :delete : :next)
        end
      end
    end
    
    #######
    private
    #######
    
    def cursor(start = nil)
      cursor = Cursor.new(@db, start.nil? ? start : start.to_s)
      yield cursor
      self
    ensure
      cursor.free if cursor
    end
    
    def cursor_in_loop(start = nil)
      cursor(start) do |iterator|
        catch(:finish_iteration) do
          loop do
            yield iterator
            break unless iterator.next
          end
        end
      end
    end
  end
end

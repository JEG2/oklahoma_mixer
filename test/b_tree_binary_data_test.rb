require "test_helper"
require "shared_binary_data"

class TestBTreeBinaryData < Test::Unit::TestCase
  def setup
    @db       = bdb
    @key      = "Binary\0Name"
    @value    = "James\0Edward\0Gray\0II"
    @db[@key] = @value
    @closed   = false
  end
  
  def teardown
    @db.close unless @closed
    remove_db_files
  end
  
  include SharedBinaryData

  def test_null_bytes_are_preserved_during_value_iteration
    @db.each_value do |value|
      assert_equal(@value, value)
    end
  end
  
  def test_null_bytes_are_preserved_by_key_ranges
    assert_equal([@key], @db.keys(:range => "A".."Z"))
  end
  
  def test_null_bytes_are_preserved_in_comparison_functions
    @db.close
    @closed = true
    remove_db_files
    
    callback = lambda { |a, b|
      assert_equal(@key, a) unless a.empty?
      assert_equal(@key, b) unless b.empty?
      a <=> b
    }
    bdb(:cmpfunc => callback) do |db|
      db[@key] = @value
      assert_equal([@key], db.keys)  # forces a comparison with ""
    end
  end
end

require "test_helper"

class TestBinaryData < Test::Unit::TestCase
  def setup
    @db       = hdb
    @key      = "Binary\0Name"
    @value    = "James\0Edward\0Gray\0II"
    @db[@key] = @value
  end
  
  def teardown
    @db.close
    remove_db_files
  end
  
  def test_keys_and_values_can_be_read_with_null_bytes
    assert_equal(@value, @db[@key])
  end
  
  def test_null_bytes_are_preservered_by_update_callback
    @db.update(@key => "conflict") { |key, old_value, new_value| "new\0value" }
    assert_equal("new\0value", @db[@key])
  end
  
  def test_null_bytes_are_preserved_during_key_iteration
    @db.each_key do |key|
      assert_equal(@key, key)
    end
  end
  
  def test_null_bytes_are_preserved_during_iteration
    @db.each do |key, value|
      assert_equal(@key,   key)
      assert_equal(@value, value)
    end
  end
  
  def test_null_bytes_are_preserved_by_key_listing
    assert_equal([@key], @db.keys)
  end
end

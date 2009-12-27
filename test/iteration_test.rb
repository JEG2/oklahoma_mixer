require "test_helper"

class TestIteration < Test::Unit::TestCase
  def setup
    @db     = hdb
    @keys   = %w[a b c]
    @values = @keys.map { |key| key * 2 }
    @keys.zip(@values) do |key, value|
      @db[key] = value
    end
  end
  
  def teardown
    @db.close
    remove_db_files
  end
  
  def test_each_key_iterates_over_all_keys_in_the_database
    @db.each_key do |key|
      @keys.delete(key)
    end
    assert(@keys.empty?, "All keys were not iterated over")
  end
  
  def test_each_iterates_over_all_key_value_pairs_in_arrays
    @db.each do |key_value_array|
      assert_instance_of(Array, key_value_array)
      assert_equal(2, key_value_array.size)
      key, value = key_value_array
      assert_equal(key * 2, value)
      @keys.delete(key)
      @values.delete(value)
    end
    assert( @keys.empty? && @values.empty?,
            "All key/value pairs were not iterated over" )
  end
  
  def test_the_arrays_passed_to_each_can_be_split
    @db.each do |key, value|
      @keys.delete(key)
      @values.delete(value)
    end
    assert( @keys.empty? && @values.empty?,
            "All key/value pairs were not iterated over" )
  end
  
  def test_each_pair_is_an_alias_for_each
    each_arrays = [ ]
    @db.each do |array|
      each_arrays << array
    end
    @db.each_pair do |array|
      each_arrays.delete(array)
    end
    each_keys_and_values = [ ]
    @db.each do |key, value|
      each_keys_and_values << [key, value]
    end
    @db.each_pair do |key, value|
      each_keys_and_values.delete([key, value])
    end
    assert( each_arrays.empty? && each_keys_and_values.empty?,
            "The iterations did not match" )
  end
  
  def test_each_value_iterates_over_all_values_in_the_database
    @db.each_value do |value|
      @values.delete(value)
    end
    assert(@values.empty?, "All values were not iterated over")
  end
  
  def test_the_standard_iterators_are_supported
    assert_kind_of(Enumerable, @db)
    
    # examples
    assert_equal(%w[b bb], @db.find { |_, value| value == "bb" })
    assert_nil(@db.find { |_, value| value == "dd" })
    assert_equal(%w[aaa bbb ccc], @db.map { |key, value| key + value }.sort)
    assert( @db.any? { |_, value| value.include? "c" },
            "A value was not found during iteration" )
  end
  
  def test_iterators_return_self_to_match_hash_interface
    %w[each_key each each_pair each_value].each do |iterator|
      assert_equal(@db, @db.send(iterator) { })
    end
  end
end

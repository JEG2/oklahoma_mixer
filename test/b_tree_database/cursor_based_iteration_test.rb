require "test_helper"
require "shared/iteration_tests"

class TestCursorBasedIteration < Test::Unit::TestCase
  def setup
    @db     = bdb
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
  
  include IterationTests
  
  def test_each_key_can_begin_iteration_at_a_passed_key
    @db.each_key("b") do |key|
      @keys.delete(key)
    end
    assert_equal(%w[a], @keys)
  end
  
  def test_each_key_can_begin_iteration_between_keys
    @db.each_key("ab") do |key|  # after "a", but before "b"
      @keys.delete(key)
    end
    assert_equal(%w[a], @keys)
  end
  
  def test_iteration_can_be_broken_with_each_key
    @db.each_key("b") do |key|
      @keys.delete(key)
      break
    end
    assert_equal(%w[a c], @keys)
  end
  
  def test_each_can_begin_iteration_at_a_passed_key
    @db.each("b") do |key, value|
      @keys.delete(key)
      @values.delete(value)
    end
    assert_equal(%w[a],  @keys)
    assert_equal(%w[aa], @values)
  end
  
  def test_each_can_begin_iteration_between_keys
    @db.each("ab") do |key, value|  # after "a", but before "b"
      @keys.delete(key)
      @values.delete(value)
    end
    assert_equal(%w[a],  @keys)
    assert_equal(%w[aa], @values)
  end
  
  def test_iteration_can_be_broken_with_each
    @db.each("b") do |key, value|
      @keys.delete(key)
      @values.delete(value)
      break
    end
    assert_equal(%w[a  c],  @keys)
    assert_equal(%w[aa cc], @values)
  end

  def test_reverse_each_can_begin_iteration_at_a_passed_key
    @db.reverse_each("b") do |key, value|
      @keys.delete(key)
      @values.delete(value)
    end
    assert_equal(%w[c],  @keys)
    assert_equal(%w[cc], @values)
  end
  
  def test_reverse_each_can_begin_iteration_between_keys
    @db.reverse_each("ab") do |key, value|  # after "a", but before "b"
      @keys.delete(key)
      @values.delete(value)
    end
    assert_equal(%w[c],  @keys)
    assert_equal(%w[cc], @values)
  end
  
  def test_iteration_can_be_broken_with_reverse_each
    @db.reverse_each("b") do |key, value|
      @keys.delete(key)
      @values.delete(value)
      break
    end
    assert_equal(%w[a  c],  @keys)
    assert_equal(%w[aa cc], @values)
  end
  
  def test_each_value_can_begin_iteration_at_a_passed_key
    @db.each_value("b") do |value|
      @values.delete(value)
    end
    assert_equal(%w[aa], @values)
  end
  
  def test_each_value_can_begin_iteration_between_keys
    @db.each_value("ab") do |value|  # after "a", but before "b"
      @values.delete(value)
    end
    assert_equal(%w[aa], @values)
  end
  
  def test_iteration_can_be_broken_with_each_value
    @db.each_value("b") do |value|
      @values.delete(value)
      break
    end
    assert_equal(%w[aa cc], @values)
  end
  
  def test_delete_if_can_begin_iteration_at_a_passed_key
    @db.delete_if("b") do |key, value|
      @keys.delete(key)
      @values.delete(value)
      true
    end
    assert_equal(%w[a],  @keys)
    assert_equal(%w[aa], @values)
  end
  
  def test_delete_if_can_begin_iteration_between_keys
    @db.delete_if("ab") do |key, value|  # after "a", but before "b"
      @keys.delete(key)
      @values.delete(value)
      true
    end
    assert_equal(%w[a],  @keys)
    assert_equal(%w[aa], @values)
  end
  
  def test_iteration_can_be_broken_with_each_delete_if
    @db.delete_if("b") do |key, value|
      break if key == "c"
      @keys.delete(key)
      @values.delete(value)
      true
    end
    assert_equal(%w[a  c],  @keys)
    assert_equal(%w[aa cc], @values)
  end
end

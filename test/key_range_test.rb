require "test_helper"

class TestKeyRange < Test::Unit::TestCase
  def teardown
    remove_db_files
  end
  
  def test_b_tree_supports_non_range_key_requests
    abc_db do |db|
      assert_equal(%w[a b], db.keys(:limit => 2))
    end
  end
  
  def test_keys_can_return_a_range_of_keys_for_a_b_tree_database
    abc_db do |db|
      assert_equal(%w[b c], db.keys(:range => "b".."c"))
    end
  end
  
  def test_range_overrides_prefix_and_triggers_a_warning
    abc_db do |db|
      warning = capture_stderr do
        # returns range
        assert_equal(%w[b c], db.keys(:range => "b".."c", :prefix => "ignored"))
      end
      assert(!warning.empty?, "A warning was not issued for a range and prefix")
    end

    num_db do |db|
      warning = capture_stderr do
        # returns range
        assert_equal([2, 3], db.keys(:range => 2..3, :prefix => "ignored"))
      end
      assert(!warning.empty?, "A warning was not issued for a range and prefix")
    end
  end
  
  def test_b_tree_key_ranges_must_be_passed_a_range_object
    abc_db do |db|
      assert_nothing_raised(ArgumentError) do
        db.keys(:range => "b".."c")
      end
      assert_raise(ArgumentError) do
        db.keys(:range => "not a Range")
      end
    end
  end
  
  def test_boundaries_are_converted_to_strings_for_a_b_tree_database
    abc_db do |db|
      assert_equal(%w[b c], db.keys(:range => %w[b]..%w[c]))
    end
  end
  
  def test_key_ranges_can_exclude_the_last_member_in_a_b_tree_database
    abc_db do |db|
      assert_equal(%w[b], db.keys(:range => "b"..."c"))
    end
  end
  
  def test_key_ranges_can_exclude_the_first_member_in_a_b_tree_database
    abc_db do |db|
      assert_equal(%w[c], db.keys(:range => "b".."c", :exclude_start => true))
    end
  end
  
  def test_key_ranges_can_use_values_between_keys_in_a_b_tree_database
    abc_db do |db|
      assert_equal(%w[b c], db.keys(:range => "ab".."f"))
    end
  end
  
  def test_a_limit_can_be_set_for_key_ranges_in_a_b_tree_database
    abc_db do |db|
      assert_equal(%w[b], db.keys(:range => "b".."c", :limit => 1))
    end
  end
  
  def test_range_queries_work_with_custom_ordering
    bdb(:cmpfunc => lambda { |a, b| a.to_i <=> b.to_i }) do |db|
      db.update(1 => :a, 11 => :b, 2 => :c)
      assert_equal(%w[2 11], db.keys(:range => 2..100))
    end
  end

  def test_fixed_length_supports_non_range_key_requests
    num_db do |db|
      assert_equal([1, 2], db.keys(:limit => 2))
    end
  end
  
  def test_keys_can_return_a_range_of_keys_for_a_fixed_length_database
    num_db do |db|
      assert_equal([2, 3], db.keys(:range => 2..3))
    end
  end
  
  def test_fixed_length_key_ranges_must_be_passed_a_range_or_array
    num_db do |db|
      assert_nothing_raised(ArgumentError) do
        db.keys(:range => "min".."max")
      end
      assert_nothing_raised(ArgumentError) do
        db.keys(:range => [:min, 100])
      end
      assert_raise(ArgumentError) do
        db.keys(:range => "not a Range")
      end
    end
  end
  
  def test_boundaries_are_converted_to_integers_for_a_fixed_length_database
    num_db do |db|
      assert_equal([2, 3], db.keys(:range => "2".."3"))
    end
  end
  
  def test_key_ranges_can_exclude_the_last_member_in_a_fixed_length_database
    num_db do |db|
      assert_equal([2], db.keys(:range => 2...3))
      assert_equal([2], db.keys(:range => [2, 3], :exclude_end => true))
    end
  end
  
  def test_key_ranges_can_exclude_the_first_member_in_a_fixed_length_database
    num_db do |db|
      assert_equal([3], db.keys(:range => 2..3, :exclude_start => true))
    end
  end
  
  def test_key_ranges_can_use_values_between_keys_in_a_fixed_length_database
    num_db do |db|
      db.update(5 => 500, 6 => 600)
      assert_equal([5, 6], db.keys(:range => 4..7))
    end
  end
  
  def test_a_limit_can_be_set_for_key_ranges_in_a_fixed_length_database
    num_db do |db|
      assert_equal([2], db.keys(:range => 2..3, :limit => 1))
    end
  end
  
  #######
  private
  #######
  
  def abc_db
    bdb do |db|
      db.update(:a => 1, :b => 2, :c => 3)
      yield db
    end
  end
  
  def num_db
    fdb do |db|
      db.update(1 => 100, 2 => 200, 3 => 300)
      yield db
    end
  end
end

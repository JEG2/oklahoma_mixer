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
  end
  
  def test_b_tree_key_ranges_must_be_passed_a_range_object
    abc_db do |db|
      assert_raise(ArgumentError) do
        db.keys(:range => "not a Range")
      end
    end
  end
  
  def test_range_boundaries_are_converted_to_strings_for_a_b_tree_database
    abc_db do |db|
      assert_equal(%w[b c], db.keys(:range => %w[b]..%w[c]))
    end
  end
  
  def test_key_ranges_can_exclude_the_last_member
    abc_db do |db|
      assert_equal(%w[b], db.keys(:range => "b"..."c"))
    end
  end
  
  def test_key_ranges_can_exclude_the_first_member
    abc_db do |db|
      assert_equal(%w[c], db.keys(:range => "b".."c", :exclude_start => true))
    end
  end
  
  def test_key_ranges_can_use_values_between_keys
    abc_db do |db|
      assert_equal(%w[b c], db.keys(:range => "ab".."f"))
    end
  end
  
  def test_a_limit_can_be_set_for_key_ranges
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
  
  #######
  private
  #######
  
  def abc_db
    bdb do |db|
      db.update(:a => 1, :b => 2, :c => 3)
      yield db
    end
  end
end

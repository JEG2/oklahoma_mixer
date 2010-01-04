require "test_helper"

class TestDuplicateStorage < Test::Unit::TestCase
  def setup
    @db = bdb
  end
  
  def teardown
    @db.close
    remove_db_files
  end
  
  def test_duplicates_can_be_stored
    assert(@db.store("Gray", "Dana",  :dup), "Failed to store initial value")
    assert(@db.store("Gray", "James", :dup), "Failed to store duplicate value")
    assert_equal("Dana", @db["Gray"])  # always returns the first
  end
  
  def test_keys_are_a_unique_listing_not_showing_duplicates
    @db.update("Gray" => "Dana", "Matsumoto" => "Yukihiro")
    @db.store("Gray", "James", :dup)
    assert_equal(%w[Gray Matsumoto], @db.keys)
    assert_equal(%w[Gray],           @db.keys(:range => "G"..."H"))
  end
  
  def test_values_can_be_scoped_to_a_key_to_retrieve_all_duplicates
    @db[:other] = "one record"
    assert_equal(["one record"], @db.values)
    assert_equal([ ],            @db.values("Gray"))
    assert(@db.store("Gray", "Dana", :dup), "Failed to store initial value")
    assert_equal(%w[Dana], @db.values("Gray"))
    assert(@db.store("Gray", "James", :dup), "Failed to store duplicate value")
    assert_equal(%w[Dana James], @db.values("Gray"))
  end
  
  def test_delete_removes_the_first_value_by_default
    @db.update("Gray" => "Dana", "Matsumoto" => "Yukihiro")
    @db.store("Gray", "James", :dup)
    assert_equal(%w[Dana James], @db.values("Gray"))
    assert_equal("Dana",         @db.delete("Gray"))
    assert_equal(%w[James],      @db.values("Gray"))
    assert_equal("James",        @db.delete("Gray"))
    assert_nil(@db.delete("Gray"))
  end
  
  def test_delete_with_dup_mode_deletes_all_values
    @db.update("Gray" => "Dana", "Matsumoto" => "Yukihiro")
    @db.store("Gray", "James", :dup)
    assert_equal(%w[Dana James], @db.values("Gray"))
    assert_equal(%w[Dana James], @db.delete("Gray", :dup))
    assert_equal([ ],            @db.delete("Gray", :dup))
  end
  
  def test_delete_with_dup_mode_supports_the_missing_handler
    assert_nil(@db.delete(:missing, :dup) { nil })
  end
  
  def test_size_can_be_scoped_to_a_key_to_retrieve_all_duplicates
    @db[:other] = "one record"
    assert_equal(1, @db.size)
    assert_equal(0, @db.size("Gray"))
    assert(@db.store("Gray", "Dana", :dup), "Failed to store initial value")
    assert_equal(1, @db.size("Gray"))
    assert(@db.store("Gray", "James", :dup), "Failed to store duplicate value")
    assert_equal(2, @db.size("Gray"))
  end
  
  def test_duplicates_show_up_in_cursor_based_iteration_of_keys
    @db.update("Gray" => "Dana", "Matsumoto" => "Yukihiro")
    @db.store("Gray", "James", :dup)
    keys = [ ]
    @db.each_key do |key|
      keys << key
    end
    assert_equal(%w[Gray Gray Matsumoto], keys)
  end
  
  def test_duplicates_show_up_in_cursor_based_iteration
    @db.update("Gray" => "Dana", "Matsumoto" => "Yukihiro")
    @db.store("Gray", "James", :dup)
    pairs = [ ]
    @db.each do |pair|
      pairs << pair
    end
    assert_equal([%w[Gray Dana], %w[Gray James], %w[Matsumoto Yukihiro]], pairs)
  end
  
  def test_duplicates_show_up_in_reverse_cursor_based_iteration
    @db.update("Gray" => "Dana", "Matsumoto" => "Yukihiro")
    @db.store("Gray", "James", :dup)
    pairs = [ ]
    @db.reverse_each do |pair|
      pairs << pair
    end
    assert_equal([%w[Matsumoto Yukihiro], %w[Gray James], %w[Gray Dana]], pairs)
  end
  
  def test_duplicates_show_up_in_cursor_based_iteration_of_values
    @db.update("Gray" => "Dana", "Matsumoto" => "Yukihiro")
    @db.store("Gray", "James", :dup)
    values = [ ]
    @db.each_value do |value|
      values << value
    end
    assert_equal(%w[Dana James Yukihiro], values)
  end
end

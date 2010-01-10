require "test_helper"

class TestGettingAndSettingByID < Test::Unit::TestCase
  def setup
    @db = fdb
  end
  
  def teardown
    @db.close
    remove_db_files
  end

  def test_a_key_value_pair_can_be_stored_and_fetched_from_the_database
    assert_equal("value", @db.store(42, "value"))
    assert_equal("value", @db.fetch(42))  # later
  end
  
  def test_keys_are_converted_to_integers
    assert_equal("value", @db.store(42, "value"))
    assert_equal("value", @db.fetch("42"))  # effectively the same key
  end
  
  def test_the_special_ids_min_and_max_are_supported_after_ids_are_set
    assert_raise(OKMixer::Error::CabinetError) do
      @db[:min]
    end
    assert_raise(OKMixer::Error::CabinetError) do
      @db[:max]
    end
    @db.update(10 => :min, 20 => :middle, 30 => :max)
    assert_equal("min", @db[:min])
    assert_equal("max", @db[:max])
  end
  
  def test_the_special_id_next_can_be_used_to_set_increasing_ids
    3.times do |n|
      assert_equal(n, @db[:next] = n)
    end
    assert_equal([[1, "0"], [2, "1"], [3, "2"]], @db.to_a)
    @db[7] = 6
    assert_equal(7, @db[:next] = 7)
    assert_equal([[1, "0"], [2, "1"], [3, "2"], [7, "6"], [8, "7"]], @db.to_a)
  end
  
  def test_the_special_id_prev_can_be_used_to_add_below_min
    # no min
    assert_raise(OKMixer::Error::CabinetError) do
      @db[:prev] = 100
    end
    
    @db[10] = 10
    assert_equal(9, @db[:prev] = 9)
    assert_equal([[9, "9"], [10, "10"]], @db.to_a)
    
    # can't go below 1
    @db[1] = 1
    assert_raise(OKMixer::Error::CabinetError) do
      @db[:prev] = 100
    end
  end
  
  def test_fetching_a_missing_value_fails_with_an_index_error
    assert_raise(IndexError) do
      @db.fetch(42)
    end
  end
  
  def test_fetch_can_return_a_default_for_a_missing_value
    assert_equal(:value, @db.fetch(42, :value))
  end
  
  def test_fetch_can_run_a_block_returning_its_result_for_a_missing_value
    assert_equal(42, @db.fetch(42) { |key| key })
  end
  
  def test_fetching_with_a_block_overrides_a_default_and_triggers_a_warning
    warning = capture_stderr do
      assert_equal(:returned, @db.fetch(42, :ignored) { :returned })
    end
    assert(!warning.empty?, "A warning was not issued for a default and block")
  end
  
  def test_storing_with_keep_mode_adds_a_value_only_if_it_didnt_already_exist
    assert(@db.store(42, :new, :keep), "Failed to store a new key")
    assert_equal("new", @db.fetch(42))
    assert(!@db.store(42, :replace, :keep), "Replaced an existing key")
    assert_equal("new", @db.fetch(42))
  end
  
  def test_storing_with_cat_mode_concatenates_content_onto_an_existing_value
    assert_equal("One",      @db.store(42, "One", :cat))
    assert_equal("One",      @db.fetch(42))
    assert_equal(", Two",    @db.store(42, ", Two", :cat))
    assert_equal("One, Two", @db.fetch(42))
  end
  
  def test_storing_with_add_mode_adds_to_an_existing_value
    assert_equal(0, @db.store(42,  0, :add))
    assert_equal(1, @db.store(42,  1, :add))
    assert_equal(2, @db.store(42,  1, :add))
    assert_equal(1, @db.store(42, -1, :add))
    
    assert_in_delta(1.5, @db.store(100,  1.5, :add), 2 ** -20)
    assert_in_delta(3.5, @db.store(100,  2.0, :add), 2 ** -20)
    assert_in_delta(2.5, @db.store(100, -1.0, :add), 2 ** -20)
  end
  
  def test_adding_to_a_non_added_value_fails_with_an_error
    @db[42] = 0
    assert_raise(OKMixer::Error::CabinetError) do
      @db.store(42, 1, :add)
    end
  end
  
  def test_switching_add_types_fails_with_an_error
    @db.store(42,    1, :add)
    @db.store(100, 1.0, :add)
    assert_raise(OKMixer::Error::CabinetError) do
      @db.store(42, 2.0, :add)
    end
    assert_raise(OKMixer::Error::CabinetError) do
      @db.store(100, 2, :add)
    end
  end
  
  def test_storing_with_a_block_allows_duplicate_resolution
    @db[42] = :old
    assert_equal( :new, @db.store(42, :new) { |key, old, new|
                                                "#{key}=#{old}&#{new}" } )
    assert_equal("42=old&new", @db[42])
  end
  
  def test_storing_with_a_block_overrides_a_mode_and_triggers_a_warning
    warning = capture_stderr do
      assert_equal(:new, @db.store(42, :new, :cat) { |key, old, new| })
    end
    assert(!warning.empty?, "A warning was not issued for a mode and block")
  end
  
  def test_storing_with_a_mode_not_supported_by_the_database_triggers_a_warning
    warning = capture_stderr do
      assert_equal(:value, @db.store(42, :value, :async))  # normal store
    end
    assert(!warning.empty?, "A warning was not issued for an unsupported mode")
    assert_equal("value", @db[42])
  end
  
  def test_store_and_fetch_can_also_be_used_through_the_indexing_brackets
    assert_equal(:value,  @db[42] = :value)
    assert_equal("value", @db[42])
  end
  
  def test_indexing_returns_nil_instead_of_failing_with_index_error
    assert_nil(@db[42])
  end
  
  def test_a_default_can_be_set_for_indexing_to_return
    @db.default = :default
    assert_equal(:default, @db[42])
  end
  
  def test_the_indexing_default_will_be_run_if_it_is_a_proc
    @db.default = lambda { |key| "is #{key}" }
    assert_equal("is 42", @db[42])
  end
  
  def test_the_indexing_default_for_a_given_key_can_be_retrieved
    @db.default = lambda { |key| "is #{key}" }
    assert_equal("is ",        @db.default)
    assert_equal("is 42", @db.default(42))
  end
  
  def test_the_indexing_default_can_be_changed
    assert_nil(@db[42])
    assert_equal(:default, @db.default = :default)
    assert_equal(:default, @db[:missing])
    proc = lambda { |key| fail RuntimeError, "%p not found" % [key]}
    assert_equal(proc, @db.default = proc)
    error = assert_raise(RuntimeError) { @db[42] }
    assert_equal("42 not found", error.message)
  end
  
  def test_include_and_aliases_can_be_used_to_check_for_the_existance_of_a_key
    @db[42] = true
    %w[include? has_key? key? member?].each do |query|
      assert(@db.send(query,  42),  "Failed to detect an existing key")
      assert(!@db.send(query, 100), "Failed to detect an missing key")
    end
  end
  
  def test_update_sets_multiple_values_at_once_overwriting_old_values
    @db[42] = "old_42"
    assert_equal(@db, @db.update(1 => "new_1", 42 => "new_42", 3 => "new_3"))
    assert_equal(%w[new_1 new_42 new_3], @db.values_at(1, 42, 3))
  end
  
  def test_update_can_be_passed_a_block_for_handling_duplicates
    @db[42] = "old"
    assert_equal( @db, @db.update( 1  => "new",
                                   42 => "new",
                                   3  => "new") { |key, old, new|
                                                  "#{key}=#{old}&#{new}" } )
    assert_equal(%w[new 42=old&new new], @db.values_at(1, 42, 3))
  end
  
  def test_values_at_can_be_used_to_retrieve_multiple_values_at_once
    @db[1] = 100
    @db[3] = 300
    assert_equal([ ],                 @db.values_at)
    assert_equal(["100", nil, "300"], @db.values_at(1, 42, 3))
  end
  
  def test_values_at_supports_defaults
    @db.default = 42
    @db[1]      = 100
    @db[3]      = 300
    assert_equal(["100", 42, "300"], @db.values_at(1, 42, 3))
  end
  
  def test_keys_returns_all_keys_in_the_database
    @db.update(1 => 100, 2 => 200, 3 => 300)
    assert_equal([1, 2, 3], @db.keys)
  end
  
  def test_keys_does_not_support_prefix_for_fixed_length_databases
    assert_raise(ArgumentError) do
      @db.keys(:prefix => "1")
    end
  end
  
  def test_keys_can_take_a_limit_of_keys_to_return
    @db.update(1 => 100, 42 => 4200, 3 => 300)
    assert_equal([1, 3], @db.keys(:limit => 2))
  end
  
  def test_values_returns_all_values_in_the_database
    @db.update(1 => 100, 2 => 200, 3 => 300)
    assert_equal(%w[100 200 300], @db.values)
  end
  
  def test_delete_removes_a_key_from_the_database
    @db[42] = :value
    assert_equal("value", @db.delete(42))
    assert_nil(@db[42])
  end
  
  def test_delete_returns_nil_for_a_missing_key
    assert_nil(@db.delete(42))
  end
  
  def test_delete_can_be_passed_a_block_to_handle_missing_keys
    assert_equal(:value, @db.delete(42) { :value })
  end
  
  def test_clear_removes_all_keys_from_the_database
    @db.update(1 => 100, 2 => 200, 3 => 300)
    assert_equal(@db, @db.clear)
    assert_equal([nil, nil, nil], @db.values_at(1, 2, 3))
  end
  
  def test_size_and_length_return_the_count_of_key_value_pairs_in_the_database
    assert_equal(0, @db.size)
    assert_equal(0, @db.length)
    @db.update(1 => 100, 2 => 200, 3 => 300)
    assert_equal(3, @db.size)
    assert_equal(3, @db.length)
  end
  
  def test_empty_returns_true_while_no_pairs_are_in_the_database
    assert(@db.empty?, "An empty database was not detected")
    @db[42] = :value
    assert(!@db.empty?, "A non-empty database was reported empty")
    @db.delete(42)
    assert(@db.empty?, "An empty database was not detected")
  end
  
  def test_each_key_iterates_over_ids
    @db.update(1 => 100, 2 => 200, 3 => 300)
    keys = [1, 2, 3]
    @db.each_key do |key|
      assert_equal(keys.shift, key)
    end
  end
  
  def test_each_and_each_pair_iterate_over_ids_and_values
    @db.update(1 => 100, 2 => 200, 3 => 300)
    %w[each each_pair].each do |iterator|
      keys   = [1, 2, 3]
      values = %w[100 200 300]
      @db.send(iterator) do |key, value|
        assert_equal(keys.shift,   key)
        assert_equal(values.shift, value)
      end
    end
  end
end

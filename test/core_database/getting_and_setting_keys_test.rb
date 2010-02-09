require "test_helper"
require "shared/storage_tests"

class TestGettingAndSettingKeys < Test::Unit::TestCase
  def setup
    @db = hdb
  end
  
  def teardown
    @db.close
    remove_db_files
  end

  include StorageTests

  def test_a_key_value_pair_can_be_stored_and_fetched_from_the_database
    assert_equal("value", @db.store("key", "value"))
    assert_equal("value", @db.fetch("key"))  # later
  end
  
  def test_both_keys_and_values_are_converted_to_strings
    assert_equal(42,   @db.store(:num, 42))
    assert_equal("42", @db.fetch("num"))  # effectively the same key
  end
  
  def test_storing_with_keep_mode_adds_a_value_only_if_it_didnt_already_exist
    assert(@db.store(:key, :new, :keep), "Failed to store a new key")
    assert_equal("new", @db.fetch(:key))
    assert(!@db.store(:key, :replace, :keep), "Replaced an existing key")
    assert_equal("new", @db.fetch(:key))
  end
  
  def test_storing_with_cat_mode_concatenates_content_onto_an_existing_value
    assert_equal("One",      @db.store(:list, "One", :cat))
    assert_equal("One",      @db.fetch(:list))
    assert_equal(", Two",    @db.store(:list, ", Two", :cat))
    assert_equal("One, Two", @db.fetch(:list))
  end
  
  def test_storing_with_async_mode_is_buffered_writing
    args = capture_args(OKMixer::HashDatabase::C, :putasync) do
      assert_equal(:buffered, @db.store(:key, :buffered, :async))
    end
    assert_instance_of(FFI::Pointer, args[0])
    assert_equal(["key", 3, "buffered", 8], args[1..-1])
  end
  
  def test_storing_with_add_mode_adds_to_an_existing_value
    assert_equal(0, @db.store(:i,  0, :add))
    assert_equal(1, @db.store(:i,  1, :add))
    assert_equal(2, @db.store(:i,  1, :add))
    assert_equal(1, @db.store(:i, -1, :add))
    
    assert_in_delta(1.5, @db.store(:f,  1.5, :add), 2 ** -20)
    assert_in_delta(3.5, @db.store(:f,  2.0, :add), 2 ** -20)
    assert_in_delta(2.5, @db.store(:f, -1.0, :add), 2 ** -20)
  end
  
  def test_adding_to_a_non_added_value_fails_with_an_error
    @db[:i] = 42
    assert_raise(OKMixer::Error::CabinetError) do
      @db.store(:i, 1, :add)
    end
  end
  
  def test_switching_add_types_fails_with_an_error
    @db.store(:i,   1, :add)
    @db.store(:f, 1.0, :add)
    assert_raise(OKMixer::Error::CabinetError) do
      @db.store(:i, 2.0, :add)
    end
    assert_raise(OKMixer::Error::CabinetError) do
      @db.store(:f, 2, :add)
    end
  end
  
  def test_storing_with_a_block_allows_duplicate_resolution
    @db[:key] = :old
    assert_equal( :new, @db.store(:key, :new) { |key, old, new|
                                                "#{key}=#{old}&#{new}" } )
    assert_equal("key=old&new", @db[:key])
  end

  def test_storing_with_a_block_overrides_a_mode_and_triggers_a_warning
    warning = capture_stderr do
      assert_equal(:new, @db.store(:key, :new, :async) { |key, old, new| })
    end
    assert(!warning.empty?, "A warning was not issued for a mode and block")
  end
  
  def test_storing_with_a_mode_not_supported_by_the_database_triggers_a_warning
    warning = capture_stderr do
      assert_equal(:one, @db.store(:dups, :one, :dup))  # normal store
    end
    assert(!warning.empty?, "A warning was not issued for an unsupported mode")
    assert_equal("one", @db[:dups])
    
    bdb do |db|
      warning = capture_stderr do
        assert_equal(:value, db.store(:key, :value, :async))  # normal store
      end
      assert( !warning.empty?,
              "A warning was not issued for an unsupported mode" )
      assert_equal("value", db[:key])
    end
    
    fdb do |db|
      warning = capture_stderr do
        assert_equal(:value, db.store(1, :value, :async))  # normal store
      end
      assert( !warning.empty?,
              "A warning was not issued for an unsupported mode" )
      assert_equal("value", db[1])
    end
    
    tdb do |db|
      warning = capture_stderr do
        assert_equal({ }, db.store(:key, { }, :async))  # normal store
      end
      assert( !warning.empty?,
              "A warning was not issued for an unsupported mode" )
      assert_equal({ }, db[:key])
    end
  end
  
  def test_store_and_fetch_can_also_be_used_through_the_indexing_brackets
    assert_equal(42,   @db[:num] = 42)
    assert_equal("42", @db[:num])
  end
  
  def test_include_and_aliases_can_be_used_to_check_for_the_existance_of_a_key
    @db[:exist] = true
    %w[include? has_key? key? member?].each do |query|
      assert(@db.send(query,  :exist),   "Failed to detect an existing key")
      assert(!@db.send(query, :missing), "Failed to detect an missing key")
    end
  end
  
  def test_update_sets_multiple_values_at_once_overwriting_old_values
    @db[:b] = "old_b"
    assert_equal(@db, @db.update(:a => "new_a", :b => "new_b", :c => "new_c"))
    assert_equal(%w[new_a new_b new_c], @db.values_at(:a, :b, :c))
  end
  
  def test_update_can_be_passed_a_block_for_handling_duplicates
    @db[:b] = "old"
    assert_equal( @db, @db.update( :a => "new",
                                   :b => "new",
                                   :c => "new") { |key, old, new|
                                                  "#{key}=#{old}&#{new}" } )
    assert_equal(%w[new b=old&new new], @db.values_at(:a, :b, :c))
  end
  
  def test_values_at_can_be_used_to_retrieve_multiple_values_at_once
    @db[:a] = 1
    @db[:c] = 2
    assert_equal([ ],             @db.values_at)
    assert_equal(["1", nil, "2"], @db.values_at(:a, :b, :c))
  end
  
  def test_values_at_supports_defaults
    @db.default = 42
    @db[:a]     = 1
    @db[:c]     = 2
    assert_equal(["1", 42, "2"], @db.values_at(:a, :b, :c))
  end
  
  def test_keys_returns_all_keys_in_the_database
    @db.update(:a => 1, :b => 2, :c => 3)
    assert_equal(%w[a b c], @db.keys.sort)
  end
  
  def test_keys_can_take_a_prefix_which_all_returned_keys_must_start_with
    @db.update( "names:1:first" => "James",
                "names:1:last"  => "Gray", 
                "names:2:first" => "Other",
                "names:2:last"  => "Guy" )
    assert_equal( %w[names:1:first names:1:last],
                  @db.keys(:prefix => "names:1:").sort )
  end
  
  def test_keys_can_take_a_limit_of_keys_to_return
    @db.update(:a => 1, :b => 2, :c => 3)
    keys = @db.keys(:limit => 2)
    assert_equal(2, keys.size)
    keys.each do |key|
      assert(%w[a b c].include?(key), "Key wasn't in known keys")
    end
  end
  
  def test_values_returns_all_values_in_the_database
    @db.update(:a => 1, :b => 2, :c => 3)
    assert_equal(%w[1 2 3], @db.values.sort)
  end
  
  def test_delete_removes_a_key_from_the_database
    @db[:key] = :value
    assert_equal("value", @db.delete(:key))
    assert_nil(@db[:key])
  end
  
  def test_clear_removes_all_keys_from_the_database
    @db.update(:a => 1, :b => 2, :c => 3)
    assert_equal(@db, @db.clear)
    assert_equal([nil, nil, nil], @db.values_at(:a, :b, :c))
  end
  
  def test_size_and_length_return_the_count_of_key_value_pairs_in_the_database
    assert_equal(0, @db.size)
    assert_equal(0, @db.length)
    @db.update(:a => 1, :b => 2, :c => 3)
    assert_equal(3, @db.size)
    assert_equal(3, @db.length)
  end
  
  def test_empty_returns_true_while_no_pairs_are_in_the_database
    assert(@db.empty?, "An empty database was not detected")
    @db[:key] = :value
    assert(!@db.empty?, "A non-empty database was reported empty")
    @db.delete(:key)
    assert(@db.empty?, "An empty database was not detected")
  end
end

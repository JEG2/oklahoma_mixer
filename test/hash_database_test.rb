require "test_helper"

require "oklahoma_mixer"

class TestHashDatabase < Test::Unit::TestCase
  DB_PATH = File.join(File.dirname(__FILE__), "test.tch")
  
  def teardown
    File.unlink(DB_PATH) if File.exist? DB_PATH
  end
  
  def test_creating_a_hash_database_creates_the_corresponding_file
    hdb  # open and close
    assert(File.exist?(DB_PATH), "The HashDatabase file was not created")
  end
  
  ################################
  ### Setting and Getting Keys ###
  ################################
  
  def test_a_key_value_pair_can_be_stored_and_fetched_from_the_database
    hdb do |db|
      assert_equal("value", db.store("key", "value"))
    end
  
    # later
    hdb do |db|
      assert_equal("value", db.fetch("key"))
    end
  end
  
  def test_both_keys_and_values_are_converted_to_strings
    hdb do |db|
      assert_equal(42,   db.store(:num, 42))
      assert_equal("42", db.fetch("num"))  # effectively the same key
    end
  end
  
  def test_fetching_a_missing_value_fails_with_an_index_error
    hdb do |db|
      assert_raise(IndexError) do
        db.fetch(:missing)
      end
    end
  end
  
  def test_fetch_can_return_a_default_for_a_missing_value
    hdb do |db|
      assert_equal(42, db.fetch(:missing, 42))
    end
  end
  
  def test_fetch_can_run_a_block_returning_its_result_for_a_missing_value
    hdb do |db|
      assert_equal(:missing, db.fetch(:missing) { |key| key })
    end
  end
  
  def test_fetching_with_a_block_overrides_a_default_and_triggers_a_warning
    warning = capture_stderr do
      hdb do |db|
        assert_equal(42, db.fetch(:missing, 13) { 42 })
      end
    end
    assert(!warning.empty?, "A warning was not issued for a default and block")
  end
  
  def test_storing_with_keep_mode_adds_a_value_only_if_it_didnt_already_exist
    hdb do |db|
      assert(db.store(:key, :new, :keep), "Failed to store a new key")
      assert_equal("new", db.fetch(:key))
      assert(!db.store(:key, :replace, :keep), "Replaced an existing key")
      assert_equal("new", db.fetch(:key))
    end
  end
  
  def test_storing_with_cat_mode_concatenates_content_onto_an_existing_value
    hdb do |db|
      assert_equal("One",      db.store(:list, "One", :cat))
      assert_equal("One",      db.fetch(:list))
      assert_equal(", Two",    db.store(:list, ", Two", :cat))
      assert_equal("One, Two", db.fetch(:list))
    end
  end
  
  def test_storing_with_async_mode_is_buffered_writing
    args = capture_args(OKMixer::HashDatabase::C, :putasync) do
      hdb do |db|
        assert_equal(:buffered, db.store(:key, :buffered, :async))
      end
    end
    assert_instance_of(FFI::Pointer, args[0])
    assert_equal(["key", 3, "buffered", 8], args[1..-1])
  end
  
  def test_storing_with_counter_mode_adds_to_an_existing_value
    hdb do |db|
      assert_equal(0, db.store(:i,  0, :counter))
      assert_equal(1, db.store(:i,  1, :counter))
      assert_equal(2, db.store(:i,  1, :counter))
      assert_equal(1, db.store(:i, -1, :counter))

      assert_in_delta(1.5, db.store(:f,  1.5, :counter), 2 ** -20)
      assert_in_delta(3.5, db.store(:f,  2.0, :counter), 2 ** -20)
      assert_in_delta(2.5, db.store(:f, -1.0, :counter), 2 ** -20)
    end
  end
  
  def test_store_and_fetch_can_also_be_used_through_the_indexing_brackets
    hdb do |db|
      assert_equal(42,   db[:num] = 42)
      assert_equal("42", db[:num])
    end
  end
  
  def test_indexing_returns_nil_instead_of_failing_with_index_error
    hdb do |db|
      assert_nil(db[:missing])
    end
  end
  
  def test_a_default_can_be_set_for_indexing_to_return
    hdb(:default => 42) do |db|
      assert_equal(42, db[:missing])
    end
  end
  
  def test_the_indexing_default_will_be_run_if_it_is_a_proc
    hdb(:default => lambda { |key| "is #{key}" }) do |db|
      assert_equal("is missing", db[:missing])
    end
  end
  
  def test_the_indexing_default_for_a_given_key_can_be_retrieved
    hdb(:default => lambda { |key| "is #{key}" }) do |db|
      assert_equal("is ",        db.default)
      assert_equal("is missing", db.default(:missing))
    end
  end
  
  def test_the_indexing_default_can_be_changed
    hdb do |db|
      assert_nil(db[:missing])
      assert_equal(42, db.default = 42)
      assert_equal(42, db[:missing])
      proc = lambda { |key| fail RuntimeError, "%p not found" % [key]}
      assert_equal(proc, db.default = proc)
      error = assert_raise(RuntimeError) { db[:missing] }
      assert_equal(":missing not found", error.message)
    end
  end
  
  def test_include_and_aliases_can_be_used_to_check_for_the_existance_of_a_key
    hdb do |db|
      db[:exist] = true
      assert(db.include?(:exist), "Failed to detect an existing key")
      assert(db.has_key?(:exist), "Failed to detect an existing key")
      assert(db.key?(:exist),     "Failed to detect an existing key")
      assert(db.member?(:exist),  "Failed to detect an existing key")

      assert(!db.include?(:missing), "Failed to detect an missing key")
      assert(!db.has_key?(:missing), "Failed to detect an missing key")
      assert(!db.key?(:missing),     "Failed to detect an missing key")
      assert(!db.member?(:missing),  "Failed to detect an missing key")
    end
  end
  
  def test_update_sets_multiple_values_at_once_overwriting_old_values
    hdb do |db|
      db[:b] = "old_b"
      assert_equal(db, db.update(:a => "new_a", :b => "new_b", :c => "new_c"))
      assert_equal(%w[new_a new_b new_c], db.values_at(:a, :b, :c))
    end
  end
  
  def test_update_can_be_passed_a_block_for_handling_duplicates
    hdb do |db|
      db[:b] = "old"
      assert_equal( db, db.update( :a => "new",
                                   :b => "new",
                                   :c => "new") { |key, old, new|
                                                  "#{key}=#{old}&#{new}" } )
      assert_equal(%w[new b=old&new new], db.values_at(:a, :b, :c))
    end
  end
  
  def test_values_at_can_be_used_to_retrieve_multiple_values_at_once
    hdb do |db|
      db[:a] = 1
      db[:c] = 2
      assert_equal([ ],             db.values_at)
      assert_equal(["1", nil, "2"], db.values_at(:a, :b, :c))
    end
  end
  
  def test_values_at_supports_defaults
    hdb(:default => 42) do |db|
      db[:a] = 1
      db[:c] = 2
      assert_equal(["1", 42, "2"], db.values_at(:a, :b, :c))
    end
  end
  
  #######
  private
  #######
  
  def hdb(options = { })
    db = OKMixer::HashDatabase.new(DB_PATH, options)
    yield db if block_given?
  ensure
    db.close
  end
end

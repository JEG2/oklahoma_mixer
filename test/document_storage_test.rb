require "test_helper"
require "shared_storage"

class TestDocumentStorage < Test::Unit::TestCase
  def setup
    @db = tdb
  end
  
  def teardown
    @db.close
    remove_db_files
  end
  
  include SharedStorage

  def test_a_document_can_be_stored_and_fetched_from_the_database
    document = {"a" => "1", "b" => "2"}
    assert_equal(document, @db.store("document", document))
    assert_equal(document, @db.fetch("document"))  # later
  end
  
  def test_both_all_keys_and_values_are_converted_to_strings
    assert_equal({:a => 1, :b => 2}, @db.store(:document, {:a => 1, :b => 2}))
    assert_equal( {"a" => "1", "b" => "2"},
                  @db.fetch("document") )  # effectively the same key
  end
  
  def test_storing_with_keep_mode_adds_a_document_only_if_it_didnt_already_exist
    original    = {"a" => "1", "b" => "2"}
    replacement = {"a" => "1", "c" => "3"}
    assert(@db.store(:doc, original, :keep), "Failed to store a new key")
    assert_equal(original, @db.fetch(:doc))
    assert(!@db.store(:doc, replacement, :keep), "Replaced an existing key")
    assert_equal(original, @db.fetch(:doc))
  end
  
  def test_storing_with_cat_mode_concatenates_new_columns_onto_a_document
    original = {"a" => "1",       "b" => "2"}
    added    = {"a" => "ignored", "c" => "new"}
    assert_equal(original,                     @db.store(:cols, original, :cat))
    assert_equal(original,                     @db.fetch(:cols))
    assert_equal(added,                        @db.store(:cols, added, :cat))
    assert_equal(original.merge("c" => "new"), @db.fetch(:cols))
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
  
  def test_additions_are_stored_in_a_document
    assert_equal(42,               @db.store(:i, 42, :add))
    assert_equal({"_num" => "42"}, @db.fetch(:i))

    assert_equal(3.14,               @db.store(:f, 3.14, :add))
    assert_equal({"_num" => "3.14"}, @db.fetch(:f))
  end
  
  def test_additions_can_be_added_to_a_document
    int = {"type" => "Integer"}
    assert_equal(int,                       @db.store(:i, int))
    assert_equal(42,                        @db.store(:i, 42, :add))
    assert_equal(int.merge("_num" => "42"), @db.fetch(:i))

    flt = {"type" => "Float"}
    assert_equal(flt,                         @db.store(:f, flt))
    assert_equal(3.14,                        @db.store(:f, 3.14, :add))
    assert_equal(flt.merge("_num" => "3.14"), @db.fetch(:f))
  end
  
  def test_adding_to_a_non_added_number_clobbers_the_column
    junk = {"_num" => "junk"}
    assert_equal(junk,            @db.store(:i, junk))
    assert_equal(1,               @db.store(:i, 1, :add))
    assert_equal({"_num" => "1"}, @db.fetch(:i))
  end
  
  def test_addition_types_can_be_switched_as_needed
    assert_equal(1,                 @db.store(:num,   1, :add))
    assert_equal(2.0,               @db.store(:num, 1.0, :add))
    assert_equal(2.1,               @db.store(:num, 0.1, :add))
    assert_equal(3,                 @db.store(:num,   1, :add))  # truncated
    assert_equal(3.5,               @db.store(:num, 0.4, :add))
    assert_equal(4,                 @db.store(:num,   1, :add))  # truncated
    assert_equal({"_num" => "4.5"}, @db.fetch(:num))
  end
  
  # def test_storing_with_a_block_allows_duplicate_resolution
  #   @db[:key] = :old
  #   assert_equal( :new, @db.store(:key, :new) { |key, old, new|
  #                                               "#{key}=#{old}&#{new}" } )
  #   assert_equal("key=old&new", @db[:key])
  # end
  # 
  # def test_storing_with_a_block_overrides_a_mode_and_triggers_a_warning
  #   warning = capture_stderr do
  #     assert_equal(:new, @db.store(:key, :new, :async) { |key, old, new| })
  #   end
  #   assert(!warning.empty?, "A warning was not issued for a mode and block")
  # end
  # 
  # def test_storing_with_a_mode_not_supported_by_the_database_triggers_a_warning
  #   warning = capture_stderr do
  #     assert_equal(:one, @db.store(:dups, :one, :dup))  # normal store
  #   end
  #   assert(!warning.empty?, "A warning was not issued for an unsupported mode")
  #   assert_equal("one", @db[:dups])
  #   
  #   bdb do |db|
  #     warning = capture_stderr do
  #       assert_equal(:value, db.store(:key, :value, :async))  # normal store
  #     end
  #     assert(!warning.empty?, "A warning was not issued for an unsupported mode")
  #     assert_equal("value", db[:key])
  #   end
  # end
  
  def test_include_and_aliases_can_be_used_to_check_for_the_existance_of_a_key
    @db[:exist] = {"I" => "exist"}
    %w[include? has_key? key? member?].each do |query|
      assert(@db.send(query,  :exist),   "Failed to detect an existing key")
      assert(!@db.send(query, :missing), "Failed to detect an missing key")
    end
  end
  
  def test_update_sets_multiple_documents_at_once_overwriting_old_documents
    @db[:b] = {"b" => "old"}
    assert_equal( @db,                @db.update( :a => {"a" => "new"},
                                                  :b => {"b" => "new"},
                                                  :c => {"c" => "new"}) )
    assert_equal( [ {"a" => "new"},
                    {"b" => "new"},
                    {"c" => "new"} ], @db.values_at(:a, :b, :c) )
  end
  
  # def test_update_can_be_passed_a_block_for_handling_duplicates
  #   @db[:b] = "old"
  #   assert_equal( @db, @db.update( :a => "new",
  #                                  :b => "new",
  #                                  :c => "new") { |key, old, new|
  #                                                 "#{key}=#{old}&#{new}" } )
  #   assert_equal(%w[new b=old&new new], @db.values_at(:a, :b, :c))
  # end
  
  def test_values_at_can_be_used_to_retrieve_multiple_documents_at_once
    @db[:a] = {:a => 1}
    @db[:c] = {:c => 2}
    assert_equal([ ],               @db.values_at)
    assert_equal( [ {"a" => "1"},
                    nil,
                    {"c" => "2"} ], @db.values_at(:a, :b, :c) )
  end
  
  def test_values_at_supports_defaults
    @db.default = { }
    @db[:a]     = {:a => 1}
    @db[:c]     = {:c => 2}
    assert_equal( [ {"a" => "1"},
                    { },
                    {"c" => "2"} ], @db.values_at(:a, :b, :c))
  end
  
  def test_keys_returns_all_keys_in_the_database
    @db.update(:a => {:a => 1}, :b => {:b => 2}, :c => {:c => 3})
    assert_equal(%w[a b c], @db.keys.sort)
  end
  
  def test_keys_can_take_a_prefix_which_all_returned_keys_must_start_with
    @db.update(:a => {:a => 1}, :ab => {:ab => 2}, :c => {:c => 3})
    assert_equal(%w[a ab], @db.keys(:prefix => :a).sort)
  end
  
  def test_keys_can_take_a_limit_of_keys_to_return
    @db.update(:a => {:a => 1}, :b => {:b => 2}, :c => {:c => 3})
    keys = @db.keys(:limit => 2)
    assert_equal(2, keys.size)
    keys.each do |key|
      assert(%w[a b c].include?(key), "Key wasn't in known keys")
    end
  end
  
  def test_values_returns_all_values_in_the_database
    @db.update(:a => {:a => 1}, :b => {:b => 2}, :c => {:c => 3})
    assert_equal( [ {"a" => "1"},
                    {"b" => "2"},
                    {"c" => "3"} ], @db.values.sort_by { |h| h.to_a } )
  end
  
  def test_delete_removes_a_document_from_the_database
    @db[:doc] = {"a" => "1"}
    assert_equal({"a" => "1"}, @db.delete(:doc))
    assert_nil(@db[:doc])
  end
  
  def test_clear_removes_all_keys_from_the_database
    @db.update(:a => {:a => 1}, :b => {:b => 2}, :c => {:c => 3})
    assert_equal(@db, @db.clear)
    assert_equal([nil, nil, nil], @db.values_at(:a, :b, :c))
  end
  
  def test_size_and_length_return_the_count_of_key_value_pairs_in_the_database
    assert_equal(0, @db.size)
    assert_equal(0, @db.length)
    @db.update(:a => {:a => 1}, :b => {:b => 2}, :c => {:c => 3})
    assert_equal(3, @db.size)
    assert_equal(3, @db.length)
  end
  
  def test_empty_returns_true_while_no_pairs_are_in_the_database
    assert(@db.empty?, "An empty database was not detected")
    @db[:doc] = {"a" => "1"}
    assert(!@db.empty?, "A non-empty database was reported empty")
    @db.delete(:doc)
    assert(@db.empty?, "An empty database was not detected")
  end
  
  def test_generate_unique_id_and_uid_can_be_used_to_manage_increasing_ids
    assert_equal(1, @db.generate_unique_id)
    assert_equal([2, 3, 4, 5], Array.new(4) { @db.uid })
  end
  
  def test_uids_are_not_stored_in_documents
    assert_equal(0, @db.size)
    assert_equal(1, @db.uid)
    assert_equal(0, @db.size)
  end
end

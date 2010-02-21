require "test_helper"

class TestQuery < Test::Unit::TestCase
  def setup
    @db = tdb
  end
  
  def teardown
    @db.close
    remove_db_files
  end
  
  def test_all_returns_primary_key_and_document_by_default
    load_simple_data
    results = @db.all
    assert_equal( [ ["pk1", {"a" => "1", "b" => "2", "c" => "3"}],
                    ["pk2", { }] ], results.to_a.sort )
  end
  
  def test_all_returns_primary_key_and_document_if_selected
    load_simple_data
    %w[ key_and_doc         keys_and_docs
        primary_key_and_doc primary_keys_and_docs ].each do |kad|
      results = @db.all(:select => kad)
      assert_equal( [ ["pk1", {"a" => "1", "b" => "2", "c" => "3"}],
                      ["pk2", { }] ], results.to_a.sort )
    end
  end
  
  def test_all_returns_primary_keys_only_if_selected
    load_simple_data
    %w[key keys primary_key primary_keys].each do |k|
      results = @db.all(:select => k)
      assert_equal(%w[pk1 pk2], results.sort)
    end
  end
  
  def test_all_returns_documents_only_if_selected
    load_simple_data
    %w[doc docs document documents].each do |d|
      results = @db.all(:select => d)
      assert_equal( [{ }, {"a" => "1", "b" => "2", "c" => "3"}],
                    results.sort_by { |doc| doc.size } )
    end
  end
  
  def test_all_selects_a_return_data_type_by_ruby_version_and_ordering
    load_simple_data
    if RUBY_VERSION < "1.9"
      results = @db.all                # not ordered
      assert_equal( { "pk1" => {"a" => "1", "b" => "2", "c" => "3"},
                      "pk2" => { } }, results )
      results = @db.all(:order => :a)  # ordered
      assert_equal( [ ["pk1", {"a" => "1", "b" => "2", "c" => "3"}],
                      ["pk2", { }] ], results )
    else
      results = @db.all
      assert_equal( { "pk1" => {"a" => "1", "b" => "2", "c" => "3"},
                      "pk2" => { } }, results )
    end
  end
  
  def test_all_can_be_forced_to_return_a_hash_of_hashes
    load_simple_data
    %w[hoh hohs hash_of_hash hash_of_hashes].each do |hoh|
      results = @db.all(:return => hoh)
      assert_equal( { "pk1" => {"a" => "1", "b" => "2", "c" => "3"},
                      "pk2" => { } }, results )
    end
  end

  def test_all_can_be_forced_to_return_a_merged_array_of_hashes
    load_simple_data
    %w[aoh aohs array_of_hash array_of_hashes].each do |aoh|
      results = @db.all(:return => aoh)
      assert_equal( [ {:primary_key  => "pk2"},
                      { :primary_key => "pk1",
                        "a"          => "1",
                        "b"          => "2",
                        "c"          => "3" }],
                    results.sort_by { |doc| doc.size } )
    end
  end
  
  def test_all_can_be_forced_to_return_an_array_of_arrays
    load_simple_data
    %w[aoa aoas array_of_array array_of_arrays].each do |aoa|
      results = @db.all(:return => aoa)
      assert_equal( [ ["pk1", {"a" => "1", "b" => "2", "c" => "3"}],
                      ["pk2", { }] ], results )
    end
  end
  
  def test_all_will_pass_keys_and_documents_to_a_passed_block_and_return_self
    load_simple_data
    results = [ ]
    assert_equal(@db, @db.all { |k, v| results << [k, v] })
    assert_equal( [ ["pk1", {"a" => "1", "b" => "2", "c" => "3"}],
                    ["pk2", { }] ], results.sort )
  end
  
  def test_all_can_pass_keys_only_to_a_passed_block_and_return_self
    load_simple_data
    results = [ ]
    assert_equal(@db, @db.all(:select => :keys) { |k| results << k })
    assert_equal(%w[pk1 pk2], results.sort)
  end
  
  def test_all_can_pass_documents_only_to_a_passed_block_and_return_self
    load_simple_data
    results = [ ]
    assert_equal(@db, @db.all(:select => :docs) { |v| results << v })
    assert_equal( [{ }, {"a" => "1", "b" => "2", "c" => "3"}],
                  results.sort_by { |doc| doc.size } )
  end
  
  def test_all_can_pass_key_in_document_to_a_passed_block_and_return_self
    load_simple_data
    results = [ ]
    assert_equal(@db, @db.all(:return => :aoh) { |kv| results << kv })
    assert_equal( [ {:primary_key  => "pk2"},
                    { :primary_key => "pk1",
                      "a" => "1", "b" => "2", "c" => "3" } ],
                  results.sort_by { |doc| doc.size } )
  end
  
  def test_all_with_a_block_does_not_modify_records_by_default
    load_simple_data
    assert_equal(@db,                                  @db.all { })
    assert_equal({"a" => "1", "b" => "2", "c" => "3"}, @db[:pk1])
    assert_equal({ },                                  @db[:pk2])
  end
  
  def test_all_with_a_block_can_update_records
    load_simple_data
    assert_equal( @db, @db.all { |k, v|
      if k == "pk1"
        v["a"] = "1.1"  # change
        v.delete("c")   # remove
        v[:d] = 4       # add
        :update
      end
    } )
    assert_equal({"a" => "1.1", "b" => "2", "d" => "4"}, @db[:pk1])
  end
  
  def test_all_with_a_block_can_delete_records
    load_simple_data
    assert_equal(@db, @db.all { |_, v| v.empty? and :delete })
    assert_equal({"a" => "1", "b" => "2", "c" => "3"}, @db[:pk1])
    assert_nil(@db[:pk2])
  end
  
  def test_all_with_a_block_can_end_the_query
    load_simple_data
    results = [ ]
    assert_equal(@db,          @db.all { |k, _| results << k; :break })
    assert_equal(1,            results.size)
    assert_match(/\Apk[12]\z/, results.first)
  end
  
  def test_all_with_a_block_can_combine_flags
    load_simple_data
    results = [ ]
    assert_equal(@db, @db.all { |k, _| results << k; %w[delete break] })
    assert_equal(1,                             results.size)
    assert_match(/\Apk[12]\z/,                  results.first)
    assert_equal(1,                             @db.size)
    assert_match((%w[pk1 pk2] - results).first, @db.keys.first)
  end
  
  def test_all_methods_can_control_what_is_passed_to_the_block
    load_simple_data
    [ [{:select => :keys}, "pk1"],
      [{:select => :docs}, {"a" => "1", "b" => "2", "c" => "3"}],
      [ {:return => :aoa}, [ "pk1",
                             {"a" => "1", "b" => "2", "c" => "3"} ] ],
      [ {:return => :hoh}, [ "pk1",
                             {"a" => "1", "b" => "2", "c" => "3"} ] ],
      [ {:return => :aoh}, { :primary_key => "pk1",
                             "a"          => "1",
                             "b"          => "2",
                             "c"          => "3" } ] ].each do |query, results|
      args = [ ]
      @db.all(query.merge(:conditions => [:a, :==, 1])) do |kv|
        args << kv
      end
      assert_equal([results], args)
    end
  end
  
  def test_all_yields_key_value_tuples
    load_simple_data
    [ [ {:return => :aoa}, [ "pk1",
                             {"a" => "1", "b" => "2", "c" => "3"} ] ],
      [ {:return => :hoh}, [ "pk1",
                             { "a" => "1",
                               "b" => "2",
                               "c" => "3" } ] ] ].each do |query, tuple|
      yielded = nil
      @db.all(query.merge(:conditions => [:a, :==, 1])) do |kv|
        yielded = kv
      end
      assert_equal(tuple, yielded)
      key, value = nil, nil
      @db.all(query.merge(:conditions => [:a, :==, 1])) do |k, v|
        key   = k
        value = v
      end
      assert_equal(tuple.first, key)
      assert_equal(tuple.last,  value)
    end
  end
  
  def test_all_fails_with_an_error_for_malformed_conditions
    assert_raise(OKMixer::Error::QueryError) do
      @db.all(:conditions => :first)  # not column, operator, and expression
    end
  end
  
  def test_all_fails_with_an_error_for_unknown_condition_operators
    assert_raise(OKMixer::Error::QueryError) do
      @db.all(:conditions => [:first, :unknown, "James"])
    end
  end
  
  def test_all_can_accept_string_equal_conditions
    load_condition_data
    %w[== eql equal str_eql string_equal].each do |op|
      ["", "s", "?", "s?"].each do |suffix|
        next if op == "==" and suffix != ""
        assert_equal( %w[james],
                      @db.all( :select     => :keys,
                               :conditions => [:first, op + suffix, "James"] ) )
      end
    end
  end
  
  def test_all_can_accept_string_not_equal_conditions
    load_condition_data
    %w[! !_ not_].each do |n|
      %w[= eql equal str_eql string_equal].each do |op|
        ["", "s", "?", "s?"].each do |suffix|
          next if op == "=" and suffix != ""
          assert_equal( %w[dana jim],
                        @db.all( :select     => :keys,
                                 :conditions => [ :first, 
                                                  n + op + suffix,
                                                  "James" ] ).sort )
        end
      end
    end
  end
  
  def test_all_can_accept_string_include_conditions
    load_condition_data
    %w[include includes include? includes?].each do |op|
      assert_equal( %w[dana james],
                    @db.all( :select     => :keys,
                             :conditions => [:first, op, "a"] ).sort )
    end
  end
  
  def test_all_can_accept_string_not_include_conditions
    load_condition_data
    %w[! !_ not_].each do |n|
      %w[include includes include? includes?].each do |op|
        assert_equal( %w[jim],
                      @db.all( :select     => :keys,
                               :conditions => [:first, n + op, "a"] ) )
      end
    end
  end
  
  def test_all_can_accept_string_starts_with_conditions
    load_condition_data
    %w[start_with starts_with start_with? starts_with?].each do |op|
      assert_equal( %w[james jim],
                    @db.all( :select     => :keys,
                             :conditions => [:first, op, "J"] ).sort )
    end
  end
  
  def test_all_can_accept_string_not_starts_with_conditions
    load_condition_data
    %w[! !_ not_].each do |n|
      %w[start_with starts_with start_with? starts_with?].each do |op|
        assert_equal( %w[dana],
                      @db.all( :select     => :keys,
                               :conditions => [:first, n + op, "J"] ).sort )
      end
    end
  end
  
  def test_all_can_accept_string_ends_with_conditions
    load_condition_data
    %w[end_with ends_with end_with? ends_with?].each do |op|
      assert_equal( [ ],
                    @db.all( :select     => :keys,
                             :conditions => [:first, op, "z"] ) )
    end
  end
  
  def test_all_can_accept_string_not_ends_with_conditions
    load_condition_data
    %w[! !_ not_].each do |n|
      %w[end_with ends_with end_with? ends_with?].each do |op|
        assert_equal( %w[dana james jim],
                      @db.all( :select     => :keys,
                               :conditions => [:first, n + op, "z"] ).sort )
      end
    end
  end
  
  def test_all_can_accept_string_includes_all_tokens_conditions
    load_condition_data
    %w[ include_all         includes_all
        include_all_tokens  includes_all_tokens
        include_all?        includes_all?
        include_all_tokens? includes_all_tokens? ].each do |op|
      assert_equal( %w[dana],
                    @db.all( :select     => :keys,
                             :conditions => [:middle, op, "Leslie Ann"] ) )
    end
  end
  
  def test_all_can_accept_string_not_includes_all_tokens_conditions
    load_condition_data
    %w[! !_ not_].each do |n|
      %w[ include_all         includes_all
          include_all_tokens  includes_all_tokens
          include_all?        includes_all?
          include_all_tokens? includes_all_tokens? ].each do |op|
        assert_equal( %w[james jim],
                      @db.all( :select     => :keys,
                               :conditions => [:middle, n + op, "Leslie Ann"] ).
                      sort )
      end
    end
  end
  
  def test_all_can_accept_string_includes_any_token_conditions
    load_condition_data
    %w[ include_any        includes_any
        include_any_token  includes_any_token
        include_any?       includes_any?
        include_any_token? includes_any_token? ].each do |op|
      assert_equal( %w[dana],
                    @db.all( :select     => :keys,
                             :conditions => [:middle, op, "Ann Joe"] ) )
    end
  end
  
  def test_all_can_accept_string_not_includes_any_token_conditions
    load_condition_data
    %w[! !_ not_].each do |n|
      %w[ include_any        includes_any
          include_any_token  includes_any_token
          include_any?       includes_any?
          include_any_token? includes_any_token? ].each do |op|
        assert_equal( %w[james jim],
                      @db.all( :select     => :keys,
                               :conditions => [:middle, n + op, "Ann Joe"] ).
                      sort )
      end
    end
  end
  
  def test_all_can_accept_string_equals_any_token_conditions
    load_condition_data
    %w[ eql_any           eql_any
        eql_any_token     eql_any_token
        eql_any?          eql_any?
        eql_any_token?    eql_any_token?
        equals_any        equals_any
        equals_any_token  equals_any_token
        equals_any?       equals_any?
        equals_any_token? equals_any_token? ].each do |op|
      assert_equal( %w[dana james],
                    @db.all( :select     => :keys,
                             :conditions => [:first, op, "Dana James"] ).sort )
    end
  end
  
  def test_all_can_accept_string_not_equals_any_token_conditions
    load_condition_data
    %w[! !_ not_].each do |n|
      %w[ eql_any           eql_any
          eql_any_token     eql_any_token
          eql_any?          eql_any?
          eql_any_token?    eql_any_token?
          equals_any        equals_any
          equals_any_token  equals_any_token
          equals_any?       equals_any?
          equals_any_token? equals_any_token? ].each do |op|
        assert_equal( %w[jim],
                      @db.all( :select     => :keys,
                               :conditions => [:first, n + op, "Dana James"] ) )
      end
    end
  end
  
  def test_all_can_accept_string_matches_regexp_conditions
    load_condition_data
    %w[=~ match].each do |op|
      ["", "es", "?", "es?"].each do |suffix|
        next if op == "=~" and suffix != ""
        assert_equal( %w[james jim],
                      @db.all( :select     => :keys,
                               :conditions => [:first, op + suffix, /J.m/] ).
                      sort )
      end
    end
  end
  
  def test_all_can_accept_string_not_matches_regexp_conditions
    load_condition_data
    %w[! !_ not_].each do |n|
      %w[~ match].each do |op|
        ["", "es", "?", "es?"].each do |suffix|
          next if op == "~" and suffix != ""
          assert_equal( %w[dana],
                        @db.all( :select     => :keys,
                                 :conditions => [ :first, 
                                                  n + op + suffix,
                                                  /J.m/ ] ) )
        end
      end
    end
  end
  
  def test_all_can_accept_number_equal_conditions
    load_condition_data
    %w[== eql equal num_eql number_equal].each do |op|
      ["", "s", "?", "s?"].each do |suffix|
        next if op == "==" and suffix != ""
        assert_equal( %w[james],
                      @db.all( :select     => :keys,
                               :conditions => [:age, op + suffix, 33] ) )
      end
    end
  end
  
  def test_all_can_accept_number_not_equal_conditions
    load_condition_data
    %w[! !_ not_].each do |n|
      %w[= eql equal num_eql number_equal].each do |op|
        ["", "s", "?", "s?"].each do |suffix|
          next if op == "=" and suffix != ""
          assert_equal( %w[dana jim],
                        @db.all( :select     => :keys,
                                 :conditions => [:age,  n + op + suffix, 33] ).
                        sort )
        end
      end
    end
  end
  
  def test_all_can_accept_number_greater_than_conditions
    load_condition_data
    assert_equal( %w[dana jim], @db.all( :select     => :keys,
                                         :conditions => [:age, :>, 33] ).sort )
  end
  
  def test_all_can_accept_number_not_greater_than_conditions
    load_condition_data
    assert_equal( %w[james], @db.all( :select     => :keys,
                                      :conditions => [:age, "!>", 33] ) )
  end
  
  def test_all_can_accept_number_greater_than_or_equal_to_conditions
    load_condition_data
    assert_equal( %w[dana jim], @db.all( :select     => :keys,
                                         :conditions => [:age, :>=, 34] ).sort )
  end
  
  def test_all_can_accept_number_not_greater_than_or_equal_to_conditions
    load_condition_data
    assert_equal( %w[james], @db.all( :select     => :keys,
                                      :conditions => [:age, "!>=", 34] ) )
  end
  
  def test_all_can_accept_number_less_than_conditions
    load_condition_data
    assert_equal( %w[dana james],
                  @db.all( :select     => :keys,
                           :conditions => [:age, :<, 53] ).sort )
  end
  
  def test_all_can_accept_number_not_less_than_conditions
    load_condition_data
    assert_equal( %w[jim], @db.all( :select     => :keys,
                                    :conditions => [:age, "!<", 53] ) )
  end
  
  def test_all_can_accept_number_less_than_or_equal_to_conditions
    load_condition_data
    assert_equal( %w[dana james],
                  @db.all( :select     => :keys,
                           :conditions => [:age, :<=, 34] ).sort )
  end
  
  def test_all_can_accept_number_not_less_than_or_equal_to_conditions
    load_condition_data
    assert_equal( %w[jim], @db.all( :select     => :keys,
                                    :conditions => [:age, "!<=", 34] ) )
  end
  
  def test_all_can_accept_number_between_conditions
    load_condition_data
    %w[between between?].each do |op|
      assert_equal( %w[dana james],
                    @db.all( :select     => :keys,
                             :conditions => [:age, op, "33 50"] ).sort )
    end
  end
  
  def test_all_can_accept_number_not_between_conditions
    load_condition_data
    %w[! !_ not_].each do |n|
      %w[between between?].each do |op|
        assert_equal( %w[jim],
                      @db.all( :select     => :keys,
                               :conditions => [:age, n + op, "33 50"] ) )
      end
    end
  end
  
  def test_all_can_accept_any_number_conditions
    load_condition_data
    %w[any_num any_number any_num? any_number?].each do |op|
      assert_equal( %w[james jim],
                    @db.all( :select     => :keys,
                             :conditions => [:age, op, "33 53"] ).sort )
    end
  end
  
  def test_all_can_accept_not_any_number_conditions
    load_condition_data
    %w[! !_ not_].each do |n|
      %w[any_num any_number any_num? any_number?].each do |op|
        assert_equal( %w[dana],
                      @db.all( :select     => :keys,
                               :conditions => [:age, n + op, "33 53"] ) )
      end
    end
  end
  
  def test_all_can_accept_phrase_search_conditions
    load_search_data
    %w[phrase_search phrase_search?].each do |op|
      assert_equal( %w[james jim],
                    @db.all( :select     => :keys,
                             :conditions => [:name, op, "Edward Gray"] ).sort )
    end
  end
  
  def test_all_can_accept_not_phrase_search_conditions
    load_search_data
    %w[! !_ not_].each do |n|
      %w[phrase_search phrase_search?].each do |op|
        assert_equal( %w[dana],
                      @db.all( :select     => :keys,
                               :conditions => [:name, n + op, "Edward Gray"] ) )
      end
    end
  end
  
  # FIXME:  could not determine how to test Full-Text token searches
  
  def test_all_can_accept_expression_search_conditions
    load_search_data
    %w[expression_search expression_search?].each do |op|
      assert_equal( %w[dana james],
                    @db.all( :select     => :keys,
                             :conditions => [:name, op, "James || Ann"] ).sort )
    end
  end
  
  def test_all_can_accept_not_expression_search_conditions
    load_search_data
    %w[! !_ not_].each do |n|
      %w[expression_search expression_search?].each do |op|
        assert_equal( %w[jim],
                      @db.all( :select     => :keys,
                               :conditions => [ :name,
                                                n + op,
                                                "James || Ann" ] ) )
      end
    end
  end
  
  def test_all_can_set_conditions_for_the_primary_key
    load_condition_data
    ["", :pk, :primary_key].each do |key|
      assert_equal( %w[james jim],
                    @db.all( :select     => :keys,
                             :conditions => [key, :starts_with?, "j"] ).sort )
    end
  end
  
  def test_all_can_accept_multiple_conditions
    load_condition_data
    assert_equal( %w[dana james],
                  @db.all( :select     => :keys,
                           :conditions => [ [:last, :==, "Gray"],
                                            [:age,  "!=", 53] ] ).sort )
  end
  
  def test_all_fails_with_an_error_for_malformed_order
    assert_raise(OKMixer::Error::QueryError) do
      @db.all(:order => %w[too many args])
    end
  end
  
  def test_all_fails_with_an_error_for_unknown_order_type
    assert_raise(OKMixer::Error::QueryError) do
      @db.all(:order => [:first, :unknown])
    end
  end
  
  def test_all_accepts_an_order_field_used_to_arrange_results
    load_order_data
    assert_equal( %w[first middle last],
                  @db.all(:select => :keys, :order => :str) )
  end
  
  def test_all_order_defaults_to_string_ascending
    load_order_data
    assert_equal( %w[1 11 2], @db.all(:select => :docs, :order => :num).
                                  map { |doc| doc["num"] } )
  end
  
  def test_all_order_can_be_forced_to_string_descending
    load_order_data
    %w[ASC STR_ASC].each do |order|
      assert_equal( %w[first middle last],
                    @db.all(:select => :keys, :order => [:str, order]) )
    end
  end
  
  def test_all_order_can_be_set_to_string_descending
    load_order_data
    %w[DESC STR_DESC].each do |order|
      assert_equal( %w[last middle first],
                    @db.all(:select => :keys, :order => [:str, order]) )
    end
  end
  
  def test_all_order_can_be_set_to_numeric_ascending
    load_order_data
    assert_equal( %w[first middle last],
                  @db.all(:select => :keys, :order => [:num, :NUM_ASC]) )
  end
  
  def test_all_order_can_be_set_to_numeric_descending
    load_order_data
    assert_equal( %w[last middle first],
                  @db.all(:select => :keys, :order => [:num, :NUM_DESC]) )
  end
  
  def test_all_can_order_the_primary_key
    load_order_data
    ["", :pk, :primary_key].each do |key|
      assert_equal( %w[first last middle],
                    @db.all(:select => :keys, :order => key) )
    end
  end
  
  def test_all_accepts_a_limit_for_returned_results
    load_order_data
    assert_equal( %w[first middle], @db.all( :select => :keys,
                                             :order  => :str,
                                             :limit  => 2 ) )
  end
  
  def test_all_accepts_an_offset_with_a_limit
    load_order_data
    assert_equal( %w[last], @db.all( :select => :keys,
                                     :order  => :str,
                                     :limit  => 2,
                                     :offset => 2 ) )
  end
  
  def test_first_is_all_with_limit_one_removed_from_the_array
    load_order_data
    assert_equal("first", @db.first(:select => :keys, :order => :str))
    assert_nil(@db.first(:select => :keys, :order => :str, :offset => 10))
  end
  
  def test_count_returns_a_count_of_records_matched
    load_condition_data
    assert_equal(2, @db.count(:conditions => [:first, :starts_with?, "J"]))
  end
  
  def test_paginate_requires_a_page_argument
    assert_raise(OKMixer::Error::QueryError) do
      @db.paginate({ })  # no :page argument
    end
  end
  
  def test_paginate_requires_a_page_greater_than_zero_with_nil_allowed
    assert_raise(OKMixer::Error::QueryError) do
      @db.paginate({:page => 0})
    end
  end
  
  def test_paginate_requires_per_page_be_greater_than_zero_if_provided
    assert_raise(OKMixer::Error::QueryError) do
      @db.paginate({:page => nil, :per_page => 0})
    end
  end
  
  def test_paginate_defaults_to_thirty_for_a_per_page_count
    load_search_data
    assert_equal(30, @db.paginate(:page => nil).per_page)
  end
  
  def test_paginate_returns_result_sets_in_pages_regardless_of_type
    load_search_data
    %w[hoh aoa aoh].each do |results_mode|
      page = @db.paginate( :order    => :primary_key,
                           :return   => results_mode.to_sym,
                           :per_page => 2,
                           :page     => nil )
      keys = page.to_a.map { |result|
        result.respond_to?(:first) ? result.first : result[:primary_key]
      }
      assert_equal(%w[dana james], keys)
      assert_equal(2,              page.size)
      assert_kind_of(OKMixer::TableDatabase::Paginated, page)
      assert_equal(1, page.current_page)
      assert_equal(2, page.per_page)
      assert_equal(3, page.total_entries)
      assert_equal(2, page.total_pages)
      assert(!page.out_of_bounds?, "The first page was out of bounds")
      assert_equal(0, page.offset)
      assert_nil(page.previous_page)
      assert_equal(2, page.next_page)
    end
  end
  
  def test_paginate_adjusts_limit_and_offset_by_page_and_per_page
    load_search_data
    page = @db.paginate( :select   => :keys,
                         :order    => :primary_key,
                         :per_page => 2,
                         :page     => 2 )
    assert_equal(%w[jim], page)
    assert_equal(1,       page.size)
    assert_equal(2,       page.current_page)
    assert_equal(2,       page.per_page)
    assert_equal(3,       page.total_entries)
    assert_equal(2,       page.total_pages)
    assert(!page.out_of_bounds?, "The last page was out of bounds")
    assert_equal(2, page.offset)
    assert_equal(1, page.previous_page)
    assert_nil(page.next_page)
  end
  
  def test_paginate_detects_out_of_bounds_pages
    load_search_data
    page = @db.paginate( :select   => :keys,
                         :order    => :primary_key,
                         :per_page => 2,
                         :page     => 3 )
    assert_equal([ ], page)
    assert_equal(0,   page.size)
    assert_equal(3,   page.current_page)
    assert_equal(2,   page.per_page)
    assert_equal(3,   page.total_entries)
    assert_equal(2,   page.total_pages)
    assert(page.out_of_bounds?, "An out of bounds page was not detected")
    assert_equal(4, page.offset)
    assert_equal(2, page.previous_page)
    assert_nil(page.next_page)
  end
  
  def test_union_returns_the_set_union_of_multiple_queries
    load_condition_data
    assert_equal( [ [ "dana",  { "first"  => "Dana",
                                 "middle" => "Ann Leslie",
                                 "last"   => "Gray",
                                 "age"    => "34" } ],
                    [ "james", { "first"  => "James",
                                 "last"   => "Gray",
                                 "age"    => "33" } ] ],
                  @db.union( { :conditions => [:first, :ends_with?, "es"],
                               :order      => :first },
                             {:conditions  => [:age, :==, 34]} ).to_a )
  end
  
  def test_union_respects_select_and_return_on_the_first_query
    load_condition_data
    assert_equal( %w[dana james],
                  @db.union( { :select     => :keys,
                               :conditions => [:first, :ends_with?, "es"],
                               :order      => :first },
                             {:conditions  => [:age, :==, 34]} ) )
    assert_equal( [ [ "dana",  { "first"  => "Dana",
                                 "middle" => "Ann Leslie",
                                 "last"   => "Gray",
                                 "age"    => "34" } ],
                    [ "james", { "first"  => "James",
                                 "last"   => "Gray",
                                 "age"    => "33" } ] ],
                  @db.union( { :select     => :keys_and_docs,
                               :return     => :aoa,
                               :conditions => [:first, :ends_with?, "es"],
                               :order      => :first },
                             {:conditions  => [:age, :==, 34]} ) )
  end

  def test_union_can_be_passed_a_block_to_iterate_over_the_results
    load_condition_data
    results = [ ]
    assert_equal( @db,
                  @db.union( { :select     => :keys,
                               :conditions => [:first, :ends_with?, "es"],
                               :order      => :first },
                             {:conditions  => [:age, :==, 34]} ) { |k|
                    results << k
                  } )
    assert_equal(%w[dana james], results)
  end
  
  def test_union_with_a_block_can_update_records
    load_condition_data
    assert_equal( @db,
                  @db.union( { :conditions => [:first, :ends_with?, "es"],
                               :order      => :first },
                             {:conditions  => [:age, :==, 34]} ) { |k, v|
                    if k == "dana"
                      v["salutation"] = "Mrs."  # add
                      v["middle"]     = "AL"    # update
                      v.delete("age")           # delete
                      :update
                    end
                  } )
    assert_equal( { "salutation" => "Mrs.",
                    "first"      => "Dana",
                    "middle"     => "AL",
                    "last"       => "Gray" }, @db["dana"] )
  end

  def test_union_with_a_block_can_delete_records
    load_condition_data
    results = [ ]
    assert_equal( @db,
                  @db.union( { :select     => :keys,
                               :conditions => [:first, :ends_with?, "es"],
                               :order      => :first },
                             {:conditions  => [:age, :==, 34]} ) { |k|
                    :delete
                  } )
    assert_equal(1,       @db.size)
    assert_equal(%w[jim], @db.keys)
  end

  def test_union_with_a_block_can_end_the_query
    load_condition_data
    results = [ ]
    assert_equal( @db,
                  @db.union( { :select     => :keys,
                               :conditions => [:first, :ends_with?, "es"],
                               :order      => :first },
                             {:conditions  => [:age, :==, 34]} ) { |k|
                    results << k
                    :break
                  } )
    assert_equal(%w[dana], results)
  end

  def test_union_with_a_block_can_combine_flags
    load_condition_data
    results = [ ]
    assert_equal( @db,
                  @db.union( { :select     => :keys,
                               :conditions => [:first, :ends_with?, "es"],
                               :order      => :first },
                             {:conditions  => [:age, :==, 34]} ) { |k|
                    results << k
                    %w[delete break]
                  } )
    assert_equal(%w[dana], results)
    assert_nil(@db["dana"])
    assert_equal(2, @db.size)
  end
  
  def test_intersection_returns_the_set_intersection_of_multiple_queries
    load_condition_data
    assert_equal( [ [ "dana",  { "first"  => "Dana",
                                 "middle" => "Ann Leslie",
                                 "last"   => "Gray",
                                 "age"    => "34" } ],
                    [ "james", { "first"  => "James",
                                 "last"   => "Gray",
                                 "age"    => "33" } ] ],
                  @db.isect( { :conditions => [:first, :include?, "a"],
                               :order      => :first },
                             {:conditions  => [:last, :==, "Gray"]} ).to_a )
  end
  
  def test_intersection_respects_select_and_return_on_the_first_query
    load_condition_data
    assert_equal( [ { "first"  => "Dana",
                      "middle" => "Ann Leslie",
                      "last"   => "Gray",
                      "age"    => "34" },
                    { "first"  => "James",
                      "last"   => "Gray",
                      "age"    => "33" } ],
                  @db.isect( { :select     => :docs,
                               :conditions => [:first, :include?, "a"],
                               :order      => :first },
                             {:conditions  => [:last, :==, "Gray"]} ) )
    assert_equal( { "dana" =>  { "first"  => "Dana",
                                 "middle" => "Ann Leslie",
                                 "last"   => "Gray",
                                 "age"    => "34" },
                    "james" => { "first"  => "James",
                                 "last"   => "Gray",
                                 "age"    => "33" } },
                  @db.isect( { :select     => :keys_and_docs,
                               :return     => :hoh,
                               :conditions => [:first, :include?, "a"],
                               :order      => :first },
                             {:conditions  => [:last, :==, "Gray"]} ) )
  end

  def test_intersection_can_be_passed_a_block_to_iterate_over_the_results
    load_condition_data
    results = [ ]
    assert_equal( @db,
                  @db.isect( { :select     => :keys,
                               :return     => :hoh,
                               :conditions => [:first, :include?, "a"],
                               :order      => :first },
                             {:conditions  => [:last, :==, "Gray"]} ) { |k|
                    results << k
                  } )
    assert_equal(%w[dana james], results)
  end
  
  def test_intersection_with_a_block_can_update_records
    load_condition_data
    assert_equal( @db,
                  @db.isect( { :return     => :hoh,
                               :conditions => [:first, :include?, "a"],
                               :order      => :first },
                             {:conditions  => [:last, :==, "Gray"]} ) { |k, v|
                    if k == "dana"
                      v["salutation"] = "Mrs."  # add
                      v["middle"]     = "AL"    # update
                      v.delete("age")           # delete
                      :update
                    end
                  } )
    assert_equal( { "salutation" => "Mrs.",
                    "first"      => "Dana",
                    "middle"     => "AL",
                    "last"       => "Gray" }, @db["dana"] )
  end

  def test_intersection_with_a_block_can_delete_records
    load_condition_data
    assert_equal( @db,
                  @db.isect( { :select     => :keys,
                               :return     => :hoh,
                               :conditions => [:first, :include?, "a"],
                               :order      => :first },
                             {:conditions  => [:last, :==, "Gray"]} ) { |k|
                    :delete
                  } )
    assert_equal(1,       @db.size)
    assert_equal(%w[jim], @db.keys)
  end

  def test_intersection_with_a_block_can_end_the_query
    load_condition_data
    results = [ ]
    assert_equal( @db,
                  @db.isect( { :select     => :keys,
                               :return     => :hoh,
                               :conditions => [:first, :include?, "a"],
                               :order      => :first },
                             {:conditions  => [:last, :==, "Gray"]} ) { |k|
                    results << k
                    :break
                  } )
    assert_equal(%w[dana], results)
  end

  def test_intersection_with_a_block_can_combine_flags
    load_condition_data
    results = [ ]
    assert_equal( @db,
                  @db.isect( { :select     => :keys,
                               :return     => :hoh,
                               :conditions => [:first, :include?, "a"],
                               :order      => :first },
                             {:conditions  => [:last, :==, "Gray"]} ) { |k|
                    results << k
                    %w[delete break]
                  } )
    assert_equal(%w[dana], results)
    assert_nil(@db["dana"])
    assert_equal(2, @db.size)
  end
  
  def test_difference_returns_the_set_difference_of_multiple_queries
    load_condition_data
    assert_equal( [ [ "dana",  { "first"  => "Dana",
                                 "middle" => "Ann Leslie",
                                 "last"   => "Gray",
                                 "age"    => "34" } ],
                    [ "james", { "first"  => "James",
                                 "last"   => "Gray",
                                 "age"    => "33" } ] ],
                  @db.diff( { :conditions => [:last, :==, "Gray"],
                              :order      => :first },
                            {:conditions  => [:first, :==, "Jim"]} ).to_a )
  end
  
  def test_difference_respects_select_and_return_on_the_first_query
    load_condition_data
    assert_equal( %w[dana james],
                  @db.diff( { :select     => :keys,
                              :conditions => [:last, :==, "Gray"],
                              :order      => :first },
                            {:conditions  => [:first, :==, "Jim"]} ) )
    assert_equal( [ { :primary_key => "dana",
                      "first"      => "Dana",
                      "middle"     => "Ann Leslie",
                      "last"       => "Gray",
                      "age"        => "34" },
                    { :primary_key => "james",
                      "first"      => "James",
                      "last"       => "Gray",
                      "age"        => "33" } ],
                  @db.diff( { :select     => :keys_and_docs,
                              :return     => :aoh,
                              :conditions => [:last, :==, "Gray"],
                              :order      => :first },
                            {:conditions  => [:first, :==, "Jim"]} ) )
  end
  
  def test_difference_can_be_passed_a_block_to_iterate_over_the_results
    load_condition_data
    results = [ ]
    assert_equal( @db,
                  @db.diff( { :select     => :keys,
                              :conditions => [:last, :==, "Gray"],
                              :order      => :first },
                            {:conditions  => [:first, :==, "Jim"]} ) { |k|
                    results << k
                  } )
    assert_equal(%w[dana james], results)
  end
  
  def test_difference_with_a_block_can_update_records
    load_condition_data
    assert_equal( @db,
                  @db.diff( { :conditions => [:last, :==, "Gray"],
                              :order      => :first },
                            {:conditions  => [:first, :==, "Jim"]} ) { |k, v|
                    if k == "dana"
                      v["salutation"] = "Mrs."  # add
                      v["middle"]     = "AL"    # update
                      v.delete("age")           # delete
                      :update
                    end
                  } )
    assert_equal( { "salutation" => "Mrs.",
                    "first"      => "Dana",
                    "middle"     => "AL",
                    "last"       => "Gray" }, @db["dana"] )
  end
  
  def test_difference_with_a_block_can_delete_records
    load_condition_data
    assert_equal( @db,
                  @db.diff( { :select     => :keys,
                              :conditions => [:last, :==, "Gray"],
                              :order      => :first },
                            {:conditions  => [:first, :==, "Jim"]} ) { |k|
                    :delete
                  } )
    assert_equal(1,       @db.size)
    assert_equal(%w[jim], @db.keys)
  end
  
  def test_difference_with_a_block_can_end_the_query
    load_condition_data
    results = [ ]
    assert_equal( @db,
                  @db.diff( { :select     => :keys,
                              :conditions => [:last, :==, "Gray"],
                              :order      => :first },
                            {:conditions  => [:first, :==, "Jim"]} ) { |k|
                    results << k
                    :break
                  } )
    assert_equal(%w[dana], results)
  end
  
  def test_difference_with_a_block_can_combine_flags
    load_condition_data
    results = [ ]
    assert_equal( @db,
                  @db.diff( { :select     => :keys,
                              :conditions => [:last, :==, "Gray"],
                              :order      => :first },
                            {:conditions  => [:first, :==, "Jim"]} ) { |k|
                    results << k
                    %w[delete break]
                  } )
    assert_equal(%w[dana], results)
    assert_nil(@db["dana"])
    assert_equal(2, @db.size)
  end
  
  def test_search_methods_can_control_what_is_passed_to_the_block
    load_condition_data
    [ [{:select => :keys},  "dana"],
      [ {:select => :docs}, { "first" => "Dana",
                              "middle" => "Ann Leslie",
                              "last"   => "Gray",
                              "age"    => "34" } ],
      [ {:return => :aoa},  [ "dana",
                              { "first" => "Dana",
                                "middle" => "Ann Leslie",
                                "last"   => "Gray",
                                "age"    => "34" } ] ],
      [ {:return => :hoh},  [ "dana",
                              { "first" => "Dana",
                                "middle" => "Ann Leslie",
                                "last"   => "Gray",
                                "age"    => "34" } ] ],
      [ {:return => :aoh},  { :primary_key => "dana",
                              "first" => "Dana",
                              "middle" => "Ann Leslie",
                              "last"   => "Gray",
                              "age"    => "34" } ] ].each do |query, results|
      %w[union intersection difference].each do |search|
        args = [ ]
        @db.send( search,
                  query.merge(:conditions => [:first, :==, "Dana"]) ) do |kv|
          args << kv
        end
        assert_equal([results], args)
      end
    end
  end
  
  def test_search_methods_yields_key_value_tuples
    load_condition_data
    [ [ {:return => :aoa},  [ "dana",
                              { "first" => "Dana",
                                "middle" => "Ann Leslie",
                                "last"   => "Gray",
                                "age"    => "34" } ] ],
      [ {:return => :hoh},  [ "dana",
                              { "first" => "Dana",
                                "middle" => "Ann Leslie",
                                "last"   => "Gray",
                                "age"    => "34" } ] ] ].each do |query, tuple|
      %w[union intersection difference].each do |search|
        yielded = nil
        @db.send( search,
                  query.merge(:conditions => [:first, :==, "Dana"]) ) do |kv|
          yielded = kv
        end
        assert_equal(tuple, yielded)
        key, value = nil, nil
        @db.send( search,
                  query.merge(:conditions => [:first, :==, "Dana"]) ) do |k, v|
          key   = k
          value = v
        end
        assert_equal(tuple.first, key)
        assert_equal(tuple.last,  value)
      end
    end
  end
  
  private
  
  def load_simple_data
    @db[:pk1] = {:a => 1, :b => 2, :c => 3}
    @db[:pk2] = { }
  end
  
  def load_condition_data
    @db[:dana]  = { :first  => "Dana",
                    :middle => "Ann Leslie",
                    :last   => "Gray",
                    :age    => 34 }
    @db[:james] = {:first => "James", :last => "Gray", :age => 33}
    @db[:jim]   = {:first => "Jim",   :last => "Gray", :age => 53}
  end
  
  def load_search_data
    @db[:dana]  = {:name => "Dana Ann Leslie Gray"}
    @db[:james] = {:name => "James Edward Gray II"}
    @db[:jim]   = {:name => "Jim Edward Gray"}
  end
  
  def load_order_data
    @db[:middle] = {:str => :b, :num => 2}
    @db[:last]   = {:str => :c, :num => 11}
    @db[:first]  = {:str => :a, :num => 1}
  end
end

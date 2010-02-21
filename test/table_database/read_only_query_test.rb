require "test_helper"

class TestReadOnlyQuery < Test::Unit::TestCase
  def setup
    # create the database and load some data
    tdb do |db|
      db[:pk1] = {:a => 1, :b => 2, :c => 3}
      db[:pk2] = { }
    end
    @db = tdb("r")
  end
  
  def teardown
    @db.close
    remove_db_files
  end
  
  def test_all_with_a_block_can_end_the_query
    results = [ ]
    assert_equal(@db,          @db.all { |k, _| results << k; :break })
    assert_equal(1,            results.size)
    assert_match(/\Apk[12]\z/, results.first)
  end
  
  def test_all_with_block_delete_is_ignored_and_triggers_a_warning
    warning = capture_stderr do
      assert_equal(@db, @db.all { :delete })
    end
    assert_equal(2, @db.size)
    assert( !warning.empty?,
            "A warning was not issued for :delete in a read only query" )
  end
  
  def test_all_with_block_update_is_ignored_and_triggers_a_warning
    warning = capture_stderr do
      assert_equal( @db, @db.all { |k, v|
        if k == "pk1"
          v["a"] = "1.1"  # change
          v.delete("c")   # remove
          v[:d] = 4       # add
          :update
        end
      } )
    end
    assert_equal({"a" => "1", "b" => "2", "c" => "3"}, @db[:pk1])
    assert( !warning.empty?,
            "A warning was not issued for :update in a read only query" )
  end
  
  def test_all_methods_can_control_what_is_passed_to_the_block
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
  
  def test_count_works_on_a_read_only_database
    assert_equal(@db.size, @db.count)
  end
  
  def test_paginate_works_on_a_read_only_database
    assert_equal( %w[pk1], @db.paginate( :select   => :keys,
                                         :order    => :primary_key,
                                         :per_page => 1,
                                         :page     => 1 ) )
    assert_equal( %w[pk2], @db.paginate( :select   => :keys,
                                         :order    => :primary_key,
                                         :per_page => 1,
                                         :page     => 2 ) )
    assert_equal( [ ],     @db.paginate( :select   => :keys,
                                         :order    => :primary_key,
                                         :per_page => 1,
                                         :page     => 3 ) )
  end
  
  def test_search_with_a_block_can_end_the_query
    each_search do |search|
      results = [ ]
      assert_equal(@db,   @db.send(search, :order => :primary_key) { |k, _|
                            results << k; :break
                          })
      assert_equal(1,     results.size)
      assert_equal("pk1", results.first)
    end
  end
  
  def test_search_with_block_delete_is_ignored_and_triggers_a_warning
    each_search do |search|
      warning = capture_stderr do
        assert_equal(@db, @db.send(search, :order => :primary_key) { :delete })
      end
      assert_equal(2, @db.size)
      assert( !warning.empty?,
              "A warning was not issued for :delete in a read only search" )
    end
  end
  
  def test_search_with_block_update_is_ignored_and_triggers_a_warning
    each_search do |search|
      warning = capture_stderr do
        assert_equal( @db, @db.send(search, :order => :primary_key) { |k, v|
          if k == "pk1"
            v["a"] = "1.1"  # change
            v.delete("c")   # remove
            v[:d] = 4       # add
            :update
          end
        } )
      end
      assert_equal({"a" => "1", "b" => "2", "c" => "3"}, @db[:pk1])
      assert( !warning.empty?,
              "A warning was not issued for :update in a read only search" )
    end
  end
  
  private
  
  def each_search(&test)
    %w[union intersection difference].each(&test)
  end
end

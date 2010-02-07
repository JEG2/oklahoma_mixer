module StorageTests
  def test_fetching_a_missing_value_fails_with_an_index_error
    assert_raise(IndexError) do
      @db.fetch(:missing)
    end
  end
  
  def test_fetch_can_return_a_default_for_a_missing_value
    assert_equal(42, @db.fetch(:missing, 42))
  end
  
  def test_fetch_can_run_a_block_returning_its_result_for_a_missing_value
    assert_equal(:missing, @db.fetch(:missing) { |key| key })
  end
  
  def test_fetching_with_a_block_overrides_a_default_and_triggers_a_warning
    warning = capture_stderr do
      assert_equal(42, @db.fetch(:missing, 13) { 42 })
    end
    assert(!warning.empty?, "A warning was not issued for a default and block")
  end
  
  def test_store_and_fetch_can_also_be_used_through_the_indexing_brackets
    assert_equal({:a => 1, :b => 2},       @db[:doc] = {:a => 1, :b => 2})
    assert_equal({"a" => "1", "b" => "2"}, @db[:doc])
  end
  
  def test_indexing_returns_nil_instead_of_failing_with_index_error
    assert_nil(@db[:missing])
  end
  
  def test_a_default_can_be_set_for_indexing_to_return
    @db.default = 42
    assert_equal(42, @db[:missing])
  end
  
  def test_the_indexing_default_will_be_run_if_it_is_a_proc
    @db.default = lambda { |key| "is #{key}" }
    assert_equal("is missing", @db[:missing])
  end
  
  def test_the_indexing_default_for_a_given_key_can_be_retrieved
    @db.default = lambda { |key| "is #{key}" }
    assert_equal("is ",        @db.default)
    assert_equal("is missing", @db.default(:missing))
  end
  
  def test_the_indexing_default_can_be_changed
    assert_nil(@db[:missing])
    assert_equal(42, @db.default = 42)
    assert_equal(42, @db[:missing])
    proc = lambda { |key| fail RuntimeError, "%p not found" % [key]}
    assert_equal(proc, @db.default = proc)
    error = assert_raise(RuntimeError) { @db[:missing] }
    assert_equal(":missing not found", error.message)
  end
  
  def test_delete_returns_nil_for_a_missing_key
    assert_nil(@db.delete(:missing))
  end
  
  def test_delete_can_be_passed_a_block_to_handle_missing_keys
    assert_equal(42, @db.delete(:missing) { 42 })
  end
end

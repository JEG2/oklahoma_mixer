require "test_helper"

class TestTransactions < Test::Unit::TestCase
  def setup
    @db        = hdb
    @db[:data] = "before transaction"
  end
  
  def teardown
    @db.close
    remove_db_files
  end
  
  def test_a_transaction_returns_the_value_of_the_last_expression
    assert_equal(42, @db.transaction { 42 })
  end
  
  def test_a_transaction_is_automatically_committed_if_the_block_finishes
    @db.transaction do
      @db[:data] = "after transaction"
    end
    assert_equal("after transaction", @db[:data])
  end
  
  def test_failing_with_an_error_aborts_the_transaction
    assert_raise(RuntimeError) do
      @db.transaction do
        @db[:data] = "after transaction"
        fail "Testing abort"
      end
    end
    assert_equal("before transaction", @db[:data])
  end
  
  def test_a_transaction_can_be_committed_before_the_end_of_the_block
    @db.transaction do
      @db[:data] = "after transaction"
      @db.commit
      @db[:other] = "set"  # not executed
    end
    assert_equal("after transaction", @db[:data])
    assert_nil(@db[:other])
  end
  
  def test_a_transaction_can_be_aborted_before_the_end_of_the_block
    @db.transaction do
      @db[:data] = "after transaction"
      @db.abort
      @db[:other] = "set"  # not executed
    end
    assert_equal("before transaction", @db[:data])
    assert_nil(@db[:other])
  end
  
  def test_commit_fails_with_an_error_if_called_outside_a_transaction
    assert_raise(OKMixer::Error::TransactionError) do
      @db.commit
    end
  end
  
  def test_abort_fails_with_an_error_if_called_outside_a_transaction
    assert_raise(OKMixer::Error::TransactionError) do
      @db.abort
    end
  end
end

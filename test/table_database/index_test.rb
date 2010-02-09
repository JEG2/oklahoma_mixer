require "test_helper"

class TestIndex < Test::Unit::TestCase
  def setup
    @db = tdb
  end
  
  def teardown
    @db.close
    remove_db_files
  end
  
  def test_an_index_can_be_added_to_a_column
    assert(@db.add_index(:column, :string), "Index not added")
  end
  
  def test_an_index_can_be_rebuilt_by_adding_it_again
    2.times do
      assert(@db.add_index(:column, :string), "Index not added")
    end
  end
  
  def test_string_numeric_token_and_qgram_indexes_are_supported
    %w[lexical string decimal numeric token qgram].each do |type|
      assert(@db.add_index(type, type), "Index not added")
    end
  end
  
  def test_an_unknown_index_type_fails_with_an_error
    assert_raise(OKMixer::Error::IndexError) do
      @db.add_index(:column, :unknown)
    end
  end
  
  def test_adding_an_existing_index_with_keep_mode_returns_false
    assert(@db.add_index(:column, :string),         "Index not added")
    assert(!@db.add_index(:column, :string, :keep), "Index readded")
  end
  
  def test_an_existing_index_can_be_removed
    assert(@db.add_index(:column, :string), "Index not added")
    assert(@db.remove_index(:column),       "Index not removed")
  end
  
  def test_removing_a_nonexisting_index_returns_false
    assert(!@db.remove_index(:missing), "Index removed")
  end
  
  def test_an_existing_index_can_be_optimized
    assert(@db.add_index(:column, :string), "Index not added")
    assert(@db.optimize_index(:column),     "Index not optimized")
  end
  
  def test_optimizing_a_nonexisting_index_returns_false
    assert(!@db.optimize_index(:missing), "Index optimized")
  end
end

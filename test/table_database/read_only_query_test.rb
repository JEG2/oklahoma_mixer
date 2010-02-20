require "test_helper"

class TestReadOnlyQuery < Test::Unit::TestCase
  def setup
    tdb { }  # create the database file
    @db = tdb("r")
  end
  
  def teardown
    @db.close
    remove_db_files
  end
  
  def test_using_a_block_fails_with_an_error
    assert_raise(OKMixer::Error::QueryError) do
      @db.all { }
    end
  end
end

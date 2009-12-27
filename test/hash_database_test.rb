require "test_helper"

class TestHashDatabase < Test::Unit::TestCase
  DB_PATH = File.join(File.dirname(__FILE__), "test.tch")
  
  def teardown
    File.unlink(DB_PATH) if File.exist? DB_PATH
  end
  
  def test_creating_a_hash_database_creates_the_corresponding_file
    hdb  # open and close
    assert(File.exist?(DB_PATH), "The HashDatabase file was not created")
  end
  
  #######
  private
  #######
  
  def hdb(options = { })
    db = OKMixer::HashDatabase.new(DB_PATH, options)
    yield db if block_given?
  ensure
    db.close if db
  end
end

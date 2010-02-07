require "test_helper"
require "shared/hash_tuning_tests"

class TestTuning < Test::Unit::TestCase
  def teardown
    remove_db_files
  end
  
  include HashTuningTests
  
  def test_limit_for_cached_records_can_be_set
    limit = rand(1_000) + 1
    assert_option_calls([:setcache, limit], :rcnum => limit)
  end
  
  def test_limit_for_cached_records_is_converted_to_an_int
    assert_option_calls([:setcache, 42], :rcnum => "42")
  end
  
  #######
  private
  #######
  
  def lib
    OKMixer::HashDatabase::C
  end
  
  def db(*args, &block)
    hdb(*args, &block)
  end
end

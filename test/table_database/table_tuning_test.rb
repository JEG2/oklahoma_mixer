require "test_helper"
require "shared/hash_tuning_tests"

class TestTableTuning < Test::Unit::TestCase
  def teardown
    remove_db_files
  end
  
  include HashTuningTests
  
  def test_records_cached_can_be_set_with_other_cache_defaults
    records = rand(1_000) + 1
    assert_option_calls([:setcache, records, 0, 0], :rcnum => records)
  end
  
  def test_records_cached_is_converted_to_an_int
    assert_option_calls([:setcache, 42, 0, 0], :rcnum => "42")
  end
  
  def test_leaf_nodes_cached_can_be_set_with_other_cache_defaults
    nodes = rand(1_000) + 1
    assert_option_calls([:setcache, 0, nodes, 0], :lcnum => nodes)
  end
  
  def test_leaf_nodes_cached_is_converted_to_an_int
    assert_option_calls([:setcache, 0, 42, 0], :lcnum => "42")
  end
  
  def test_non_leaf_nodes_cached_can_be_set_with_other_cache_defaults
    nodes = rand(1_000) + 1
    assert_option_calls([:setcache, 0, 0, nodes], :ncnum => nodes)
  end
  
  def test_non_leaf_nodes_cached_is_converted_to_an_int
    assert_option_calls([:setcache, 0, 0, 42], :ncnum => "42")
  end
  
  def test_multiple_cache_parameters_can_be_set_at_the_same_time
    l_nodes = rand(1_000) + 1
    n_nodes = rand(1_000) + 1
    assert_option_calls( [:setcache, 0, l_nodes, n_nodes],
                         :lcnum => l_nodes, :ncnum => n_nodes )
  end
  
  #######
  private
  #######
  
  def lib
    OKMixer::TableDatabase::C
  end
  
  def db(*args, &block)
    tdb(*args, &block)
  end
end

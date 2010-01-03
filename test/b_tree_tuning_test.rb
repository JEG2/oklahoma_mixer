require "test_helper"
require "shared_tuning"

class TestBTreeTuning < Test::Unit::TestCase
  def teardown
    remove_db_files
  end
  
  include SharedTuning
  
  def test_leaf_members_can_be_set_with_other_tuning_defaults
    members = rand(1_000) + 1
    assert_option_calls([:tune, members, 0, 0, -1, -1, 0xFF], :lmemb => members)
  end
  
  def test_leaf_members_is_converted_to_an_int
    assert_option_calls([:tune, 42, 0, 0, -1, -1, 0xFF], :lmemb => "42")
  end
  
  def test_non_leaf_members_can_be_set_with_other_tuning_defaults
    members = rand(1_000) + 1
    assert_option_calls([:tune, 0, members, 0, -1, -1, 0xFF], :nmemb => members)
  end
  
  def test_non_leaf_members_is_converted_to_an_int
    assert_option_calls([:tune, 0, 42, 0, -1, -1, 0xFF], :nmemb => "42")
  end
  
  def test_a_bucket_array_size_can_be_set_with_other_tuning_defaults
    size = rand(1_000) + 1
    assert_option_calls([:tune, 0, 0, size, -1, -1, 0xFF], :bnum => size)
  end
  
  def test_bucket_array_size_is_converted_to_an_int
    assert_option_calls([:tune, 0, 0, 42, -1, -1, 0xFF], :bnum => "42")
  end
  
  def test_a_record_alignment_power_can_be_set_with_other_tuning_defaults
    pow = rand(10) + 1
    assert_option_calls([:tune, 0, 0, 0, pow, -1, 0xFF], :apow => pow)
  end
  
  def test_record_alignment_power_is_converted_to_an_int
    assert_option_calls([:tune, 0, 0, 0, 42, -1, 0xFF], :apow => "42")
  end
  
  def test_a_max_free_block_power_can_be_set_with_other_tuning_defaults
    pow = rand(10) + 1
    assert_option_calls([:tune, 0, 0, 0, -1, pow, 0xFF], :fpow => pow)
  end
  
  def test_max_free_block_power_is_converted_to_an_int
    assert_option_calls([:tune, 0, 0, 0, -1, 42, 0xFF], :fpow => "42")
  end
  
  def test_options_can_be_set_with_other_tuning_defaults
    assert_option_calls([:tune, 0, 0, 0, -1, -1, 1 | 2], :opts => "ld")
  end
  
  def test_options_is_a_string_of_characters_mapped_to_enums_and_ored_together
    opts = {"l" => lib::OPTS[:BDBTLARGE], "b" => lib::OPTS[:BDBTBZIP]}
    assert_option_calls( [ :tune, 0, 0, 0, -1, -1,
                           opts.values.inject(0) { |o, v| o | v } ],
                         :opts => opts.keys.join )
  end
  
  def test_the_options_string_is_not_case_sensative
    assert_option_calls([:tune, 0, 0, 0, -1, -1, 1 | 2], :opts => "ld")
    assert_option_calls([:tune, 0, 0, 0, -1, -1, 1 | 2], :opts => "LD")
  end
  
  def test_unknown_options_are_ignored_with_a_warning
    warning = capture_stderr do
      assert_option_calls([:tune, 0, 0, 0, -1, -1, 1 | 8], :opts => "ltu")
    end
    assert(!warning.empty?, "A warning was not issued for an unknown option")
  end
  
  def test_multiple_tuning_parameters_can_be_set_at_the_same_time
    members = rand(1_000) + 1
    size    = rand(1_000) + 1
    assert_option_calls( [:tune, members, 0, size, -1, -1, 1 | 2],
                         :lmemb => members, :bnum => size, :opts => "ld" )
  end
  
  def test_optimize_allows_the_adjustment_of_tune_options_for_an_open_database
    db do |db|
      args = capture_args(lib, :optimize) do
        db.optimize(:apow => "42", :opts => "ld")
      end
      assert_instance_of(FFI::Pointer, args[0])
      assert_equal([0, 0, 0, 42, -1, 1 | 2], args[1..-1])
    end
  end

  def test_leaf_nodes_cached_can_be_set_with_other_cache_defaults
    nodes = rand(1_000) + 1
    assert_option_calls([:setcache, nodes, 0], :lcnum => nodes)
  end

  def test_leaf_nodes_cached_is_converted_to_an_int
    assert_option_calls([:setcache, 42, 0], :lcnum => "42")
  end

  def test_non_leaf_nodes_cached_can_be_set_with_other_cache_defaults
    nodes = rand(1_000) + 1
    assert_option_calls([:setcache, 0, nodes], :ncnum => nodes)
  end

  def test_non_leaf_nodes_cached_is_converted_to_an_int
    assert_option_calls([:setcache, 0, 42], :ncnum => "42")
  end
  
  def test_multiple_cache_parameters_can_be_set_at_the_same_time
    l_nodes = rand(1_000) + 1
    n_nodes = rand(1_000) + 1
    assert_option_calls( [:setcache, l_nodes, n_nodes],
                         :lcnum => l_nodes, :ncnum => n_nodes )
  end
  
  #######
  private
  #######
  
  def lib
    OKMixer::BTreeDatabase::C
  end
  
  def db(*args, &block)
    bdb(*args, &block)
  end
end

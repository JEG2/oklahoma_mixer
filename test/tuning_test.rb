require "test_helper"

class TestTuning < Test::Unit::TestCase
  def teardown
    remove_db_files
  end
  
  def test_a_mutex_can_be_activated_as_the_database_is_created
    assert_option_calls([:setmutex], :mutex => true)
  end
  
  def test_a_bucket_array_size_can_be_set_with_other_tuning_defaults
    size = rand(1_000) + 1
    assert_option_calls([:tune, size, -1, -1, 0xFF], :bucket_array_size => size)
  end
  
  def test_bucket_array_size_is_converted_to_an_int
    assert_option_calls([:tune, 42, -1, -1, 0xFF], :bucket_array_size => "42")
  end
  
  def test_a_record_alignment_power_can_be_set_with_other_tuning_defaults
    pow = rand(10) + 1
    assert_option_calls( [:tune, 0, pow, -1, 0xFF],
                         :record_alignment_power => pow )
  end
  
  def test_record_alignment_power_is_converted_to_an_int
    assert_option_calls( [:tune, 0, 42, -1, 0xFF],
                         :record_alignment_power => "42" )
  end
  
  def test_a_max_free_block_power_can_be_set_with_other_tuning_defaults
    pow = rand(10) + 1
    assert_option_calls([:tune, 0, -1, pow, 0xFF], :max_free_block_power => pow)
  end
  
  def test_max_free_block_power_is_converted_to_an_int
    assert_option_calls([:tune, 0, -1, 42, 0xFF], :max_free_block_power => "42")
  end
  
  def test_options_can_be_set_with_other_tuning_defaults
    assert_option_calls([:tune, 0, -1, -1, 1 | 2], :options => "ld")
  end
  
  def test_options_is_a_string_of_characters_mapped_to_enums_and_ored_together
    opts = { "l" => OKMixer::HashDatabase::C::OPTS[:HDBTLARGE],
             "b" => OKMixer::HashDatabase::C::OPTS[:HDBTBZIP] }
    assert_option_calls( [ :tune, 0, -1, -1,
                           opts.values.inject(0) { |o, v| o | v } ],
                         :options => opts.keys.join )
  end
  
  def test_the_options_string_is_not_case_sensative
    assert_option_calls([:tune, 0, -1, -1, 1 | 2], :options => "ld")
    assert_option_calls([:tune, 0, -1, -1, 1 | 2], :options => "LD")
  end
  
  def test_unknown_options_are_ignored_with_a_warning
    warning = capture_stderr do
      assert_option_calls([:tune, 0, -1, -1, 1 | 8], :options => "ltu")
    end
    assert(!warning.empty?, "A warning was not issued for an unknown option")
  end
  
  def test_multiple_tuning_parameters_can_be_set_at_the_same_time
    size = rand(1_000) + 1
    assert_option_calls( [:tune, size, -1, -1, 1 | 2],
                         :bucket_array_size => size, :options => "ld" )
  end
  
  def test_optimize_allows_the_adjustment_of_tune_options_for_an_open_database
    hdb do |db|
      args = capture_args(OKMixer::HashDatabase::C, :optimize) do
        db.optimize( :record_alignment_power => "42",
                     :options                => "ld" )
      end
      assert_instance_of(FFI::Pointer, args[0])
      assert_equal([0, 42, -1, 1 | 2], args[1..-1])
    end
  end
  
  def test_limit_for_cached_records_can_be_set
    limit = rand(1_000) + 1
    assert_option_calls([:setcache, limit], :max_cached_records => limit)
  end
  
  def test_limit_for_cached_records_is_converted_to_an_int
    assert_option_calls([:setcache, 42], :max_cached_records => "42")
  end
  
  def test_a_size_can_be_set_for_extra_mapped_memory
    size = rand(1_000) + 1
    assert_option_calls([:xmsiz, size], :extra_mapped_mem => size)
  end
  
  def test_extra_mapped_memory_size_is_converted_to_an_int
    assert_option_calls([:xmsiz, 42], :extra_mapped_mem => "42")
  end
  
  def test_a_step_unit_can_be_set_for_auto_defragmentation
    unit = rand(1_000) + 1
    assert_option_calls([:dfunit, unit], :auto_defrag_step_unit => unit)
  end
  
  def test_auto_defragmentation_step_unit_is_converted_to_an_int
    assert_option_calls([:dfunit, 42], :auto_defrag_step_unit => "42")
  end
  
  private
  
  def assert_option_calls(c_call, options)
    args = capture_args(OKMixer::HashDatabase::C, c_call[0]) do
      hdb(options) do
        # just open and close
      end
    end
    assert_instance_of(FFI::Pointer, args[0])
    assert_equal(c_call[1..-1], args[1..-1])
  end
end

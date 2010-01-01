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
    assert_option_calls([:tune, size, -1, -1, 0xFF], :bnum => size)
  end
  
  def test_bucket_array_size_is_converted_to_an_int
    assert_option_calls([:tune, 42, -1, -1, 0xFF], :bnum => "42")
  end
  
  def test_a_record_alignment_power_can_be_set_with_other_tuning_defaults
    pow = rand(10) + 1
    assert_option_calls([:tune, 0, pow, -1, 0xFF], :apow => pow)
  end
  
  def test_record_alignment_power_is_converted_to_an_int
    assert_option_calls([:tune, 0, 42, -1, 0xFF], :apow => "42")
  end
  
  def test_a_max_free_block_power_can_be_set_with_other_tuning_defaults
    pow = rand(10) + 1
    assert_option_calls([:tune, 0, -1, pow, 0xFF], :fpow => pow)
  end
  
  def test_max_free_block_power_is_converted_to_an_int
    assert_option_calls([:tune, 0, -1, 42, 0xFF], :fpow => "42")
  end
  
  def test_options_can_be_set_with_other_tuning_defaults
    assert_option_calls([:tune, 0, -1, -1, 1 | 2], :opts => "ld")
  end
  
  def test_options_is_a_string_of_characters_mapped_to_enums_and_ored_together
    opts = { "l" => OKMixer::HashDatabase::C::OPTS[:HDBTLARGE],
             "b" => OKMixer::HashDatabase::C::OPTS[:HDBTBZIP] }
    assert_option_calls( [ :tune, 0, -1, -1,
                           opts.values.inject(0) { |o, v| o | v } ],
                         :opts => opts.keys.join )
  end
  
  def test_the_options_string_is_not_case_sensative
    assert_option_calls([:tune, 0, -1, -1, 1 | 2], :opts => "ld")
    assert_option_calls([:tune, 0, -1, -1, 1 | 2], :opts => "LD")
  end
  
  def test_unknown_options_are_ignored_with_a_warning
    warning = capture_stderr do
      assert_option_calls([:tune, 0, -1, -1, 1 | 8], :opts => "ltu")
    end
    assert(!warning.empty?, "A warning was not issued for an unknown option")
  end
  
  def test_multiple_tuning_parameters_can_be_set_at_the_same_time
    size = rand(1_000) + 1
    assert_option_calls( [:tune, size, -1, -1, 1 | 2],
                         :bnum => size, :opts => "ld" )
  end
  
  def test_optimize_allows_the_adjustment_of_tune_options_for_an_open_database
    hdb do |db|
      args = capture_args(OKMixer::HashDatabase::C, :optimize) do
        db.optimize(:apow => "42", :opts => "ld")
      end
      assert_instance_of(FFI::Pointer, args[0])
      assert_equal([0, 42, -1, 1 | 2], args[1..-1])
    end
  end
  
  def test_limit_for_cached_records_can_be_set
    limit = rand(1_000) + 1
    assert_option_calls([:setcache, limit], :rcnum => limit)
  end
  
  def test_limit_for_cached_records_is_converted_to_an_int
    assert_option_calls([:setcache, 42], :rcnum => "42")
  end
  
  def test_a_size_can_be_set_for_extra_mapped_memory
    size = rand(1_000) + 1
    assert_option_calls([:setxmsiz, size], :xmsiz => size)
  end
  
  def test_extra_mapped_memory_size_is_converted_to_an_int
    assert_option_calls([:setxmsiz, 42], :xmsiz => "42")
  end
  
  def test_a_step_unit_can_be_set_for_auto_defragmentation
    unit = rand(1_000) + 1
    assert_option_calls([:setdfunit, unit], :dfunit => unit)
  end
  
  def test_auto_defragmentation_step_unit_is_converted_to_an_int
    assert_option_calls([:setdfunit, 42], :dfunit => "42")
  end
  
  def test_nested_transactions_can_be_ignored
    hdb(:nested_transactions => :ignore) do |db|
      result = db.transaction {
        db.transaction {  # ignored
          41
        } + 1             # ignored
      }
      assert_equal(42, result)
    end
  end
  
  def test_nested_transactions_can_be_set_to_fail_with_an_error
    [:fail, :raise].each do |setting|
      hdb(:nested_transactions => setting) do |db|
        db.transaction do
          assert_raise(OKMixer::Error::TransactionError) do
            db.transaction {  }  # nested fails with error
          end
        end
      end
    end
  end
  
  def test_a_mode_string_can_be_passed
    assert_raise(OKMixer::Error::CabinetError) do  # file not found
      hdb("r")
    end
  end
  
  def test_the_mode_can_be_passed_as_as_option
    assert_raise(OKMixer::Error::CabinetError) do  # file not found
      hdb(:mode => "r")
    end
  end
  
  def test_an_option_mode_overrides_the_mode_argument_and_triggers_a_warning
    warning = capture_stderr do
      hdb("r", :mode => "wc") do
        # just open and close
      end
    end
    assert( !warning.empty?,
            "A warning was not issued for an option mode with a mode argument" )
  end
  
  def test_an_unknown_mode_triggers_a_warning
    warning = capture_stderr do
      hdb("wcu") do
        # just open and close
      end
    end
    assert(!warning.empty?, "A warning was not issued for an unknown mode")
  end
  
  #######
  private
  #######
  
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

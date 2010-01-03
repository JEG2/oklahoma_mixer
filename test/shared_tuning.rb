module SharedTuning
  def test_a_mutex_can_be_activated_as_the_database_is_created
    assert_option_calls([:setmutex], :mutex => true)
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
    db(:nested_transactions => :ignore) do |db|
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
      db(:nested_transactions => setting) do |db|
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
      db("r")
    end
  end
  
  def test_the_mode_can_be_passed_as_as_option
    assert_raise(OKMixer::Error::CabinetError) do  # file not found
      db(:mode => "r")
    end
  end
  
  def test_an_option_mode_overrides_the_mode_argument_and_triggers_a_warning
    warning = capture_stderr do
      db("r", :mode => "wc") do
        # just open and close
      end
    end
    assert( !warning.empty?,
            "A warning was not issued for an option mode with a mode argument" )
  end
  
  def test_an_unknown_mode_triggers_a_warning
    warning = capture_stderr do
      db("wcu") do
        # just open and close
      end
    end
    assert(!warning.empty?, "A warning was not issued for an unknown mode")
  end
  
  #######
  private
  #######
  
  def assert_option_calls(c_call, options)
    args = capture_args(lib, c_call[0]) do
      db(options) do
        # just open and close
      end
    end
    assert_instance_of(FFI::Pointer, args[0])
    assert_equal(c_call[1..-1], args[1..-1])
  end
end

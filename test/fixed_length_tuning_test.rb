require "test_helper"

class TestFixedLengthTuning < Test::Unit::TestCase
  def teardown
    remove_db_files
  end
  
  def test_a_mutex_can_be_activated_as_the_database_is_created
    args = capture_args(OKMixer::FixedLengthDatabase::C, :setmutex) do
      fdb(:mutex => true) do
        # just open and close
      end
    end
    assert_instance_of(FFI::Pointer, args[0])
    assert_equal([ ], args[1..-1])
  end
  
  def test_width_controls_value_length
    fdb(:width => 4) do |db|
      db.update(1 => "one", 2 => "two", 3 => "three", 4 => "four")
      assert_equal([[1, "one"], [2, "two"], [3, "thre"], [4, "four"]], db.to_a)
    end
  end
  
  def test_width_can_be_changed_later_with_optimize
    fdb do |db|  # default width of 255
      db.update(1 => "one", 2 => "two", 3 => "three", 4 => "four")
      assert_equal([[1, "one"], [2, "two"], [3, "three"], [4, "four"]], db.to_a)
      assert(db.optimize(:width => 4), "Width was not changed")
      assert_equal([[1, "one"], [2, "two"], [3, "thre"], [4, "four"]], db.to_a)
    end
  end
  
  def test_limsiz_controls_the_maximum_database_size
    fdb(:width => 1024, :limsiz => 3 * 1024) do |db|
      data = "X" * 1024
      assert_nothing_raised(OKMixer::Error::CabinetError) do
        3.times do |i|
          db[i + 1] = data
        end
      end
      assert_raise(OKMixer::Error::CabinetError) do
        db[4] = "X"
      end
      assert_equal([[1, data], [2, data], [3, data]], db.to_a)
    end
  end
  
  def test_limsiz_can_be_increases_later_with_optimize
    fdb(:width => 1024, :limsiz => 3 * 1024) do |db|
      data = "X" * 1024
      3.times do |i|
        db[i + 1] = data
      end
      assert(db.optimize(:limsiz => 4 * 1024), "Size limit was not increased")
    end
  end
  
  def test_defrag_is_a_no_op
    fdb(:width => 1024) do |db|
      # load some data
      data = "X" * 1024
      10.times do |i|
        db[i + 1] = data
      end
      old_size = File.size(db.path)
      # delete some data
      [3, 5, 7].each do |i|
        db.delete(i)
      end
      assert_equal(old_size, File.size(db.path))
      # no-op
      db.defrag
      assert_equal(old_size, File.size(db.path))
    end
  end
end

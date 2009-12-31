require "test_helper"

class TestTopLevelInterface < Test::Unit::TestCase
  def teardown
    remove_db_files
  end
  
  def test_ok_mixer_is_a_shortcut_for_oklahoma_mixer
    assert_same(OklahomaMixer, OKMixer)
  end
  
  def test_open_of_a_tch_extension_file_creates_a_hash_database
    OKMixer.open(db_path("tch")) do |db|
      assert_instance_of(OKMixer::HashDatabase, db)
    end
  end
  
  def test_open_of_an_unrecognized_extension_fails_with_an_error
    assert_raise(ArgumentError) do
      OKMixer.open("unrecognized")
    end
  end
end

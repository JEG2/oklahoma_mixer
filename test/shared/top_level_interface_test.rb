require "test_helper"

class TestTopLevelInterface < Test::Unit::TestCase
  def teardown
    remove_db_files
  end
  
  def test_ok_mixer_is_a_shortcut_for_oklahoma_mixer
    assert_same(OklahomaMixer, OKMixer)
  end
  
  def test_the_version_constant_contains_the_current_version_number
    assert_match(/\A\d\.\d\.\d\z/, OKMixer::VERSION)
  end
  
  def test_the_hash_database_interface_is_autoloaded_as_needed
    assert_loads(%w[hash], %Q{OKMixer.open(#{db_path('tch').inspect}) { }})
  end
  
  def test_the_b_tree_database_interface_is_autoloaded_as_needed
    assert_loads( %w[b_tree hash],
                  %Q{OKMixer.open(#{db_path('tcb').inspect}) { }} )
  end
  
  def test_the_fixed_length_database_interface_is_autoloaded_as_needed
    assert_loads( %w[fixed_length hash],
                  %Q{OKMixer.open(#{db_path('tcf').inspect}) { }} )
  end
  
  def test_the_table_database_interface_is_autoloaded_as_needed
    assert_loads( %w[hash table],
                  %Q{OKMixer.open(#{db_path('tct').inspect}) { }} )
  end
  
  def test_open_of_a_tch_extension_file_creates_a_hash_database
    OKMixer.open(db_path("tch")) do |db|
      assert_instance_of(OKMixer::HashDatabase, db)
    end
  end
  
  def test_open_of_a_tcb_extension_file_creates_a_b_tree_database
    OKMixer.open(db_path("tcb")) do |db|
      assert_instance_of(OKMixer::BTreeDatabase, db)
    end
  end
  
  def test_open_of_a_tcf_extension_file_creates_a_fixed_length_database
    OKMixer.open(db_path("tcf")) do |db|
      assert_instance_of(OKMixer::FixedLengthDatabase, db)
    end
  end
  
  def test_open_of_a_tct_extension_file_creates_a_table_database
    OKMixer.open(db_path("tct")) do |db|
      assert_instance_of(OKMixer::TableDatabase, db)
    end
  end
  
  def test_open_of_an_unrecognized_extension_fails_with_an_error
    assert_raise(ArgumentError) do
      OKMixer.open("unrecognized")
    end
  end
  
  def test_open_with_a_block_returns_the_value_of_the_last_expression
    assert_equal(42, OKMixer.open(db_path("tch")) { 42 })
  end
  
  def test_open_with_a_block_automatically_closes_the_database
    OKMixer.open(db_path("tch")) do |db|
      db[:data] = :saved
    end
    OKMixer.open(db_path("tch")) do |db|  # we can reopen since the lock is gone
      assert_equal("saved", db[:data])
    end
  end
  
  def test_open_without_a_block_returns_the_still_open_database
    db = OKMixer.open(db_path("tch"))
    assert_nil(db[:unset])  # we can fetch a value since it's still open
  ensure
    db.close if db
  end
  
  private
  
  def assert_loads(fields, ruby_code)
    run_ruby <<-END_RUBY
    loaded_dbs = lambda { $".grep(/\\b(\\w+)_database\\.rb\\z/) { $1 }.sort }
    before     = loaded_dbs.call
    #{ruby_code}
    puts loaded_dbs.call - before
    END_RUBY
    assert_equal(fields, @output.scan(/\w+/))
  end
end

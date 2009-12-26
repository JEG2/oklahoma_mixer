require "test_helper"

require "oklahoma_mixer"

class TestTopLevelInterface < Test::Unit::TestCase
  def test_ok_mixer_is_a_shortcut_for_oklahoma_mixer
    assert_same(OklahomaMixer, OKMixer)
  end
  
  def test_hash_database_interface_is_autoloaded_as_needed
    run_ruby <<-'END_RUBY'
    hdb_loaded = lambda { !$".grep(/\bhash_database\.rb\z/).empty? }
    puts "after_require = #{hdb_loaded.call}"
    OklahomaMixer::HashDatabase
    puts "after_access = #{hdb_loaded.call}"
    END_RUBY
    assert_match(/\bafter_require\s*=\s*false\b/, @output)
    assert_match(/\bafter_access\s*=\s*true\b/,   @output)
  end
end

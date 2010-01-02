require "test_helper"

class TestOrder < Test::Unit::TestCase
  def teardown
    remove_db_files
  end
  
  def test_b_tree_databases_default_to_lexical_ordering
    bdb do |db|
      db.update(:c => 3, :a => 1, :b => 2)
      assert_equal(%w[a b c],                   db.keys)
      assert_equal([%w[a 1], %w[b 2], %w[c 3]], db.to_a)
    end
  end
end

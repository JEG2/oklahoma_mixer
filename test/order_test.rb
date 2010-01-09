require "test_helper"

class TestOrder < Test::Unit::TestCase
  REVERSE_ORDER_CMPFUNC = lambda { |a, b| a == "" ? a <=> b : b <=> a }
  
  def teardown
    remove_db_files
  end
  
  def test_b_tree_databases_default_to_lexical_ordering
    bdb do |db|
      db.update(:c => 3, :a => 1, :b => 2)
      assert_equal(%w[a b c],                   db.keys)
      assert_equal([%w[a 1], %w[b 2], %w[c 3]], db.to_a)
    end

    remove_db_files
    bdb do |db|
      db.update(1 => :a, 11 => :b, 2 => :c)
      assert_equal(%w[1 11 2],                   db.keys)
      assert_equal([%w[1 a], %w[11 b], %w[2 c]], db.to_a)
    end
  end
  
  def test_b_tree_database_ordering_can_be_changed_with_a_comparison_function
    bdb(:cmpfunc => REVERSE_ORDER_CMPFUNC) do |db|
      db.update(:c => 3, :a => 1, :b => 2)
      assert_equal(%w[c b a],                   db.keys)
      assert_equal([%w[c 3], %w[b 2], %w[a 1]], db.to_a)
    end

    remove_db_files
    cmpfunc = lambda { |a, b| a.to_i <=> b.to_i }  # numerical order
    bdb(:cmpfunc => cmpfunc) do |db|
      db.update(1 => :a, 11 => :b, 2 => :c)
      assert_equal(%w[1 2 11],                   db.keys)
      assert_equal([%w[1 a], %w[2 c], %w[11 b]], db.to_a)
    end
  end
  
  def test_each_key_iterates_through_keys_in_order_for_b_trees
    assert_forward_iteration(%w[a b c], :each_key)
    assert_reverse_iteration(%w[c b a], :each_key)
  end
  
  def test_each_iterates_through_key_value_pairs_in_order_for_b_trees
    assert_forward_iteration([%w[a 1], %w[b 2], %w[c 3]], :each)
    assert_reverse_iteration([%w[c 3], %w[b 2], %w[a 1]], :each)
  end
  
  def test_reverse_each_iterates_through_key_value_pairs_in_revserse_order
    assert_forward_iteration([%w[c 3], %w[b 2], %w[a 1]], :reverse_each)
    assert_reverse_iteration([%w[a 1], %w[b 2], %w[c 3]], :reverse_each)
  end
  
  def test_each_value_iterates_through_values_in_order_for_b_trees
    assert_forward_iteration(%w[1 2 3], :each_value)
    assert_reverse_iteration(%w[3 2 1], :each_value)
  end
  
  def test_delete_if_iterates_through_key_value_pairs_in_order_for_b_trees
    assert_forward_iteration([%w[a 1], %w[b 2], %w[c 3]], :delete_if)
    assert_reverse_iteration([%w[c 3], %w[b 2], %w[a 1]], :delete_if)
  end
  
  def test_fixed_length_databases_have_numerical_ordering_by_keys
    fdb do |db|
      db.update(3 => 300, 1 => 100, 2 => 200)
      assert_equal([1, 2, 3],                            db.keys)
      assert_equal([[1, "100"], [2, "200"], [3, "300"]], db.to_a)
    end
  end
  
  def test_each_key_iterates_through_keys_in_order_for_fixed_lengths
    assert_forward_iteration([1, 2, 3], :each_key, :fdb)
  end
  
  def test_each_iterates_through_key_value_pairs_in_order_for_fixed_lengths
    assert_forward_iteration([[1, "100"], [2, "200"], [3, "300"]], :each, :fdb)
  end
  
  def test_each_value_iterates_through_values_in_order_for_fixed_lengths
    assert_forward_iteration(%w[100 200 300], :each_value, :fdb)
  end
  
  def test_delete_if_iterates_through_key_value_pairs_in_order_for_fixed_lengths
    assert_forward_iteration( [[1, "100"], [2, "200"], [3, "300"]],
                              :delete_if,
                              :fdb )
  end
  
  #######
  private
  #######
  
  def assert_forward_iteration(expected_order, iterator, option = nil)
    remove_db_files
    if option == :fdb
      fdb do |db|
        db.update(3 => 300, 1 => 100, 2 => 200)
        actual_order = [ ]
        db.send(iterator) do |*args|
          actual_order << (args.size == 1 ? args.first : args)
        end
        assert_equal(expected_order, actual_order)
      end
    else
      bdb(:cmpfunc => option) do |db|
        db.update(:c => 3, :a => 1, :b => 2)
        actual_order = [ ]
        db.send(iterator) do |*args|
          actual_order << (args.size == 1 ? args.first : args)
        end
        assert_equal(expected_order, actual_order)
      end
    end
  end
    
  def assert_reverse_iteration(expected_order, iterator)
    assert_forward_iteration(expected_order, iterator, REVERSE_ORDER_CMPFUNC)
  end
end

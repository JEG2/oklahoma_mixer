require "test_helper"
require "shared/iteration_tests"

class TestIteration < Test::Unit::TestCase
  def setup
    @db     = hdb
    @keys   = %w[a b c]
    @values = @keys.map { |key| key * 2 }
    @keys.zip(@values) do |key, value|
      @db[key] = value
    end
  end
  
  def teardown
    @db.close
    remove_db_files
  end
  
  include IterationTests
end

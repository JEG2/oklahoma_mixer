require "test_helper"
require "shared/iteration_tests"

class TestDocumentIteration < Test::Unit::TestCase
  def setup
    @db     = tdb
    @keys   = %w[a b c]
    @values = @keys.map { |key|
      Hash[*@keys.map { |k| [key + k, "abc".index(k).to_s] }.flatten]
    }
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

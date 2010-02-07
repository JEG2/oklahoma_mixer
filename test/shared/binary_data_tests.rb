module BinaryDataTests
  def test_null_bytes_are_preserved_during_key_iteration
    @db.each_key do |key|
      assert_equal(@key, key)
    end
  end
  
  def test_null_bytes_are_preserved_during_iteration
    @db.each do |key, value|
      assert_equal(@key,   key)
      assert_equal(@value, value)
    end
  end
end
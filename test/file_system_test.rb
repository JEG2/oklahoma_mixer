require "test_helper"

class TestFileSystem < Test::Unit::TestCase
  def setup
    @db = hdb
  end
  
  def teardown
    @db.close
    remove_db_files
  end
  
  def test_creating_a_hash_database_creates_the_corresponding_file
    assert(File.exist?(db_path("tch")), "The HashDatabase file was not created")
  end
  
  def test_path_returns_the_path_the_database_was_created_with
    assert_equal(db_path("tch"), @db.path)
  end
  
  def test_file_size_returns_the_size_of_the_contents_on_disk
    @db[:data] = "X" * 1024
    assert_operator(@db.file_size, :>, 1024)
  end
  
  def test_flush_and_aliases_force_contents_to_be_written_to_disk
    @db[:data] = "X" * 1024
    @db.flush
    assert_operator(File.size(@db.path), :>, 1024)
    @db[:more_data] = "X" * 1024
    @db.sync
    assert_operator(File.size(@db.path), :>, 2048)
    @db[:even_more_data] = "X" * 1024
    @db.fsync
    assert_operator(File.size(@db.path), :>, 3072)
  end
  
  def test_copy_and_backup_create_a_backup_copy_of_the_database_file
    @db[:data] = "X" * 1024
    old_path   = @db.path
    old_ext    = File.extname(old_path)
    new_path   = "#{File.basename(old_path, old_ext)}_2#{old_ext}"
    new_path_2 = "#{File.basename(old_path, old_ext)}_3#{old_ext}"
    assert(@db.copy(new_path), "Database could not be copied")
    new_db = OKMixer::HashDatabase.new(new_path)
    assert_equal(@db.to_a.sort, new_db.to_a.sort)
    assert(@db.backup(new_path_2), "Database could not be copied")
    new_db_2 = OKMixer::HashDatabase.new(new_path_2)
    assert_equal(@db.to_a.sort, new_db_2.to_a.sort)
  ensure
    File.unlink(new_path)   if new_path   and File.exist? new_path
    File.unlink(new_path_2) if new_path_2 and File.exist? new_path_2
    new_db.close            if new_db
    new_db_2.close          if new_db_2
  end
  
  def test_defrag_removes_wholes_in_the_database_file
    # load some data
    data = "X" * 1024
    100.times do |i|
      @db[i] = data
    end
    # delete some data
    (0...100).sort_by { rand }.first(10).each do |i|
      @db.delete(i)
    end
    # push changes to disk
    @db.flush
    # defragment the database file
    old_size = File.size(@db.path)
    @db.defrag
    assert_operator(old_size, :>, File.size(@db.path))
  end
end

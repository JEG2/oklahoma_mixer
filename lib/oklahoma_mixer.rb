module OklahomaMixer
  VERSION = "0.3.0"
  
  autoload :HashDatabase,        "oklahoma_mixer/hash_database"
  autoload :BTreeDatabase,       "oklahoma_mixer/b_tree_database"
  autoload :FixedLengthDatabase, "oklahoma_mixer/fixed_length_database"
  autoload :TableDatabase,       "oklahoma_mixer/table_database"
  
  def self.open(path, *args)
    db_class = case File.extname(path).downcase
               when ".tch" then HashDatabase
               when ".tcb" then BTreeDatabase
               when ".tcf" then FixedLengthDatabase
               when ".tct" then TableDatabase
               else             fail ArgumentError, "unsupported database type"
               end
    db       = db_class.new(path, *args)
    if block_given?
      begin
        yield db
      ensure
        db.close
      end
    else
      db
    end
  end
end
OKMixer = OklahomaMixer

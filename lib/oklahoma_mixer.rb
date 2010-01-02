require "ffi"

require "oklahoma_mixer/error"
require "oklahoma_mixer/utilities"

require "oklahoma_mixer/extensible_string/c"
require "oklahoma_mixer/extensible_string"
require "oklahoma_mixer/array_list/c"
require "oklahoma_mixer/array_list"
require "oklahoma_mixer/cursor/c"
require "oklahoma_mixer/cursor"

require "oklahoma_mixer/hash_database/c"
require "oklahoma_mixer/hash_database"
require "oklahoma_mixer/b_tree_database/c"
require "oklahoma_mixer/b_tree_database"

module OklahomaMixer
  VERSION = "0.1.0"
  
  def self.open(path, *args)
    db_class = case File.extname(path).downcase
               when ".tch" then HashDatabase
               when ".tcb" then BTreeDatabase
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

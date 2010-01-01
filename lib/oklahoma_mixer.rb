require "ffi"

require "oklahoma_mixer/error"
require "oklahoma_mixer/utilities"

require "oklahoma_mixer/extensible_string/c"
require "oklahoma_mixer/extensible_string"
require "oklahoma_mixer/array_list/c"
require "oklahoma_mixer/array_list"

require "oklahoma_mixer/hash_database/c"
require "oklahoma_mixer/hash_database"

module OklahomaMixer
  VERSION = "0.1.0"
  
  def self.open(path, *args)
    db = case File.extname(path).downcase
         when ".tch" then HashDatabase.new(path, *args)
         else             fail ArgumentError, "unsupported database type"
         end
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

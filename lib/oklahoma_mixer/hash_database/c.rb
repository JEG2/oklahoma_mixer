require "oklahoma_mixer/utilities"

module OklahomaMixer
  class HashDatabase
    module C  # :nodoc:
      extend OklahomaMixer::Utilities::FFIDSL

      prefix :tchdb
      
      def_hash_database_consts_and_funcs

      func :name    => :tune,
           :args    => [:pointer, :int64, :int8, :int8, OPTS],
           :returns => :bool
      func :name    => :setcache,
           :args    => [:pointer, :int32],
           :returns => :bool
      func :name    => :optimize,
           :args    => [:pointer, :int64, :int8, :int8, OPTS],
           :returns => :bool
           
      func :name    => :putasync,
           :args    => [:pointer, :pointer, :int, :pointer, :int],
           :returns => :bool

      func :name    => :iterinit,
           :args    => :pointer,
           :returns => :bool
      func :name    => :iternext,
           :args    => [:pointer, :pointer],
           :returns => :pointer
      func :name    => :iternext3,
           :args    => [:pointer, :pointer, :pointer],
           :returns => :bool
    end
  end
end

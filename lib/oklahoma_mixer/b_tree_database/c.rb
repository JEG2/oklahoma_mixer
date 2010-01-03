module OklahomaMixer
  class BTreeDatabase < HashDatabase
    module C  # :nodoc:
      extend OklahomaMixer::Utilities::FFIDSL

      prefix :tcbdb
      
      def_hash_consts_and_funcs

      call :name    => :TCCMP,
           :args    => [:pointer, :int, :pointer, :int, :pointer],
           :returns => :int
      func :name    => :setcmpfunc,
           :args    => [:pointer, :TCCMP, :pointer],
           :returns => :bool
      func :name    => :tune,
           :args    => [:pointer, :int32, :int32, :int64, :int8, :int8, OPTS],
           :returns => :bool
      func :name    => :setcache,
           :args    => [:pointer, :int32, :int32],
           :returns => :bool
      func :name    => :optimize,
           :args    => [:pointer, :int32, :int32, :int64, :int8, :int8, OPTS],
           :returns => :bool

      func :name    => :range,
           :args    => [:pointer, :pointer, :int, :bool, :pointer, :int, :bool,
                        :int],
           :returns => :pointer
    end
  end
end

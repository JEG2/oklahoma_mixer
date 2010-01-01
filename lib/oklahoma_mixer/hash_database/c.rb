module OklahomaMixer
  class HashDatabase
    module C  # :nodoc:
      extend OklahomaMixer::Utilities::FFIDSL

      MODES = enum :HDBOREADER,  1 << 0,
                   :HDBOWRITER,  1 << 1,
                   :HDBOCREAT,   1 << 2,
                   :HDBOTRUNC,   1 << 3,
                   :HDBONOLCK,   1 << 4,
                   :HDBOLCKNB,   1 << 5,
                   :HDBOTSYNC,   1 << 6
      OPTS  = enum :HDBTLARGE,   1 << 0,
                   :HDBTDEFLATE, 1 << 1,
                   :HDBTBZIP,    1 << 2,
                   :HDBTTCBS,    1 << 3
      
      prefix :tchdb
      
      def_new_and_del_funcs
      func :name    => :open,
           :args    => [:pointer, :string, MODES],
           :returns => :bool
      func :name    => :sync,
           :args    => :pointer,
           :returns => :bool
      func :name    => :fsiz,
           :args    => :pointer,
           :returns => :uint64
      func :name    => :copy,
           :args    => [:pointer, :string],
           :returns => :bool
      func :name    => :defrag,
           :args    => [:pointer, :int64],
           :returns => :bool

      func :name    => :ecode,
           :args    => :pointer,
           :returns => :int
      func :name    => :errmsg,
           :args    => :int,
           :returns => :string

      func :name    => :setmutex,
           :args    => :pointer,
           :returns => :bool
      func :name    => :tune,
           :args    => [:pointer, :int64, :int8, :int8, OPTS],
           :returns => :bool
      func :name    => :setcache,
           :args    => [:pointer, :int32],
           :returns => :bool
      func :name    => :setxmsiz,
           :args    => [:pointer, :int64],
           :returns => :bool
      func :name    => :setdfunit,
           :args    => [:pointer, :int32],
           :returns => :bool
      func :name    => :optimize,
           :args    => [:pointer, :int64, :int8, :int8, OPTS],
           :returns => :bool

      func :name    => :put,
           :args    => [:pointer, :pointer, :int, :pointer, :int],
           :returns => :bool
      func :name    => :putkeep,
           :args    => [:pointer, :pointer, :int, :pointer, :int],
           :returns => :bool
      func :name    => :putcat,
           :args    => [:pointer, :pointer, :int, :pointer, :int],
           :returns => :bool
      func :name    => :putasync,
           :args    => [:pointer, :pointer, :int, :pointer, :int],
           :returns => :bool
      call :name    => :TCPDPROC,
           :args    => [:pointer, :int, :pointer, :pointer],
           :returns => :pointer
      func :name    => :putproc,
           :args    => [:pointer, :pointer, :int, :pointer, :int, :TCPDPROC,
                        :pointer],
           :returns => :bool
      func :name    => :addint,
           :args    => [:pointer, :pointer, :int, :int],
           :returns => :int
      func :name    => :adddouble,
           :args    => [:pointer, :pointer, :int, :double],
           :returns => :double
      func :name    => :out,
           :args    => [:pointer, :pointer, :int],
           :returns => :bool
      func :name    => :get,
           :args    => [:pointer, :pointer, :int, :pointer],
           :returns => :pointer
      func :name    => :vanish,
           :args    => :pointer,
           :returns => :bool
      func :name    => :vanish,
           :args    => :pointer,
           :returns => :bool
      func :name    => :fwmkeys,
           :args    => [:pointer, :pointer, :int, :int],
           :returns => :pointer
      func :name    => :rnum,
           :args    => :pointer,
           :returns => :uint64

      func :name    => :iterinit,
           :args    => [:pointer],
           :returns => :bool
      func :name    => :iternext,
           :args    => [:pointer, :pointer],
           :returns => :pointer
      func :name    => :iternext3,
           :args    => [:pointer, :pointer, :pointer],
           :returns => :bool

      func :name    => :tranbegin,
           :args    => :pointer,
           :returns => :bool
      func :name    => :trancommit,
           :args    => :pointer,
           :returns => :bool
      func :name    => :tranabort,
           :args    => :pointer,
           :returns => :bool
    end
  end
end

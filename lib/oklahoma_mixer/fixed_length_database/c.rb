require "oklahoma_mixer/utilities"

module OklahomaMixer
  class FixedLengthDatabase < HashDatabase
    module C  # :nodoc:
      extend OklahomaMixer::Utilities::FFIDSL
      
      IDS = enum :FDBIDMIN,  -1,
                 :FDBIDPREV, -2,
                 :FDBIDMAX,  -3,
                 :FDBIDNEXT, -4

      prefix :tcfdb
      
      def_core_database_consts_and_funcs

      func :name    => :tune,
           :args    => [:pointer, :int32, :int64],
           :returns => :bool
      func :name    => :optimize,
           :args    => [:pointer, :int32, :int64],
           :returns => :bool

      func :name    => :put,
           :args    => [:pointer, :int64, :pointer, :int],
           :returns => :bool
      func :name    => :putkeep,
           :args    => [:pointer, :int64, :pointer, :int],
           :returns => :bool
      func :name    => :putcat,
           :args    => [:pointer, :int64, :pointer, :int],
           :returns => :bool
      call :name    => :TCPDPROC,
           :args    => [:pointer, :int, :pointer, :pointer],
           :returns => :pointer
      func :name    => :putproc,
           :args    => [:pointer, :int64, :pointer, :int, :TCPDPROC, :pointer],
           :returns => :bool
      func :name    => :addint,
           :args    => [:pointer, :int64, :int],
           :returns => :int
      func :name    => :adddouble,
           :args    => [:pointer, :int64, :double],
           :returns => :double
      func :name    => :out,
           :args    => [:pointer, :int64],
           :returns => :bool
      func :name    => :get,
           :args    => [:pointer, :int64, :pointer],
           :returns => :pointer

      func :name    => :iterinit,
           :args    => :pointer,
           :returns => :bool
      func :name    => :iternext,
           :args    => :pointer,
           :returns => :uint64

      func :name    => :range,
           :args    => [:pointer, :int64, :int64, :int, :pointer],
           :returns => :pointer
    end
  end
end

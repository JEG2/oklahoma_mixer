require "oklahoma_mixer/utilities"

module OklahomaMixer
  class TableDatabase < HashDatabase
    module C  # :nodoc:
      extend OklahomaMixer::Utilities::FFIDSL
      
      prefix :tctdb

      const :OPTS, %w[TLARGE TDEFLATE TBZIP TTCBS]
      INDEXES  = enum :TDBITLEXICAL,  0,
                      :TDBITDECIMAL,  1,
                      :TDBITTOKEN,    2,
                      :TDBITQGRAM,    3,
                      :TDBITOPT,      9998,
                      :TDBITVOID,     9999,
                      :TDBITKEEP,     1 << 24
      FLAGS    = enum :TDBQPPUT,      1 << 0,
                      :TDBQPOUT,      1 << 1,
                      :TDBQPSTOP,     1 << 24
      SEARCHES = enum :TDBMSUNION, 0,
                      :TDBMSISECT, 1,
                      :TDBMSDIFF,  2
      
      
      def_core_database_consts_and_funcs
      
      func :name    => :tune,
           :args    => [:pointer, :int64, :int8, :int8, OPTS],
           :returns => :bool
      func :name    => :setcache,
           :args    => [:pointer, :int32, :int32, :int32],
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
           :args    => [:pointer, :pointer, :int, :pointer],
           :returns => :bool
      func :name    => :putkeep,
           :args    => [:pointer, :pointer, :int, :pointer],
           :returns => :bool
      func :name    => :putcat,
           :args    => [:pointer, :pointer, :int, :pointer],
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
           :args    => [:pointer, :pointer, :int],
           :returns => :pointer
      func :name    => :fwmkeys,
           :args    => [:pointer, :pointer, :int, :int],
           :returns => :pointer
      func :name    => :genuid,
           :args    => :pointer,
           :returns => :int64
      
      func :name    => :iterinit,
           :args    => :pointer,
           :returns => :bool
      func :name    => :iternext,
           :args    => [:pointer, :pointer],
           :returns => :pointer
      func :name    => :iternext3,
           :args    => :pointer,
           :returns => :pointer

      func :name    => :setindex,
           :args    => [:pointer, :string, INDEXES],
           :returns => :bool

      func :name    => :qrysearch,
           :args    => :pointer,
           :returns => :pointer
      call :name    => :TDBQRYPROC,
           :args    => [:pointer, :int, :pointer, :pointer],
           :returns => :int
      func :name    => :qryproc,
           :args    => [:pointer, :TDBQRYPROC, :pointer],
           :returns => :bool
      func :name    => :metasearch,
           :args    => [:pointer, :int, SEARCHES],
           :returns => :pointer
    end
  end
end

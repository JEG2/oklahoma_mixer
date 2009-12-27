require "oklahoma_mixer/utilities"

module OklahomaMixer
  class HashDatabase
    module C
      extend OklahomaMixer::Utilities::FFIDSL
      
      prefix :tchdb
      
      func :name    => :new,
           :returns => :pointer
      func :name    => :del,
           :args    => :pointer
      func :name    => :open,
           :args    => [:pointer, :string, :int],
           :returns => :bool
      func :name    => :close,
           :args    => :pointer,
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
      func :name    => :addint,
           :args    => [:pointer, :pointer, :int, :int],
           :returns => :int
      func :name    => :adddouble,
           :args    => [:pointer, :pointer, :int, :double],
           :returns => :double
      func :name    => :get,
           :args    => [:pointer, :pointer, :int, :pointer],
           :returns => :pointer

      func :name    => :iterinit,
           :args    => [:pointer],
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

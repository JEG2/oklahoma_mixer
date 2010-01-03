module OklahomaMixer
  class Cursor
    module C  # :nodoc:
      extend OklahomaMixer::Utilities::FFIDSL

      prefix :tcbdbcur
      
      func :name    => :new,
           :args    => :pointer,
           :returns => :pointer
      func :name    => :del,
           :args    => :pointer

      func :name    => :first,
           :args    => :pointer,
           :returns => :bool
      func :name    => :last,
           :args    => :pointer,
           :returns => :bool
      func :name    => :jump,
           :args    => [:pointer, :pointer, :int],
           :returns => :bool
      func :name    => :next,
           :args    => :pointer,
           :returns => :bool
      func :name    => :prev,
           :args    => :pointer,
           :returns => :bool

      func :name    => :key,
           :args    => [:pointer, :pointer],
           :returns => :pointer
      func :name    => :val,
           :args    => [:pointer, :pointer],
           :returns => :pointer
      func :name    => :rec,
           :args    => [:pointer, :pointer, :pointer],
           :returns => :bool

      func :name    => :out,
           :args    => :pointer,
           :returns => :bool
    end
  end
end

require "oklahoma_mixer/utilities"

module OklahomaMixer
  class ArrayList
    module C  # :nodoc:
      extend OklahomaMixer::Utilities::FFIDSL

      prefix :tclist
      
      func :name    => :new2,
           :args    => :int,
           :returns => :pointer
      func :name    => :del,
           :args    => :pointer

      func :name    => :num,
           :args    => :pointer,
           :returns => :int
      func :name    => :val,
           :args    => [:pointer, :int, :pointer],
           :returns => :pointer
      
      func :name    => :push,
           :args    => [:pointer, :pointer, :int]
    end
  end
end

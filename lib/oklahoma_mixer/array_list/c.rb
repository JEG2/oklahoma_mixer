module OklahomaMixer
  class ArrayList
    module C  # :nodoc:
      extend OklahomaMixer::Utilities::FFIDSL

      prefix :tclist
      
      def_new_and_del_funcs
      func :name    => :new2,
           :args    => :int,
           :returns => :pointer
      
      func :name    => :shift,
           :args    => [:pointer, :pointer],
           :returns => :pointer
      func :name    => :push,
           :args    => [:pointer, :pointer, :int]
    end
  end
end

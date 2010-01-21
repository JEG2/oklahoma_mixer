module OklahomaMixer
  class HashMap
    module C  # :nodoc:
      extend OklahomaMixer::Utilities::FFIDSL

      prefix :tcmap
      
      def_new_and_del_funcs
      
      func :name    => :put,
           :args    => [:pointer, :pointer, :int, :pointer, :int]
      func :name    => :get,
           :args    => [:pointer, :pointer, :int, :pointer],
           :returns => :pointer

      func :name    => :iterinit,
           :args    => :pointer
      func :name    => :iternext,
           :args    => [:pointer, :pointer],
           :returns => :pointer
    end
  end
end

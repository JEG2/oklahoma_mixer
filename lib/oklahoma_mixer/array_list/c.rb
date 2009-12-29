module OklahomaMixer
  class ArrayList
    module C
      extend OklahomaMixer::Utilities::FFIDSL

      prefix :tclist
      
      def_new_and_del_funcs
      
      func :name    => :shift,
           :args    => [:pointer, :pointer],
           :returns => :pointer
    end
  end
end

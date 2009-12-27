module OklahomaMixer
  class ExtensibleString
    module C
      extend OklahomaMixer::Utilities::FFIDSL

      prefix :tcxstr
      
      func :name    => :new,
           :returns => :pointer
      func :name    => :del,
           :args    => :pointer

      func :name    => :ptr,
           :args    => :pointer,
           :returns => :pointer
      func :name    => :size,
           :args    => :pointer,
           :returns => :int
    end
  end
end

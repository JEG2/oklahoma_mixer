require "oklahoma_mixer/utilities"

module OklahomaMixer
  class ExtensibleString
    module C  # :nodoc:
      extend OklahomaMixer::Utilities::FFIDSL

      prefix :tcxstr
      
      def_new_and_del_funcs

      func :name    => :ptr,
           :args    => :pointer,
           :returns => :pointer
      func :name    => :size,
           :args    => :pointer,
           :returns => :int
    end
  end
end

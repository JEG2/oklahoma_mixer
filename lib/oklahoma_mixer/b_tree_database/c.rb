module OklahomaMixer
  class BTreeDatabase < HashDatabase
    module C  # :nodoc:
      extend OklahomaMixer::Utilities::FFIDSL

      prefix :tcbdb
      
      def_hash_consts_and_funcs

      # func :name    => :tune,
      #      :args    => [:pointer, :int64, :int8, :int8, OPTS],
      #      :returns => :bool
      # func :name    => :setcache,
      #      :args    => [:pointer, :int32],
      #      :returns => :bool
      # func :name    => :optimize,
      #      :args    => [:pointer, :int64, :int8, :int8, OPTS],
      #      :returns => :bool
    end
  end
end

require "ffi"

module OklahomaMixer
  class HashDatabase
    module C
      extend FFI::Library
      begin
        ffi_lib(
          *Array(
            ENV.fetch(
              "TOKYO_CABINET_LIB",
              Dir["/{opt,usr}/{,local/}lib{,64}/libtokyocabinet.{dylib,so*}"]
            )
          )
        )
      rescue LoadError
        fail "Tokyo Cabinet could not be loaded "           +
             "(you can install it from http://1978th.net/ " +
             "and set the TOKYO_CABINET_LIB environment variable to its path)"
      end
      
      def self.prefix(new_prefix = nil)
        @prefix = new_prefix unless new_prefix.nil?
        defined?(@prefix) and @prefix
      end
      
      def self.func(details)
        args =  [ ]
        args << details.fetch(:alias, details[:name])
        args << "#{prefix}#{details[:name]}".to_sym
        args << Array(details[:args])
        args << details.fetch(:returns, :void)
        attach_function(*args)
      end
      
      prefix :tc
      
      func :name => :free,
           :args => [:pointer]
      
      prefix :tchdb
      
      func :name    => :new,
           :returns => :pointer
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
    end
  end
end

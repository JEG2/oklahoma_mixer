require "ffi"

module OklahomaMixer
  module Utilities
    module FFIDSL
      def self.extended(ffi_interface)
        ffi_interface.extend(FFI::Library)
        ffi_interface.ffi_lib(
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
      
      def prefix(new_prefix = nil)
        @prefix = new_prefix unless new_prefix.nil?
        defined?(@prefix) and @prefix
      end
      
      def func(details)
        args =  [ ]
        args << details.fetch(:alias, details[:name])
        args << "#{prefix}#{details[:name]}".to_sym
        args << Array(details[:args])
        args << details.fetch(:returns, :void)
        attach_function(*args)
      end
    end
    
    def self.temp_int
      int = FFI::MemoryPointer.new(:int)
      yield int
    ensure
      int.free if int
    end
    
    def self.temp_xstr
      xstr = ExtensibleString.new
      yield xstr
    ensure
      xstr.delete if xstr
    end
    
    extend FFIDSL
    
    prefix :tc
    
    func :name => :free,
         :args => [:pointer]
  end
end

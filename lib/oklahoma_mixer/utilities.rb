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
      
      def read_from_func(func, *args)
        Utilities.temp_int do |size|
          begin
            args    << size
            pointer =  send(func, *args)
            pointer.address.zero? ? nil : pointer.get_bytes(0, size.get_int(0))
          ensure
            Utilities.free(pointer) if pointer
          end
        end
      end
      
      def call(details)
        args =  [ ]
        args << details[:name]
        args << Array(details[:args])
        args << details.fetch(:returns, :void)
        callback(*args)
      end
      
      def def_new_and_del_funcs
        func :name    => :new,
             :returns => :pointer
        func :name    => :del,
             :args    => :pointer
      end
    end
    
    int_min = `getconf INT_MIN 2>&1`[/-\d+/]
    unless INT_MIN = int_min && int_min.to_i
      warn "set OKMixer::Utilities::INT_MIN before using counters"
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
      xstr.free if xstr
    end
    
    extend FFIDSL
    
    prefix :tc
    
    func :name => :free,
         :args => :pointer
  end
end

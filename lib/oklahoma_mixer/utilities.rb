module OklahomaMixer
  module Utilities  # :nodoc:
    module FFIDSL   # :nodoc:
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
      
      def const(name, values)
        const_set( name, enum( *(0...values.size).map { |i|
          ["#{prefix.to_s[2..-1].upcase}#{values[i]}".to_sym, 1 << i]
        }.flatten ) )
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
        no_free = args.shift if args.first.is_a?(Symbol) and
                                args.first == :no_free
        Utilities.temp_int do |size|
          begin
            args    << size
            pointer =  send(func, *args)
            pointer.address.zero? ? nil : pointer.get_bytes(0, size.get_int(0))
          ensure
            Utilities.free(pointer) if pointer and not no_free
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
      
      def def_core_database_consts_and_funcs
        const :MODES, %w[OREADER OWRITER OCREAT OTRUNC ONOLCK OLCKNB OTSYNC]

        def_new_and_del_funcs
        
        func :name    => :open,
             :args    => [:pointer, :string, const_get(:MODES)],
             :returns => :bool
        func :name    => :sync,
             :args    => :pointer,
             :returns => :bool
        func :name    => :fsiz,
             :args    => :pointer,
             :returns => :uint64
        func :name    => :copy,
             :args    => [:pointer, :string],
             :returns => :bool

        func :name    => :ecode,
             :args    => :pointer,
             :returns => :int
        func :name    => :errmsg,
             :args    => :int,
             :returns => :string

        func :name    => :setmutex,
             :args    => :pointer,
             :returns => :bool

        func :name    => :vanish,
             :args    => :pointer,
             :returns => :bool
        func :name    => :rnum,
             :args    => :pointer,
             :returns => :uint64

        func :name    => :tranbegin,
             :args    => :pointer,
             :returns => :bool
        func :name    => :trancommit,
             :args    => :pointer,
             :returns => :bool
        func :name    => :tranabort,
             :args    => :pointer,
             :returns => :bool
      end
      
      def def_hash_database_consts_and_funcs
        const :OPTS, %w[TLARGE TDEFLATE TBZIP TTCBS]

        def_core_database_consts_and_funcs

        func :name    => :defrag,
             :args    => [:pointer, :int64],
             :returns => :bool

        func :name    => :setxmsiz,
             :args    => [:pointer, :int64],
             :returns => :bool
        func :name    => :setdfunit,
             :args    => [:pointer, :int32],
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
        call :name    => :TCPDPROC,
             :args    => [:pointer, :int, :pointer, :pointer],
             :returns => :pointer
        func :name    => :putproc,
             :args    => [:pointer, :pointer, :int, :pointer, :int, :TCPDPROC,
                          :pointer],
             :returns => :bool
        func :name    => :addint,
             :args    => [:pointer, :pointer, :int, :int],
             :returns => :int
        func :name    => :adddouble,
             :args    => [:pointer, :pointer, :int, :double],
             :returns => :double
        func :name    => :out,
             :args    => [:pointer, :pointer, :int],
             :returns => :bool
        func :name    => :get,
             :args    => [:pointer, :pointer, :int, :pointer],
             :returns => :pointer
        func :name    => :fwmkeys,
             :args    => [:pointer, :pointer, :int, :int],
             :returns => :pointer
      end
    end
    
    unless int_min = `getconf INT_MIN 2>&1`[/-\d+/]
      warn "set OKMixer::Utilities::INT_MIN before using the :add storage mode"
    end
    INT_MIN = int_min && int_min.to_i
    
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

    def self.temp_list(size)
      list = ArrayList.new(size)
      yield list
    ensure
      list.free if list
    end

    def self.temp_map
      map = HashMap.new
      yield map
    ensure
      map.free if map
    end
    
    extend FFIDSL
    
    prefix :tc
    
    func :name    => :malloc,
         :args    => :size_t,
         :returns => :pointer
    func :name    => :free,
         :args    => :pointer
  end
end

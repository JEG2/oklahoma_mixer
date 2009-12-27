require "pathname"
require "rbconfig"
require "stringio"

require "test/unit"

require "rubygems"  # for FFI

require "oklahoma_mixer"

module TestHelper
  def run_ruby(code)
    # find Ruby and OklahomaMixer
    exe = File::join( *Config::CONFIG.values_at( *%w[ bindir
                                                      ruby_install_name ] ) ) <<
          Config::CONFIG["EXEEXT"]
    lib = File.join(File.dirname(__FILE__), *%w[.. lib])

    # escape for the shell
    [exe, lib].each do |path|
      path.gsub!(/(?=[^a-zA-Z0-9_.\/\-\x7F-\xFF\n])/n, '\\')
      path.gsub!(/\n/, "'\n'")
      path.sub!(/\A\z/, "''")
    end

    # run the program and read the results
    open("| #{exe} -I #{lib} -rubygems -r oklahoma_mixer", "r+") do |program|
      program << code
      program.close_write
      @output = program.read.to_s
    end
  end
  
  def capture_stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = STDERR
  end
  
  def capture_args(receiver, method)
    called_with = nil
    singleton   = class << receiver; self end
    singleton.send(:define_method, method) do |*args|
      called_with = args
    end
    yield
    called_with
  end
  
  def db_path(ext)
    File.join( File.dirname(__FILE__),
               "#{self.class.to_s.sub(/\ATest/, '').downcase}.#{ext}" )
  end

  def hdb(options = { })
    db = OKMixer::HashDatabase.new(db_path("tch"), options)
    if block_given?
      begin
        yield db
      ensure
        db.close
      end
    else
      db
    end
  end
  
  def remove_db_files
    Dir.glob(db_path("*")) do |file|
      File.unlink(file)
    end
  end
end
Test::Unit::TestCase.send(:include, TestHelper)

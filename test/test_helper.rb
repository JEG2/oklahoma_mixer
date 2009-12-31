require "stringio"
require "test/unit"

require "rubygems"  # for FFI

require "oklahoma_mixer"

module TestHelper
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

  def hdb(*args)
    db = OKMixer::HashDatabase.new(db_path("tch"), *args)
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

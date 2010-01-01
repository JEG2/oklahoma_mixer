require "rake/testtask"
require "rake/rdoctask"
require "rubygems"
require "rake/gempackagetask"

desc "Default task:  run all tests"
task :default => :test

Rake::TestTask.new do |test|
  test.libs    << "test"
  test.pattern =  "test/*_test.rb"
  test.warning =  true
  test.verbose =  true
end

Rake::RDocTask.new do |rdoc|
	rdoc.main               = "README.rdoc"
	rdoc.rdoc_dir           = "doc/html"
	rdoc.title              = "Oklahoma Mixer Documentation"
	rdoc.rdoc_files.include   *%w[ README.rdoc  INSTALL.rdoc
	                               TODO.rdoc    CHANGELOG.rdoc
	                               AUTHORS.rdoc MIT-LICENSE
	                               lib/ ]
end

spec = Gem::Specification.new do |spec|
	spec.name    = "oklahoma_mixer"
	spec.version = File.read(
                   File.join(File.dirname(__FILE__), *%w[lib oklahoma_mixer.rb])
                 )[/^\s*VERSION\s*=\s*(['"])(\d\.\d\.\d)\1/, 2]

	spec.platform = Gem::Platform::RUBY
	spec.summary  = "An full featured and robust FFI interface to Tokyo Cabinet."

	spec.test_files = Dir.glob("test/*_test.rb")
	spec.files      = Dir.glob("{lib,test}/**/*.rb") +
	                  Dir.glob("*.rdoc")             +
	                  %w[MIT-LICENSE Rakefile]

	spec.has_rdoc         = true
	spec.extra_rdoc_files = %w[ README.rdoc  INSTALL.rdoc
	                            TODO.rdoc    CHANGELOG.rdoc
	                            AUTHORS.rdoc MIT-LICENSE ]
	spec.rdoc_options     << "--title" << "Oklahoma Mixer Documentation" <<
	                         "--main"  << "README.rdoc"

	spec.require_path = "lib"

	spec.author      = "James Edward Gray II"
	spec.email       = "james@graysoftinc.com"
	spec.homepage    = "http://github.com/JEG2/oklahoma_mixer"
	spec.description = <<END_DESC
Oklahoma Mixer is a intended to be an all inclusive wrapper for Tokyo Cabinet.
It provides Rubyish interfaces for all database types and supports the full
range of features provided.
END_DESC
end
Rake::GemPackageTask.new(spec) do |pkg|
  # do nothing:  the spec is all we need
end

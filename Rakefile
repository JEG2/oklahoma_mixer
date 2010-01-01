require "rake/testtask"
require "rake/rdoctask"

desc "Default task:  run all tests"
task :default => :test

Rake::TestTask.new do |test|
  test.libs    << "test"
  test.pattern =  "test/**/*_test.rb"
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

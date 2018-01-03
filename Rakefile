require 'rubygems'
require 'rake'

$:.unshift File.expand_path('../lib', __FILE__)
require 'numerizer/version'

def version
  Numerizer::VERSION
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.test_files = Dir['test/test_*.rb']
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

desc "Release Numerizer version #{version}"
task :release => :build do
  unless `git branch` =~ /^\* master$/
    puts "You must be on the master branch to release!"
    exit!
  end
  sh "git commit --allow-empty -a -m 'Release #{version}'"
  sh "git tag v#{version}"
  sh "git push origin master"
  sh "git push origin v#{version}"
  sh "gem push pkg/numerizer-#{version}.gem"
end

desc 'Build a gem from the gemspec'
task :build do
  FileUtils.mkdir_p 'pkg'
  sh 'gem build numerizer.gemspec'
  FileUtils.mv("./numerizer-#{version}.gem", "pkg")
end


task :default => :test

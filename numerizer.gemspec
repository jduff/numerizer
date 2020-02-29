$:.unshift File.expand_path('../lib', __FILE__)
require 'numerizer/version'

Gem::Specification.new do |s|
  s.name = "numerizer"
  s.version = Numerizer::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["John Duff"]
  s.date = "2014-04-23"
  s.description = "Numerizer is a gem to help with parsing numbers in natural language from strings (ex forty two). It was extracted from the awesome Chronic gem http://github.com/evaryont/chronic."
  s.email = "duff.john@gmail.com"
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]
  s.files = `git ls-files`.split($/)
  s.test_files = `git ls-files -- test`.split($/)
  s.homepage = "http://github.com/jduff/numerizer"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.2.2"
  s.summary = "Numerizer is a gem to help with parsing numbers in natural language from strings (ex forty two)."

  s.add_development_dependency 'rake', '~> 13'
  s.add_development_dependency 'minitest', '~> 5.0'
end


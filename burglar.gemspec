require 'English'
$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'burglar/version'

Gem::Specification.new do |s|
  s.name        = 'burglar'
  s.version     = Burglar::VERSION
  s.date        = Time.now.strftime('%Y-%m-%d')
  s.required_ruby_version = '>= 2.5.0'

  s.summary     = 'Tool for parsing data from bank websites'
  s.description = 'Tool for parsing data from bank websites'
  s.authors     = ['Les Aker']
  s.email       = 'me@lesaker.org'
  s.homepage    = 'https://github.com/akerl/burglar'
  s.license     = 'MIT'

  s.files       = `git ls-files`.split
  s.test_files  = `git ls-files spec/*`.split
  s.executables = ['burglar']

  s.add_dependency 'cymbal', '~> 2.0.0'
  s.add_dependency 'libledger', '~> 0.0.8'
  s.add_dependency 'logcabin', '~> 0.1.3'
  s.add_dependency 'mercenary', '~> 0.4.0'

  s.add_development_dependency 'codecov', '~> 0.6.0'
  s.add_development_dependency 'goodcop', '~> 0.9.7'
  s.add_development_dependency 'rake', '~> 13.0.6'
  s.add_development_dependency 'rspec', '~> 3.12.0'
end

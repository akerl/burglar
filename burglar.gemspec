require 'English'
$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'burglar/version'

Gem::Specification.new do |s|
  s.name        = 'burglar'
  s.version     = Burglar::VERSION
  s.date        = Time.now.strftime('%Y-%m-%d')

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
  s.add_dependency 'libledger', '~> 0.0.3'
  s.add_dependency 'logcabin', '~> 0.1.3'
  s.add_dependency 'mercenary', '~> 0.3.4'

  s.add_development_dependency 'codecov', '~> 0.1.1'
  s.add_development_dependency 'fuubar', '~> 2.4.1'
  s.add_development_dependency 'goodcop', '~> 0.7.1'
  s.add_development_dependency 'rake', '~> 12.3.0'
  s.add_development_dependency 'rspec', '~> 3.8.0'
  s.add_development_dependency 'rubocop', '~> 0.74.0'
end

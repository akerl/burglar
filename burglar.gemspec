Gem::Specification.new do |s|
  s.name        = 'burglar'
  s.version     = '0.0.1'
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

  s.add_dependency 'mercenary', '~> 0.3.4'
  s.add_dependency 'logcabin', '~> 0.1.3'
  s.add_dependency 'cymbal', '~> 1.0.0'
  s.add_dependency 'libledger', '~> 0.0.3'

  s.add_development_dependency 'rubocop', '~> 0.51.0'
  s.add_development_dependency 'goodcop', '~> 0.1.0'
  s.add_development_dependency 'rake', '~> 12.1.0'
  s.add_development_dependency 'codecov', '~> 0.1.1'
  s.add_development_dependency 'rspec', '~> 3.7.0'
  s.add_development_dependency 'fuubar', '~> 2.2.0'
end

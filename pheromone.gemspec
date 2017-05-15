# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pheromone/version'

Gem::Specification.new do |spec|
  spec.name          = 'pheromone'
  spec.version       = Pheromone::VERSION
  spec.authors       = ['Ankita Gupta']
  spec.email         = ['ankitagupta12391@gmail.com']

  spec.summary       = %q{Transmits messages to kafka from active record}
  spec.description   = %q{Sends messages to kafka using different formats and strategies}
  spec.homepage      = 'https://rubygems.org/'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files         = Dir["{lib}/**/*.rb", "bin/*", "LICENSE", "*.md"]
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '~> 5.0.0'
  spec.add_dependency 'activerecord', '~> 5.0.0'
  spec.add_dependency 'waterdrop', '~> 0.3.2.1'
  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'timecop'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'with_model', '~> 1.2.1'
  spec.add_development_dependency 'pry'
end

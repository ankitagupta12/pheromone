# frozen_string_literal: true
# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pheromone/version'

Gem::Specification.new do |spec|
  spec.name          = 'pheromone'
  spec.version       = Pheromone::VERSION
  spec.authors       = ['Ankita Gupta']
  spec.email         = ['ankitagupta12391@gmail.com']

  spec.summary       = 'Transmits messages to kafka from active record'
  spec.description   = 'Sends messages to kafka using different formats and strategies'
  spec.homepage      = 'https://github.com/ankitagupta12/pheromone'
  spec.license       = 'MIT'

  spec.files         = Dir['{lib}/**/*.rb', 'bin/*', 'LICENSE', '*.md']
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '~> 5.0'
  spec.add_dependency 'activerecord', '~> 5.0'
  spec.add_dependency 'waterdrop', '~> 0.3.2.1'
  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'timecop', '~> 0.8'
  spec.add_development_dependency 'rake', '~> 0'
  spec.add_development_dependency 'rspec-rails', '~> 3.5'
  spec.add_development_dependency 'with_model', '~> 1.2'
end

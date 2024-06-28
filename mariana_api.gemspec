# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mariana_api/version'

Gem::Specification.new do |spec|
  spec.name          = 'mariana_api'
  spec.version       = MarianaApi::VERSION
  spec.authors       = ['Jesse Cotton']
  spec.email         = ['jcotton@bitlancer.com']

  spec.summary       = 'Mariana Tek API Client'
  spec.description   = 'Mariana Tek API Client'
  spec.homepage      = 'https://github.com/bitlancer/mariana_api'
  spec.license       = ''

  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '~> 3.0'

  spec.add_runtime_dependency 'async', '~> 1.2'
  spec.add_runtime_dependency 'oauth2', '~> 1.4.3'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'webmock'
end

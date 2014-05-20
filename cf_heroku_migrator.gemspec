# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cf_heroku_migrator/version'

Gem::Specification.new do |spec|
  spec.name          = "cf_heroku_migrator"
  spec.version       = CfHerokuMigrator::VERSION
  spec.authors       = ["Pivotpong"]
  spec.email         = ["ple+pivotpong@pivotallabs.com", "jpalermo@pivotallabs.com"]
  spec.summary       = %q{Move an app to CF from Heroku}
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "heroku-api"
  spec.add_dependency "highline"
  spec.add_dependency "sshkey"
  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end

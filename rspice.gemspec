# -*- encoding: utf-8 -*-
require File.expand_path('../lib/rspice/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Adam Nelson"]
  gem.email         = ["anelson@apocryph.org"]
  gem.description   = %q{Provides a pure Ruby wrapper around the CSPICE astronomy library from NASA JPL.  Uses the ffi gem to wrap the native cspice library, so there is no C extension code to compile}
  gem.summary       = %q{Provides a pure Ruby wrapper around the CSPICE astronomy library from NASA JPL}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.extensions    = ['ext/rspice_wrapper/extconf.rb']
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "rspice"
  gem.require_paths = ["lib"]
  gem.version       = RSpice::VERSION

  gem.add_dependency "rake-compiler", "~> 0.8.0"

  gem.add_development_dependency "rspec", "~> 2.11.0"
end

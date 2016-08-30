# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'activerecord/instant/version'

Gem::Specification.new do |spec|
  spec.name          = "activerecord-instant"
  spec.version       = Activerecord::Instant::VERSION
  spec.authors       = ["koshigoe"]
  spec.email         = ["koshigoeb@gmail.com"]

  spec.summary       = %q{Manage ActiveRecord model instantly.}
  spec.description   = %q{Manage ActiveRecord model instantly.}
  spec.homepage      = "https://github.com/koshigoe/activerecord-instant"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "database_cleaner"

  spec.add_runtime_dependency "activerecord", ">=5.0.0"
end

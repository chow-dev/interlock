# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name        = "interlock"
  s.version     = "1.4.custom"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Evan Weaver"]
  s.email       = []
  s.summary     = "Interlock"

  s.required_rubygems_version = ">= 1.3.6"


  s.files        = `git ls-files`.split("\n")
  s.require_path = 'lib'
end
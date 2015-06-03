# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "knife-brightbox/version"

Gem::Specification.new do |s|
  s.name        = "knife-brightbox"
  s.version     = Knife::Brightbox::VERSION
  s.license     = "Apache License, Version 2.0"
  s.has_rdoc = true
  s.authors     = ["Sergio Rubio"]
  s.email       = ["rubiojr@frameos.org","rubiojr@frameos.org"]
  s.homepage = "http://wiki.opscode.com/display/chef"
  s.summary = "Brightbox Support for Chef's Knife Command"
  s.description = "Plugin to add support for Brightbox's Cloud service to Chef's Knife command"
  s.extra_rdoc_files = ["README.rdoc", "LICENSE" ]

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.add_dependency "fog-brightbox", "~> 0.7"
  s.add_dependency "chef", ">= 0.10"
  s.require_paths = ["lib"]
end

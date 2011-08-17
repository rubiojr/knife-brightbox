# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "knife-brightbox/version"

Gem::Specification.new do |s|
  s.name        = "knife-brightbox"
  s.version     = Knife::Brightbox::VERSION
  s.has_rdoc = true
  s.authors     = ["Sergio Rubio"]
  s.email       = ["rubiojr@frameos.org","rubiojr@frameos.org"]
  s.homepage = "http://wiki.opscode.com/display/chef"
  s.summary = "Brightbox Support for Chef's Knife Command"
  s.description = s.summary
  s.extra_rdoc_files = ["README.rdoc", "LICENSE" ]

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.add_dependency "fog", "~> 0.8"
  s.add_dependency "chef", ">= 0.10"
  s.require_paths = ["lib"]

end

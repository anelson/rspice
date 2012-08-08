#!/usr/bin/env rake
require "bundler/gem_tasks"
require 'rake/extensiontask'
require 'rspec/core/rake_task'

Rake::ExtensionTask.new('rspice') do |ext|
  ext.name = 'cspice_wrapper'
  ext.ext_dir = 'ext/cspice_wrapper'
  ext.source_pattern = "*.{c,cpp,i}"

  #TODO: How to parameterize this at runtime?
  ext.config_options << '--with-cspice-dir=/Users/anelson/sources/cspice'
end

RSpec::Core::RakeTask.new(:test)

CLEAN.include('**/mkmf.log')
CLEAN.include('**/Makefile')
CLEAN.include('**/cspice_wrapper.c')
#!/usr/bin/env rake
require "bundler/gem_tasks"
require 'rake/extensiontask'

Rake::ExtensionTask.new('rspice') do |ext|
  ext.config_options << '--with-cspice-dir=/Users/anelson/sources/cspice'
end


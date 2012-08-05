#!/usr/bin/env rake
require "bundler/gem_tasks"

require 'ffi-swig-generator'

# Create a rake task to generate the cspice ffi wrapper
FFI::Generator::Task.new do |task|
  task.input_fn = 'lib/rspice/*.i'
  task.output_dir = 'lib/rspice/cspice_wrapper'
end

# Make the wrapper generator task run as part of the build process
task :build => [ "ffi:generate" ]
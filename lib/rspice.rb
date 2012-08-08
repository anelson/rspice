module RSpice
end

require "rspice/version"
require "rspice/cspice"
require "rspice/cspice_error"
require "rspice/kernels"
require "rspice/time"
require "rspice/ephemeris"
require "rspice/body_position"
require "rspice/body_velocity"
require "rspice/body_state"

# Require the extension library which wraps cspice
require 'cspice_wrapper'



# Require the extension library which wraps cspice
require 'cspice_wrapper'

module RSpice
  DEGREES_PER_RADIAN = Cspice_wrapper::dpr_c()
end

require "rspice/version"
require "rspice/spice_vector"
require "rspice/spice_cell"
require "rspice/cspice"
require "rspice/cspice_error"
require "rspice/kernel"
require "rspice/time"
require "rspice/body_state"
require "rspice/body"



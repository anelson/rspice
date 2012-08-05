require "rspice/version"

# Require the extension library which wraps cspice
require 'rspice.bundle'

module RSpice
  # Furnishes (aka loads into memory) a SPICE kernel file.  Kernel files can be ASCII or binary format.  There are various
  # types of kernel files, containing various types of information.  The 'Intro to Kernels' [1] tutorial on the NAIF website
  # is key to understanding this concept.
  #
  # Note that multiple kernel files can be loaded.  In fact, for almost all computations you will find yourself loading multipe kernels.
  # There are particular rules as to which files take precedence depending upon the type of data.  Again, the tutorial is instructive here.
  #
  # Sometimes a metakernel is loaded, which is kind of like a C .h file that #include's other files.
  # 
  # 1. ftp://naif.jpl.nasa.gov/pub/naif/toolkit_docs/Tutorials/pdf/individual_docs/08_intro_to_kernels.pdf
  def furnish(kernel_file)
    furnsh_c kernel_file
  end
end

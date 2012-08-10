require 'mkmf'

# Allow users to override the compiler command with an environment variable
RbConfig::MAKEFILE_CONFIG['CC'] = ENV['CC'] if ENV['CC']

# Take parameters to specify the cspice include and lib directories
cspice_include, cspice_lib = dir_config('cspice')

# Make sure the cspice headers are available
abort("cspice header file SpiceUsr.h not found") unless have_header('SpiceUsr.h')

abort("math library not found") unless have_library("m")

abort("swig must be installed and accessible in your PATH") unless find_executable('swig') != nil

# Run SWIG to generate ruby bindings
interface_file = File.join(File.dirname(__FILE__), 'cspice.i')
wrapper_file = File.join(File.dirname(__FILE__), 'cspice_wrapper.cpp')

puts cspice_include
puts cspice_lib
puts "swig -ruby -I#{cspice_include} -c++ -o #{wrapper_file} -Wall #{interface_file}"

# Generate the SWIG wrapper around the CSPICE functions
`swig -ruby -I#{cspice_include} -c++ -o #{wrapper_file} -Wall #{interface_file}`

# The CSPICE lib is not a dynamic library it's a static .a library.  The only way I can get it to link is by treating it
# like a source file for the purposes of calling cc; that is, listing it on the command line without the -l prefix.
# The only way I can figure out how to do that is by adding it to LIBS in the makfile.  The only way I know how to do THAT
# is by modifying the variable mkmf uses to keep track of the libraries in the makefile, which thankfully is global and easy
# to munge.  Ugly, I know.  Please suggest something better.
$LIBS += " #{cspice_lib}/cspice.a"

create_makefile("cspice_wrapper")

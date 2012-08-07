module RSpice
  #Internal method intended to be called on module initialization.  Initializes the CSPICE error handling system
  #so we can translate CSPICE errors into Ruby exceptions
  def RSpice.initialize_error_handlers
    #When an error occurrs, report a short message, a longer more detailed message, an error explanation, and a traceback
    Cspice_wrapper.errprt_c('SET', 0, 'LONG, SHORT, EXPLAIN, TRACEBACK')

    #When an error happens, return from the erroring function, but do not abort the whole process
    Cspice_wrapper.erract_c('SET', 0, 'RETURN')

    # Calls one or more Cspice_wrapper methods
    def with_wrapper(&blk)
    end
end

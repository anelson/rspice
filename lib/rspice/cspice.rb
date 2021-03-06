require 'singleton'

module RSpice
  # A second layer of wrapper around the SWIG-generated Cspice_wrapper, which itself wraps the CSPICE C API
  # This layer adds Ruby-style error handling (that is to say, exceptions) when CSPICE functions report an error
  class CSpice
    include Singleton

    def initialize()
      initialize_error_handlers
    end

    # Intercepts method calls to this class.  If these methods exist and take the same args in Cspice_wrapper, 
    # then the call is passed through to Cspice_wrapper, but with an error handling frame set up so that 
    # CSPICE errors are translated into Ruby exceptions
    def method_missing(sym, *args, &block)
      begin
        retval = Cspice_wrapper.send sym, *args, &block
      rescue NoMethodError
        super
      end

      if Cspice_wrapper.failed_c
        #The CSPICE method just called reported an error.  Translate it into an RSpice exception
        short = get_error_message :short
        long = get_error_message :long
        traceback = get_error_message :traceback
        explain = get_error_message :explain

        # Reset the error state so subsequent CSPICE calls do not immediately fail
        Cspice_wrapper.reset_c()

        raise CSpiceError.new(short, long, traceback, explain)
      end

      retval
    end

    private
      MAX_MESSAGE_LENGTH = 4095
      MAX_TRACEBACK_LENGTH = 255

      #Internal method intended to be called on module initialization.  Initializes the CSPICE error handling system
      #so we can translate CSPICE errors into Ruby exceptions
      def initialize_error_handlers
        #When an error occurrs, write nothing to stdout.  We'll handle the errors ourselves
        Cspice_wrapper.errprt_c('SET', 0, 'NONE')

        #When an error happens, return from the erroring function, but do not abort the whole process
        Cspice_wrapper.erract_c('SET', 0, 'RETURN')
      end

      def get_error_message(kind)
        case kind
        when :short
          message = Cspice_wrapper.getmsg_c 'short', MAX_MESSAGE_LENGTH

        when :long
          message = Cspice_wrapper.getmsg_c 'long', MAX_MESSAGE_LENGTH

        when :traceback
          # For some reason the traceback sometimes has garbage in it.  It's only traceback never other strings so
          # I don't think it's a marshalling bug.  Try to use a smaller buffer; I assume it's just a bug in CSPICE
          result, message = Cspice_wrapper.qcktrc_ MAX_TRACEBACK_LENGTH

        when :explain
          message = Cspice_wrapper.getmsg_c 'explain', MAX_MESSAGE_LENGTH

        else
          raise ArgumentError, "Invalid kind #{kind}"
        end

        message
      end
  end
end


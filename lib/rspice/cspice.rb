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
        puts "Calling #{sym}"
        Cspice_wrapper.send sym, *args, &block
      rescue NoMethodError
        super
      end

      if Cspice_wrapper.failed_c()
        puts "#{sym} reported an error"

        #The CSPICE method just called reported an error.  Translate it into an RSpice exception
        short = get_error_message :short
        long = get_error_message :long
        traceback = get_error_message :traceback
        explain = get_error_message :explain

        puts "Error was #{short}"

        # Reset the error state so subsequent CSPICE calls do not immediately fail
        Cspice_wrapper.reset_c()

        raise CSpiceError.new(short, long, traceback, explain)
      end
    end

    private
      MAX_MESSAGE_LENGTH = 8192

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
          message = Cspice_wrapper.getmsg_short MAX_MESSAGE_LENGTH

        when :long
          message = Cspice_wrapper.getmsg_long MAX_MESSAGE_LENGTH

        when :traceback
          result, message = Cspice_wrapper.qcktrc_ MAX_MESSAGE_LENGTH

          #For some reason qcktrc_c doesn't null terminate
          message.rstrip!

        when :explain
          message = Cspice_wrapper.getmsg_explain MAX_MESSAGE_LENGTH

        else
          raise "Invalid kind #{kind}"
        end

        message
      end
  end
end


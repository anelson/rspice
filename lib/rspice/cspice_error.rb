module RSpice
  #Exception thrown when a CSPICE API call encounters an error
  class CSpiceError < StandardError
    attr_reader :short, :long, :traceback, :explain

    def initialize(short, long, traceback, explain)
      super("CSPICE runtime error!\n\nError: #{short} (#{explain})\nDetails: #{long}\n\nTrace: #{traceback}")

      @short = short
      @long = long
      @traceback = traceback
      @explain = explain
    end
  end
end

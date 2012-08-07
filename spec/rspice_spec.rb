require 'rspec'

require 'rspice'

describe RSpice do
  it "throws when given bogus kernel to furnish" do
    lambda {
      RSpice::furnish "this file does not exist"
    }.should raise_error(RSpice::CSpiceError, /NOSUCHFILE/)
  end
end
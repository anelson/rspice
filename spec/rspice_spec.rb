require 'rspec'
require 'rspice'

describe RSpice do
  it "throws when given bogus kernel to furnish" do
    RSpice::furnish "this file does not exist"
  end
end
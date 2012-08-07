require 'rspec'

require 'rspice'

describe RSpice do
  let(:test_data_dir) {
    File.join(File.dirname(__FILE__), 'test_data/')
  }

  it "throws when furnish called with a non-existent file name" do
    lambda {
      RSpice::furnish "this file does not exist"
    }.should raise_error(RSpice::CSpiceError, /NOSUCHFILE/)
  end

  it "succeeds when furnish called with a kernel file with invalid content" do
    RSpice::furnish(File.join(test_data_dir, 'invalid_kernel.txt'))
  end

  it "succeeds when furnish called with a valid kernel file" do
    RSpice::furnish(File.join(test_data_dir, 'naif0010.tls'))
  end
end
require 'rspec'

require 'rspice'

require 'helpers/kernel_loader'

describe RSpice do
  let(:test_data_dir) {
    get_test_data_dir()
  }

  after(:each) do 
    #Clear any kernels furnished during the run
    RSpice::Kernel.unload_all
  end

  it "should fail to parse datetime if there is no leapseconds kernel loaded" do 
    lambda {
      RSpice::str_to_et("2012-08-08T14:42:28")
    }.should raise_error(RSpice::CSpiceError, /NOLEAPSECONDS/)
  end

  it "should fail to convert ET to datetime if there is no leapseconds kernel loaded" do 
    lambda {
      RSpice::et_to_utc_str(397709015.18307787179946899414062500000000)
    }.should raise_error(RSpice::CSpiceError, /MISSINGTIMEINFO/)
  end

  it "should parse a valid ISO datetime into ET" do 
    # Input and output values come from test_data_generator.c
    RSpice::Kernel.furnish(File.join(test_data_dir, 'naif0010.tls'))
    et = RSpice::str_to_et("2012-08-08T14:42:28")
    et.should == 397709015.18307787179946899414062500000000
  end

  it "should produce the correct ISO datetime given an ET" do
    # Input and output values come from test_data_generator.c
    RSpice::Kernel.furnish(File.join(test_data_dir, 'naif0010.tls'))
    utc_str = RSpice::et_to_utc_str(397709015.18307787179946899414062500000000)

    utc_str.should == "2012-08-08T14:42:28.0000000000000"
  end
end
require 'rspec'

require 'rspice'

describe RSpice do
  let(:test_data_dir) {
    File.join(File.dirname(__FILE__), 'test_data/')
  }

  after(:each) do 
    #Clear any kernels furnished during the run
    RSpice::unload_all_kernels
  end

  describe "kernel functions" do
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
      RSpice::kernel_count().should == 1
      RSpice::kernel_count(:spk).should == 0
      RSpice::kernel_count(:ck).should == 0
      RSpice::kernel_count(:pck).should == 0
      RSpice::kernel_count(:ek).should == 0
      RSpice::kernel_count(:text).should == 1
      RSpice::kernel_count(:meta).should == 0
      RSpice::kernel_count(:all).should == 1
    end

    it "should throw if kernel count requested for an invalid kind" do
      lambda {
        RSpice::kernel_count(:foo)
      }.should raise_error(ArgumentError, /invalid kernel kind/i)
    end

    it "reports 0 kernels of all kinds when nothing has been loaded yet" do 
      RSpice::kernel_count().should == 0
      RSpice::kernel_count(:spk).should == 0
      RSpice::kernel_count(:ck).should == 0
      RSpice::kernel_count(:pck).should == 0
      RSpice::kernel_count(:ek).should == 0
      RSpice::kernel_count(:text).should == 0
      RSpice::kernel_count(:meta).should == 0
      RSpice::kernel_count(:all).should == 0
    end

    it "should throw if kernel data requested for an invalid kind" do
      lambda {
        RSpice::kernel_data(0, :foo)
      }.should raise_error(ArgumentError, /invalid kernel kind/i)
    end

    it "should return kernel data for a previously furnished kernel" do
      test_data_file = File.join(test_data_dir, 'naif0010.tls')
      RSpice::furnish(test_data_file)
      kernel_data = RSpice::kernel_data(0, :text)
      kernel_data.should_not == nil
      kernel_data[:file_name].should == test_data_file
      kernel_data[:file_type].should == :text
      kernel_data[:source].should == ''
    end

    it "should unload a kernel that was previously loaded" do
      test_data_file = File.join(test_data_dir, 'naif0010.tls')
      RSpice::furnish(test_data_file)
      RSpice::kernel_count(:text).should == 1
      RSpice::unload_kernel(test_data_file)
      RSpice::kernel_count(:text).should == 0
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
      RSpice::furnish(File.join(test_data_dir, 'naif0010.tls'))
      et = RSpice::str_to_et("2012-08-08T14:42:28")
      et.should == 397709015.18307787179946899414062500000000
    end

    it "should produce the correct ISO datetime given an ET" do
      # Input and output values come from test_data_generator.c
      RSpice::furnish(File.join(test_data_dir, 'naif0010.tls'))
      utc_str = RSpice::et_to_utc_str(397709015.18307787179946899414062500000000)

      utc_str.should == "2012-08-08T14:42:28.0000000000000"
    end
  end
end
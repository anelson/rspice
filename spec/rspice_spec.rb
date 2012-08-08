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

    it "should produce known correct object state for a given ET" do
      # Known answer data comes from the VSEP section of the test data generator
      RSpice::furnish(File.join(test_data_dir, 'de405_1960_2020.bsp'))
      RSpice::furnish(File.join(test_data_dir, 'earth_000101_121026_120804.bpc'))
      RSpice::furnish(File.join(test_data_dir, 'moon_pa_de421_1900-2050.bpc'))
      RSpice::furnish(File.join(test_data_dir, 'pck00010.tpc'))
      RSpice::furnish(File.join(test_data_dir, 'naif0010.tls'))
      et = RSpice::str_to_et("2012-08-08T14:42:28")

      state, light_time = RSpice::compute_body_relative_state('MOON', et, 'ITRF93', :lts, 'EARTH')

      state.position.x.should == -327807.8171300230314955115318298339843750000000000000000000000000000000
      state.position.y.should == -208070.5176482859533280134201049804687500000000000000000000000000000000
      state.position.z.should == 103915.6926515815721359103918075561523437500000000000000000000000000000
      state.velocity.dx.should == -14.6354676574775854902554783620871603488922119140625000000000000000
      state.velocity.dy.should == 23.1357059604107426764585397904738783836364746093750000000000000000
      state.velocity.dz.should == 0.2594509178034260510337105642975075170397758483886718750000000000
      light_time.should == 1.3407026808337947354488051132648251950740814208984375000000000000
    end

    it "should produce known correct VSEP for a given pair of object states" do
      # Known answer data comes from the VSEP section of the test data generator
      body1_state = RSpice::BodyState.new
      body1_state.unpack([-327807.8171300230314955115318298339843750000000000000000000000000000000, 
        -208070.5176482859533280134201049804687500000000000000000000000000000000, 
        103915.6926515815721359103918075561523437500000000000000000000000000000, 
        -14.6354676574775854902554783620871603488922119140625000000000000000, 
        23.1357059604107426764585397904738783836364746093750000000000000000, 
        0.2594509178034260510337105642975075170397758483886718750000000000],
        0)
      body2_state = RSpice::BodyState.new
      body2_state.unpack([112991803.1414944082498550415039062500000000000000000000000000000000000000, 
        -92247976.9782654941082000732421875000000000000000000000000000000000000000, 
        41566361.0355590283870697021484375000000000000000000000000000000000000000, 
        -6707.4296965026614998350851237773895263671875000000000000000000000000, 
        -8219.1514789360153372399508953094482421875000000000000000000000000000, 
        -8.5496280333794647532386079546995460987091064453125000000000000000],
        0)

      vsep_radians = RSpice::compute_vsep_radians(body1_state.position, body2_state.position)
      vsep_degrees = RSpice::DEGREES_PER_RADIAN * vsep_radians

      vsep_radians.should == 1.7945354984499337636094651315943337976932525634765625000000000000
      vsep_degrees.should == 102.8193102475866851364116882905364036560058593750000000000000000000
    end
  end
end
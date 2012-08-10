require 'rspec'

require 'rspice'

require 'helpers/kernel_loader'

describe RSpice do
  let(:test_data_dir) {
    get_test_data_dir()
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

    it "should enumerate kernel data for all furnished kernels" do
      test_data_file = File.join(test_data_dir, 'naif0010.tls')
      RSpice::furnish(test_data_file)

      count = 0
      RSpice::each_kernel() do |k|
        count.should == 0
        count += 1
        k[:file_name].should == test_data_file
      end
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
      load_all_ephemerides()
      et = RSpice::str_to_et("2012-08-08T14:42:28")

      state, light_time = RSpice::compute_body_relative_state('MOON', et, 'ITRF93', :lts, 'EARTH')

      state.x().should == -327807.8171300230314955115318298339843750000000000000000000000000000000
      state.y().should == -208070.5176482859533280134201049804687500000000000000000000000000000000
      state.z().should == 103915.6926515815721359103918075561523437500000000000000000000000000000
      state.dx().should == -14.6354676574775854902554783620871603488922119140625000000000000000
      state.dy().should == 23.1357059604107426764585397904738783836364746093750000000000000000
      state.dz().should == 0.2594509178034260510337105642975075170397758483886718750000000000
      light_time.should == 1.3407026808337947354488051132648251950740814208984375000000000000
    end

    it "should throw when queried for a non-existent body variable" do
      load_all_ephemerides()

      lambda {
        RSpice::get_body_vector_variable('earth', 'foobarbaz', 3)
      }.should raise_error(RSpice::CSpiceError, /KERNELVARNOTFOUND/)
    end

    it "should throw when queried for a body variable without sufficient dimensions" do
      load_all_ephemerides()

      lambda {
        RSpice::get_body_vector_variable('earth', 'RADII', 1)
      }.should raise_error(RSpice::CSpiceError, /ARRAYTOOSMALL/)
    end

    it "should produce the correct radii of a body in the ephemeris" do
      load_all_ephemerides()

      radii = RSpice::get_body_vector_variable('earth', 'RADII', 3)

      radii[0].should == 6378.1365999999998166458681225776672363281250000000000000000000000000
      radii[1].should == 6378.1365999999998166458681225776672363281250000000000000000000000000
      radii[2].should == 6356.7519000000002051820047199726104736328125000000000000000000000000
    end

    it "should compute the known correct subobserver point by intercept method" do
      load_all_ephemerides()
      et = RSpice::str_to_et("2012-08-08T14:42:28")

      sub_observer_point, tx_time, surface_vector = RSpice::compute_subobserver_point(:intercept,
       'earth',
        et,
        'ITRF93',
        :lts,
        'moon')

      sub_observer_point[0].should == -5200.3861637028949189698323607444763183593750000000000000000000000000
      sub_observer_point[1].should == -3301.5604626680042201769538223743438720703125000000000000000000000000
      sub_observer_point[2].should == 1648.6330228757860822952352464199066162109375000000000000000000000000

      tx_time.should == 397709013.8633919954299926757812500000000000000000000000000000000000000000

      surface_vector[0].should == 322649.3856330637354403734207153320312500000000000000000000000000000000
      surface_vector[1].should == 204839.8756125726795289665460586547851562500000000000000000000000000000
      surface_vector[2].should == -102286.7177976060484070330858230590820312500000000000000000000000000000
    end

    it "should compute the known correct subobserver point by near point method" do
      load_all_ephemerides()
      et = RSpice::str_to_et("2012-08-08T14:42:28")

      sub_observer_point, tx_time, surface_vector = RSpice::compute_subobserver_point(:near_point,
       'earth',
        et,
        'ITRF93',
        :lts,
        'moon')

      sub_observer_point[0].should == -5202.6848348823286869446747004985809326171875000000000000000000000000
      sub_observer_point[1].should == -3303.0198161979051292291842401027679443359375000000000000000000000000
      sub_observer_point[2].should == 1638.4943682527168675733264535665512084960937500000000000000000000000

      tx_time.should == 397709013.8633920550346374511718750000000000000000000000000000000000000000

      surface_vector[0].should == 322647.0867848269990645349025726318359375000000000000000000000000000000
      surface_vector[1].should == 204838.4161469032987952232360839843750000000000000000000000000000000000
      surface_vector[2].should == -102296.8574323647626442834734916687011718750000000000000000000000000000
    end
  end
end
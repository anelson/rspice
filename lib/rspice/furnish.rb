module RSpice
  KERNEL_KINDS = {
    :spk => 'SPK',
    :ck => 'CK',
    :pck => 'PCK',
    :ek => 'EK',
    :text => 'TEXT',
    :meta => 'META',
    :all => 'ALL'
  }

  MAX_KERNEL_STRING_LENGTH = 1024

  # Furnishes (aka loads into memory) a SPICE kernel file.  Kernel files can be ASCII or binary format.  There are various
  # types of kernel files, containing various types of information.  The 'Intro to Kernels' [1] tutorial on the NAIF website
  # is key to understanding this concept.
  #
  # Note that multiple kernel files can be loaded.  In fact, for almost all computations you will find yourself loading multipe kernels.
  # There are particular rules as to which files take precedence depending upon the type of data.  Again, the tutorial is instructive here.
  #
  # Sometimes a metakernel is loaded, which is kind of like a C .h file that #include's other files.
  # 
  # 1. ftp://naif.jpl.nasa.gov/pub/naif/toolkit_docs/Tutorials/pdf/individual_docs/08_intro_to_kernels.pdf
  def RSpice.furnish(kernel_file)
    CSpice.instance.furnsh_c kernel_file
  end

  # Gets the total number of kernels loaded of a particular kind, or all kernels by default
  #
  # Possible kinds:
  #  :spk
  #  :ck
  #  :pck
  #  :ek
  #  :text
  #  :meta
  #  :all 
  def RSpice.kernel_count(kind = :all)
    cspice_kind = KERNEL_KINDS[kind]
    raise ArgumentError, "Invalid kernel kind #{kind}" if cspice_kind == nil

    CSpice.instance.ktotal_c(cspice_kind)
  end

  # Gets the data for a kernel at a given 0-based index.  The index must be less than the value returned by kernel_count for 
  # the same value of kind.
  #
  # If the kernel data is not found, returns nil
  # Otherwise returns a hash with the following elements:
  #  :file_name - The name of the kernel file
  #  :file_type - The type of the kernel (one of the values in KERNEL_KINDS)
  #  :source - The name of the metadata kernel file which caused this file to be loaded, if any.  Empty if this kernel was loaded with furnish
  #  :handle - For binary kernels, the CSPICE handle to this file, which can be used with other APIs later.
  def RSpice.kernel_data(index, kind = :all)
    cspice_kind = KERNEL_KINDS[kind]
    raise ArgumentError, "Invalid kernel kind #{kind}" if cspice_kind == nil

    file, filetyp, source, handle, found = CSpice.instance.kdata_c(index, cspice_kind, MAX_KERNEL_STRING_LENGTH, MAX_KERNEL_STRING_LENGTH, MAX_KERNEL_STRING_LENGTH)

    data = nil
    if found
      data = {
        :file_name => file,
        :file_type => KERNEL_KINDS.invert[filetyp],
        :source => source,
        :handle => handle
      }
    end

    data
  end

  # Unloads a previously furnished kernel.  If the kernel file is not loaded, does nothing
  def RSpice.unload_kernel(file_name)
    CSpice.instance.unload_c(file_name)
  end

  # Unloads ALL loaded kernels
  def RSpice.unload_all_kernels()
    # The act of unloading will change the indexes and counts of loaded kernels, especially if metakernels are used since unloading
    # the metakernel unloads all kernels it loaded.  Thus, keep unloading index 0 of kernel type :all until the count is 0
    while kernel_count() >  0
      data = kernel_data(0)
      if data == nil then break end
      unload_kernel(data[:file_name])
    end
  end
end

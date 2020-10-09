
[TOC]

# AEG Mesher: Installation and testing

## Requirements

The code is written in a portable subset of GNU [Octave][] and [MATLAB][], one of which is required
to use the software. Additional requirements are:

1. (Mandatory for use with GNU [Octave][]) The [optim](http://octave.sourceforge.net/optim/index.html) package 
   from [OctaveForge][]. This can be installed from within Octave using the command `pkg add -forge optim`.

2. (Recommended) The [Gmsh][] unstructured mesh generator is highly recommended for creating and viewing meshes. 
   It also enables importing meshes in many other formats such as [STL](http://en.wikipedia.org/wiki/STL_%28file_format%29).

3. (Optional) The [nlopt][] package provides enhanced optimisation capability.

4. (Optional) For [AMELET-HDF][] format support the command line tools from the [HDF5][] package are required.

5. (Optional) To run the test-suite automatically the [CMake][] software build tool is needed.

6. (Optional) To help with development or as an alternative way to download the source a client for the [Mercurial][] Version 
   Control System is required.

The code has been primarily developed using GNU [Octave][] on Linux platforms, but should run under both GNU [Octave][] 
and [MATLAB][] on Linux and Windows systems.

## Installation on Linux

### Set up init file for GNU/Octave

If you are using GNU Octave and you want to run the test-suite add the lines

    if( exist( './startup.m' , 'file' ) )
      startup
    end %if

to the initialisation file ~/.octaverc. This makes Octave read a startup.m
file in the current working directory when is is started. This is *only* required
by the test-suite for setting paths to m-files. It is *not required* for using
the software outside of the test-suite.

### Get the source code

Either use git to clone the source code repository on github.com,
for example using git directly from a Linux shell,

    $ git clone https://github.com/flintoftid/aegmesher.git aegmesher-working

or download a zip file of the source code from
https://github.com/flintoftid/aegnec2/archive/master.zip
and unzip it into a directory call aegmesher-working

    $ unzip aeg-aegmesher-x12ey12ey.zip
    $ mv aeg-aegmesher-x12ey12ey aegmesher-working

### Run the test-suite

The testsuite can be run be issuing the following commands:

   $ mkdir aegmesher-build_linux_$(arch)
   $ cd aegmesher-build_linux_$(arch)
   $ cmake -D CMAKE_INSTALL_PREFIX=$HOME -D WITH_MESHER=ON -D WITH_GMSH=ON -D WITH_AMELET=ON ../aegmesher-working
   $ make
   $ make test
 
This will try to use GNU Octave as the m-file Interpreter. If using MATLAB add 
the arguments `-D WITH_MATLAB=ON` to the cmake command. 

The test output is logged to the file Testing/Temporary/LastTest.log.
Specific tests can be run using:

    $ ctest -R "WireBox_*" -D ExperimentalTest

To run specific tests logging full output to file (useful for debugging):

    $ ctest -V -R "BLADE1_*" -D ExperimentalTest | tee output.txt

**NOTE** that currently the tests will pass providing all the elements of the 
test run to completion without error. No check is made yet of the correctness 
or even sanity of the final output meshes.

### Install the software

To install the software in the file-system tree defined in the CMAKE_INSTALL_PREFIX
variable above type:

    $ make install

This will install the m-files in the directory CMAKE_INSTALL_PREFIX/share/octave/packages/mesh
which should then be added to your MATLAB/Octave path. For Octave added

    addpath( '<CMAKE_INSTALL_PREFIX>/share/octave/packages/mesh' );

to the .octiaverc file in your home directory.

### Manual installation

After getting the source code copy the sub-directory called mesh from the aegmesher-working 
directory to somewhere convenient and add it to your Octave/MATLAB path.

## Installation on Windows

[FIXME]



[Gmsh]: http://geuz.org/gmsh
[AMELET-HDF]: https://code.google.com/p/amelet-hdf
[Octave]: http://www.gnu.org/software/octave
[MATLAB]: http://www.mathworks.co.uk/products/matlab
[Mercurial]: http://mercurial.selenic.com
[OctaveForge]: http://octave.sourceforge.net
[HDF5]: http://www.hdfgroup.org/HDF5
[CMake]: http://www.cmake.org
[nlopt]: http://ab-initio.mit.edu/wiki/index.php/NLopt

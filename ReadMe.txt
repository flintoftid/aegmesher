

AEG Mesher: An Open Source Structured Mesh Generator for FDTD Simulations

The Applied Electromagnetics Group (AEG) mesh generator, aegmesher, is an Open
Source structured mesh generator for creating uniform and non-uniform cuboid
meshes. It was primarily developed in the Department_of_Electronics at the
University_of_York for generating meshes for finite-difference time-domain
(FDTD) and similar electromagnetic solvers.

Code Features

The mesh generator takes a description of a physical structure in the form of an
unstructured mesh and then, using options provided by the user, creates a
structured mesh representation of the structure. The mesh generator and
associated utilities are able to read unstructured meshes in Gmsh and AMELET-HDF
format. The target structured mesh can be cubic, uniform or non-uniform. The
input unstructured mesh can contain any number of physical objects defined by
groups of mesh elements. These groups can define point-like, linear, surface or
volumetric objects.
The software is script-driven using the GNU Octave language which allows it to
be easily extended and combined with other phases of an overall simulation work-
flow. The meshing is performed in two stages:

  1. The input unstructured mesh is first analysed together with the user
     provided options and a set of mesh lines generated that optimally satisfy
     the meshing constraints. The key constraints are the maximum and minimum
     cell size each object in the mesh.
  2. Each object in the unstructured mesh is then mapped onto the structured
     mesh.

Currently aegmesher can export the structured meshes in the AEG Vulture FDTD
Code format. Other formats can easily be added.
The package also has some limited support for transforming unstructured meshes
into formats suitable for use in the CONCEPT-II method-of-moments code.

Requirements

The code is written in a portable subset of GNU Octave and MATLAB. Additional
requirements are:

  1. (Mandatory for use with GNU Octave) The optim package from OctaveForge.
  2. (Recommended) The Gmsh unstructured mesh generator is highly recommended
     for creating and viewing meshes. It also enables importing meshes in many
     other formats such as STL.
  3. (Optional) The nlopt package provides enhanced optimisation capability.
  4. (Optional) For AMELET-HDF format support the command line tools from the
     HDF5 package are required.
  5. (Optional) To run the test-suite automatically the CMake software build
     tool is needed.
  6. (Optional) To help with development or as an alternative way to download
     the source a client for the Mercurial Version Control System is required.

The code has been primarily developed using GNU Octave on Linux platforms, but
should run under both GNU Octave and MATLAB on Linux and Windows systems.

Documentation

Installation instructions are contained in the file Install.txt in the source
distribution. There is also a draft user manual in the file doc/UserManual.txt.

Bugs and support

The code is still under development and no doubt will contain many bugs. Known
significant bugs are listed in the file doc/Bugs.txt in the source code.
Please report bugs using the bitbucket issue tracker at https://bitbucket.org/
uoyaeg/aegmesher/issues or by email to ian.flintoft@york.ac.uk.
For general guidance on how to write a good bug report see, for example:

* http://www.chiark.greenend.org.uk/~sgtatham/bugs.html
* http://noverse.com/blog/2012/06/how-to-write-a-good-bug-report
* http://www.softwaretestinghelp.com/how-to-write-good-bug-report

Some of the tips in http://www.catb.org/esr/faqs/smart-questions.html are also
relevant to reporting bugs.
There is a Wiki on the bitbucket project_page.

How to contribute

We welcome any contributions to the development of the mesher, including:

* Fixing bugs.
* Interesting examples that can be used for test-cases.
* Improving the user documentation.
* Working on importers and exporters for other formats and codes.
* Improving the quality of the meshes generated and the general robustness of
  the mesher.
* Speeding up the mesh mapping phase, maybe be reimplementing keys parts as low
  level code in another language.

Please contact Dr_Ian_Flintoft if you are interested in helping with these or
any other aspect of development.

Licence

The code is licensed under the GNU_Public_Licence,_version_3.

Developers

Dr_Ian_Flintoft : ian.flintoft@york.ac.uk
Mr Michael Berens : michael-berens1@web.de
Dr_John_Dawson : john.dawson@york.ac.uk

Contacts

Dr_Ian_Flintoft : ian.flintoft@york.ac.uk
Dr_John_Dawson : john.dawson@york.ac.uk

Credits

The mesher originated as the project of ERASMUS student Mr Michael Berens from
the Leibnitz_Universität_Hannover during his internship at the University_of
York under the supervision of Dr John Dawson during 2013.
The mesh formats are largely based on the AMELET-HDF specification.
Many thanks to the Gmsh developers for creating an excellent Open_Source mesh
generator.

Related links


* Robert Schneiders' list_of_free_and_commercial_mesh_generation_software.
* Matthijs Sypkens Smit's list_of_free/open_mesh_generation_software


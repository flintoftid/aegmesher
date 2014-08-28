University of York Applied Electromagnetics Group Mesh Generator
================================================================

aegmesher is a structured mesh generator for uniform and non-uniform cuboid 
meshes. It was primarily developed for creating meshes for finite-difference 
time-domain [FDTD] and similar electromagnetic solvers. 

Code Features
-------------

The mesh generator and associated utilities are able to read unstructured 
meshes in [Gmsh] and [AMELET-HDF] format. Meshing information is then provided 
by the user for each of the objects in  the unstructured mesh as well as global 
requirements for the target structured mesh using a simple script. The target 
structured mesh can be cubic, uniform of non-uniform.

The meshing is performed in two stages:

1. The input unstructured mesh is first analysed together with the user 
provided options and a set of mesh lines generated that optimally satisfy the 
meshing constraints.

2. Each object in the unstructured mesh is then mapped onto the structured mesh.

Currently aegmesher can export structured meshes in the AEG [Vulture] FDTD Code 
format. Other formats can easily be added.

The package also has some limited support for transforming unstructured meshes 
into formats suitable for use in the [CONCEPT-II] method-of-moments code.

Requirements
------------

The code is written in a portable subset of GNU [Octave] and [MATLAB]. 
Additional requirements are:

1. For use with GNU Octave the optim package from [OctaveForge] is required.

2. The [Gmsh] unstructured mesh generator is highly recommended for creating 
   and viewing meshes. It also enables importing meshes in many other formats 
   such as STL.

3. The optional [nlopt] package provides enhanced optimisation capability.

4. For [AMELET-HDF] format support the command line tools from the [HDF5]
   package are required.

5. To run the test-suite automatically the [CMake] software build tool is 
   needed.

6. To help with development or as an alternative way to download the source The 
   [Mercurial] Version Control System is required.

The code has been primarily developed using GNU Octave on Linux platforms, but 
should run under both GNU Octave and MATLAB on Linux and Windows systems. the
source code is hosted on bitbucket at https://bitbucket.org/uoyaeg/aegmesher/src.

Documentation
-------------

Installation instructions are contained in the file Install.txt.

There is also a draft user manual in the file UserManual.txt.

Bugs
----

The code is still under development and no doubt will contain many bugs. Known 
significant bugs  are listed in the file doc/Bugs.txt in the source code. 

Please report bugs using the bitbucket issue tracker at
<https://bitbucket.org/uoyaeg/aegmesher/issues> 

or by email to <ian.flintoft@york.ac.uk>.

For general guidance on how to write a good bug report see, for example:

* <http://www.gnu.org/software/emacs/manual/html_node/emacs/Bugs.html#Bugs>
* <http://www.chiark.greenend.org.uk/~sgtatham/bugs.html>
* <http://www.softwaretestinghelp.com/how-to-write-good-bug-report>

Some of the tips in <http://www.catb.org/esr/faqs/smart-questions.html> are 
also relevant to reporting bugs.

Licence
--------

The code is licensed under the [GNU Public Licence, version 3. See the
file Licence.txt for further information.

Developers
----------

Dr Ian Flintoft, <ian.flintoft@york.ac.uk>.
Mr Michael Berens, <michael-berens1@web.de>.
Dr John Dawson, <john.dawson@york.ac.uk>.

Contacts
--------

Dr Ian Flintoft, <ian.flintoft@york.ac.uk>.
Dr John Dawson, <john.dawson@york.ac.uk>.

References
----------

[AEG]: http://www.elec.york.ac.uk/research/physLayer/appliedEM.html
[Gmsh]: http://geuz.org/gmsh
[AMELET-HDF]: https://code.google.com/p/amelet-hdf
[Octave]: http://www.gnu.org/software/octave
[MATLAB]: http://www.mathworks.co.uk/products/matlab
[Mercurial]: http://mercurial.selenic.com
[Vulture]: https://bitbucket.org/uoyaeg/vulture/overview
[FDTD]: http://en.wikipedia.org/wiki/Finite-difference_time-domain_method
[OctaveForge]: http://octave.sourceforge.net
[HDF5]: http://www.hdfgroup.org/HDF5
[CMake]: http://www.cmake.org
[nlopt]: http://ab-initio.mit.edu/wiki/index.php/NLopt
[CONCEPT-II]: http://www.tet.tuhh.de/concept/?lang=en

﻿
[TOC]

# AEG Mesher: Implementation Manual

Ian Flintoft, Version 2 - 06/12/2012


**This early document is now superceded by the report**

Michael Berens, "Algorithm for mesh generation with application for
FDTD", Internship Report, University of York and The Leibnitz 
Universität Hannover, October 2013.

## Introduction


### Input unstructured mesh

To make the mesh generator as flexible and general as possible the approach used
by NASH appears useful [Spin2011]. The input geometry is specified by an
unstructured mesh. This allows many different CAD and meshing tools to be
utilised in the creation of simulation geometries. The format of the input mesh
must be decided based on a number of factors:

1. To keep the mesh generator simple it should only support one mesh format
   initially.
2. The format should be simple and easy to read into the program.
3. All unstructured mesh formats should allow the definition of mesh nodes and
   various mesh elements. In the first instance a minimal set of elements should
   be: nodes, lines (bar2), triangles (tri3) and maybe quadrilaterals (quad4).
4. Computational models typically include solid objects, open and closed
   surfaces, wires and points (e.g. observation points , generators, lumped loads).
   The mesh format should allow named groupings of elements of different types
  (node, line, surface) in order to identify these types of object in the mesh.
5. The ability to name groups of groups may also be very useful to maintaining
   the overall topology and linkages between the mesh and physical objects.
6. The format should be stable, documented and open.

Candidate mesh formats:

1. AMELET [Spin2011]. This is based on HDF5 [HDF5].
2. Gmsh’s msh format [Geuz2012].
3. A bespoke format. See for example the MATLAB converters for gmsh to CONCEPT
   meshes.

In addition to the geometrical mesh itself a significant amount of control
information is required by the mesher. Global control information includes:

* The type of mesh to generate – uniform or non-uniform.
* Mesh size information. This can be defined in a number of ways using:
    + The maximum frequency of the simulation
    + The minimum and maximum mesh density (cell per wavelength).
    + The mesh size in each direction for (uniform only).
    + The number of cells in the input mesh bounding box [Spin2011, p.7]. 
* The amount of free space offset to the external boundary of the mesh at each
  side of input objects. This can be defined by [Spin2011,  p.7]:
    + The distance.
    + The number of cells.

Information is also required about each object in the input mesh:

* The surface type for surface objects: OPEN, CLOSED, FILLED [Spin2011, p. 17].
* The fill priority for filled surfaces [Fern2007].
* The effective refractive index for filled surfaces. This is used to
  determine the required mesh density inside object.
* Whether or not a surface is oriented. Requires investigation [Spin2011, p. 17]. 

The object mapping phase of the mesh generation may also require user defined
options. These options can be set globally but overridden on an object-by-object
basis: 

* The type of ray to use for mapping an object: NASH uses CROSS or MAGNETIC
  types [Spin2011, p.18 ]. CROSS type rays must cross a face in order for it to be
  included whereas MAGNETIC type rays can select a face based on a proximity
 factor.
* For MAGNETIC rays the range of attraction maybe adjusted - the TOUCHGRIP
  parameter in NASH  [Spin2011, p.18 ].
* For solid objects NASH defines different fill types, LOW, MEDIUM, HIGH and
  thresholds FILL_THRESHOLD_LOW, FILL_THRESHOLD_HIGH [Spin2011, p.20]. These
  control how many directions rays are cast from in order to resolve “blistering”
  issues.
* Surface mapping may require some parameterisation.  
* Wire mapping may require some parameterisation.


## Mesh generation


### Phase 1: Determination of structured grid lines

The algorithm given in [Fern2007] looks a promising place to begin. In outline:

1. Add overall bounding box of objects in input mesh to set of nodes.
2. Add extreme nodes of bounding box of each object in mesh to sets of nodes.
3. Add user defined nodes to sets of nodes.
4. Determine maximum refractive index along all intervals in each direction.
5. Use piecewise optimisation problem to determine intermediate nodes with
   penalties for breaking meshing constraints.
6. Construct and save structured mesh. 

Non-uniform algorithm:

Strategy 1: Use Dmin/dmax in centre of object and Dmax/dmin at interfaces.
            Dmin/dmax are mandatory everywhere.
            Dmax/dmin are advisory a boundaries and can be exceeded/inceeded
  
Strategy 2: Use close to Dmin/dmax where possible (without going under/over)
            and up/down to Dmax/dmin in order to meet constraints. 
            Dmin/dmax are mandatory everywhere.

Outline idea - three phases:
  
1. Assemble constraints into uniform representation.
2. Pass through constraint intervals and resolved global inconsistencies.
   * Points whose separation from neighbours is less than requested mesh size cannot be resolved.
   * Use smaller mesh size 
   * If really small coalesce points
   * Small mesh sizes need enough distance to reach larger sizes with ratio limit.
   * Pull down all dx 
3. Pass through all constraint intervals [X(i),X(i+1)] meshing locally.
   * Continue optimiser approach? 
   * Ideas in Spanish thesis?
   * Go through interval in order on increasing mesh size constrsint
     to pull down to most restrictive.

         
## Phase 2: Projection of objects onto structured grid


This is the most complex phase and crucial for obtaining viable meshes for EM
computation. Objects are mapped in the following order:

1. Solid objects
2. Surfaces
3. Wires
4. Nodes

Solid objects have to respect a meshing priority. Not clear whether to map all
together or individually according to meshing priority. The result of this
process is the creation of the list of elements in the structured mesh that
correspond to the named groups and groups of groups in the input unstructured
mesh. 

Notes:

* Use ray casting. 
* Simple information for solids is given in [Fern2007]
* Hints at features needed for complex meshes can be found in [Spin2011].
* Details about how to deal with thin boundaries are sparse.
* What about filled surfaces that are too thin for the mesh size? Convert to thin
  boundaries?

    
## Output structured mesh


The output should be a generic structured mesh:

* It could be represented as an unstructured mesh. This is how AMELET and NASH
  interact. However, it is a very inefficient way to deal with structured meshes
  and makes the subsequent conversion very inefficient.
* Are there any other simple “standard” ways to do this? The issue isn’t the
  definition of the grid lines but how the objects are defined on the mesh. A
  large metal plate aligned on a mesh only need two coordinates to define it
 completely but the AMELET approach defines it using all of its constituent mesh
  faces any there is no way, other than complex processing, to know it is a
  contiguous flat rectangular plate. So a vast number of individual faces could be
  generated in the native FDTD/TLM input file. All our codes deal with objects on
  the mesh in terms of bounding boxes that span multiple cells. Of course a
  bounding box can be just one face.
* Related to the above, the format should allow easy conversion to required
  formats below.

## Structured mesh converters


We need to convert the generic structured mesh into specific formats for our codes.

### AEG Vulture FDTD Code

The mesh in Vulture can be cubic, cuboid or nonuniform. In the most general
nonuniform case the mesh is defined by three lists of the x, y and z coordinates
of the mesh lines. Considering the x direction the coordinates of the nlx nodes
are denoted by x[0],...., x[nlx ‑ 1]. This corresponds to nx = nlx  ‑ 1
intervals or cells in the x direction. The cells are labeled by the mesh line
number on low coordinate side, so we have a total of nlx ‑ 2 cells labeled
0,....,nx ‑ 1. Bounding boxes on the mesh use nodes/line numbers from 0 to nx.
Similarly for the y and z directions. Cubic and cuboid mesh can also be defined
implicitly by the cell size in each direction.


        0     1     2                  nx-2  nx-1      Cell number
      -----------------         ------------------
     |     |     |     |  ..... |     |     |     |
      -----------------         ------------------
     0     1     2     3  .....           nx-1    nx   Node number
       
     |------> x


Bounding boxes defined as sextuples of integer mesh line numbers, <XLO> <XHI>
<YLO> <YHI> <ZLO> <ZHI>, that are applied uniformly as selectors on the mesh.
All cells/faces/edges/nodes that are on or within the bounding box and that are
compatible with the target physical model are selected. Some examples of
bounding boxes are:

    2 2 3 3 4 4   A node at (2,3,4)
    2 2 3 3 4 5   A z-directed edge
    2 2 3 3 4 7   A z-directed line 3 edges long
    2 2 1 2 1 2   An x-normal face
    2 2 1 5 1 5   An x-normal 4x4 face surface
    2 3 3 4 4 5   A single cell
    2 4 3 5 4 6   A 2x2x2 cell volume

Bounding boxes must be "normal", i.e. xhi >= xlo , yhi >= ylo and zhi >= zlo.
MB, TB, and TW selectors associate the bounding boxes of solid volumetric
objects (material blocks), surfaces (thin boundaries) and linear object (thin
wires) respectively with a physical model:

    MB <XLO> <XHI> <YLO> <YHI> <ZLO> <ZHI> <modelName>
    TB <XLO> <XHI> <YLO> <YHI> <ZLO> <ZHI> <modelName> [<orient> [ <angle> ] ]
    TW <XLO> <XHI> <YLO> <YHI> <ZLO> <ZHI> <modelName> [<end1Type>] [<end2Type>]

The parameters following the model name define how the model is applied to the
mesh elements, for example, the angle between the principal axes of an
anisotropic material and the mesh. All physical parameters are defined by other
objects and referenced by the model name. The full mesh specification is 

    VM <majorVersion>.<minorVersion>.<patchVersion>
    CE <comment>
    DM <nx> <ny> <nz>
    GS
    MT <name> <type> [ <param1> … <paramN> ]
    BT <name> <type> [ <param1> … <paramN> ]
    WT <name> <type> [ <param1> … <paramN> ]
    MB <xlo> <xhi> <ylo> <yhi> <zlo> <zhi> <name> [ <param1> … <paramN> ]
    TB <xlo> <xhi> <ylo> <yhi> <zlo> <zhi> <name> [ <param1> … <paramN> ]
    TW <xlo> <xhi> <ylo> <yhi> <zlo> <zhi> <name> [ <param1> … <paramN> ]
    WF <name> <type> [ <size> [ <delay> [ <width> [ <freq> ] ] ] ]
    WF <name> EXTERNAL <fileName> [ <size> [ <delay> ] ]
    EX <xlo> <xhi> <ylo> <yhi> <zlo> <zhi> <type> <waveformName> [ <size> [ <delay>] ]
    EX <xlo> <xhi> <ylo> <yhi> <zlo> <zhi> <type> <waveformName> <imped> [ <size> [<delay> ] ]
    PW <xlo> <xhi> <ylo> <yhi> <zlo> <zhi> <waveformName> <mask> <theta> <phi> <eta> [<size> [ < delay> ] ]
    OP <xlo> <xhi> <ylo> <yhi> <zlo> <zhi> <type> [<refWaveform>]
    OP <xlo> <xhi> <ylo> <yhi> <zlo> <zhi> <type> <XSTEP> <YSTEP> <ZSTEP> [<refWaveform>] 
    FF <xlo> <xhi> <ylo> <yhi> <zlo> <zhi> <theta1> <theta2> <num_theta> <phi1> <phi2> <num_phi> [ <mask> [<refWaveform>] ]
    GE
    NT <numSteps>
    CN <courantNumber>
    OT <tstart> <tstop>
    OF <fstart> <fstop> <numFreq>
    MS <delx> [ <dely> < delz> ] ]
    XL 
    <x[0]>
    .....
    <x[nx]>
    YL 
    <y[0]> 
    .....
    <y[ny]>
    ZL
    <z[0]> 
    .....
    <z[nz]>
    EN

In addition to the syntax the semantics of how the mesh is interpreted is very
important. Some key points are:

1. Irrespective of the order objects are declared in the mesh file they are 
   applied to the grid in the following order:
     a. MBs in order found in the mesh
     b. TBs in order found in the mesh
     c. TWs in order found in the mesh
     d. EXs in order found in the mesh
     e. PWs in the order found in the mesh
 2. MB/TB/TW objects of type PEC, FREE_SPACE and SIMPLE will overwrite each other
   without side effects since they are all implemented through the material
   coefficient arrays. Other types (e.g SIBCs and frequency dependent materials)
   will *NOT* overwrite and will probably generate indeterminate results.
3. Depending on the compilation options, the material parameters of MBs are
   averaged at block surfaces to ensure correct second order accuracy. It is not
   yet clear how frequency dependent materials will be dealt with.
4. Bounding boxes for observers select the nodes in and on the bounding boxes
   consistent with the observer type and parameters. This makes post-processing and
   viewing the data more straightforward as the data is defined at the nodes of the
   input mesh. (This is not implemented yet – observers still dump fields at the E
   and H field points of the primary and secondary grids. Eventually all quantities
   will also be temporally interpolated to E field times as well.)

### AEG FDTD code Falcon

The UoY AEG FDTD code “Falcon” only supports uniform cubic meshes.

    CE <comment>
    DM <NX> <NY> <NZ>
    BR <rho_xlo> < rho_xhi> <rho_ylo> <rho_yhi> <rho_zlo> <rho_zhi>
    TB <xlo> <xhi> <ylo> <yhi> <zlo> <zhi> <type> <rho>
    TW <xlo> <xhi> <ylo> <yhi> <zlo> <zhi> <orien> <radius>
    MB <xlo> <xhi> <ylo> <yhi> <zlo> <zhi> <mu_r> <eps_r> <g0> <r0> <rm>
    MC <xlo> <xhi> <ylo> <yhi> <zlo> <zhi> <radius> <mu_r> <eps_r> <g0> <r0> <rm>
    EX <xlo> <xhi> <ylo> <yhi> <zlo> <zhi> <orient> <size> <type> <params>
    VR <xlo> <xhi> <ylo> <yhi> <zlo> <zhi> <orient> <size> <type> <Rs>
    OP <xlo> <xhi> <xstep> <ylo> <yhi> <ystep> <zlo> <zhi> <zstep>
    GE
    SM <pos1> <pos2> <hpos> <orient> <height> <radius> <angle> <dangle> <npos> <zerofld>
    NT <niterations>
    OT <outstart> <outstop>
    MS <meshsize>
    PP <xlo> <xhi> <ylo> <yhi> <zlo> <zhi> <comp>
    EN

### AEG TLM cod Hawk

The UoY AEG TLM code “Hawk” only supports uniform cubic meshes.

    CE <comment>
    DM <NX> <NY> <NZ>
    BR <rho_xlo> < rho_xhi> <rho_ylo> <rho_yhi> <rho_zlo> <rho_zhi>
    TB <xlo> <xhi> <ylo> <yhi> <zlo> <zhi> <type>
    TE <romin> <fmin> <rohi> <fhi> <roul> <dir>
    TE <rho_lo> <tau_hl> <rho_hi> <tau_lh>
    TE <mu_r> <eps_r> <sigma> <thick> <freq>
    MB <xlo> <xhi> <ylo> <yhi> <zlo> <zhi> <mu_r> <eps_r> <g0> <r0> <rm>
    EX <xlo> <xhi> <ylo> <yhi> <zlo> <zhi> <orient> <size> <type> <params>
    OP <xlo> <xhi> <xstep> <ylo> <yhi> <ystep> <zlo> <zhi> <zstep>
    GE
    SM <pos1> <pos2> <hpos> <orient> <height> <radius> <angle> <dangle> <npos> <zerofld>
    NT <niterations>
    OT <outstart> <outstop>
    MS <meshsize>
    PP <xlo> <xhi> <ylo> <yhi> <zlo> <zhi> <comp>
    EN

  
## Implementation

### Requirements

* Must be cross platform – Linux (32/64-bit), Windows (32/64-bit).
* Must use “open-source” technologies.
 Must be maintainable by “us”.
* We may want to license the code under GPL and/or commercial terms. Choice of
  technologies should allow this. 

### Language options

* C99: Fast, simple, portable but no OO may make it cumbersome for this
  application.
* C++: “Dogs dinner” of a language. No doubt it can do it and will be fast but
  probably best to avoid unless very experienced.
* Fortran95: Fast, portable, some OO. 
* Java: Portable, somewhat open, lots of class libraries. [Fern2007] used it.
* Python: Portable, widely used for scientific purposes, some experience in AEG.
  Probably prime contender providing there are support packages for the heavy
  ray-tracing stuff.

### Libraries 

Re-use existing libraries if possible and convenient, but avoid needless dependencies: 

* “Java3D” may be useful if using Java [Fern2007].
* Some of the OSS CAD/meshing tools use python as a scripting language and may
  have usable components.

### Development tools

* MATLAB/Octave or Python may be useful for prototyping ideas.
* Use Mercurial for version control.
* If using C/C++/F95 use valgrind memory debugger routinely. 
* Use Cmake for building if appropriate (depends on language).
* Create a test-suite. CTest is good driver if using CMake.


## References


[Bala1989] C. A. Balanis, Advanced Engineering Electromagnetics, John Wiley,
1989. 

[Afto] M. J. Aftosmis, M. J. Berger and J. E. Melton, “Adaptive Cartesian mesh
generation”.

[Gira2011] C. Giraudon, “Amelet-HDF Documentation”, Release 1.5.3, Axessim, 15
November, 2011.

[Fern2007] H. M. L. A. Fernandes, “Development of software for antenna analysis
and design using FDTD”, Dissertation, University of Lisbon, September 2007.

[Flub2003] Flubacher and R. Luebbers, “FDTD mesh generation using computer
graphics technology”, ???, IEEE Symposium on, pp. 323-326, 2003.

[Geuz2012] C. Geuzaine, “Gmsh Reference Manual: The documentation for Gmsh 2.6 A
finite element mesh generator with built-in pre- and post-processing
facilities”, 15 July 2012.

[HDF5] The HDF Group, Hierarchical Data Format, Version 5. URL:
http://www.hdfgroup.org/HDF5

[Hill1996] J. Hill, “Efficient Implementation of Mesh Generation and FDTD
Simulation of Electromagnetic Fields”, Master of Science Thesis,  Worcester
Polytechnic Institute, August 1996.

[Ishi2008] T. Ishida, S. Takahashi and K. Nakahashi, “Efficient and robust
Cartesian mesh generation for building-cube method”, Journal of Computational
Science and Technology. vol. 2, no. 4, pp. 435-437, 2008.

[Kana1998] Y. Kanai and K. Sato, “Automatic mesh generation for 3D
electromagnetic field analysis by FDTD method”, Magnetics, IEEE Transactions on,
vol. 34, no. 5, pp. 3383-3386, September 1998.

[Kim2011] H.-S. Kim, I. Ihm and K. Choi, “Generation of non-uniform meshes for
finite-difference time-domain simulations”, Journal of Electrical Engineering &
Technology, vol. 6, no. 1, pp. 128-132, 2011. DOI: 10.5370/JEET.2011.6.1.128.

[MacG2008] J. T. MacGillivray, “Trillion cell CAD-based cartesian mesh generator
for the finite-difference time-domain method on a single-processor 4-GB
workstation”, Antennas and Propagation, IEEE Transactions on, vol. 56, no. 8,
pp. 2187-2190, August 2008.

[Spin2011] P. Spinosa and N. Muot, “Software User Manual of NASH in CuToo”,
Release 1.2.0, 27 September 2011, Axessim.

[Sris2002] Y. Srisukh, J. Nehrbrass, F. L. Teixeira, J.-F. Lee and R. Lee, “An
approach for automatic grid generation in three-dimensional FDTD simulations of
complex geometries”, IEEE Antennas and Propagation Magazine, vol. 44, no.4, pp.
75-80, August 2002.

[Sris2003] Y. Srisukh, J. Nehrbuss, F. L. Teixeira. JLF. Lee, and R. Lee,
“Automatic grid generation of complex geometries for 3-D FDTD  simulations”,
???, IEEE Symposium on, pp. 326-329, 2003.

[Sun1993] W. Sun, C. A. Balanis, M. P. Purchine and G. C. Barber,
“Three-dimensional automatic FDTD mesh generation on a PC”, IEEE Symposium on,
pp. 30-33, 1993.

[Wang2009] S. Wang and J. H. Duyn, “Three-dimensional automatic mesh generation
for hybrid electromagnetic simulations”, IEEE Antennas and Propagation Magazine,
vol. 51, no.2, pp. 71-85, April 2009.

[Yang1999] M. Yang and Y. Chen, “AutoMesh: An automatically adjustable,
non-uniform, orthogonal FDTD mesh generator”, IEEE Antennas and Propagation
Magazine, vol. 41, no.2, pp. 13-19, April 1999.

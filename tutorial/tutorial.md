
# AEG Mesher: Tutorial Example: AEG Enclosure Validation Test Case

[TOC]

## Prerequisites

This tutorial assumes you that the mesher software and Gmsh have already
been installed on your computer using the installation instructions in
[Install.md][]. The example uses GNU [Octave][] on a Linux system but
can easily be followed using [MATLAB][] and Windows based systems.

It is also assumed that you have some familiarity with [Gmsh][] and unstructured
meshes in general. If not, it is recommended that you have a look at the
[Gmsh manual][] and follow through one or two of the 
[tutorials](http://geuz.org/gmsh/#Documentation) from the Gmsh web-site 
before starting this tutorial.

## Overview

![Figure 1: The test object geometry][Figure1]

The tutorial works through in detailed the meshing of one of the test
configurations from the [AEG Box Test Suite][] ([Flintoft2016][]). The 
configuration to be meshed is shown in Figure 1. It consists of five 
distinct objects:

1. A metal enclosure (EN) with a large aperture in one face.

2. A cubic block of radio-absorbing material (A1).

3. A short probe antenna at port-A of the enclosure (PA).

4. A second identical probe at port-B of the enclosure (PB).

5. A straight wire connecting the tips of the two probes (SW).

Object 2 is volumetric, object 1 is a surface and objects 3 to 5 are
linear. The enclosure and RAM share a common surface of intersection
(where the base of the cube sits on the floor of the enclosure).

We will generate a uniform cubic structured mesh of the system as might be
used by an FDTD code. We assume that the target solver has the following
modelling capabilities:

1. A thin metal sheet model. The enclosure should therefore be represented 
   as a surface in the structured mesh.
   
2. A volumetric medium model requiring the RAM to be presented as a volume 
   in the structure mesh.
   
3. A thin wire model that does not mesh the inside of the wires but requires
   the curve along the central axis of each wire. 

## Creating an input geometry

The first step in the AEG Mesher work-flow is create a representation of the
structure using an unstructured mesh. This can be done using many different
tools or could even be scripts using an Octave function. In this tutorial we
will use [Gmsh][] to create the unstructured mesh by specifying primitive geometrical
objects in Gmsh's native BREP format.

Copy the input geometry [tutorial.geo][] from the tutorial directory of the
software distribution into a working directory and open it using
a text editor. It is beyond the scope of this tutorial to describe using Gmsh
to create and manipulate unstructured meshes. However, the following should 
be noted:

* Each object is represented by a named "physical" group of elements.

* Gmsh only outputs elements that belong to physical groups.
 
* The elements forming the common surface of the enclosure and block of RAM 
  are contained in the physical groups for both objects.

Now close the file and open it again using Gmsh:

    $ gmsh tutorial.geometry

You can use mouse to change angle of view and scroll the mouse wheel to 
zoom in and out. The initial view is of the input BREP objects. To 
create an unstructured mesh of these objects from the menu tree to the 
right choose "Modules" -> "Mesh" -> "2D".

To see the generated mesh more clearly from the top menu bar choose
"Tools" -> "Options" to bring up the "Options" window. In this window 
choose "Mesh" in the left pane and then in the "Visibility" tab to the 
right activate the "Edges", "Surface faces" and Volume faces" radio 
buttons. This will render the surfaces using difference colours. In 
the "Color" tab select "By physical group" in the "Coloring mode" 
drop-down menu. This colours all elements belonging to the same physical 
group in the mesh the same colour. You should have something that looks 
like Figure 2.

![Figure 2: Unstructured mesh of the test object viewed in Gmsh][graph]

To select and deselect different groups, from the top menu bar choose
"Tools" -> "Visibility" and in the "List Browser" Tab you can select
and deselect different physical groups. You can use Ctrl and Shift to
select/deselect multiple groups. So, to just see the enclosure, click on 
the line with "Name" "EN" and then click "Apply". Ctrl-A then "Apply" in 
the list will select all the groups again.

Note that this mesh would not be suitable for simulation in a finite-element
or method-of-moments code. The mesh density is far too low. However, for the
purposes of creating a structured mesh, providing it adequately described the
shape, particularly of curve surface, then the size of the mesh elements is
not important. 

To save the generated mesh from the top menu bar choose "File" -> "Save Mesh".
This should create a file called "tutorial.msh".

Now close Gmsh.

## Loading the geometry into Octave

All the command for the following section are contained in the function file
[meshTutorialExample.m][] in the tutorial directory if you wish to cut and
paste them rather than type them!

Start Octave in the same working directory.

    $ octave

It is assumed that you have already installed AEG Mesher according to the 
installation instructions and that its functions are in the load path.

To read in the unstructured mesh we just created use the meshReadGmsh function:

    octave> [ mesh ] = meshReadGmsh( 'tutorial.msh' );

This should be fairly quick. The mesh is now stored in the structure named "mesh".
If you want to see it just type

    octave> mesh

with no semi-colon. The mesh can be save in its native format to a "mat" file using 

    octave> meshSaveMesh( 'tutorial_input_mesh.mat' , mesh );

This will allow faster loading of large meshes than reading the Gmsh file each time.
The mesh just saved can be reloaded using:

    octave> mesh = meshLoadMesh( 'tutorial_input_mesh.mat' );

## Defining the mesh generation options

In order to create a structured version of the mesh we have to supply some meshing
options. Some of these are global options and some can be specified separately for 
each object group. To set the defaults for all these options type:

    octave> [ options ] = meshSetDefaultOptions( mesh.numGroups , 'useDensity' , false , 'dmin' , 1e-2 , 'dmax' , 1e-2 );

The first argument gives the number of mesh groups to set up default options for. Each subsequent
pair of arguments is an option name and value pair for the per-group options that over-rides the 
built in defaults. Here 'useDensity' is set to false, meaning do not construct the mesh based on 
constraints on the density of mesh lines. Rather we constrain the actual mesh size for the region 
occupied by each object to values between dmin and dmax. In this case dmin is equal to dmax because 
we are going to create a uniform cubic mesh. The options are returned in the structure called options. 
This structure has a number of members. Firstly these is a struct-array called groups of dimension 
equal to the number of groups in the mesh. Each member of this struct-array is in turn a structure 
holding the meshing options for that group. So, for example, to see the  options for group number 2 type

    octave> options.group(2)

The options structure also contains an member called mesh which contains the global meshing options
and the options to be applied to the free space around the objects. It can be viewed with

    octave> options.mesh

We need to change some of the default options here. First, we haven't specified
the computational volume of the target structured mesh in the input unstructured mesh
so we need to set

    octave> options.mesh.useMeshCompVol = false;

and then provide the computational volume with:

    octave> options.mesh.compVolAABB = [ 0.0 , 0.0 , 0.0 , 0.5 , 0.6 , 0.3 ];

In the same way as we switched from density based constraints to mesh size based
constraints for each object above we do the same for the rest of the computational
volume:
  
    octave> options.mesh.useDensity = false ;
    octave> options.mesh.dmin = 1e-2;
    octave> options.mesh.dmax = 1e-2;  
  
The default mesh type is CUBIC, but we can set it anyway with:

    octave> options.mesh.meshType = 'CUBIC';

Now we have to specify which groups in the unstructured mesh are to be mapped. These
are given in a cell-array of strings - let's do them all:
  
    octave> groupNamesToMap = { 'A1' , 'EN' , 'PA' , 'PB' , 'SW' }; 
  
These names must match those in the input mesh file exactly. To get the group number (index)
for each group we call a helper function:
  
    octave> groupIdxToMap = meshGetGroupIndices( mesh , groupNamesToMap );

It is useful to make some labels to help keep track of the indices for each group:

    octave> idxA1 = groupIdxToMap(1);
    octave> idxEN = groupIdxToMap(2);
    octave> idxPA = groupIdxToMap(3);
    octave> idxPB = groupIdxToMap(4);  
    octave> idxSW = groupIdxToMap(5);
  
Now for each group we provide mapping options. Group 'A1' is a solid block
of absorber represented by its closed boundary surface. We want to map this 
as a volumetric material object:
  
    octave> options.group(idxA1).type = 'VOLUME';
    octave> options.group(idxA1).materialName = 'LS22';
 
The material name is used for a number of purposes. If using density based 
constraints (which we are not doing here) the material properties are looked up
in a database to determine the maximum cell size to be applied in that region.
Of course the material must be in the database for this to work!
The names can also be used by mesh exporters to automatically provide the 
correct material models for each object.

The enclosure itself is a perfectly conducting open metal surface so we give
the options:

    octave> options.group(idxEN).type = 'SURFACE';
    octave> options.group(idxEN).materialName = 'PEC';
  
The other three groups are metal wires so the correct mapping options are:

    octave> options.group(idxPA).type = 'LINE';
    octave> options.group(idxPA).materialName = 'PEC';
    octave> options.group(idxPB).type = 'LINE';
    octave> options.group(idxPB).materialName = 'PEC';
    octave> options.group(idxSW).type = 'LINE';
    octave> options.group(idxSW).materialName = 'PEC';

## Creating a set of mesh lines

We can now do the first stage of the mesh generation - creating a set of structured
mesh lines using:

    octave> [ lines ] = meshCreateLines( mesh , groupNamesToMap , options );

The mesh lines are returned in a structure with members x, y and z. The mesh lines
along x can be viewed using

    octave> lines.x

In fact you can create the mesh lines however you like or modify them by hand.

## Mapping the objects onto the structured mesh

Now we map each object from the unstructured mesh onto the structured mesh specified by
these mesh lines:

    octave> [ smesh ] = meshMapGroups( mesh , groupNamesToMap , lines , options );

This will take a few seconds if you've used the same parameters as above. The structured
mesh is stored in another structure. We can save this to a mat file using

    octave> meshSaveMesh( 'tutorial_structured_mesh.mat' , smesh );

## Viewing the structured mesh

It is difficult to interpret structured mesh structure directly so it is best to view it
in Gmsh. To do this we first convert the structured mesh into an unstructured format using
  
    octave> [ unmesh ] = meshSmesh2Unmesh( smesh );

and then export it as a Gmsh mesh file with

    octave> meshWriteGmsh( 'tutorial_structured_mesh.msh' , unmesh );

This mesh file can then be opened with Gmsh

    $ gmsh tutorial_structured_mesh.msh 

and viewed in the same way as the original unstructured mesh. You will need to
set the visibility on the edges, surface faces and volume faces in the Options
as before for a clear view. You should have something similar to Figure 3.

![Figure 3: The structured mesh viewed in Gmsh][Figure3]

To merge the original input mesh on top of the structured mesh choose 
"File" -> "Merge" and select the file "tutorial.msh". This can be difficult to 
understand, however, you should be able to see how well the two meshes match. 
Note in this case the slight offset in the wire positions due to the limited ability 
of the cubic mesh to accommodate the original geometry (see Figure 4).

![Figure 4: Merged input unstructured mesh and output structured mesh][Figure4]

## Exporting the structured mesh to a solver

Once you are happy with the structured mesh it can then be exported for use in a solver.
At the moment we only have an exporter for Vulture so let's try that:

    octave> options.export.useMaterialNames = false;
    octave> meshWriteVulture( 'vulture.mesh' , smesh , options );

The option useMaterialNames tells the exporter to use the group name to tag the 
objects in the Vulture mesh rather than the material names. The output is written to 
the file 'vulture.mesh'. If you've got Vulture on your system you can use its 
graphical tool, gvulture, to read this mesh and output it in Gmsh format again:

    $ gvulture -e -m vulture,mesh

The mesh is written to a file called mesh.msh and if you open it in Gmsh it should look
identical to that in the file tutorial_structured_mesh.msh.

## Concluding remarks

It is usually best to put all these commands into an Octave function rather than doing
the meshing interactively, such as [meshTutorialExample.m][].

For further examples take a look at the test-suite in the source distribution.
Each sub-directory in the [test directory][] contains an input mesh and a function to set 
the meshing options. You can load the mesh and meshing options and follow through the steps 
above for each test object.

Further details of the full capabilities can be found in the [user manual][].


## References

[Flintoft2016]: http://dx.doi.org/10.1109/TEMC.2016.2601658

([Flintoft2016]) I D Flintoft, J F Dawson, L Dawson, A C Marvin, J Alvarez and S G. Garcia, 
“A modular test suite for the validation and verification of electromagnetic solvers in 
electromagnetic compatibility applications”, IEEE Transactions on Electromagnetic Compatibility, 
in press, 2016.



[Figure1]: https://github.com/flintoftid/aegmesher/blob/master/tutorial/figure1.jpg "The test object geometry"
[Figure2]: https://github.com/flintoftid/aegmesher/blob/master/tutorial/figure2.jpg "Unstructured mesh of the test object viewed in Gmsh"
[Figure3]: https://github.com/flintoftid/aegmesher/blob/master/tutorial/figure3.jpg "The structured mesh viewed in Gmsh"
[Figure4]: https://github.com/flintoftid/aegmesher/blob/master/tutorial/figure4.jpg "Merged input unstructured mesh and output structured mesh"

[Octave]: http://www.gnu.org/software/octave
[MATLAB]: http://www.mathworks.co.uk/products/matlab
[Install.md]: https://github.com/flintoftid/aegmesher/blob/master/Install.md
[Gmsh]: http://geuz.org/gmsh
[user manual]: https://github.com/flintoftid/aegmesher/blob/master/doc/UserManual.md
[Gmsh manual]: http://geuz.org/gmsh/doc/texinfo/gmsh.html
[AEG Box Test Suite]: (https://github.com/flintoftid/aegboxts
[tutorial.geo]: https://github.com/flintoftid/aegmesher/blob/master/tutorial/tutorial.geo
[meshTutorialExample.m]: https://github.com/flintoftid/aegmesher/blob/master/tutorial/meshTutorialExample.m
[test directory]: (https://github.com/flintoftid/aegmesher/blob/master/tests


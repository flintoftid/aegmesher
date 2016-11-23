# AEG Mesher: User Manual

Ian Flintoft, Michael Berens

[TOC]

This manual is a **work in progress** and may not be consistent with
the current version of the code!**

# Overview

The mesh generator takes a description of a physical structure in the form of an 
unstructured mesh and then, using options provided by the user, creates a structured mesh 
representation of the structure. The mesh generator and associated utilities are able 
to read unstructured meshes in [Gmsh][] and [AMELET-HDF][] format. The target structured 
mesh can be cubic, uniform or non-uniform. The input unstructured mesh can contain 
any number of physical objects defined by groups of mesh elements. These groups can 
define point-like, linear, surface or volumetric objects.

The software is script-driven using the GNU [Octave][] language which allows it to be
easily extended and combined with other phases of an overall simulation work-flow. 
The meshing  is performed in two stages:

1. The input unstructured mesh is first analysed together with the user provided options and 
   a set of mesh lines generated that optimally satisfy the meshing constraints. The key 
   constraints are the maximum and minimum cell size each object in the mesh. 

2. Each object in the unstructured mesh is then mapped onto the structured mesh.

Currently *aegmesher* can export the structured meshes in the [AEG][] [Vulture][] FDTD Code format. 
Other formats can easily be added.

The package also has some limited support for transforming unstructured meshes into formats suitable for
use in the [CONCEPT-II][] method-of-moments code.

# Unstructured meshes

The physical structure to be meshed must be described using
an unstructured mesh containing each physical object. The 
internal format of the unstructured mesh is described in Appendix A.

Each material object is represented as a named 
group of mesh elements. Elements of dimension
0 (points), 1 (lines), 2 (surfaces) and 3 (volume)
are supported by the format. Common element types
are given in the following table.

Mesh element type | Number of nodes | Description
:-----------------|:----------------|:--------------------
node1             | 1               | single node
bar2              | 2               | line element
tri3              | 3               | triangle
quad4             | 4               | planar quadrilateral
hex8              | 8               | hexahedron

However 3-dimensional elements are not used for structured 
mesh generation - volumetric physical objects should be described 
by their closed boundary surface. Also, currently only triangular 
surface  elements are supported by the mesh mapping functions. 
The representation of physical objects in the structured mesh 
should therfore follow the rules summarised in the table below.

Physical object | Unstructured mesh representation  | Supported element types
:---------------|:----------------------------------|:------------------------
volumetric      | closed bounding surface           | tri3
surface         | open or closed surface            | tri3
linear/wire     | lines                             | bar2
points          | nodes                             | node1

Each group of elements must be a complete representation of 
the object. In particular any elements belonging to shared 
intersection surfaces between two touching solid objects must 
be included in the groups for both objects. Meshing of objects 
is done individually, so although the input mesh can contain 
duplicate elements, e.g. for shared surfaces, the duplicate 
elements must be identical to avoid meshing artefacts.

## Importing and exporting unstructured meshes

### Unstructured mesh import

The mesher supports importing unstructured meshes in
the following formats:

1. The [Gmsh][] ASCII format version 2.
2. The [AMELET-HDF][] format.
3. The [CONCEPT-II][] surface format. 

Other formats, such as STL, can be loaded into Gmsh and then
saved in the Gmsh format to enable them to be imported into
the mesher.

#### meshReadGmsh()

    [ mesh ] = meshReadGmsh( mshFileName , groupFormat )
    
#### meshReadAmelet()

    [ mesh ] = meshReadAmelet( h5FileName , meshGroupName , meshName )

The functions requires that the [HDF5][] command line tools 
are installed on the system.

#### meshReadSurf()

    [ mesh ] = meshReadSurf( surfFileName , groupName )

### Unstructured mesh export

Unstructured meshes can be exported in the following formats:

1. The [Gmsh][] ASCII format version 2.
2. The [CONCEPT-II][] surface/wire format. 

#### meshWriteGmsh()

    meshWriteGmsh( mshFileName , mesh  , groupNames )

#### meshWriteSurf() and meshWriteWire()

    meshWriteSurf( surfFileName , mesh , groupNames )
    meshWriteWire( wireFileName , mesh , groupNames )
    
### Unstructured mesh conversion

For convenience a number of functions are provided to
convert meshes between different formats. 

#### meshAmelet2Gmsh()

    meshAmelet2Gmsh( mshFileName , h5FileName , meshGroupName , meshName )
    
#### meshGmsh2Concept()

    meshGmsh2Concept( mshFileName )
    
#### meshGmsh2Surf() and meshGmsh2Wire()

    meshGmsh2Surf( surfFileName , mshFileName , groupNames )
    meshGmsh2Wire( wireFileName , mshFileName , groupNames )
    
#### meshSurf2Gmsh()

    meshSurf2Gmsh( mshFileName , surfFileName , groupName )

## Saving and loading unstructured meshes

Meshes in the native AEG_Mesher format can be saved in 
mat file format.
 
#### meshSaveMesh()

    meshSaveMesh( matFileName , mesh )

#### meshLoadMesh()

    [ mesh ] = meshLoadMesh( matFileName )
    
## Unstructured mesh utilities

#### meshMergeUnstructured()

    [ mesh ] = meshMergeUnstructured( mesh1 , mesh2 )
    
#### meshCylinders()

    [ mesh ] = meshCylinders( endPoints , radius , numSides )
    
#### meshSpheres()

    [ mesh ] = meshSpheres( centres , radii , numSides )
    
# Structured mesh generation

## Overview

Meshing a physical structure proceeds according to the following steps:

1. Import/create an unstructured mesh.
2. Set the meshing options - both global and for each physical group.
3. Generate a set of mesh lines.
4. Map each physical object onto the structured mesh.
5. Export the structured mesh to the required format.

The default meshing options can be set using

    options = meshSetDefaultOptions( numGroups [ , optName , optValue ] )

where `numGroups` is the number of groups in the unstructured mesh. For an
unstructured mesh stored in a structure called `unmesh` this can
be found using

    numGroups = unmesh.numGroups

The optional arguments are **pairs** of option name and values pair for 
per-group options that over-rides the built-in defaults.

The options are returned in a structure which has two members:

1. A struct-array called `groups` of dimension equal to the 
   number of groups. Each member of this struct-array is in turn a 
   structure holding the meshing options for that group.
2. Another structure called `mesh` which contains the global meshing 
   options and the options to be applied to the free space around the objects. 

The options are described in detail in the following sections. The index of the 
group in `options.groups()` should match the index of the group in the input 
mesh. The helper function `meshGetGroupIndices()` can be used to get the
indices of particular named groups:

    groupIndices = meshGetGroupIndices( groupNamesToMap )

    options.groups(groupIdx).<perGroupOptionName> = <optionValue>
 
    options.mesh.<globalOptionName> = <optionValue>
    
Once the options are set the mesh line are created using the `meshCreateLines()`
function

    [ lines ] = meshCreateLines( unmesh , groupNamesToMap , options );

This returns a structure called `lines` with fields `x`, `y` and `z` containing
the mesh line coordinates. The groups in the unstructured mesh are then mapped
onto the structured mesh using `meshMapGroups()`:
    
    [ smesh , soptions ] = meshMapGroups( unmesh , groupNamesToMap , lines , options );

This returns the structured mesh in the structure `smesh` and the meshing options
for the mapped groups in `soptions`.
    

## Mesh line generation options

### Global options
 
options.mesh.<optionName>

Name             | Type         | Default      | Units   | Range
:----------------|:------------:|:------------:|---------|:--------------------------------
meshType         | string       | 'CUBIC'      | n/a     | 'CUBIC', 'UNIFORM', 'NONUNIFORM'
useMeshCompVol   | boolean      | true         | n/a     | true, false
compVolName      | string       | 'CompVolume' | n/a     |
compVolAABB      | real(1x6)    | []           | m       | >=-Inf, <=Inf 
epsCompVol       | real         | 1e-6         | [FIXME] | >=0
compVolIsTight   | boolean(1x6) | all false    | n/a     | true , false
useDensity       | boolean      | true         | n/a     | true, false
dmin             | real         | []           | m       | >0
dmax             | real         | []           | m       | >0
maxRatio         | real         | 1.5          | n/a     | >=1
maxAspect        | real         | 2.0          | n/a     | >=1
Dmin             | real         | 10           | n/a     | >0
Dmax             | real         | 10           | n/a     | >0, >=Dmin
minFreq          | real         | 1e6          | Hz      | >=0
maxFreq          | real         | 3e9          | Hz      | >=0, >=minFreq
numFreqSamp      | integer      | 50           | n/a     | >=1
epsCoalesceLines | real         | 1e-4         | [FIXME] | >=0
lineAlgorithm    | string       | 'OPTIM1'     | n/a     | 'OPTIM1', 'OPTIM2'
costAlgorithm    | string       | 'RMS'        | n/a     | 'RMS', 'MEAN', 'MAX'
costFuncTol      | real         | 1e-6         | [FIXME] | >=0.0
maxOptimTime     | real         | 5            | s       | >=0.0
maxOptimEvals    | integer      | 10000        | n/a     | >=0
isPlot           | boolean      | false        | n/a     | true, false

#### meshType

Determines whether to use uniform or non-uniform mesh lines.

#### useMeshCompVol

Indicates the computational volume should be determined from the bounding
box of a group contained in the input mesh.

#### compVolName

Name of the mesh group to use for determining the computational volume. Only
effective when useMeshCompVol is true.

#### compVolAABB

Provides the AABB as row vector, [ x_lo y_lo z_lo x~_hi y_hi z_hi ], containing the bounding box
coordinates to use for the computational volume. Used if useMeshCompVol is false.
If empty and useMeshCompVol is false the minimal AABB of the objects to be mesh is used as 
computational volume.

#### epsCompVol

Tolerance [FIXME].

#### compVolIsTight

Not implemented yet.

Booleen vector indicating if the lowest and highest mesh lines in each direction should be 
forced to be exactly conincident with the computational volume. This is only possible on 
non-uniform meshes.

#### useDensity

Boolean indicating whether or not to use density based mesh line creation. If false
absolute mesh size much be specified using dmin and dmax. If true then mesh lines
density bounds should be specified using Dmin and Dmax. The mesh size constraints
for the computational voulem will be determined from the specified mesh densities 
and the material properties of the object over the range specified by the global 
minFreq and maxFreq parameters.

#### dmin 

A real scalar specifying the minimum global mesh size of the computational volume. Used if useMeshCompVol is false
and useDensity is false.

#### dmax

A real scalar specifying the maximum global mesh size of the computational volume. Used if useMeshCompVol is false
and useDensity is false.

#### maxRatio

Maximum cell size ratio between neighbouring cells.

#### maxAspect

Maximum cell aspect ratio to allow in the mesh.

#### Dmin 

A real scalar specifying the minimum global mesh line density of the computational volume. Used if useMeshCompVol is false
and useDensity is true.

#### Dmax

A real scalar specifying the maximum global mesh line density of the computational volume. Used if useMeshCompVol is false
and useDensity is true.

#### minFreq

Minimum frequency for the mesh. Used to determine mesh line densities and waveform parameters if useDensity is true.

#### maxFreq

Maximum frequency for the mesh. Used to determine mesh line densities and waveform parameters if useDensity is true.

#### numFreqSamp 

Number of frequency samples to use for evaluation of complex permittivities of
materials when the maximum mesh sizes are being determined from material database and 
mesh densities. Used if useDensity is true.

#### epsCoalesceLines

Tolerance [FIXME] below which constraint points are merged before the mesh line
generation algorithm is run. Currently uses non-transistive algorithm so use with care!

#### lineAlgorithm

Chooses the algorithm used for optimsiation of the location of the mesh lines.
[FIXME] 'OPTIM1', 'OPTIM2'.

#### costAlgorithm

Chooses the cost function used in the optimisation of the mesh line locations. The cost
function can attempt to minimise the root-mean-square ('RMS'), mean ('MEAN') or maximum ('MAX')
deviation between the mesh lines and the constraints points. The default is 'RMS'.

#### costFuncTol

Stopping tolerance on the cost functions used for optimisations used to determine mesh line locations.
[FIXME] units?

#### maxOptTime

Maximum time in seconds for optimisations used to determine mesh line locations. After this time the best
solution so far will be used.

#### maxOptimEvals

Maximum number of objective function evaluations for optimisations used to 
determine mesh line locations. After this number of evaluations the best
solution so far will be used.

#### isPlot

Determines whether to plot mesh line generation statistics.

### Per group options

options.group(groupIdx).<optionName>

Name         | Type    | Default    | Units | Range
:------------|:-------:|:----------:|:-----:|:----------------
materialName | string  | 'PEC'      | n/a   | arbitrary string
useDensity   | boolean |  true      | n/a   | true, false
dmin         | real    | 1e-2       | m     | >0.0
dmax         | real    | 1e-2       | m     | >0.0, >=dmin
Dmin         | real    | 10.0       | n/a   | >0.0
Dmax         | real    | 20.0       | n/a   | >0.0, >=Dmax
weight       | real    | 1.0        | n/a   | >=-Inf, <=Inf

#### materialName

Name of the material an object is composed of. Used for determining
mesh density from material database if useDensity is true. The material
name must be in the material database.

#### useDensity

Boolean indicating whether or not to use density based mesh line creation for a
group. If false absolute per-group mesh size much be specified using dmin and dmax. 
If true then per-group mesh lines density bounds should be specified using Dmin and Dmax. 
The mesh size constraints for the computational voulem will be determined from the 
specified mesh densities and the material properties of the group over the range 
specified by the global minFreq and maxFreq parameters.

#### dmin 

A real scalar specifying the minimum mesh size of the group. Used per-group option 
useDensity is false.

#### dmax

A real scalar specifying the maximum mesh size of the group. Used if per-group option
useDensity is false.

#### Dmin 

A real scalar specifying the minimum mesh line density of the group. Used if per-group option
useDensity is true.

#### Dmax

A real scalar specifying the maximum mesh line density of the group. Used if per-group option
useDensity is true.

#### weight

Weighting factor used for constraint points in this group.

## Group mapping options

### Global options
 
options.mesh.<optionName>
  
Name | Type | Default | Units | Range     
:----|:----:|:-------:|:-----:|:----------
     |      |         |       |  

### Per group options

options.group(groupIdx).<optionName>

Name                  | Type    | Default     | Units   | Range
:---------------------|--------:|:-----------:|:-------:|:--------------------------------------------------------------
type                  | string  | 'VOLUME'    | n/a     | 'VOLUME', 'SURFACE', 'CLOSED_SURFACE' , 'THICK_SURFACE' , 'WIRE', 'BBOX', 'NODE' 
physicalType          | string  | 'MATERIAL'  | n/a     | 'MATERIAL', 'SOURCE', 'OBSERVER' 
thickness             | real    | 0.0         | m       | >=0
precedence            | integer | 1           | n/a     | >=0
rayDirections         | string  | 'xyz'       | n/a     | 'x', 'y', 'z', 'd', 'e', 'f'
reduceMethod          | string  | 'CONCENSUS' | n/a     | 'CONCENSUS', 'MAJORITY', 'DICTATOR'
epsParallelRay        | real    | 1e-12       | *FIXME* | >0
epsRayEnds            | real    | 1e-6        | *FIXME* | >0.0
epsUniqueIntersection | real    | 1e-6        | *FIXME* | >0.0
isUseInterpResolver   | boolean | false       | n/a     | true, false
epsResolver           | real    | 1e-12       | *FIXME* | >0
isUnresolvedInside    | boolean | true        | n/a     | true, false
isValidNormals        | boolean | false       | n/a     | true, false
isInvertNormals       | boolean | false       | n/a     | true, false
splitMethod           | string  | 'SAH'       | n/a     | 'SAH', 'MEDIAN', 'EQUAL'
maxDepth              | integer | 15          | n/a     | >0
minNumElemPerNode     | integer | 5000        | n/a     | >0
maxNumElemPerNode     | integer | Inf         | n/a     | >0, >minNumElemPerNode
isPlot                | boolean | false       | n/a     | true, false
isInfiniteRay         | boolean | true        | n/a     | true, false [FIXME] Remove
isTwoSidedTri         | boolean | true        | n/a     | true, false [FIXME] Remove
isIncludeRayEnds      | boolean | true        | n/a     | true, false [FIXME] Remove

Description:

#### type

Type of the mapped object in the structured mesh. The valid types depend on the groups 
type in the unstructured mesh according to the table below. 
 
type             | group type       | group type     | Description of mapped group 
:----------------|:-----------------|:---------------|:------------------------------------------------
                 | **Unstructured** | **Structured** |
'VOLUME'         | 2                | 3              | volumetric object enclosed by the closed surface
'SURFACE'        | 2                | 2              | open or closed surface
'CLOSED_SURFACE' | 2                | 2              | closed surface (shell).
'LINE'           | 1                | 1              | line.
'POINT'          | 0, 1, 2 or 3     | 0              | set of all element nodes in the group
'BBOX'           | 0, 1, 2 or 3     | 0              | bounding box of the group

Notes:

1. If the surface is known to be closed a more robust algorithm can
   be applied by selecting the type 'CLOSED_SURFACE': The group is 
   first mapped as a volume object and then the faces of the mapped 
   volume object are identified. This approach is less susceptible 
   to meshing artefacts than the general surface algorithm.
2. Bounding boxes are used for defining the computational volume in 
   the input mesh and can be used to define source plane, observers volumes etc.

   
#### physicalType
   
Physical type of the mapped object in the structured mesh. Currently not used by the mapper
though it may be in future version. It is currently passed through for use in mesh exporters.

physicalType     | group type       | Description of mapped group 
:----------------|:-----------------|:-----------------------------------------------
'MATERIAL'       | 1, 2 or 3        | a material object
'SOURCE'         | 1, 2 or 3        | an electromagnetic source
'OBSERVER'       | 0                | a set of observation points

#### thickness

For volume mapping of surface groups this option defines the thickness of the surface in metres.

#### precedence

Objects are mapped onto the structured mesh in the order of their assigned 
precedence, lowest first. Objects with the same precedence are mapped in the
order they appear in the unstructured mesh.
 
[FIXME] This is nolonger important for the mapper, but could still be relevent for
exporters.

#### rayDirections

Direction to cast rays through a volume object. This is a string composed of 
the characters 'x', 'y', 'z', 'e', 'f'  and 'g'. Each character should appear 
at most once. 'x', 'y' and 'z' cause rays parallel to the respective direction to be cast
along each cell centre from the lower group AABB face to the corresponding upper
group AAB face. The calculation is vectorised in the normal direction and
much faster than with 'd', 'e' and 'f'. However, it can be more susceptible to
singularity arefacts. 'd', 'e' and 'f' cause divergent rays to be cast to every cell centre on the mesh
from a point outside the objects bounding box along a diagonal through the bounding
box corners with the different cases corresponding to different diagonals of the
bounding box. The calculation is not vectorised and is much slower than using
'x', 'y' and 'z'. However if is probably more robust.

#### reduceMethod

If more than one direction is specified, e.g. 'xyz' then the insideness for a cell 
centre is determined by a vote between the results for each direction:

reduceMethod | Outcome
:------------|--------------------------------------------------------
'CONCENSUS'  | cell is inside if __all__ directions agree.
'MAJORITY'   | cell is inside if __half or more__ of directions agree.
'DICTATOR'   | cell is inside if __any__ direction identifies it.

#### epsParallelRay

Tolerance [FIXME] on determining if a ray and elemenet are parallel and
therefore don't intersect. It must be much less than epsRayEnds!

#### epsRayEnds

Tolerance [FIXME] for determining an intersection at ends of a finite ray.

#### epsUniqueIntersection

Tolerance [FIXME] for determining unique interactions of rays with elements.
Intersections with t parameters within this tolerance will be assumed to be the equivalent.

#### isUseInterpResolver

Determine whether to use interpolation resolver for volume mapper.

#### epsResolver

Tolerance on proximity of intersection at which to invoke resolver.

#### isUnresolvedInside

Default insideness for unresolved cells in volume object if resolver is not used.

#### isValidNormals

Indicates the normals of the mesh elements in this group can be
assumed to be valid, i.e. for a closed object they are all outward
normals according to a clockwise node number order convention. This helps
in the detection of some singularities in the group mapping.

#### isInvertNormals

Indicates the normals of the mesh elements in this group can be
assumed to be valid but are inverted, i.e. for a closed object they 
are all inward normals according to a clockwise node number order convention.
            
#### splitMethod

Partitioning method to use in BVH generation.

splitMethod | Algorithm
:-----------|:--------------------------------------------
'SAH'       | use a surface area heuristic 
'MEDIAN'    | split according to the median ?what? [FIXME]
'EQUAL'     | split elements equally 
 
#### maxDepth

Maximum depth of BVH tree.

#### minNumElemPerNode

Minimum number of elements in node of BVH tree. Advisory.

#### maxNumElemPerNode

Maximum number of elements in node of BVH tree. Advisory.

#### isPlot

Whether to plot statistics.

#### isInfiniteRay

[FIXME] Remove.

#### isTwoSidedTri

[FIXME] Remove.

#### isIncludeRayEnds

[FIXME] Remove.

# Structured mesh tools

    [mesh ] = meshSmesh2Unmesh( smesh )

# Structured mesh export

## Vulture

    meshWriteVulture( mshFileName , smesh , options )

### Vulture export options

options.vulture.<optionName>

Name             | Type    | Default    | Units | Range
:----------------|: ------:|:----------:|:-----:|:--------------------------------
physicalType     | string  | 'MATERIAL' | n/a   | 'MATERIAL', 'SOURCE', 'OBSERVER' 
useMaterialNames | boolean | false      | n/a   | true, false
scaleFactor      | real    | 1.0        | n/a   | > 0.0

#### physicalType

See group mapping options above.

#### useMaterialNames

If true the material name is used to tag the groups elements
in the Vulture mesh, otherwise the group name is used.

#### scaleFactor

Apply scale factor to mesh lines before exporting into Vulture
mesh file.

# Testing

  meshTestCreateLines()
  meshTestDriver()
  meshTestTimingSummary()
  meshTestFBVH()
  meshTestMapGroups()
  meshTestResolveRayVolume()
  meshTimeIntersections()

# References

[AMELET-HDF][] Cyril Giraudon, "Amelet-HDF Documentation", Release 1.5.3, AxesSim, 15 November 2011.
            
[Berens2013] Project report.

[Berens2014]] APM article.
            
# Appendix A: Unstructured mesh format

An unstructured mesh is represented by a structure with the following members:

Member name     | Types                      | Description
:---------------|:---------------------------|:----------------------------------------------
dimension       | integer                    | dimension of the mesh 1,2 or 3
numNodes        | integer                    | number of nodes
nodes           | real(dimension,numNodes)   | node coordinates in metres
numElements     | integer                    | number of elements
elementTypes    | integer(1,numElements)     | type of each element
elements        | integer(var,numElements)   | sparse array of element's node indices
numGroups       | integer                    | number of groups
groupNames      | string{numGroups}          | cell-array of group names
groupTypes      | integer(numGroups)         | type (dimensionality) of each group
groups          | integer(var,numGroups)     | sparse array of group's element indices
numGroupGroups  | integer                    | number of groups of groups
groupGroupNames | string{numGroupGroups}     | cell-array of group of groups names
groupGroups     | integer(var,numGroupGroup) | sparse array of group of group's group indices

Notes:

* nodes(i,j) gives the i-th coordinate of the j-th node.
* elements(i,j) gives the i-th node index (into the nodes array) of the j-th element.
* groups(i,j) gives the index of the i-th element (into the elements array) of the j-th group.
* groupGroup(i,j) gives the i-th index (into the groups array) of the j-th group of groups.
* Hierarchical group of groups are **not supported**.

The supported element types are:

Element type number | Type tag | Dimension | Number of nodes
:-------------------|:--------:|:---------:|:--------------:
1                   | bar2     | 1         | 2
11                  | tri3     | 2         | 3
13                  | quad4    | 2         | 4
101                 | tetra4   | 3         | 4
104                 | hex8     | 3         | 8
199                 | node1    | 0         | 1

The supported group types are:

Group type number | Type of elements
:-----------------|:----------------
0                 | nodes
1                 | linear
2                 | surface
3                 | volume

# Appendix B: Structured mesh format

A structured mesh is represented by a structure with the following members:

Member name     | Types                      | Description
:---------------|:---------------------------|:----------------------------------------------
dimension       | integer                    | dimension of the mesh 1,2 or 3
x               | real(numXLines)            | x-coordinates of mesh lines
y               | real(numYLines)            | y-coordinates of mesh lines
z               | real(numZLines)            | z-coordinates of mesh lines
numGroups       | integer                    | number of groups
groupNames      | string{numGroups}          | cell-array of group names
groupTypes      | integer(numGroups)         | type (dimensionality) of each group
groups          | array{numGroups}(nx6)      | cell-array of elements bounding boxes
numGroupGroups  | integer                    | number of groups of groups
groupGroupNames | string{numGroupGroups}     | cell-array of group of groups names
groupGroups     | integer(var,numGroupGroup) | sparse array of group of group's group indices

Notes:

* groups{groupIdx} is a (numElementsInGroup x 6) real array of structured mesh indices of the
  bounding box corners of the elements in the group. Each row in the array takes the form
  [xlo,ylo,zlo,xhi,yhi,zhi]. The bounding box can be a single element (edge,face,cell) or 
  multiple elements (line,surface,volume). 
* In most cases the bounding coordinates much be integers; however floating indices can be used
  to reference positions within a structured mesh cell. For example, [1.5,2.5,3.5,1.5,2.5,3.5]
  is the point in the centre of the cell with lowest node indices (1,2,3). 
* Hierarchical group of groups are **not supported**.

The supported group types are:

Group type number | Type of elements
:-----------------|:----------------
0                 | nodes
1                 | linear
2                 | surface
3                 | volume
4                 | AABB

Group type 4 provides special support for AABBs.

[Gmsh]: http://geuz.org/gmsh
[AMELET-HDF]: https://code.google.com/p/amelet-hdf
[CONCEPT-II]: http://www.tet.tuhh.de/concept/?lang=en
[HDF5]: http://www.hdfgroup.org/HDF5
[Dr Ian Flintoft]: http://www.elec.york.ac.uk/staff/idf1.html
[AEG]: http://www.elec.york.ac.uk/research/physLayer/appliedEM.html
[Gmsh]: http://geuz.org/gmsh
[AMELET-HDF]: https://code.google.com/p/amelet-hdf
[Octave]: http://www.gnu.org/software/octave
[MATLAB]: http://www.mathworks.co.uk/products/matlab
[Vulture]: https://bitbucket.org/uoyaeg/vulture
[FDTD]: http://en.wikipedia.org/wiki/Finite-difference_time-domain_method
[HDF5]: http://www.hdfgroup.org/HDF5
[nlopt]: http://ab-initio.mit.edu/wiki/index.php/NLopt
[CONCEPT-II]: http://www.tet.tuhh.de/concept/?lang=en

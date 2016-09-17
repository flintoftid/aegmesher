
[TOC]

# AEG Mesher: Things to do


## Priority Items

### Complete integration of Michael's non-uniform mesh generation algorithm.

The prototype implmentation is in mesh/private/meshCreateNonUniformMeshLinesMB.m.
It is currently disabled at lines of 366-371 in mesh/meshCreateLines.m due to some issues
with the implementation of the local mesh line generation. A refactored form of the 
algorithm is being built in mesh/private/meshCreateNonUniformMeshLines.m. Test drivers
for these functions are in mesh/private/meshTestCreateNonUniformMeshLinesMB.m and 
mesh/private/meshTestCreateNonUniformMeshLines.m.

### Make sure all the tests work with both Octave and MATLAB on both Linux and Windows.

Most developement work has taken place with Octave so the behaviour under MATLAB needs 
to be checked.

### Add more of Michael's tests to the test-suite, particularly for the nonuniform case.

### Complete first draft of a full user manual.

### Determine why TIMING_intersect test fails with such a big margin on 32-bit Linux.

### Review setting and use of all tolerances and improve user documentation of these

The current method by which these are set is not scale invariant leading to unexpected
default results and placing uneccessary burden on the user. Much more robust values can
probably be determined by an initial analysis of the range of elements sizes in the 
input mesh and cell sizes in the target structured mesh.

Name: epsCoalesceLines
Used in: meshCreateLines()
Units: metres
Default: 1e-4 m
Purpose: Combine closely space contraints points within this distance
Issues: Not transitive, not scale invariant
Changes: Could it be set using the smallest mesh size *requested*, e.g.
         epsCoalesceLines = 1e-4 * minMeshSize;
         Since mesh lines not known at this stage need to know minimum from
         constraints imposed?
         
Name: epsCompVol
Used in: meshCreateCubicMeshLines(), meshCreateNonUniformMeshLines() , meshCreateUniformMeshLines()
Units: metres
Default: 1e-6
Purpose: Tolerance on removing spare cells to tighten the computational volume.
Issues: Not scale invariant
Changes: Could be applied in relative terms to mesh size, e.g.
         epsCompVol = 1e-4 * minMeshSize;

Name: epsRayEnds (1)
Used in: meshBBoxRayIntersection(), meshTriRayIntersection1(), meshTriRayIntersection2(), meshTriRayIntersection3() 
Units: normalised ray parameter
Default: 1e-6
Purpose: Inclusion/exlusion of intersections at rayEnds depending on value of isIncludeRayEnds 
         Currently only important for divergent ray volume mapping when far end of ray is within the mapped volume.
Issues: See (*) below
Changes:  Make absolute, but determined from minimum mesh size in groups to be meshed.
          
Name: epsRayEnds (2)
Used in: meshSurfaceMapParallelRays(), meshVolumeMapParallelRays()
Units: metres
Default 1e-6 m
Purpose: Used to offset ends of ray origin and end points to ensure ray covers the AABB
Issues: Different use and units to above, not scale invariant. Value probably isn't
        critical or really related to other uses. 
Changes: After change use same as above. 
             
Name: epsRayEnds (3)             
Used in: meshVolumeMapDivergentRays
Units: normalised ray parameter
Default: 1e-6
Purpose: Used to determine if an intersection point is close to a cell centre and hence resolver should be applied 
Issues: See (*) below
Changes: Rename or should we use epsResolver?
               
Name: epsRayEnds (4)             
Used in: meshIntersectFBVH(), meshTriRayIntersection1(), meshTriRayIntersection2(), meshTriRayIntersection3() 
Units: normalised barycentric coords of element
Default: 1e-6
Purpose: Determination of ray hitting edge of element 
Issues: Different purpose to above. See also (*) below
Changes: Rename and make absolute, but determined from minimum mesh size and element size in groups to be meshed, e.g. 
         epsRayEdgeAbs = epsRayEdgeRel * min( [ minMeshSize , minElementSize ] );
         Need to 

Name: epsParallelRay
Used in: meshTriRayIntersection1(), meshTriRayIntersection2(), meshTriRayIntersection3()
Units: m^3
Default: 1e-12
Purpose: Used to determine if a ray is parallel to an element and if an element is front-facing
Issues: Not scale invariant, misses intersections on near parallel elements.
Changes: The determinant is given by
                 
         det = ||edge1|| ||edge2|| ||dir|| cos( alpha )
                 
         where 
         
         ||dir||      - is the length of a finite ray ~ size of AABB
         ||edge1/2||  - are element edge lengths - could be very small to significant 
                        proportion of object AABB.
         cos( alpha ) = cos( pi/2 - epsAngle ) ~ epsAngle
         
         So test for parallelism is 
         
         abs( det ) ~ ||edge1|| ||edge2|| ||dir|| epsAngle
                    ~ maxElementSize^2 * sizeOfAABB * epsAngle
                    ~ minElementSize^2 * sizeOfAABB * epsAngle
                    
         The RHS product could have a huge range so rigorously it seems like the most 
         robust method is to make epsParallelRay = epsAngle and calculate the norms: 
         
         %rownorm = @(X,P) sum( abs( X ).^P , 2 ).^(1/P);
         rownorm2 = @(X) sqrt( sum( X.^2 , 2 ) );
         %rownorm2 = @(X) sqrt( X(:,1) .* X(:,1) + X(:,2) .* X(:,2) + X(:,3) .* X(:,3) );
         parallel = ( abs( det ) < rownorm2( edge1 ) .* rownorm2( edge2 ) .* rownorm2( dir ) .* epsParallelRay );
         
         However the norms are expensive to determine, so a heuristic
         is often applied - see [4, ch. 2.4.4].
  
         det > epsParallelRay
         abs( det ) > rownorm2( edge1 ) .* rownorm2( edge2 ) .* rownorm2( dir ) .* epsParallelRay

         *BUT* this still means we could miss an intersection at grazing angles. See (+) below.
         
Name: epsUniqueIntersection
Used in: meshResolveRayVolume()
Units: normalised ray parameter
Default: 1e-6
Purpose: Used to find potentially equivalent intersections, e.g. hitting edge/vertex in multiple triangles. 
Issues: See (*) below
Changes: Should be set high enuogh to catch numerical rounding effects but much smaller than any
         distance between surfaces in the mesh. 
         Should probably be << minMeshSize, << minElementSize 

Name: epsResolver
Used in: meshSurfaceMapParallelRays()
Units: relative tolerance on normalised ray parameter
Default: 1e-12
Purpose: Relative tolerance on normalised ray parameters used to round intersections 
         to see if the are near cell centres and resolver should be used.
Issues: Not scale invariant.
Changes: Should be absolute and determined from cell size etc.

(*) General issue: Tolarances on normalised ray parameters t, u, v.
These are difficult to set. Parameters are normalised to the range 0 to 1 
so it at first looks like they can be fixed. However, the normalisation
is different for different rays/elements which could be of greatly different
sizes, so this will not be scale invariant. For example, the effect on 
neighbouring elements of greatly differing sizes could be important. So they 
are not true relative tolerances. Maybe they should be treated as absolute 
tolerance in some sense - some heuristic derived from the smallest mesh 
and elements sizes could be used? 

For rays:

    r = r0 + t * dir       with 0 <= t <= 1
    
      = r0 + tn * tunit    with 0 <= tn <= || dir ||
      
    dr = dt * || dir || = d(tn)
    
    epsRayEndsAbs = epsRayParameter * || dir ||
    
    epsRayEndsAbs = epsRayEndsRel * minMeshSize
    
    epsRayParameter = epsRayEndsRel * minMeshSize / || dir ||
    
For triangles:
 
    epsRayEdgeRel = epsRayEdgeAbs / sqrt( || edge1 || * ||edge2|| )

(+) See also the watertight algorithm in

http://jcgt.org/published/0002/01/05/paper.pdf  

which uses an algorithm that guarantees not to miss intersections - also 
with guarantees about hits on neighbouring triangles. It also makes some
statements about parallel rays which could be significant. The parallel
test uses an exact zero and claims intersections are guaranteed to be
detected in neighbouring triangles. This has been implemented in 
meshTriRayIntersection4() but not tested. If may need support from 
a matched ray-box intersection test to ensure the BVH partitioning is
not confounded.

Other refs:

http://totologic.blogspot.fr/2014/01/accurate-point-in-triangle-test.html
http://geomalgorithms.com/a06-_intersect-2.html


## General


### Fully support groupGroup

groupGroup stuff should always be optionally considered in all mesh operations.
If it is not present ignore it. If present process consistently.
Check all functions handle this correctly.


## Mesh Line Generation


### Add function to load user defined mesh lines:

    [ lines ] = meshReadMeshLine( xFileName , yFileName , zFileName )

### Review mechanisms for forcing mesh lines exactly onto CV boundary:

Use weighting of CV constraint points to tighten.
Implement isCompVolTight for non-uniform meshes.

### Add user defined constraint points to mesh line creation function.

How to deal with weights and Dmin/Dmax or dmin/dmax to left/right?

    X = row vector etc
    Xuser = [ X , Xweight , Dmin , Dmax , dmin , dmax ];

### Constraint point determination from unstructured mesh node statistics
 
Only valid if unstructured mesh node density is representative of spatial variation
of surfaces.

For each group determine histogram of nodes coordinates in each directions

    [ nn , xx ] = hist( nodex , bincentres , 1 );
  
nodex -> strong peaks in nn(i) indicate probable presence of lots of x-normal elements
at xx(i) and that location and should therefore be a constraint point.

Could also be used to alter mesh density/size Dmax/ dx_max?

How to determine resolution of the histogram?

Don't want to generate lots constraint points
bincentres determine from Dmax/dmin and object AABB
Use fraction 0 to 1 to determine peak. E.g. nn(i) > frac => xx(i) constraint pointing


## Mesh Mapping


### Consider propagating new structured mesh format into other functions
  
    meshLineMapGroup.m
    meshSurfaceMapGroup.m
    meshVolumeMapGroup.m
  
The main issue is the "voting algorithm" for casting rays in different directions for 
volume groups. This can only be done efficiently with the isInside(i,j,k,dir) format.

### Review how to deal with sources and observers

New per group options: physicalType = 'MEDIUM' , 'SOURCE' , 'OBSERVER'
                   
How are they defined in the input mesh?
    
* Observers: Normal group of elements - any dimensionality.
* Sources: Normal group of elements - any dimensionality.
      
How should they be mapped?
    
* Observers: physicalType = 'OBSERVER'. Map as all nodes in group using float indices.
* Sources: physicalType = 'SOURCE'. Map according to dimensionality as normal.

This doesn't really change anything in the mapper!
    
How are they exported in Vulture?
    
Observers: 

    OT <groupName> <format> <domain> <quantity1> ... <quantityN>
    OP <ilo> <ihi> <jlo> <jhi> <klo> <khi> <groupName> <param1> ... <paramN> 
    
Sources: 

    WF .... one default waveform determine from frequency range. 
    EX <ilo> <ihi> <jlo> <jhi> <klo> <khi> <groupName> <param1> ... <paramN> 

Sources: nodes, lines, planes, surfaces, volumes.
Observers: nodes, lines planes, surfaces. volumes.

In Vulture EX, PW, OP can only be defined for cuboid (possibly degenerate)
shapes. In more complex cases may want to e.g define observation of current
on curved surface. Related to issue of how to get outputs out and map back 
onto input mesh. Also should observers be nodal or use natural elements
for output type? 

Define new meshing type for SOURCE and OBSERVER which just add the overall
bounding box to the structured mesh? 

### Surface mapping is not robust on stair-cased surfaces. 

E.g. cube at 45 degrees.
Improve algorithm so get similar results from CLOSED_SURFACE and SURFACE
mapping. This is hard.

### Support other surface elements

Michael has code to transform non-triangular elements into triangles using the
MATAB Delauny function. Maybe offer this at higher level using function:

    mesh2 = meshTriangulate( mesh1 )

    x_obj = mesh.nodes(1,mesh.elements(:,objNodes));
    y_obj = mesh.nodes(2,mesh.elements(:,objNodes));
    z_obj = mesh.nodes(3,mesh.elements(:,objNodes));
    
    if length(mesh.elements(:,1)) > 3 
      faces = [x_obj' y_obj' z_obj'];
      faces_ = faces(3,:) == 0;
      faces(:,faces_) = [];
      faces = DelaunayTri(faces);     
      vertices(:,~faces_) = faces.X;
      vertices(:,faces_) = 0;
      faces = faces.Triangulation;
    else % normal case with triangulation
      faces = mesh.elements(:,objNodes)';
      vertices = mesh.nodes';
    end
    
replaces all non-triangular surface elements with multiple triangles.

### Add more sophisticated ideas from Michael's surface mapper into basic implementation.

### Allow precedence = 0 meaning "do not mesh this object".

### Delete unmapped groups from groupGroups.
   
   
## Unstructured mesh import and export


### Add function to import a MATLAB format surface triangluation

    meshImportMatlab()

### Add function to export a MATLAB format surface triangluation

    meshExportMatlab()

### Add function to export an STL format surface triangluation

    meshWriteSTL( stlFileName , mesh , format )

* format can be 'ASCII' or 'BINARY'.
* Need to create normal vectors - assume right-hand rule for nodes.
* Only needs to support triangles - start from meshWriteSurf which 
  is very close to the required algorithm. 

### Add function to import an STL format surface triangluation

    [ mesh ] = meshReadSTL( stlFileName )

* Detect format.

### Improve CONCEPT exporter

    meshWriteConcept( conDirName , mesh )

* Current version is not very general.

* Dealing with closed dielectric bodies is going to be hard and require 
  more meta information to be stored. E.g blade model - intersection
  surfaces need to be output separately and everything stitched together
  with correct topology and without duplicate elements.


## Structured mesh exporters


### Vulture exporter

    meshWriteVulture( vultureFileName , mesh )

* options.vulture.meshScaleFactor - scale structure on output.
* Use group precedence during export.
* Consider best way to write out objects and combine with rest
  of mesh. Do we want to always write a full mesh or separate files
  (mb.mesh, tb.mesh,..) which can be combined by another function
  with material information to provide a complete mesh?
* Use maxFreq/minFreq to determine waveform parameters.
* Could generalise material database to return simple medium parameters 
  and Debye parameters that could be included in mesh. 

    [ modelType , modelParams ] = matModelLookUp( f , matName );

  where f is used to check realm of validity. modelType - SIMPLE, DEBYE,....

### Write AEG Hawk TLM code exporter

    meshWriteHawk( hawkFileName , mesh )

Straight-forward translation of Vulture exporter. Need to copw with fixed
mesh origin.
    
### Write AMELET-HDF exporter

Would be nice to export to AMELET-HDF but Octave has no generic
HDF5 writing support - need tight control of dataset types and names
and attributes. Could possibly save mesh in mat file and read into
Python then use pytables. Actually want to ADD structured mesh to
existing AMELET file?


## Data on mesh


### Develop strategy for post-processing

Example nodal data in Gmsh format:
 
    $NodeData
    1                        one string tag:
    "Observer group name"      the name of the view ("A scalar view")
    1                        two real tags:
    0.0                        the time/frequency value
    3                        three integer tags:
    0                          the time step/frequency number (0; time steps always start at 0)
    3                          3-component (scalar) field
    6                          number of associated nodal values
    1 0.0 0.0 0.0            value associated with node #1 (0.0)
    2 0.1 0.0 0.0            value associated with node #2 (0.1)
    3 0.2 0.0 0.0            etc.
    4 0.0 1.0 1.0
    5 0.2 3.0 4.0
    6 0.4 2.3 4.5
    $EndNodeData 

Function meshReadVulture will read data from Vulture output files and original unstructured mesh
and generate Gmsh data - can put in separate .msh files and merge.


## Performance


### Run profiler on the mapper to find any obvious performance issues:

* Growing arrays.
* i,j,k loops should be in order k, j, i.
* Unchanging calculations inside loops.
* Easy vectorisations.
* What is the current dominant contribution to the mapping time?

### Check BVH is tuned correctly. What happens if we double Nc?
  
### Speed up ray AABB intersection calculation.

### Is there a better way to deal with degenerate case when AABB a surface?
  
### Improve efficiency of closed surface mapping in meshVolumeGroup2SurfaceGroup.m.

### Check all sparse arrays operations are handle efficiently

Example:

    [ i1, j1 , s1 ] = find( mesh1.groups );
    [ i2, j2 , s2 ] = find( mesh2.groups );
    mesh.groups = sparse( [ i1 ; i2 ] , [ j1 ; j2 + mesh1.numGroups ] , [ s1 ; s2 + mesh1.numElements ] , ...
                           max( [ i1 ; i2 ] ) , mesh.numGroups );


## Tests


### Solids

* Spheres of different sizes on fixed size mesh.
* Sphere varying resolution of unstructured mesh:
  - Very low resolution.
  - Very high resolution.
* Hollow sphere with thickness of >> mesh size.
* Hollow sphere with thickness of 1-2 times mesh size.
* Cylinder of different size at different angles to mesh.
* Hollow cylinder with thickness of >> mesh size.
* Hollow cylinder with thickness of 1-2 times mesh size.
 Three concentric cylinders PEC-dielectric-PEC (coaxial TL):
   - Mesh outer shells "properly" as shells.
   - Use three solid cylinders with appropriate priorities.
* SAM head - can we close surface:
  - freeCAD?
  - various mesh repair tools?

### Closed surfaces

* Spheres of different sizes on fixed size mesh.
* Cylinder of different size at different angles to mesh.
* Torus.
* Irregular object with features << mesh size.

### Open surfaces

* Planes at various angles to mesh.
* Corners (3 sides of cube) at various angles to mesh.

### Wires

* Straight diagonal wires.
* Curved wires.
* Loops.
* Wires with multiple intersections.
* Wire mesh.
 
 
## Documentation


### Automatic generation of txt files from Markdown with tables/code?

### Add implementation notes.


## Packaging and distribution


### Add CPack directives to create distribution package.

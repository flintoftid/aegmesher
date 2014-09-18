
[TOC]

# AEG Mesher: Completed tasks

## New structured mesh format

The structured mesh format has a serious limitation - only one group can 
exist on each node/edge/face/volume. For the real physical objects
this is not too serious since only one physical object can exist on
each entity. However for sources, observers and other abstract objects
like the computational volume this is a problem. This needs to be fixed
before other things like sources, observers, data on the mesh can be progressed.

Generalise the structured mesh to use the AMELET-HDF structured mesh format:
  
    % smesh - structure containing a structured mesh modelled on the AMELET-HDF format [1]:
    %
    %        .dimension         - integer, dimension of mesh: 1, 2 or 3.
    %        .x()               - real(Nx) vector of mesh line coordinates in x-direction.
    %        .y()               - real(Ny) vector of mesh line coordinates in y-direction.
    %        .z()               - real(Nz) vector of mesh line coordinates in z-direction.
    %        .numGroups         - integer, number of groups.
    %        .groupNames{}      - string{numGroups}, cell array of group names.
    %        .groupTypes()      - integer(numGroups), array of AMELET-HDF group types:
    %
    %                             0 - node
    %                             1 - edge
    %                             2 - face
    %                             3 - volume
    %
    %        .groups{}          - cell array of bounding boxes of structured mesh elements for
    %                             each group. groups{groupIdx} is a 3xn or 6xn array of structured mesh
    %                             indices of the bounding box corners of the elements in the group. For
    %                             node groups only one coordinate is required (BBox is degenerate).
    %                              
    %                             For group type 0 (node): groups{groupIdx} is 3xnumNodesInGroup array
    %                                                      groups{groupIdx}(coordIdx,nodeIdx)
    %                                                      coordIdx = 1: i
    %                                                      coordIdx = 2: j
    %                                                      coordIdx = 3: k
    %
    %                             For all other group types: groups{groupIdx} is 6 x numBBoxInGroup array
    %                                                        groups{groupIdx}(coordIdx,bboxIdx)
    %                                                        coordIdx = 1: ilo
    %                                                        coordIdx = 2: jlo
    %                                                        coordIdx = 3: klo
    %                                                        coordIdx = 4: ihi
    %                                                        coordIdx = 5: jhi
    %                                                        coordIdx = 6: khi  
    %                                                        Boundng box can be single element (edge,face,cell)
    %                                                        or multiple elements (line,surface,volume).
    %              
    %        .numGroupGroups    - integer, number of groups of groups.
    %        .groupGroupNames{} - string{numGroupGroups}, cell array of group group names.
    %        .groupGroups()     - integer(var,numGroupGroup), sparse array of group of group indices.
    %                             groupGroup(i,j) gives the i-th index (into the groups array) of the
    %                             j-th group of groups. Hierarchical group of groups are NOT SUPPORTED.

    % Node
    bboxStencils = [ 0 , 0 , 0 ; ....   % Node
                     1 , 0 , 0 ; ...    % x-edge
                     0 , 1 , 0 ; ...    % y-edge  
                     0 , 0 , 1 ; ...    % z-edge
                     1 , 1 , 0 ; ...    % xy-face
                     0 , 1 , 1 ; ...    % yz-face  
                     1 , 0 , 1 ; ...    % zx-face                   
                     1 , 1 , 1 ];       % cell    

    % Nodes.
    [ isNode ] = meshNodeMapGroup( mesh , thisGroupIdx , lines , objBBox , idxBBox , thisOptions );    
    bboxType = 1;  
    flatIdx = find( isNode );
    [ i , j , k ] = ind2sub( size( isInGroup ) , flatIdx );
    groups{smesh.numGroups} = [ imin + i - 1 , jmin + j - 1 , kmin + k - 1 ];

    % Lines.
    [ isX , isY , isZ ] = meshLineMapGroup( mesh , thisGroupIdx , lines , objBBox , idxBBox , thisOptions );  
    bboxType = 2;                              
    flatIdx = find( isX );
    [ i , j , k ] = ind2sub( size( isX ) , flatIdx );
    groups{smesh.numGroups} = [ imin + i - 1 , jmin + j - 1 , kmin + k - 1 , ...
                              imin + i - 1 + bboxStencils(bboxType,1) , jmin + j - 1 + bboxStencils(bboxType,2) , kmin + k - 1 + bboxStencils(bboxType,3) ];
    bboxType = 3;                              
    flatIdx = find( isY );
    [ i , j , k ] = ind2sub( size( isY ) , flatIdx );
    groups{smesh.numGroups} = [ imin + i - 1 , jmin + j - 1 , kmin + k - 1 , ...
                                imin + i - 1 + bboxStencils(bboxType,1) , jmin + j - 1 + bboxStencils(bboxType,2) , kmin + k - 1 + bboxStencils(bboxType,3) ];  
    bboxType = 4;                              
    flatIdx = find( isZ );
    [ i , j , k ] = ind2sub( size( isZ ) , flatIdx );
    groups{smesh.numGroups} = [ imin + i - 1 , jmin + j - 1 , kmin + k - 1 , ...
                                imin + i - 1 + bboxStencils(bboxType,1) , jmin + j - 1 + bboxStencils(bboxType,2) , kmin + k - 1 + bboxStencils(bboxType,3) ];
                              
    % Surfaces.
    [ isXY , isYZ , isZX ] = meshSurfaceMapGroup( mesh , fbvh , elementMap , lines , objBBox , idxBBox , thisOptions );  
    bboxType = 5;                              
    flatIdx = find( isXY );
    [ i , j , k ] = ind2sub( size( isXY ) , flatIdx );
    groups{smesh.numGroups} = [ imin + i - 1 , jmin + j - 1 , kmin + k - 1 , ...
                                imin + i - 1 + bboxStencils(bboxType,1) , jmin + j - 1 + bboxStencils(bboxType,2) , kmin + k - 1 + bboxStencils(bboxType,3) ];
    bboxType = 6;                              
    flatIdx = find( isYZ );
    [ i , j , k ] = ind2sub( size( isYZ ) , flatIdx );
    groups{smesh.numGroups} = [ imin + i - 1 , jmin + j - 1 , kmin + k - 1 , ...
                                imin + i - 1 + bboxStencils(bboxType,1) , jmin + j - 1 + bboxStencils(bboxType,2) , kmin + k - 1 + bboxStencils(bboxType,3) ];  
    bboxType = 7;                              
    flatIdx = find( isZX );
    [ i , j , k ] = ind2sub( size( isZX ) , flatIdx );
    groups{smesh.numGroups} = [ imin + i - 1 , jmin + j - 1 , kmin + k - 1 , ...
                                imin + i - 1 + bboxStencils(bboxType,1) , jmin + j - 1 + bboxStencils(bboxType,2) , kmin + k - 1 + bboxStencils(bboxType,3) ];
                               
    % Volumes.
   isInside = meshVolumeMapGroup( mesh , fbvh , elementMap , lines , objBBox , idxBBox , thisOptions );
    bboxType = 8;
    flatIdx = find( isInside );
    [ i , j , k ] = ind2sub( size( isInside ) , flatIdx );
    groups{smesh.numGroups} = [ imin + i - 1 , jmin + j - 1 , kmin + k - 1 , ...
                                imin + i - 1 + bboxStencils(bboxType,1) , jmin + j - 1 + bboxStencils(bboxType,2) , kmin + k - 1 + bboxStencils(bboxType,3) ];

Need to consider shape of arrays.
  
Will be much more memory efficient for sparsely populated grids.
  
Functions that will need to be changed:
  
    meshMapGroups.m
    meshSmesh2Unmesh.m
    meshWriteVulture.m
    meshWriteLines2Gmsh.m (Now redundant)
    meshAddCompVol.m
  
## Support nodes in mapper: meshNodeMapGroup.m
 
Map to nearest structured node.
  
Thinking ahead to observers - we could make mapped node indices floats, e.g
i=4.5 would reference a point half way between x(4) and x(5):
   
    dx = diff( lines.x )  
    idx = find( x > lines.x );
    i = idx(end);
    lambda = ( x - lines.x(i) ) / dx(i); 
    fi = i + lambda
  
    i = floor( fi );
    lambda = fi - i;
    x = lines.x(i) + lambda * dx(i);
    x = ( 1 - lambda ) * lines.x(i) + lambda * lines.x(i+1);
   
This allows observers to request output anywhere in the mesh. Spatial interpolation
is done most efficiently in the FDTD code itself which has acces to all the data
without having to dump it to file.
  
We probably want to make float indices a group option ->  isNodesFloat.

## Support nodes in meshSmesh2Unmesh

Mostly done, needs validating.

* Don't use FBVH in case of line mesher - but still need to get overall AABB.
  Or identify and fix div by zeros in FBVH generation for line objects. 
* Optmise meshSurfaceMapParallelRays - move fixed values out of x/y loops.
* Find way to automatically generate ReadMe.txt from Wiki home page.

## Review situation where computational volume truncates objects in mesh

* Remove constraints points outside CV. Done.
* Add constraints points on CV. Done.
* Check solid mappers still deal with truncated objects. 
    + Divergent rays OK.
    + Parallel rays hosed because the ray only spans the part of the object within
      the CV. Fixed.
* Check surface mappers still deal with truncated objects. Done
* Make line mapper deal with truncated objects. Done.
* Make node mapper deal with truncated objects. Done, untested.

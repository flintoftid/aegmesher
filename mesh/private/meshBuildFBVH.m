function [ fbvh , elementMap ] = meshBuildFBVH( mesh , groupNames , options )
%
% meshBuildFBVH - Build (flattened) bounding volume heirarchy (BVH) for elements of a mesh. 
%
% [ fbvh , elementMap ] = meshBuildFBVH( mesh [, groupNames [, options ] ] )
%
% Inputs:
%
% mesh              - structure containing the unstructured mesh. See help for meshReadAmelet().
% groupNames{}      - cell array of strings, containing the names of the groups to add to be BVH. 
%                     Default: all elements are inserted.
%
% options           - structure containing the options:
%
%                     .splitMethod - string (case insensitive) specifying the method used to partition elements:
%
%                                    'MEDIAN' - Split at median of barycentres. 
%                                    'EQUAL'  - Split into equal sized partitions.
%                                    'SAH'    - Split using SAH heuristic tuned for vectorised 
%                                               triangle intersection function (default).
%                      
%                     .maxDepth - scalar integer giving maximum depth of BVH tree. The tree is built 
%                                 recursively which can consume large amounts of memory if the depth 
%                                 becomes too large (default: 15).
%
%                     .minNumElemPerNode - scalar integer giving the typical minimum number of elements 
%                                          per node: Nodes with less thna or equal to this number of elements 
%                                          are not partitioned when using 'median' and 'equal' partitioning. 
%                                          Based on vectorised triangle intersection function timing tests there 
%                                          is little benefit in having less than 3000-5000 elements in a node 
%                                          (default: 5000). 
%
%                     .maxNumElemPerNode - scalar integer giving the maximum number of elements per node. 
%                                          Nodes with greater than this number of elements will be partitioned 
%                                          if possible when SAH partitioning is used. Inf should be OK if theory
%                                          SAH algorithm is tuned correctly (default: Int).
%
%                     .isPlot - boolean scalar indicating whether to plot statistics (default: false).
%
% Outputs:
%
% fbvh - struct array containing flattened BVH:
%
%       fbvh(i).bbox()       - (6) real vector, bounding box of all elements in or under node i.
%       fbvh(i).numElements  - integer scaler, number of elements in leaf node i, zero for interior node i.
%       fbvh(i).offset       - integer scalar. For a leaf node gives the offset into elementMap for the leaf node's 
%                              elememt indices: elementMap((fbvh(i).offset):(fbvh(i).offset+fbvh(i).numElements - 1)).
%                              For an interior node gives the index of the node-i's right child node in fbvh. The left 
%                              child node is always at i+1.
%
% elementMap()              - (numElements) integer array containing element indices (into mesh.elements) stored
%                             such that leaf nodes elements are contiguous.
%

% 
% This file is part of aegmesher.
%
% aegmesher structured mesh generator and utilities.
% Copyright (C) 2014 Ian Flintoft, Michael Berens & John Dawson
%
% aegmesher is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% aegmesher is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with aegmesher.  If not, see <http://www.gnu.org/licenses/>.
% 

% Author: I. D Flintoft
% Date: 23/07/2013
% Version: 1.0.0

%
% Implementation notes:
%
% bvh - struct array containing the BVH:
%
%       bvh(i).lnode        - scalar integer, index of the left child node of node i. Zero if leaf node.
%       bvh(i).rnode        - scalar integer, index of the right child node of node i. Zero if leaf node.
%       bvh(i).bbox()       - (6) real vector, bounding box of all elements in or under node i.
%       bvh(i).numElements  - integer scaler, number of elements in leaf node;
%       bvh(i).elements()   - (var) integer vector of element indices in leaf node.
%       bvh(i).offset       - integer scalar, offset into elementMap for leaf node's elememt indices. 
%       bvh(i).dim          - scalar integer, direction of partition used to create child nodes of i.
%       bvh(i).barycentre   - (3) real vector, bbox barycentre of node i.
%
% References:
%
% [1] M. Pharr and G. Humphreys, "Physically based rendering - from theory to implementation", Morgan Kaupmann, 2004.
%

  % Surface area of AABB. Will return Inf for undefnied AABB.
  function [ area ] = bboxSurfaceArea( bbox )

    if( bbox == [  Inf ;  Inf ;  Inf ; -Inf ; -Inf ; -Inf ] )
      % Undefined AABB.
      % [FIXME] This test has performance hit.
      area = 0.0;
    else
      dx = bbox(4) - bbox(1);
      dy = bbox(5) - bbox(2);
      dz = bbox(6) - bbox(3);
      area = 2 * ( dx * dy + dy * dz + dz * dx );
    end %if

  end % function

  % Partition elements using median barycentre.
  function [ isLeafNode , leftElementIdx , rightElementIdx ] = ...
    meshPartitionMiddle( numElements , dim , elementIdx , barycentres , bcBBoxLow , bcBBoxHigh )

    isLeafNode = false;
    midPoint = 0.5 * ( bcBBoxLow(dim) + bcBBoxHigh(dim) );
    [ idx ] = find( barycentres(dim,elementIdx) < midPoint );
    leftElementIdx = elementIdx(idx);
    [ idx ] = find( barycentres(dim,elementIdx) >= midPoint );
    rightElementIdx =  elementIdx(idx); 
    % rightElementIdx = setdiff( elementIdx , leftElementIdx );
    % assert( sort( union( leftElementIdx, rightElementIdx )(:) )  == sort( elementIdx(:) ) );
  end % function

  % Partition elements using equal left/right numbers.
  function [ isLeafNode , leftElementIdx , rightElementIdx ] = ...
    meshPartitionEqual( numElements , dim , elementIdx , barycentres )

    isLeafNode = false;           
    breakIndex = ceil( numElements / 2 ); 
    [ ~ , idx ] = sort( barycentres(dim,elementIdx) );
    leftElementIdx = elementIdx(idx(1:breakIndex));
    rightElementIdx = elementIdx(idx((breakIndex+1):end));

  end % function

  % Partition elements using surface area heuristic.
  function [ isLeafNode , leftElementIdx , rightElementIdx ] = ...
    meshPartitionSAH( numElements , dim , elementIdx , barycentres , bcBBoxLow , bcBBoxHigh , bboxes , thisNodeBBox , maxNumElemPerNode )

    % Number of buckets to use.
    numBuckets = 12;

    % Cost of calculating intersection of ray with N elements:
    % a. Simple linear model suitable for non-vectorised intersection calculation function.
    %intersectCost = @(N) N;
    % b. Model based on measured behaviour of vectorised meshTriRayIntersection function.
    intersectCost = @(N) sqrt( N^2 + 5500^2 );

    % Relative cost of node traversal to intersection.
    % a. Simple linear model suitable for non-vectorised intersection calculation function.
    %traversalCost = 0.125;
    % b. Model based on measured behaviour of vectorised meshTriRayIntersection function.
    traversalCost = 600;

    % Find bucket for each element.
    b = 1 + floor( numBuckets * ( barycentres(dim,elementIdx) - bcBBoxLow(dim) ) / ( bcBBoxHigh(dim) - bcBBoxLow(dim) ) );
    % Check for barycenttre on upper edge and move into bucket below.
    b(find( b > numBuckets )) = numBuckets;
    % Count elements in each bucket.
    buckets.count = accumarray( b(:) , 1 , [ numBuckets , 1 ] );
    % assert( all( b >= 0 ) );
    % assert( all( b <= numBuckets ) );
    % assert( sum( buckets.count ) == numElements );
    % Find bounding box of elements in each bucket.
    for bucketIdx=1:numBuckets
      idx = find( b == bucketIdx );
      if( isempty( idx ) )
        % Empty bucket. Set AABB so that union with another AABB will just give the other.
        bbl = [  Inf ;  Inf ;  Inf ];
        bbh = [ -Inf ; -Inf ; -Inf ];       
      else
        bbl = min( bboxes(1:3,elementIdx(idx)) , [] , 2 );
        bbh = max( bboxes(4:6,elementIdx(idx)) , [] , 2 );
      end % if
      buckets.bbox(1:6,bucketIdx) = [ bbl ; bbh ];
    end % for
    % Estimate cost of splitting after each bucket.
    cost = zeros( 1 , numBuckets - 1 );
    for bucketIdx=1:(numBuckets - 1)
      % Find count and bbox for buckets up to and including bucketIdx.
      belowRange = 1:bucketIdx;
      belowCount = sum( buckets.count(belowRange) );
      belowBBox = [ min( buckets.bbox(1:3,belowRange) , [] , 2 ) ; max( buckets.bbox(4:6,belowRange) , [] , 2 ) ];
      belowSurfArea = bboxSurfaceArea( belowBBox );
      % Find count and bbox for buckets above bucketIdx.
      aboveRange = (bucketIdx+1):numBuckets;
      aboveCount = sum( buckets.count(aboveRange) );
      aboveBBox = [ min( buckets.bbox(1:3,aboveRange) , [] , 2 ) ; max( buckets.bbox(4:6,aboveRange) , [] , 2 ) ];
      aboveSurfArea = bboxSurfaceArea( aboveBBox );
      % Surface area for this nodes elements.
      [ surfArea ] = bboxSurfaceArea( thisNodeBBox );
      % assert( belowCount + aboveCount == numElements );
      % assert( belowBBox(1:3) >=  thisNodeBBox(1:3) );
      % assert( belowBBox(4:6) <=  thisNodeBBox(4:6) );
      % assert( aboveBBox(1:3) >=  thisNodeBBox(1:3) );
      % assert( aboveBBox(4:6) <=  thisNodeBBox(4:6) );
      % assert( belowSurfArea <= surfArea );
      % assert( aboveSurfArea <= surfArea );
      % Cost for partitioning.
      cost(bucketIdx) = traversalCost + ( intersectCost( belowCount ) * belowSurfArea + intersectCost( aboveCount ) * aboveSurfArea ) / surfArea;
    end % for         
    % Find bucket split to give minimum cost.
    [ minCost , splitBucketIdx ] = min( cost );
    % Compare cost of splitting to that of not splitting (numElements ray-element intersections).
    if( ( minCost < intersectCost( numElements ) ) || ( numElements > maxNumElemPerNode ) )
      % Cost of partitioning at the selected bucket is less than the cost of 
      % dumping all elements into leaf node so make the partition.
      isLeafNode = false;
      leftElementIdx = elementIdx( find( b <= splitBucketIdx ) );
      rightElementIdx = elementIdx( find( b > splitBucketIdx ) ); 
    else
      % Otherwise create a leaf node.
      leftElementIdx = [];
      rightElementIdx = []; 
      isLeafNode = true;  
    end % if

  end % function

  % Function to recursively construct BVH tree.
  function [ thisNodeBBox ] = partitionElements( elementIdx , parentNodeIdx , depth , maxDepth , minNumElemPerNode , ...
                                                 maxNumElemPerNode , splitMethodNumber , bboxes , barycentres )
    
     barycentreMinExtent = 1e-6;
     minSAHElements = 4;

     % Total number of elements in node.
     numElements = length( elementIdx );

     % Calculate bounding box of all elements in node.
     thisNodeBBox = [ min( bboxes(1:3,elementIdx) , [] , 2 ) ; max( bboxes(4:6,elementIdx) , [] , 2 ) ];
       
     % Determine whether and how to partition.
     if( numElements <= minNumElemPerNode || depth >= maxDepth )
       % Definitely leaf node.
       isLeafNode = true;
     else
       % Consider partitioning elements.
       % Calculate bbox of element barycentres.
       bcBBoxLow = min( barycentres(1:3,elementIdx) , [] , 2 );
       bcBBoxHigh = max( barycentres(1:3,elementIdx) , [] , 2 );
       % Choose parition direction that has largest barycentre extent.
       barycentreExtents = bcBBoxHigh - bcBBoxLow;
       [ barycentreMaxExtent , dim ] = max( barycentreExtents );
       bvh(parentNodeIdx).dim = dim;
       if( barycentreMaxExtent < barycentreMinExtent )
         % Elements are approximately degenerate so make a leaf node.
         isLeafNode = true;
       else
         % Partition elements based on split method.
         if( splitMethodNumber == 1 )
           % Split at mid-point of barycentre extent in partition direction.
           [ isLeafNode , leftElementIdx , rightElementIdx ] = ...
             meshPartitionMiddle( numElements , dim , elementIdx , barycentres , bcBBoxLow , bcBBoxHigh );
         elseif( splitMethodNumber == 2 || ( splitMethodNumber == 3 && numElements < minSAHElements ) ) 
           % Split with equal sized left/right counts.
           [ isLeafNode , leftElementIdx , rightElementIdx ] = ...
             meshPartitionEqual( numElements , dim , elementIdx , barycentres );
         elseif( splitMethodNumber ==  3 )
           % Split using surface area heuristic.
           [ isLeafNode , leftElementIdx , rightElementIdx ] = ...
             meshPartitionSAH( numElements , dim , elementIdx , barycentres , bcBBoxLow , bcBBoxHigh , bboxes , thisNodeBBox , maxNumElemPerNode );
         else
           assert( false );
         end % switch     
       end % if
     end % if

     if( isLeafNode )
       % Leaf node.
       bvh(parentNodeIdx).numElements = numElements;
       % Store element indices.
       bvh(parentNodeIdx).elements = elementIdx;
       % Add elements to mapping.
       bvh(parentNodeIdx).offset = nextElemIdx;
       elementMap(nextElemIdx:(nextElemIdx+numElements-1)) = elementIdx;
       nextElemIdx = nextElemIdx + numElements;
     else
       % Interior node.
       bvh(parentNodeIdx).numElements = 0;
       % Recurse left and right nodes.
        leftNodeIdx = nextNodeIdx + 1;
       nextNodeIdx = nextNodeIdx + 1;
       bvh(parentNodeIdx).lnode = leftNodeIdx;
       [ leftBbox ] = partitionElements( leftElementIdx , leftNodeIdx , depth + 1 , maxDepth , minNumElemPerNode , ...
                                         maxNumElemPerNode , splitMethodNumber , bboxes , barycentres );
       rightNodeIdx = nextNodeIdx + 1;
       nextNodeIdx = nextNodeIdx + 1;
       bvh(parentNodeIdx).rnode = rightNodeIdx;                                          
       [ rightBbox ] = partitionElements( rightElementIdx , rightNodeIdx , depth + 1 , maxDepth , minNumElemPerNode , ...
                                          maxNumElemPerNode , splitMethodNumber , bboxes , barycentres );
       % Combine AABBs of children to give that of this node.
       % thisNodeBBox = [ min( [ leftBbox(1:3) , rightBbox(1:3) ] , [] , 2 ) ; max( [ leftBbox(4:6) , rightBbox(4:6) ] , [] , 2 ) ];
     end % if

     % Store bounding box in leaf node, also passed back as return value.
     bvh(parentNodeIdx).bbox = thisNodeBBox;
     
  end % function

  % Function to recursively flatten BVH tree.
  function flattenTree( bvhNodeIdx , fbvhNodeIdx )

     if( isempty( bvh(bvhNodeIdx).lnode ))
       % Leaf node.
       fbvh(fbvhNodeIdx).bbox = bvh(bvhNodeIdx).bbox;
       fbvh(fbvhNodeIdx).numElements = bvh(bvhNodeIdx).numElements;
       % Offset is index of node first element in elementMap array.
       fbvh(fbvhNodeIdx).offset = bvh(bvhNodeIdx).offset;
     else
       % Interior node.
       fbvh(fbvhNodeIdx).bbox = bvh(bvhNodeIdx).bbox;
       fbvh(fbvhNodeIdx).numElements = 0;
       leftNodeIdx = bvh(bvhNodeIdx).lnode;
       rightNodeIdx = bvh(bvhNodeIdx).rnode;
       newLeftNodeIdx = nextNodeIdx;
       nextNodeIdx  = nextNodeIdx + 1;
       flattenTree( leftNodeIdx , newLeftNodeIdx );
       newRightNodeIdx = nextNodeIdx;
       nextNodeIdx  = nextNodeIdx + 1;
      % Offset is index of right child node in flat tree.
       fbvh(fbvhNodeIdx).offset = newRightNodeIdx;
       % Recurse down tree.
       flattenTree( rightNodeIdx , newRightNodeIdx );
     end % if

  end % function

  % Default options.
  splitMethod = 'SAH';
  maxDepth = 15;
  minNumElemPerNode = 5000;
  maxNumElemPerNode = Inf;
  isPlot = false;  

  % Check for default arguments.  
  if( nargin < 2 )
    groupNames = {};
  end % if

  % Parse options.
  if( nargin >= 3 )
    if( isfield( options , 'splitMethod' ) )
      splitMethod = options.splitMethod;
    end % if
    if( isfield( options , 'maxDepth' ) )
      maxDepth = options.maxDepth;
    end % if
    if( isfield( options , 'minNumElemPerNode' ) )
      minNumElemPerNode = options.minNumElemPerNode;
    end % if
    if( isfield( options , 'maxNumElemPerNode' ) )
      maxNumElemPerNode = options.maxNumElemPerNode;
    end % if
    if( isfield( options , 'isPlot' ) )
      isPlot = options.isPlot;
    end % if
  end % if

  % Turn split method strings into integer flags for performance in recusive build.
  switch( upper( splitMethod ) )
  case 'MEDIAN'
    splitMethodNumber = 1;
  case 'EQUAL'
    splitMethodNumber = 2; 
  case 'SAH'
    splitMethodNumber = 3;
  otherwise
    error( 'Invalid split method %s' , splitMethod );
  end % switch

  % If using SAH left its built in heuristic deal with minimum number per node.
  if( splitMethodNumber == 3 )
    minNumElemPerNode = 1;
  end % if

  % Maximum number of nodes in BVH.
  maxNodes = 2^( maxDepth + 1 ) - 1;
 
  fprintf( '  Building BVH with split method "%s"\n' , splitMethod );
   
  % Initialise BVH.
  % [FIXME] Check if better to pre-allocate or allocate on the fly. maxNodes it typically 
  % far higher than the number used.
  bvh = [];
  bvh(maxNodes).lnode = [];
  bvh(maxNodes).rnode = [];
  bvh(maxNodes).bbox = [];
  bvh(maxNodes).elements = [];
  bvh(maxNodes).numElements = [];
  bvh(maxNodes).offset = [];
  bvh(maxNodes).dim = [];

  % Get list of elements to include in BVH.
  if( isempty( groupNames ) )

    % Output all groups.
    groupIdx = 1:mesh.numGroups;
    % Find all elements in mesh.
    elementIdx = 1:mesh.numElements;

  else
  
    % Find group indices.
    groupIdx = meshGetGroupIndices( mesh , groupNames );
    % Get corresponding elements.
    elementIdx = nonzeros( mesh.groups(:,groupIdx) );

  end % if

  numElements =  length( elementIdx );
    
  % Mapping of elements - holds indices all elements with those in leaf nodes % store contiguously.
  elementMap = zeros( 1 , numElements );

  % Determine normals, AABBs and barycentres.
  % [FIXME] Currently calculates for all elements - restrict to those in elementIdx.
  [ normals , bboxes , barycentres ] = meshCalcElemProp( mesh );

  % We don't use the normals.
  clear normals;

  % Partition elements.
  nextNodeIdx = 2;
  nextElemIdx = 1;
  [ bbox ] = partitionElements( elementIdx , 1 , 0 , maxDepth ,  minNumElemPerNode , maxNumElemPerNode , splitMethodNumber , bboxes , barycentres );
  numBVHNodes = nextNodeIdx - 1;

  if( isPlot )
    x = [ bvh.numElements ];
    figure();
    hist( x(find(x)) , 30 );
    xlabel( 'Number of elements in leaf node' );
    ylabel( 'Number of leaf nodes' );
    title( 'BVH leaf node element distribution' );
  end % if
  
  % Defense work.
  % assert( nextElemIdx == numElements + 1 );
  % assert( sort( elementMap(:) ) == sort( elementIdx(:) ) );

  % Initialise flattened BVH.
  fbvh = [];
  fbvh(numBVHNodes).bbox = [];
  fbvh(numBVHNodes).offset = [];
  fbvh(numBVHNodes).numElements = [];

  % Flatten BVH.
  fprintf( '  Flattening BVH\n' );
  nextNodeIdx = 2;
  flattenTree( 1 , 1 );

  % assert( nextNodeIdx - 1 == numBVHNodes );
    
end % function

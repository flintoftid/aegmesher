function meshTestFBVH( mesh , groupNames , meshSize , splitMethod )
%
% meshTestFBVH - Test and time FBVH creation and intersection functions on a given mesh.
%
% meshTestFBVH( mesh , groupNames , meshSize , splitMethod )
%
% Inputs:
%
% mesh        - structure contain mesh to test against - see help for meshReadAmelet().
% groupNames  - string array, cell array of group names to cast rays against.
% meshSize    - real scalar, size of cubic mesh to use for test in same units as node coordinates
%               in mesh structure.
% splitMethod - BVH split method to use: 'MEDIAN, 'EQUAL' or 'SAH'.
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
% Date: 26/07/2013
% Version: 1.0.0

  % Options for ray-triangle intersection function.
  % Treat rays as infinite.
  intersectOptions.isInfiniteRay = true;
  % Tolerance on detection of elements parallel to rays.
  intersectOptions.epsParallelRay = 1e-12;
  % Treat triangles as two-sided.
  intersectOptions.isTwoSidedTri = true;
  % Include border points.
  intersectOptions.isIncludeRayEnds = true;
  % Tolerance for inclusion of border points tmin/tmax.
  intersectOptions.epsRayEnds = 1e-12;

  % Options for FBVH creation.
  % Split method.
  fbvhOptions.splitMethod = splitMethod;
  % Maximum BVH tree depth.
  fbvhOptions.maxDepth = 15;
  % Minimum number of elements for median and equal split.
  fbvhOptions.minNumElemPerNode = 5000;
  % Maximum  number of elements for SAH split.
  fbvhOptions.maxNumElemPerNode = Inf;
  % Plot statistics.
  fbvhOptions.isPlot = true; 

  % Build FBVH.
  tic();
  [ fbvh , elementMap ] = meshBuildFBVH( mesh , groupNames , fbvhOptions );
  times(1) = toc();

  numElementsInNodes = [ fbvh.numElements ];
  idx = find( numElementsInNodes > 0 );
  numElementsInLeafNodes = numElementsInNodes( idx );
  meanNumElementsInLeafNodes = mean( numElementsInLeafNodes );
  numElements = length( elementMap );

  fprintf( '\n' );
  fprintf( '  Number of elements in mesh is %d\n' , mesh.numElements );  
  fprintf( '  Number of elements in selected groups is %d\n' , numElements );  
  fprintf( '  Built FBVH in %.2f seconds\n' , times(1) );
  fprintf( '  Mean number of elements in FBVH leaf nodes is %d\n' , meanNumElementsInLeafNodes );
  %fflush( stdout );
  
  % Get overall bounding box of object.
  objBBox = fbvh(1).bbox;

  % Number of cells in each direction.
  numCell(1) = floor( ( objBBox(4) - objBBox(1) ) / meshSize );
  numCell(2) = floor( ( objBBox(5) - objBBox(2) ) / meshSize );
  numCell(3) = floor( ( objBBox(6) - objBBox(3) ) / meshSize );
  fprintf( '  Test grid is %d x %d x %d cells\n' , numCell );

  % Cell centres.
  x = objBBox(1) + 0.5 * meshSize + meshSize .* (0:(numCell(1)-1));
  y = objBBox(2) + 0.5 * meshSize + meshSize .* (0:(numCell(2)-1));
  z = objBBox(3) + 0.5 * meshSize + meshSize .* (0:(numCell(3)-1));
    
  % Total number of rays.
  numRays = numCell(1) * numCell(2) + numCell(2) * numCell(3) + numCell(3) * numCell(1);
    
  % Cast rays.
  numHits = [ 0 , 0 , 0 ];

  numRayXDir = numCell(2) * numCell(3);
  fprintf( '  Casting %d x-normal rays...' , numRayXDir );
  %fflush( stdout );
  dir = [ 1 , 0 , 0 ];
  tic();
  for j=1:numCell(2)
    for k=1:numCell(3)
       origin = [ objBBox(1) , y(j) , z(k) ];
       [ t , elementIdx , isHitEdge , isFrontFacing ] = meshIntersectFBVH( mesh , fbvh , elementMap , origin , dir , intersectOptions );
       numHits(1) = numHits(1) + length( t );
    end % for
  end % for
  timeXDir = toc();
  fprintf( ' %d hits in %.2f seconds (%.2f ms per ray)\n' , numHits(1) , timeXDir , 1e3 * timeXDir / numRayXDir );
 
  numRayYDir = numCell(1) * numCell(3);
  fprintf( '  Casting %d y-normal rays...' , numCell(1) * numCell(3) );
  %fflush( stdout );
  dir = [ 0 , 1 , 0 ];
  tic();
  for i=1:numCell(1)
    for k=1:numCell(3)
       origin = [ x(i) , objBBox(2) , z(k) ];
       [ t , elementIdx , isHitEdge , isFrontFacing ] = meshIntersectFBVH( mesh , fbvh , elementMap , origin, dir , intersectOptions );
       numHits(2) = numHits(2) + length( t );
    end % for
  end % for
  timeYDir = toc();
  fprintf( ' %d hits in %.2f seconds (%.2f ms per ray)\n' , numHits(2) , timeYDir , 1e3 * timeYDir / numRayYDir );
  
  numRayZDir = numCell(1) * numCell(2);
  fprintf( '  Casting %d z-normal rays...' , numCell(1) * numCell(2) );
  %fflush( stdout );
  dir = [ 0 , 0 , 1 ];
  tic();
  for i=1:numCell(1)
    for j=1:numCell(2)
       origin = [ x(i) , y(j) , objBBox(3) ];
       [ t , elementIdx , isHitEdge , isFrontFacing ] = meshIntersectFBVH( mesh , fbvh , elementMap , origin, dir , intersectOptions );
       numHits(3) = numHits(3) + length( t );
    end % for
  end % for
  timeZDir = toc();
  fprintf( ' %d hits in %.2f seconds (%.2f ms per ray)\n' , numHits(3) , timeZDir , 1e3 * timeZDir / numRayZDir );
    
  times(2) = timeXDir +  timeYDir + timeZDir;

  fprintf( '  Cast %d rays (%d hits) in %.2f seconds\n' , numRays , sum( numHits ) , times(2) );
  fprintf( '  Average time per ray %.2f ms\n' , 1e3 * times(2) / numRays );
  fprintf( '  Average time per ray per element %.2f ns\n' , 1e9 * times(2) / numRays / numElements );
  
  times(3) = times(1) + times(2);
 
  fprintf( '  Total time %.2f seconds\n' , times(3) );
  fprintf( '\n' );

end % function

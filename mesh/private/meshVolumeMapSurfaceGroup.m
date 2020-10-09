function [ isInside ] = meshVolumeMapSurfaceGroup( mesh , fbvh , elementMap , lines , objBBox , idxBBox , options )
%
% meshVolumeMapSurfaceGroup - Map a surface group from an unstructured mesh onto a volume group in the structured mesh.
%
% [ isInside ] = meshVolumeMapSurfaceGroup( mesh , fbvh , elementMap , lines , objBBox , idxBBox , options )
%
% Inputs:
%
% mesh         - structure containing the unstructured mesh. See help for meshReadAmelet().
% fvbh         - flattened BVH - see help for meshBuildFBVH.
% elementMap() - (numElements) integer array containing element indices (into mesh.elements) stored
%                such that leaf nodes elements are contiguous.
% lines        - structures contains mesh lines - see help for meshCreateLines.
% objBBox()    - real(6), AABB of group in real unit.
% idxBBox()    - integer(6), indeix AABB of group on structured mesh. 
% options      - structure containing options for intersection function - see help for meshTriRayIntersection().
%
% Outputs:
%
% isInside() - boolean(nx,ny,nz), isInside(i,j,k) indicates if cell (i,j,k) is inside the
%              the volume group.
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
% Version: 1.0.0

  fprintf( '  Volume mapping surface group using 3 ray directions xyz\n' );  

  % Insideness array for volume of mesh occupied by group. idxBBox must have non-zero volume at this stage.
  % The arrays cells on the top faces will not be used for solid objects - they are for holding surface/wire/node
  % elements on the upper AABB faces and retained for consistency of approach.
  isInside = false( idxBBox(4) - idxBBox(1) + 1 , idxBBox(5) - idxBBox(2) + 1 , idxBBox(6) - idxBBox(3) + 1 , 3 );

  % Map group in each direction.
  isInside(:,:,:,1) = meshSurf2VolMapParallelRays( mesh , fbvh , elementMap , lines.y , lines.z , lines.x , objBBox , idxBBox , 1 , options );
  isInside(:,:,:,2) = meshSurf2VolMapParallelRays( mesh , fbvh , elementMap , lines.z , lines.x , lines.y , objBBox , idxBBox , 2 , options );
  isInside(:,:,:,3) = meshSurf2VolMapParallelRays( mesh , fbvh , elementMap , lines.x , lines.y , lines.z , objBBox , idxBBox , 3 , options );

  % Apply dictator reduce.
  isInside = any( isInside , 4 );

end % function

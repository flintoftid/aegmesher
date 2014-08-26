function [ isXY , isYZ , isZX ] = meshSurfaceMapGroup( mesh , fbvh , elementMap , lines , objBBox , idxBBox , options )
%
% meshSurfaceMapGroup - Map a surface group from an unstructured mesh onto a structured mesh.
%
% [ isXY , isYZ , isZX ] = meshSurfaceMapGroup( mesh , fbvh , elementMap , lines , objBBox , idxBBox , options )
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
% isXY() - boolean(nx,ny,nz), boolean isXY(i,j,k) indicating whether the z-normal face
%          from (i,j,k) to (i+1,j+1,k) belongs to the group been mapped. Note that the indices
%          are relative to the group's AABB in idxBBox.
% isYZ() - boolean(nx,ny,nz), boolean isYZ(i,j,k) indicating whether the x-normal face
%          from (i,j,k) to (i,j+1,k+1) belongs to the group been mapped. Note that the indices
%          are relative to the group's AABB in idxBBox.
% isZX() - boolean(nx,ny,nz), boolean isZX(i,j,k) indicating whether the y-normal face
%          from (i,j,k) to (i+1,j,k+1) belongs to the group been mapped. Note that the indices
%          are relative to the group's AABB in idxBBox.
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

  fprintf( '  Surface mapping group\n' );  

  % Cast rays parallel rays alond cell centres in each direction.
  fprintf( '  Ray direction "x":\n' );
  [ isYZ , unresCellsXY ] = meshSurfaceMapParallelRays( mesh , fbvh , elementMap , lines.y , lines.z , lines.x , objBBox , idxBBox , 1 , options );
  fprintf( '  Ray direction "y":\n' );
  [ isZX , unresCellsYZ ] = meshSurfaceMapParallelRays( mesh , fbvh , elementMap , lines.z , lines.x , lines.y , objBBox , idxBBox , 2 , options );
  fprintf( '  Ray direction "z":\n' );
  [ isXY , unresCellsZX ] = meshSurfaceMapParallelRays( mesh , fbvh , elementMap , lines.x , lines.y , lines.z , objBBox , idxBBox , 3 , options );

  % Deal with unresolved cells by activating all faces.
  unresolvedCells = [ unresCellsXY ; unresCellsYZ ; unresCellsZX ]; 
  numUnresolvedCells = length( unresolvedCells );
  for idx=1:numUnresolvedCells
    cell = unresolvedCells{idx};
    i = cell(1);
    j = cell(2);    
    k = cell(3);
    isXY(i,j,k) = true;
    isXY(i,j,k+1) = true;
    isYZ(i,j,k) = true;
    isYZ(i+1,j,k) = true;
    isZX(i,j,k) = true;
    isZX(i,j+1,k) = true;
  end % for
  if( numUnresolvedCells > 0 )
    fprintf( '  %d cells were resolved by activating all faces.\n' , numUnresolvedCells );
  else
    fprintf( '  There were no unresolved cells.\n' );
  end % if

end % function

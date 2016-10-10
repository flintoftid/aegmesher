function [ isXY , isYZ , isZX ] = meshVolumeGroup2SurfaceGroup( isInside , idxBBox , options )
%
% meshVolumeGroup2SurfaceGroup - Remap a voulme group on a structured mesh onto a surface
%                                group of the bounding surface.
%
% [ isXY , isYZ , isZX ] = meshVolumeGroup2SurfaceGroup( isInside , idxBBox , options )
%
% Inputs:
%
% isInside() - boolean(nx,ny,nz), isInside(i,j,k) indicates if cell (i,j,k) is inside the
%              the volume group.
% idxBBox()  - integer(6), indeix AABB of group on structured mesh.
% options    - structure containing options for intersection function - see help for meshTriRayIntersection().
%
% Outputs:
%
% isXY() - boolean(nx,ny,nz), boolean isXY(i,j,k) indicating whether the z-normal face
%          from (i,j,k) to (i+1,j+1,k) belongs to the group been mapped. Note that the indices
%          are relative to the group's AABB in idxBBox.
% isYZ() - boolean(nx,ny,nz), boolean isYZ(i,j,k) indicating whether the x-normal face
%          from (i,j,k) to (i,j+1,k+1) belongs to the group been mapped. Note that the indices
%          are relative to the group's AABB in idxBBox.
% isZX)  - boolean(nx,ny,nz), boolean isZX(i,j,k) indicating whether the y-normal face
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

  fprintf( '  Remapping volume group to surface group\n' );  
 
  % Number of cells in group's sub-grid.
  numCells = idxBBox(4:6) - idxBBox(1:3) + 1;     

  % Includeness array for faces of mesh occupied by object.
  isXY = false( numCells(1) , numCells(2) , numCells(3) );
  isYZ = false( numCells(1) , numCells(2) , numCells(3) );
  isZX = false( numCells(1) , numCells(2) , numCells(3) );

  % Find x-y faces.
  for i=1:numCells(1)
    for j=1:numCells(2)
      isXY( i, j , find( diff( [ 0 ; squeeze( isInside(i,j,:) ) ] ) ) ) = true;
    end % for
  end % for

  % Find y-z faces.
  for j=1:numCells(2)
    for k=1:numCells(3)
      isYZ( find( diff( [ 0 ; squeeze( isInside(:,j,k) ) ] ) ) , j , k ) = true;
    end % for
  end % for

  % Find z-x faces.
  for k=1:numCells(3)
    for i=1:numCells(1)
      isZX( i , find( diff( [ 0 , squeeze( isInside(i,:,k) ) ] ) ) , k ) = true;
    end % for
  end % for

end % function

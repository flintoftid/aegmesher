function [ isInside  ] = meshVolumeMapParallelRays( mesh , fbvh , elementMap , xLines , yLines , zLines , objBBox , idxBBox , dirShift , options )
%
% meshVolumeMapParallelRays - Map a volume group using rays parallel to one side of the AABB.
%
% [ isInside ] = meshVolumeMapParallelRays( mesh , fbvh , elementMap , ...
%                     xLines , yLines , zLines , objBBox , idxBBox , dirShift , options )
%
% Inputs:
%
% mesh           - structure containing the unstructured mesh. See help for meshReadAmelet().
% fvbh           - flattened BVH - see help for meshBuildFBVH.
% elementMap()   - (numElements) integer array containing element indices (into mesh.elements) stored
%                  such that leaf nodes elements are contiguous.
% xLines()       - real(), mesh lines in x direction.
% yLines()       - real(), mesh lines in y direction.
% zLines()       - real(), mesh lines in z direction.
% objBBox()      - real(6), AABB of group in real unit.
% idxBBox()      - integer(6), indeix AABB of group on structured mesh.
% dirShift       - integer, indicates direction of rays:
%
%                  1 - x-direction to find YZ faces.
%                  2 - y-direction to find ZX faces.
%                  3 - z-direction to find XY faces.
%
% options        - structure containing options for intersection function - see help for meshTriRayIntersection().
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

% Author: M. Berens and I. D Flintoft
% Version: 1.0.0

  % Default options.
  isUseInterpResolver = false;
  isUnresolvedInside = true;

  % Parse options.
  if( nargin >= 9 )
    if( isfield( options , 'isUseInterpResolver' ) )
      isUseInterpResolver = options.isUseInterpResolver;  
    end % if
    if( isfield( options , 'isUnresolvedInside' ) )
      isUnresolvedInside = options.isUnresolvedInside;  
    end % if
  end % if

  % Required options to be passed through to meshIntersectFBVH.
  options.isInfiniteRay = false;
  options.isIncludeRayEnds = true;

  % Permute coordinates so rays are cast along the z directrion.
  objBBox = [ circshift( objBBox(1:3) , -dirShift ) ; circshift( objBBox(4:6) , -dirShift ) ];
  idxBBox = [ circshift( idxBBox(1:3) , [ 0 , -dirShift ] ) , circshift( idxBBox(4:6) , [ 0 , -dirShift ] ) ];
  
  % If using the resolver padding is needed to prevent interpolation algorithm 
  % in resolver becoming complex on computastional volume AABB faces.
  if( isUseInterpResolver )
    % Number of cells in group's computation volume sub-grid - add one cell padding above and below.
    numCells = idxBBox(4:6) - idxBBox(1:3) + 2;
    % Mesh lines relative to group's computational volume.
    xLocal = [ 2 * xLines(idxBBox(1)) - xLines(idxBBox(1)+1) , xLines(idxBBox(1):idxBBox(4)) , 2 * xLines(idxBBox(4)) - xLines(idxBBox(4)-1) ];
    yLocal = [ 2 * yLines(idxBBox(2)) - yLines(idxBBox(2)+1) , yLines(idxBBox(2):idxBBox(5)) , 2 * yLines(idxBBox(5)) - yLines(idxBBox(5)-1) ];
    zLocal = [ 2 * zLines(idxBBox(3)) - zLines(idxBBox(3)+1) , zLines(idxBBox(3):idxBBox(6)) , 2 * zLines(idxBBox(6)) - zLines(idxBBox(6)-1) ];
  else
    % Number of cells in group's sub-grid.
    numCells = idxBBox(4:6) - idxBBox(1:3) + 1;     
    % Mesh lines relative to group's computational volume.     
    xLocal = xLines(idxBBox(1):idxBBox(4));
    yLocal = yLines(idxBBox(2):idxBBox(5));
    zLocal = zLines(idxBBox(3):idxBBox(6));
  end % if

  % Insideness array for volume of mesh occupied by object.
  isInside = false( numCells(1) , numCells(2) , numCells(3) );

  % List of unresolved cells.
  numUnresolvedCells = 0;
  unresolvedCells = {};

  % Transverse coordinates of cell centres.
  x = 0.5 * ( xLocal(1:end-1) + xLocal(2:end) );
  y = 0.5 * ( yLocal(1:end-1) + yLocal(2:end) );
  zCellCentres = 0.5 * ( zLocal(1:(end-1)) + zLocal(2:end) );
  
  % Create finite ray along midpoints of cells from front to back face of object AABB. 
  zOrigin = zLocal(1) - options.epsRayEnds;
  zDestination = zLocal(end) + options.epsRayEnds;
  zDir = zDestination - zOrigin;
  
  % Ray parameter at face centres.
  tFaceCentres = ( zLocal - zOrigin ) / zDir;

  % Ray parameter at cell centres.
  tCellCentres = ( zCellCentres - zOrigin ) / zDir;
 
  % Loop over all cell centres in x and y directions.
  for j=1:numCells(2)-1
    for i=1:numCells(1)-1
      % Permute coordinate to correct dimension for ray casting.
      origin = circshift( [ x(i) , y(j) , zOrigin ] , [ 0 , dirShift ] );    
      destination = circshift( [ x(i) , y(j) , zDestination ] , [ 0 , dirShift ] );
      dir = destination - origin;
      % Cast ray. Elements parallel to elements are discarded by meshIntersectFBVH but other types
      % of singularity will still be present.
      [ tIntersect , elementIdx , isIntersectEdge , isFrontFacing ] = meshIntersectFBVH( mesh , fbvh , elementMap , origin , dir , options );    
      % If no intersections found move to next ray.
      if( isempty( tIntersect ) )
        continue;
      end % if
      % Attempt to resolve remaining singularities in the intersections found and mark any non-traversing singularities.
      % If valid normals are present only pairs of traversing (entering,leaving) intersections remain in tIntersect.
      [ tIntersect ,  elementIdx , isIntersectEdge  , isFrontFacing , tNonTravSing , parity ] = ...
        meshResolveRayVolume( tIntersect ,  elementIdx , isIntersectEdge , isFrontFacing , options );
      % Find cell centres between entering and leaving intersections. 
      for pairIdx=1:(length(tIntersect)/2)
        % [FIXME] Should we used epsUniqueIntersection here?
        kInside = find( ( tCellCentres > tIntersect(2*pairIdx-1) & tCellCentres < tIntersect(2*pairIdx) ) );
        % Assign insideness for cells along ray.
        isInside(i,j,kInside) = true;
      end %for
      % Mark non-traversing intersections that occur at cell centres.
      [ ~ , ~ , kUnresolved ] = intersect( tNonTravSing , tCellCentres );
      if( ~isempty( kUnresolved ) )
        isInside(i,j,kUnresolved) = isUnresolvedInside;
        numUnresolvedCells = numUnresolvedCells + length( kUnresolved );
        unresolvedCells = [ unresolvedCells ; mat2cell( repmat( [ i , j ] , length( kUnresolved ) , 1 ) + kUnresolved(:) , ones( 1 , length( kUnresolved ) ) , 3 ) ];
      end % if
    end % for
  end % for

  % Resolve remaining cells using 6-point interpolation.
  % [FIXME] This may not work well if there are a lot of neighbouring unresolved cells.
  fprintf( '    %d unresolved cells\n' , numUnresolvedCells );
  if( isUseInterpResolver )
    for idx=1:numUnresolvedCells
      cell = unresolvedCells{idx};
      i = cell(1);
      j = cell(2);    
      k = cell(3);
      isInside(i,j,k) = ( isInside(i+1,j,k) + isInside(i-1,j,k) ...
                        + isInside(i,j+1,k) + isInside(i,j-1,k) ...
                        + isInside(i,j,k+1) + isInside(i,j,k-1) ) >= 3;
    end % for
    % Remove padding cells.
    % [FIXME] Any way to remove expense of this operation? Use profiler to see if it is a significant hit.
    isInside = isInside(2:(numCells(1)),2:(numCells(2)),2:(numCells(3)));
  end % if
  
  % Permute coordinate axes back to required order.
  isInside = permute( isInside , circshift( [ 1 , 2 , 3 ] , [ 0 , dirShift ] ) );

end % function

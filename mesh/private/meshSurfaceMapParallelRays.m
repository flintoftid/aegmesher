function [ isXY , unresolvedCells ] = ...
  meshSurfaceMapParallelRays( mesh , fbvh , elementMap , xLines , yLines , zLines , objBBox , idxBBox , dirShift , options )
%
% meshSurfaceMapParallelRays - Map a surface group from an unstructured mesh onto a structured mesh
%                              rays parallel to one coordinate axis. Only faces of the structured
%                              mesh normal to the ray direction are mapped.
%
% [ isXY , unresolvedCells ] = meshSurfaceMapParallelRays( mesh , fbvh , elementMap , ...
%                                 xLines , yLines , zLines , objBBox , idxBBox , dirShift , options )
%
% Inputs:
%
% mesh         - structure containing the unstructured mesh. See help for meshReadAmelet().
% fvbh         - flattened BVH - see help for meshBuildFBVH.
% elementMap() - (numElements) integer array containing element indices (into mesh.elements) stored
%                such that leaf nodes elements are contiguous.
% xLines()     - real(), mesh lines in x direction.
% yLines()     - real(), mesh lines in y direction.
% zLines()     - real(), mesh lines in z direction.
% objBBox()    - real(6), AABB of group in real unit.
% idxBBox()    - integer(6), indeix AABB of group on structured mesh.
% dirShift     - integer, indicates direction of rays:
%
%                1 - x-direction to find YZ faces.
%                2 - y-direction to find ZX faces.
%                3 - z-direction to find XY faces.
%
% options      - structure containing options for intersection function - see help for meshTriRayIntersection().
%
% Outputs:
%
% isXY()            - boolean(nx,ny,nz), boolean isXY(i,j,k) indicating whether the "dirShift"-normal face
%                     of cell (i,j,k) belongs to the group been mapped. Note that the indices
%                     are relative to the group's AABB in idxBBox.
% unresolvedCells{} - cell array of coordinates indices of cells that could not be 
%                     unambiguoulsy resolved.
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

  % Required options to be passed through to meshIntersectFBVH.
  options.isInfiniteRay = false;
  options.isIncludeRayEnds = true;

  % Permute coordinates so rays are cast along the z directrion.
  objBBox = [ circshift( objBBox(1:3) , -dirShift ) ; circshift( objBBox(4:6) , -dirShift ) ];
  idxBBox = [ circshift( idxBBox(1:3) , [ 0 , -dirShift ] ) , circshift( idxBBox(4:6) , [ 0 , -dirShift ] ) ];
 
  % Number of cells in group's sub-grid.
  numCells = idxBBox(4:6) - idxBBox(1:3) + 1;     

  % Mesh lines relative to group's computational volume.     
  xLocal = xLines(idxBBox(1):idxBBox(4));
  yLocal = yLines(idxBBox(2):idxBBox(5));
  zLocal = zLines(idxBBox(3):idxBBox(6));

  % Includeness array for faces of mesh occupied by object.
  isXY = false( numCells(1) , numCells(2) , numCells(3) );

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
      % Find number of intersections on each secondary grid egde (centred on face centres).
      if( length( tFaceCentres ) > 1 )
        [ numIntersections , ~ ] = hist( tIntersect , tFaceCentres );
      else
        numIntersections = length( tIntersect );
      end % if
      kInside = find( numIntersections );
      % If any intersection on secondary edge activate the normal face.
      isXY(i,j,kInside) = true;
      % If there are multiple intersections on a secondary edge mark both cells as unresolved.
      % k = find( numIntersections > 1 );
      % kUnresolved = [ k - 1 , k ];
      % If there is an intersection on a cell centre mark that cell unresolved.
      tIntersectRounded = round( tIntersect ./ options.epsResolver ) .* options.epsResolver;
      tCellCentresRounded = round( tCellCentres ./ options.epsResolver ) .* options.epsResolver;   
      [ ~ , ~ , kUnresolved ] = intersect( tIntersectRounded , tCellCentresRounded );
      %[ ~ , ~ , kUnresolved ] = intersect( tIntersect , tCellCentres );
      % Keep indices of all unresolved cells and activate faces below and above.
      if( ~isempty( kUnresolved ) )     
        isXY(i,j,kUnresolved) = true;
        isXY(i,j,kUnresolved+1) = true;
        isInside(i,j,kUnresolved) = options.isUnresolvedInside;
        numUnresolvedCells = numUnresolvedCells + length( kUnresolved );
        unresolvedCells = [ unresolvedCells ; ...
           mat2cell( repmat( [ i , j , 0 ] , length( kUnresolved )  , 1 ) + [ zeros( length( kUnresolved ) , 2 ) , kUnresolved(:) ] , ...
              ones( 1 , length( kUnresolved ) ) , 3 ) ];
      end % if
    end % for
  end % for
  fprintf( '    %d unresolved cells\n' , numUnresolvedCells );

  % Translate unresolved cell indices to global mesh line numbers and permute back to required order.
  for idx=1:length( unresolvedCells )
    unresolvedCells{idx} = circshift( unresolvedCells{idx} , [ 0 , dirShift ] );
  end % for

  % Permute coordinate axes back to required order.
  isXY = permute( isXY , circshift( [ 1 , 2 , 3 ] , [ 0 , dirShift ] ) );

end % function

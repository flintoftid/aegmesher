function [ isInside ] = meshVolumeMapDivergentRays( mesh , fbvh , elementMap , xLines , yLines , zLines , objBBox , idxBBox , diagonalNumber , options )
%
% meshVolumeMapDivergentRays - Map a volume group using divergent rays from outside the group AABB.
%
% [ isInside ] = meshVolumeMapDivergentRays( mesh , fbvh , elementMap , ...
%                     xLines , yLines , zLines , objBBox , idxBBox , diagonalNumber , options )
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
% diagonalNumber - integer, which diagonal of AABB to place ray origin on:
%
%                  1 - 'd' [FIXME]
%                  2 - 'e' [FIMXE]
%                  3 - 'f' [FIXME]
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

% Author: I. D Flintoft
% Version: 1.0.0

  % Default options.
  epsRayEnds = 1e-10;
  isUseInterpResolver = false;
  isUnresolvedInside = true;

  % Parse options.
  if( nargin >= 9 )
    if( isfield( options , 'epsRayEnds' ) )
      epsRayEnds = options.epsRayEnds;  
    end % if
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
 
  % Corners of object AABB.
  Pmin = [ objBBox(1) , objBBox(2) , objBBox(3) ];
  Pmax = [ objBBox(4) , objBBox(5) , objBBox(6) ];

  % Parameters for location of search origin.
  lambda = [ 2 , 2 , 2 ; ... % Diagonal 'd'
             3 , 2 , 2 ; ... % Diagonal 'e'
             2 , 3 , 2 ];    % Diagonal 'f'

  % Set origin to point on diagonal outside AABB of group.
  origin = Pmin + ( Pmax - Pmin ) * diag( lambda(diagonalNumber,1:3) );
  fprintf( '    Ray origin: [%g,%g,%g]\n' , origin );
      
  % Loop over cell centres.
  for i=1:numCells(1)-1
    for j=1:numCells(2)-1
      for k=1:numCells(3)-1
        % Coordinates of cell centre.
        x = 0.5 * ( xLocal(i) + xLocal(i+1) );
        y = 0.5 * ( yLocal(j) + yLocal(j+1) );
        z = 0.5 * ( zLocal(k) + zLocal(k+1) );        
        % Create finite ray from origin to cell centre.
        dir = [ x , y , z ] - origin;
        % Cast rays. Elements parallel to ray are discarded by meshIntersectFBVH but other types
        % of singularity will still be present.
        [ tIntersect , elementIdx , isIntersectEdge , isFrontFacing ] = meshIntersectFBVH( mesh , fbvh , elementMap , origin , dir , options );
        % If no intersections found move to next ray.
        if( isempty( tIntersect ) )
          continue;
        end % if
        % Attempt to resolve ambiguites due to singularities in the intersections found.
        [ tIntersect ,  elementIdx , isIntersectEdge  , isFrontFacing , tNonTravSing , parity ] = ...
          meshResolveRayVolume( tIntersect , elementIdx , isIntersectEdge  , isFrontFacing , options );      
        % Check for cell centre on surface of group element.
        if( abs( tIntersect(end) - 1.0 ) < epsRayEnds )
          % Cell centre is very close to an intersection point - set to default insideness value...
          isInside(i,j,kInside) = isUnresolvedInside;
          % ...and then mark it for resolving later.
          numUnresolvedCells = numUnresolvedCells + 1
          unresolvedCells{numUnresolvedCells} = [ i , j , k ];
        else
          % Assign insideness of cell based on parity count of the last intersection along the ray segment.
          isInside(i,j,k) = parity(end);
        end % if
      end % for
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

end % function

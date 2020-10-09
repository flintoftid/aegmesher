function [ t ,  elementIdx , isIntersectEdge  , isFrontFacing , tNonTravSing , parity ] = ...
  meshResolveRayVolume( t ,  elementIdx , isIntersectEdge  , isFrontFacing , options )
%
% meshResolveRayVolume - Resolve intersections along a ray in case where the
%                        object is a solid. If valid normal directions of the mesh 
%                        elements, as defined by the right-hand rule for node ordering,
%                        are present the singularities can be fully resolved, otherwise 
%                        ray casting for multiple directions will be needed in many cases.
%
% [ t ,  elementIdx , isIntersectEdge  , isFrontFacing , tNonTravSing , parity ] = ...
%         meshResolveRayVolume( t ,  elementIdx , isIntersectEdge  , isFrontFacing , options )
%
% Inputs:
%
% t()               - (N) real vector, ray's parameter values at intersection points.
% elementIdx()      - (N) integer vector of corresponding intersected element indices.
% isIntersectEdge() - (N) boolean vector indicating if intersection is on edge of elements.
% isFrontFacing()   - (N) boolean vector indicating if intersection are on front-facing elements.
% options           - structure containing the options:
%
%                     .epsUniqueIntersection - real scalar tolerance on assigning unique 
%                                              intersection points (default 100 * eps).
%                     .isValidNormals        - scalar boolean indicating if normal vectors, as
%                                              encodsing in the values of isFrontFacing are valid.
%
% Outputs:
%
% t()               - (M<=N) real vector of resolved parameter values at intersection points.
% elementIdx()      - (M<=N) integer vector of corresponding resolved intersected element indices.
%                     For traversing intersections on edge/corner only one element index is provided.
% isIntersectEdge() - (M<=N) boolean vector indicating if resolved intersection is on edge of elements.
% isFrontFacing()   - (M<=N) boolean vector indicating if resolved intersection are on front-facing elements.
% tNonTravSing()    - (>=0) real vector of paramters for non-traversing singularities identified.
% parity()          - (M<=N) integer vector indicating parity of resolved intersections (0 - leaving, 1- entering).
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
% Date: 30/07/2013
% Version: 1.0.0

  tNonTravSing = [];

  % Default options.
  epsUniqueIntersection = 1e-6;
  isValidNormals = false;
 
  % Parse options.
  if( nargin >= 5 )
    if( isfield( options , 'epsUniqueIntersection' ) )
      epsUniqueIntersection = options.epsUniqueIntersection;  
    end % if
    if( isfield( options , 'isValidNormals' ) )
      isValidNormals = options.isValidNormals;
    end % if    
  end % if

  % Fast return.
  if( isempty( t ) )
    parity = 0;
    return;
  end % if

  % Order intersection parameters.
  [ t , idx ] = sort( t );
  isFrontFacing = isFrontFacing(idx);
  isIntersectEdge = isIntersectEdge(idx);
  elementIdx = elementIdx(idx);
  
  % Find neighbouring elements that are unique within tolerance.
  % [FIXME] Is this transitive and what are implications of answer.
  [ tt , ~ , ttIdx ] = meshUniqueTol1( t , epsUniqueIntersection );

  % List of intersections to keep in following analysis.
  keepIdx = [];

  if( isValidNormals )
    % Loop over unqiue values of t.
    for thisUniqueIdx=1:length( tt )
      % Indices of this unique value in original t array.
      tIdxs = find( ttIdx == thisUniqueIdx );
      if( length( tIdxs ) == 1 )
        % Unique hit. Shouldn't have hit an edge in this case.
        assert( ~isIntersectEdge( tIdxs(1) ) );
        % Keep hit.
        keepIdx = [ keepIdx , tIdxs(1) ];
      else
        % Multiple hit. Check if traversing or non-traversing. 
        if( all( isFrontFacing(tIdxs) ) || all( ~isFrontFacing(tIdxs) ) )
          % Traversing ray intersection on edges/corners of multiple elements. Keep one.
          keepIdx = [ keepIdx , tIdxs(1) ];
        else
          % Non-traversing tangential ray intersection on edges/corners of multiple elements.
          % Miss - mark it.
          tNonTravSing = [ tNonTravSing , t(tIdxs(1)) ];
        end % if
      end % if
    end % for
  else
    % Without normal information the best we can do is keeps all the unique hits
    % and let ray casting from multiple directions resolve singular cases.
    for thisUniqueIdx=1:length( tt )
      % Indices of this unique value in original t array.
      tIdxs = find( ttIdx == thisUniqueIdx );
      keepIdx = [ keepIdx , tIdxs(1) ];
    end % for
  end % if

  % Keep unique traversing ray hits.
  t = t(keepIdx);
  isFrontFacing = isFrontFacing(keepIdx);
  isIntersectEdge = isIntersectEdge(keepIdx);
  % [FIXME] This will only have first element index in case of multiple hits on traversing edge/corner.
  % Can't easily deal with this without using cell array or sparse array.
  elementIdx = elementIdx(keepIdx);

  % Cross validate. We always cast rays through the entire object even
  % if the computational volume truncates the group. 
  windingNumber = 1:length( t );
  % Parity count - 1 for entering object, 0 for leaving.
  parity = rem( windingNumber , 2 );
  % Parity count should match hits on facing triangles if normals are valid.
  if( isValidNormals )
    assert( all( parity(:) == isFrontFacing(:) ) );
  end % if 

end % function

function meshTestResolveRayVolume()
%
% meshTestResolveRayVolume - Test volume ray resolver.
%
% meshTestResolveRayVolume()
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
% Date:
% Version: 1.0.0

  options.isValidNormals = true;

  % Basic in and out ray.
  t               = [ 1 , 2 ];
  elementIdx      = [ 1 , 2 ];
  isIntersectEdge = [ 0 , 0 ];
  isFrontFacing   = [ 1 , 0 ];
  [ t2 ,  elementIdx2 , isIntersectEdge2 , isFrontFacing2 ] = meshResolveRayVolume( t ,  elementIdx , isIntersectEdge , isFrontFacing , options );
  assert( all( t2               == [ 1 , 2 ] ) );
  assert( all( elementIdx2      == [ 1 , 2 ] ) );
  assert( all( isIntersectEdge2 == [ 0 , 0 ] ) );
  assert( all( isFrontFacing2   == [ 1 , 0 ] ) );

  % Traversing edge hit on entering.
  t               = [ 1 , 1 , 2 ];
  elementIdx      = [ 1 , 2 , 3 ];
  isIntersectEdge = [ 1 , 1 , 0 ];
  isFrontFacing   = [ 1 , 1 , 0 ];
  [ t2 ,  elementIdx2 , isIntersectEdge2 , isFrontFacing2 ] = meshResolveRayVolume( t ,  elementIdx , isIntersectEdge , isFrontFacing , options );
  assert( all( t2               == [ 1 , 2 ] ) );
  assert( all( elementIdx2      == [ 1 , 3 ] ) );
  assert( all( isIntersectEdge2 == [ 1 , 0 ] ) );
  assert( all( isFrontFacing2   == [ 1 , 0 ] ) ); 

  % Traversing corner hit on entering.
  t               = [ 1 , 1 , 1 , 2 ];
  elementIdx      = [ 1 , 2 , 3 , 4 ];
  isIntersectEdge = [ 1 , 1 , 1 , 0 ];
  isFrontFacing   = [ 1 , 1 , 1 , 0 ];
  [ t2 ,  elementIdx2 , isIntersectEdge2 , isFrontFacing2 ] = meshResolveRayVolume( t ,  elementIdx , isIntersectEdge , isFrontFacing , options );
  assert( all( t2               == [ 1 , 2 ] ) );
  assert( all( elementIdx2      == [ 1 , 4 ] ) );
  assert( all( isIntersectEdge2 == [ 1 , 0 ] ) );
  assert( all( isFrontFacing2   == [ 1 , 0 ] ) ); 
  
  % Non-traversing edge hit then in/out.
  t               = [ 1 , 1 , 2 , 3 ];
  elementIdx      = [ 1 , 2 , 3 , 4 ];
  isIntersectEdge = [ 1 , 1 , 0 , 0 ];
  isFrontFacing   = [ 1 , 0 , 1 , 0 ];
  [ t2 ,  elementIdx2 , isIntersectEdge2 , isFrontFacing2 ] = meshResolveRayVolume( t ,  elementIdx , isIntersectEdge , isFrontFacing, options );
  assert( all( t2               == [ 2 , 3 ] ) );
  assert( all( elementIdx2      == [ 3 , 4 ] ) );
  assert( all( isIntersectEdge2 == [ 0 , 0 ] ) );
  assert( all( isFrontFacing2   == [ 1 , 0 ] ) );

  % Non-traversing corner hit then in/out.
  t               = [ 1 , 1 , 1 , 2 , 3 ];
  elementIdx      = [ 1 , 2 , 3 , 4 , 5 ];
  isIntersectEdge = [ 1 , 1 , 1 , 0 , 0 ];
  isFrontFacing   = [ 1 , 0 , 1 , 1 , 0 ];
  [ t2 ,  elementIdx2 , isIntersectEdge2 , isFrontFacing2 ] = meshResolveRayVolume( t ,  elementIdx , isIntersectEdge , isFrontFacing , options );
  assert( all( t2               == [ 2 , 3 ] ) );
  assert( all( elementIdx2      == [ 4 , 5 ] ) );
  assert( all( isIntersectEdge2 == [ 0 , 0 ] ) );
  assert( all( isFrontFacing2   == [ 1 , 0 ] ) );
  
end % function

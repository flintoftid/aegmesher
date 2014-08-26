function [ AABB ] = meshGetGroupAABB( mesh , groupIdx )
%
% meshGetGroupAABB - Get axis aligned bounding box (AABB) of 
%                    group in unstructutred mesh.
% 
% [ AABB ] = meshGetGroupAABB( mesh , groupIdx )
%
% Inputs:
%
% mesh     - structure containing the unstructured mesh. See help for meshReadAmelet().
% groupIdx - index of group to find AABB for.
%
% Outputs:
%
% AABB - real(6) vector of AABB coordinates [xlo,ylo,zlo,xhi,yhi,zhi].
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
% Date: 25/07/2013
% Version: 1.0.0

  elementIdx = nonzeros( mesh.groups(:,groupIdx) );
  nodes = nonzeros( mesh.elements(:,elementIdx) );
  nodeCoords = full( mesh.nodes(1:3,nodes) );
  AABB = [ min( nodeCoords , [] , 2 ) , max( nodeCoords , [] , 2 ) ];

end % function

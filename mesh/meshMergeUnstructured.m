function [ mesh ] = meshMergeUnstructured( mesh1 , mesh2 )
%
% meshMergeUnstructured - Merge the elements in two unstructured meshes.
%
% Usage:
%
% [ mesh ] = meshMergeUnstructured( mesh1 , mesh2 )
%
% Inputs:
%
% mesh1 - structure containing the first unstructured mesh. See help for meshReadAmelet().
% mesh2 - structure containing the second unstructured mesh. See help for meshReadAmelet().
%
% Outputs:
%
% mesh  - structure containing the mereged unstructured meshes. See help for meshReadAmelet().
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

% Author: M. Berens
% Date: 12/10/2013
% Version 1.0.0

% Author: I. D. Flintoft
% Date: 31/10/2013
% Version 1.1.0
% Refactored out of meshWriteLines2Gmsh.

%
% Notes:
%
% 1. Repeated nodes and elements are not removed.
%
% 2. No checks are done for duplicate group names. 
%

  % Merge nodes.
  assert( all( mesh1.nodes(:) <= mesh1.numNodes ) );
  assert( all( mesh2.nodes(:) <= mesh2.numNodes ) );
  assert( size( mesh1.nodes, 2 ) == mesh1.numNodes );
  assert( size( mesh2.nodes, 2 ) == mesh2.numNodes );
  mesh.numNodes = mesh1.numNodes + mesh2.numNodes;
  mesh.nodes = [ mesh1.nodes , mesh2.nodes ];

  % Merge elements.
  assert( all( mesh1.elements(:) <= mesh1.numNodes ) );
  assert( all( mesh2.elements(:) <= mesh2.numNodes ) );
  assert( size( mesh1.elements, 2 ) == mesh1.numElements );
  assert( size( mesh2.elements, 2 ) == mesh2.numElements );
  mesh.numElements = mesh1.numElements + mesh2.numElements;
  mesh.elementTypes = [ mesh1.elementTypes , mesh2.elementTypes ];
  [ i1, j1 , s1 ] = find( mesh1.elements );
  [ i2, j2 , s2 ] = find( mesh2.elements );
  mesh.elements = sparse( [ i1 ; i2 ] , [ j1 ; j2 + mesh1.numElements ] , [ s1 ; s2 + mesh1.numNodes ] , ...
                          max( [ i1 ; i2 ] ) , mesh.numElements );

  % Merge groups.
  assert( size( mesh1.groups , 2 ) == mesh1.numGroups );
  assert( size( mesh2.groups , 2 ) == mesh2.numGroups );
  mesh.numGroups = mesh1.numGroups + mesh2.numGroups;
  mesh.groupNames = [ mesh1.groupNames , mesh2.groupNames ];
  mesh.groupTypes = [ mesh1.groupTypes , mesh2.groupTypes ];
  [ i1, j1 , s1 ] = find( mesh1.groups );
  [ i2, j2 , s2 ] = find( mesh2.groups );
  mesh.groups = sparse( [ i1 ; i2 ] , [ j1 ; j2 + mesh1.numGroups ] , [ s1 ; s2 + mesh1.numElements ] , ...
                         max( [ i1 ; i2 ] ) , mesh.numGroups );

  % Merge groups of groups.
  if( isfield( mesh , 'groupGroupNames' ) )
    assert( size( mesh1.groupGroups , 2 ) == mesh1.numGroupGroups );
    assert( size( mesh2.groupGroups , 2 ) == mesh2.numGroupGroups );
    mesh.numGroupGroups = mesh1.numGroupGroups + mesh2.numGroupGroups;
    mesh.groupGroupNames = [ mesh1.groupGroupNames , mesh2.groupGroupNames ];
    [ i1, j1 , s1 ] = find( mesh1.groupGroups );
    [ i2, j2 , s2 ] = find( mesh2.groupGroups );
    mesh.groupGroups = sparse( [ i1 ; i2 ] , [ j1 ; j2 + mesh1.numGroupGroups ] , [ s1 ; s2 + mesh1.numGroups ] , ...
                       max( [ i1 ; i2 ] ) , mesh.numGroupGroups );
  end % if

  % Validate.
  assert( all( mesh.nodes(:) <= mesh.numNodes ) );
  assert( size( mesh.nodes, 2 ) == mesh.numNodes );
  assert( all( mesh.elements(:) <= mesh.numNodes ) );
  assert( size( mesh.elements, 2 ) == mesh.numElements );
  assert( size( mesh.groups , 2 ) == mesh.numGroups );

end % function

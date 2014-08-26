function [ mesh ] = meshSmesh2UnmeshFast( smesh )
%
% meshSmesh2UnmeshFast - Converts a structured mesh into an unstructured mesh.
%
% Usage:
%
% [ mesh ] = meshSmesh2UnmeshFast( smesh )
%
% Inputs:
%
% smesh - structure containing the structured mesh. See help for meshMapGroups().
%
% Outputs:
%
% mesh  - structure containing the unstructured mesh. See help for meshReadAmelet().
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
% Date: 01/11/2013
% Version 1.1.0
% Refactored to remove repeated code.
% Changed semantics of unstructured mesh surface elements to match Vulture.

% Author: I. D. Flintoft
% Date: 25/08/2014
% Version 1.3.0
% Refactored into higlhy vectoried code to improve scalability.

  % Element types.
  % Cell.
  numElemVertices(1) = 8;
  elemStencil{1} = [ 0 0 0 ; 1 0 0 ; 1 1 0 ; 0 1 0 ; 0 0 1 ; 1 0 1 ; 1 1 1  ; 0 1 1 ]; 
  elemTypes(1) = [ 104 ];
  % xy-face
  numElemVertices(2) = 4;
  elemStencil{2} = [ 0 0 0 ; 1 0 0 ; 1 1 0 ; 0 1 0 ];
  elemTypes(2) = [ 13 ];  
  % yz-face
  numElemVertices(3) = 4;
  elemStencil{3} = [ 0 0 0 ; 0 1 0 ; 0 1 1 ; 0 0 1 ];
  elemTypes(3) = [ 13 ];  
  % zx-face
  numElemVertices(4) = 4;
  elemStencil{4} = [ 0 0 0 ; 1 0 0 ; 1 0 1 ; 0 0 1 ];
  elemTypes(4) = [ 13 ]; 
  % x-edge
  numElemVertices(5) = 2;
  elemStencil{5} = [ 0 0 0 ; 1 0 0 ];
  elemTypes(5) = [ 1 ]; 
  % y-edge
  numElemVertices(6) = 2;
  elemStencil{6} = [ 0 0 0 ; 0 1 0 ];
  elemTypes(6) = [ 1 ]; 
  % z-edge
  numElemVertices(7) = 2;
  elemStencil{7} = [ 0 0 0 ; 0 0 1 ];
  elemTypes(7) = [ 1 ]; 
  % node
  numElemVertices(8) = 1;
  elemStencil{8} = [ 0 0 0 ];
  elemTypes(8) = [ 199 ]; 
  
  % Carry across invariant data into unstructured mesh.
  mesh.dimension = smesh.dimension;
  mesh.numGroups = smesh.numGroups;
  mesh.groupNames = smesh.groupNames;
  mesh.groupTypes = smesh.groupTypes;
  if( isfield( smesh , 'groupGroupNames' ) )
    mesh.numGroupGroups = smesh.numGroupGroups;
    mesh.groupGroupNames = smesh.groupGroupNames;
    mesh.groupGroups = smesh.groupGroups;
  end % if

  % Short hand for mesh line coordinates.
  x = smesh.lines.x;
  y = smesh.lines.y;
  z = smesh.lines.z;
  Nx = length( x );
  Ny = length( y );
  Nz = length( z );
  assert( Nx == size(smesh.elements,1) );
  assert( Ny == size(smesh.elements,2) );
  assert( Nz == size(smesh.elements,3) );

  % Calculate flattened index stencils for this mesh size.
  for entityNum=1:size( smesh.elements , 4 )
    stencil = elemStencil{entityNum};
    implicitStencil{entityNum} = stencil(:,1) + Nx * stencil(:,2) + Nx * Ny * stencil(:,3);
  end % for

  % Find number of elements in each group.
  for groupIdx=1:mesh.numGroups
    [ flatCellIdx ] = find( smesh.elements == groupIdx );
    numElementsInGroup(groupIdx) = length( flatCellIdx );
  end % for
  clear flatCellIdx;

  % Initialise arrays.
  mesh.numElements = sum( numElementsInGroup );
  mesh.elementTypes = zeros( 1 , mesh.numElements ); 
  mesh.elements = sparse( 8 , mesh.numElements );
  %mesh.elements = zeros( 8 , mesh.numElements );
  mesh.groups = sparse( max( numElementsInGroup ) , mesh.numGroups );
  %mesh.groups = zeros( max( numElementsInGroup ) , mesh.numGroups );

  % Mark which nodes (flat index) are used.
  isNodeUsed = false( 1 , Nx * Ny * Nz );

  elementIdx = 0;
  nextElemIdxInGroup = zeros( mesh.numGroups );
  for groupIdx=1:mesh.numGroups
    for entityNum=1:size( smesh.elements , 4 )
      % Find implicit flattened index of all entities belonging to current group.
      [ flatCellIdx ] = find( smesh.elements(:,:,:,entityNum) == groupIdx );
      thisNumElements = length( flatCellIdx );
      if( thisNumElements == 0 ) 
        continue;
      end % if
      thisElemIdx = elementIdx + (1:thisNumElements);
      % Find implicit flattened index of all vertices belonging to entities.
      flatVertexIdx = bsxfun( @plus , flatCellIdx , implicitStencil{entityNum}' );
      % Mark used verices.
      isNodeUsed(flatVertexIdx(:)) = true;
      % Add elements.
      mesh.elements(1:numElemVertices(entityNum),thisElemIdx) = flatVertexIdx';
      mesh.elementTypes(thisElemIdx) = elemTypes(entityNum);
      % Add elements to group.
      mesh.groups((nextElemIdxInGroup(groupIdx)+(1:thisNumElements))  , groupIdx ) = thisElemIdx';
      nextElemIdxInGroup(groupIdx) = nextElemIdxInGroup(groupIdx) + thisNumElements;
      elementIdx = elementIdx + thisNumElements; 
    end % entityNum
  end % for groupIdx

  % Find used nodes and map to contiguous node number starting at 1.
  flatNodeIdx = find( isNodeUsed );
  mesh.numNodes = length( flatNodeIdx );
  [ i , j , k ] = ind2sub( [ Nx , Ny ,Nz ] , flatNodeIdx );
  mesh.nodes = [ x(i) ; y(j) ; z(k) ];

  % Remap node indices in elements.
  elementTypesData = meshElementTypes();
  nodeMap(flatNodeIdx) = 1:length(flatNodeIdx);
  for elementIdx=1:mesh.numElements
    numVertex = elementTypesData( mesh.elementTypes(elementIdx) , 1 );
    mesh.elements(1:numVertex,elementIdx) = nodeMap( mesh.elements(1:numVertex,elementIdx) )';
  end %for

  %mesh.elements = sparse( mesh.elements );
  %mesh.groups = sparse( mesh.groups );

end % function

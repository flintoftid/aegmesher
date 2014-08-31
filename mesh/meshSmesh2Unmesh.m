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
  elementTypesData = meshElementTypes();
  
  % Entity indices must be the flat array index entityIdx = sub2ind( [ 2 , 2 , 2 ] , mask(1) + 1 , mask(2) + 1 , mask(3) + 1 ).
  % Cell, mask = [ 1 , 1 , 1 ].
  numElemVertices(8) = 8;
  elemStencil{8} = [ 0 0 0 ; 1 0 0 ; 1 1 0 ; 0 1 0 ; 0 0 1 ; 1 0 1 ; 1 1 1  ; 0 1 1 ]; 
  elemTypes(8) = [ 104 ];
  % xy-face, mask = [ 1 , 1 , 0 ].
  numElemVertices(4) = 4;
  elemStencil{4} = [ 0 0 0 ; 1 0 0 ; 1 1 0 ; 0 1 0 ];
  elemTypes(4) = [ 13 ];  
  % yz-face, mask = [ 0 , 1 , 1 ].
  numElemVertices(7) = 4;
  elemStencil{7} = [ 0 0 0 ; 0 1 0 ; 0 1 1 ; 0 0 1 ];
  elemTypes(7) = [ 13 ];  
  % zx-face, mask = [ 1 , 0 , 1 ].
  numElemVertices(6) = 4;
  elemStencil{6} = [ 0 0 0 ; 1 0 0 ; 1 0 1 ; 0 0 1 ];
  elemTypes(6) = [ 13 ]; 
  % x-edge, mask = [ 1 , 0 , 0 ].
  numElemVertices(2) = 2;
  elemStencil{2} = [ 0 0 0 ; 1 0 0 ];
  elemTypes(2) = [ 1 ]; 
  % y-edge, mask = [ 0 , 1 , 0 ].
  numElemVertices(3) = 2;
  elemStencil{3} = [ 0 0 0 ; 0 1 0 ];
  elemTypes(3) = [ 1 ]; 
  % z-edge, mask = [ 0 , 0 , 1 ].
  numElemVertices(5) = 2;
  elemStencil{5} = [ 0 0 0 ; 0 0 1 ];
  elemTypes(5) = [ 1 ]; 
  % node, mask = [ 0 , 0 , 0 ].
  numElemVertices(1) = 1;
  elemStencil{1} = [ 0 0 0 ];
  elemTypes(1) = [ 199 ]; 
  
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
  
  % Calculate flattened index stencils for this mesh size.
  implicitStencil = zeros(8,8);
  for entityNum=1:length( numElemVertices )
    stencil = elemStencil{entityNum};
    implicitStencil(entityNum,1:numElemVertices(entityNum)) = stencil(:,1)' + Nx * stencil(:,2)' + Nx * Ny * stencil(:,3)';
  end % for
  
  % Find number of elements in each group.
  for groupIdx=1:mesh.numGroups
    numElementsInGroup(groupIdx) = size( smesh.groups{groupIdx} , 1 );
  end % for

  % Initialise arrays.
  mesh.numElements = sum( numElementsInGroup );
  mesh.elementTypes = zeros( 1 , mesh.numElements ); 
  mesh.elements = sparse( 8 , mesh.numElements );
  %mesh.elements = zeros( 8 , mesh.numElements );
  mesh.groups = sparse( max( numElementsInGroup ) , mesh.numGroups );
  %mesh.groups = zeros( max( numElementsInGroup ) , mesh.numGroups );

  % Array used to mark which nodes (flat index) are used.
  isNodeUsed = false( 1 , Nx * Ny * Nz );

  % Iterate over groups.
  elementIdx = 0;
  nextElemIdxInGroup = zeros( mesh.numGroups );
  for groupIdx=1:mesh.numGroups

    % Find implicit flattened cell index of all entities belonging to current group.
    flatCellIdx = sub2ind( [ Nx , Ny , Nz ] , smesh.groups{groupIdx}(:,1) , smesh.groups{groupIdx}(:,2) , smesh.groups{groupIdx}(:,3) );
    thisNumElements = length( flatCellIdx );
    if( thisNumElements == 0 ) 
      continue;
    end % if
    
    % Create element indices for new elements.
    thisElemIdx = elementIdx + (1:thisNumElements);

    % Find entity types of all entities.
    entityTypes = sub2ind( [ 2 , 2 , 2 ] , 1 + smesh.groups{groupIdx}(:,4) - smesh.groups{groupIdx}(:,1) , ...
                                           1 + smesh.groups{groupIdx}(:,5) - smesh.groups{groupIdx}(:,2) , ...
                                           1 + smesh.groups{groupIdx}(:,6) - smesh.groups{groupIdx}(:,3) );

    % Find element types.
    thisElemType = unique( elemTypes( unique( entityTypes ) ) );
    if( length( thisElemType ) ~= 1 )
      error( 'Mixed element types in group %s invalid' , smesh.groupNames{groupIdx} );
    end % if
    
    % Get implicit stencils for entities.
    thisNumVertex = elementTypesData( thisElemType , 1 ); 
    thisStencils = implicitStencil(entityTypes,1:thisNumVertex);

    % Find implicit flattened index of all vertices belonging to all entities.
    flatVertexIdx = bsxfun( @plus , flatCellIdx , thisStencils );
    
    % Mark used vertices.
    isNodeUsed(flatVertexIdx(:)) = true;
    
    % Add elements to element list.
    mesh.elements(1:size(flatVertexIdx,2),thisElemIdx) = flatVertexIdx';
    mesh.elementTypes(thisElemIdx) = thisElemType;
    
    % Add element indices to group.
    mesh.groups((nextElemIdxInGroup(groupIdx)+(1:thisNumElements))  , groupIdx ) = thisElemIdx';
    nextElemIdxInGroup(groupIdx) = nextElemIdxInGroup(groupIdx) + thisNumElements;
    elementIdx = elementIdx + thisNumElements; 

  end % for groupIdx

  % Find used nodes and map to contiguous node number starting at 1.
  flatNodeIdx = find( isNodeUsed );
  mesh.numNodes = length( flatNodeIdx );
  [ i , j , k ] = ind2sub( [ Nx , Ny , Nz ] , flatNodeIdx );
  mesh.nodes = [ x(i) ; y(j) ; z(k) ];

  % Remap node indices in elements.
  nodeMap(flatNodeIdx) = 1:length(flatNodeIdx);
  for elementIdx=1:mesh.numElements
    numVertex = elementTypesData( mesh.elementTypes(elementIdx) , 1 ); 
    mesh.elements(1:numVertex,elementIdx) = nodeMap( mesh.elements(1:numVertex,elementIdx) )';
    %assert( all( mesh.elements((numVertex+1):8,elementIdx) == 0 ) );
    %mesh.elements((numVertex+1):8,elementIdx) = 0;
  end %for

  %mesh.elements = sparse( mesh.elements );
  %mesh.groups = sparse( mesh.groups );

end % function

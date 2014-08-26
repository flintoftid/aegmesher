function [ mesh ] = meshSmesh2Unmesh( smesh )
%
% meshSmesh2Unmesh - Converts a structured mesh into an unstructured mesh.
%
% Usage:
%
% [ mesh ] = meshSmesh2Unmesh( smesh )
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

  % Mapping from (i,j,k) to node index for used nodes.
  nodeMap = zeros( Nx , Ny , Nz , 'int32' );
  
  % Array of node coordinates.
  nodes = [];

  % First pass over structured mesh identifying used nodes and 
  % counting number of elements. Used nodes are collected and a
  % mapping constructed for use in the second pass.
  nodesIdx = 1;
  numElements = 0;
  for i = 1:Nx
    for j = 1:Ny
      for k = 1:Nz
        % Cell volume (i,j,k,1).
        if( size( smesh.elements , 4 ) >= 1 )
          if( smesh.elements(i,j,k,1) ~= 0 )
            numElements = numElements + 1;
            if( nodeMap(i,j,k) == 0 )
              nodeMap(i,j,k) = nodesIdx;
              nodes(1:3,nodesIdx) = [ x(i) , y(j) , z(k) ];
              nodesIdx = nodesIdx + 1;
            end % if
            if( nodeMap(i+1,j,k) == 0 )
              nodeMap(i+1,j,k) = nodesIdx;
              nodes(1:3,nodesIdx) = [ x(i+1) , y(j) , z(k)];
              nodesIdx = nodesIdx + 1;
            end % if
            if( nodeMap(i+1,j+1,k) == 0 )
              nodeMap(i+1,j+1,k) = nodesIdx;
              nodes(1:3,nodesIdx) = [ x(i+1) , y(j+1) , z(k) ];
              nodesIdx = nodesIdx + 1;
            end % if
            if( nodeMap(i,j+1,k) == 0 )
              nodeMap(i,j+1,k) = nodesIdx;
              nodes(1:3,nodesIdx) = [ x(i) , y(j+1) , z(k) ];
              nodesIdx = nodesIdx + 1;
            end % if
            if( nodeMap(i,j,k+1) == 0 )
              nodeMap(i,j,k+1) = nodesIdx;
              nodes(1:3,nodesIdx) = [ x(i) , y(j) , z(k+1) ];
              nodesIdx = nodesIdx + 1;
            end % if
            if( nodeMap(i+1,j,k+1) == 0 )
              nodeMap(i+1,j,k+1) = nodesIdx;
              nodes(1:3,nodesIdx) = [ x(i+1) , y(j) , z(k+1) ];
              nodesIdx = nodesIdx + 1;
            end % if
            if( nodeMap(i+1,j+1,k+1) == 0 )
              nodeMap(i+1,j+1,k+1) = nodesIdx;
              nodes(1:3,nodesIdx) = [ x(i+1) , y(j+1) , z(k+1) ];
              nodesIdx = nodesIdx + 1;
            end % if
            if( nodeMap(i,j+1,k+1) == 0 )
              nodeMap(i,j+1,k+1) = nodesIdx;
              nodes(1:3,nodesIdx) = [ x(i) , y(j+1) , z(k+1) ];
              nodesIdx = nodesIdx + 1;
            end % if
          end %if
        end % if
        % xy boundary surface (i,j,k,2).
        if( size( smesh.elements , 4 ) >= 2 )
          if( smesh.elements(i,j,k,2) ~= 0 )
            numElements = numElements + 1;    
            if( nodeMap(i,j,k) == 0 )
              nodeMap(i,j,k) = nodesIdx;
              nodes(1:3,nodesIdx) = [ x(i) , y(j) , z(k) ];
              nodesIdx = nodesIdx + 1;
            end % if
            if( nodeMap(i+1,j,k) == 0 )
              nodeMap(i+1,j,k) = nodesIdx;
              nodes(1:3,nodesIdx) = [ x(i+1) , y(j) , z(k) ];
              nodesIdx = nodesIdx + 1;
            end % if
            if( nodeMap(i+1,j+1,k) == 0 )
              nodeMap(i+1,j+1,k) = nodesIdx;
              nodes(1:3,nodesIdx) = [ x(i+1) , y(j+1) , z(k) ];
              nodesIdx = nodesIdx + 1;
            end % if
            if( nodeMap(i,j+1,k) == 0 )
              nodeMap(i,j+1,k) = nodesIdx;
              nodes(1:3,nodesIdx) = [ x(i) , y(j+1) , z(k) ];
              nodesIdx = nodesIdx + 1;
            end % if           
          end % if
        end %if
        % yz boundary surface (i,j,k,3).
        if( size( smesh.elements , 4 ) >= 3 )
          if( smesh.elements(i,j,k,3) ~= 0 )    
            numElements = numElements + 1;         
            if( nodeMap(i,j,k) == 0 )
              nodeMap(i,j,k) = nodesIdx;
              nodes(1:3,nodesIdx) = [ x(i) , y(j) , z(k) ];              
              nodesIdx = nodesIdx + 1;
            end % if
            if( nodeMap(i,j+1,k) == 0 )
              nodeMap(i,j+1,k) = nodesIdx;
              nodes(1:3,nodesIdx) = [ x(i) , y(j+1) , z(k) ];
              nodesIdx = nodesIdx + 1;
            end % if
            if( nodeMap(i,j+1,k+1) == 0 )
              nodeMap(i,j+1,k+1) = nodesIdx;
              nodes(1:3,nodesIdx) = [ x(i) , y(j+1) , z(k+1) ];
              nodesIdx = nodesIdx + 1;
            end % if
            if( nodeMap(i,j,k+1) == 0 )
              nodeMap(i,j,k+1) = nodesIdx;
              nodes(1:3,nodesIdx) = [x(i) , y(j) , z(k+1) ];
              nodesIdx = nodesIdx + 1;
            end % if
          end % if
        end % if
        % zx boundary surface (i,j,k,4).
        if( size( smesh.elements , 4 ) >= 4 )        
          if( smesh.elements(i,j,k,4) ~= 0 )   
            numElements = numElements + 1;       
            if( nodeMap(i,j,k) == 0 )
              nodeMap(i,j,k) = nodesIdx;
              nodes(1:3,nodesIdx) = [ x(i) , y(j) , z(k) ];
              nodesIdx = nodesIdx + 1;
            end % if
            if( nodeMap(i+1,j,k) == 0 )
              nodeMap(i+1,j,k) = nodesIdx;
              nodes(1:3,nodesIdx) = [ x(i+1) , y(j) , z(k) ];
              nodesIdx = nodesIdx + 1;
            end % if
            if( nodeMap(i+1,j,k+1) == 0 )
              nodeMap(i+1,j,k+1) = nodesIdx;
              nodes(1:3,nodesIdx) = [ x(i+1) , y(j) , z(k+1) ];
              nodesIdx = nodesIdx + 1;
            end % if
            if( nodeMap(i,j,k+1) == 0 )
              nodeMap(i,j,k+1) = nodesIdx;
              nodes(1:3,nodesIdx) = [ x(i) , y(j) , z(k+1) ];
              nodesIdx = nodesIdx + 1;
            end % if
          end %if
        end % if 
        if( size( smesh.elements , 4 ) >= 5 )
          % x edge (i,j,k,5).
          if( smesh.elements(i,j,k,5) ~= 0 )   
            numElements = numElements + 1;     
            if( nodeMap(i,j,k) == 0 )
              nodeMap(i,j,k) = nodesIdx;
              nodes(1:3,nodesIdx) = [ x(i) , y(j) , z(k) ];
              nodesIdx = nodesIdx + 1;
            end % if
            if( nodeMap(i+1,j,k) == 0 )
              nodeMap(i+1,j,k) = nodesIdx;
              nodes(1:3,nodesIdx) = [ x(i+1) , y(j) , z(k) ];
              nodesIdx = nodesIdx + 1;
            end % if
          end % if         
        end % if
        if( size( smesh.elements , 4 ) >= 6 )
          % y edge (i,j,k,6).
          if( smesh.elements(i,j,k,6) ~= 0 )   
            numElements = numElements + 1;     
            if( nodeMap(i,j,k) == 0 )
              nodeMap(i,j,k) = nodesIdx;
              nodes(1:3,nodesIdx) = [ x(i) , y(j) , z(k) ];
              nodesIdx = nodesIdx + 1;
            end % if
            if( nodeMap(i,j+1,k) == 0 )
              nodeMap(i,j+1,k) = nodesIdx;
              nodes(1:3,nodesIdx) = [ x(i) , y(j+1) , z(k) ];
              nodesIdx = nodesIdx + 1;
            end % if
          end % if         
        end % if
        if( size( smesh.elements , 4 ) >= 7 )
          % z edge (i,j,k,7).
          if( smesh.elements(i,j,k,7) ~= 0 )   
            numElements = numElements + 1;     
            if( nodeMap(i,j,k) == 0 )
              nodeMap(i,j,k) = nodesIdx;
              nodes(1:3,nodesIdx) = [ x(i) , y(j) , z(k) ];
              nodesIdx = nodesIdx + 1;
            end % if
            if( nodeMap(i,j,k+1) == 0 )
              nodeMap(i,j,k+1) = nodesIdx;
              nodes(1:3,nodesIdx) = [ x(i) , y(j) , z(k+1) ];
              nodesIdx = nodesIdx + 1;
            end % if
          end % if         
        end % if
      end % for
    end % for
  end % for

  % Assemble used nodes.
  mesh.numNodes = nodesIdx - 1;
  mesh.nodes = nodes;

  % Variables to collect node, element and group information.
  mesh.numElements = numElements;
  mesh.elements = zeros( 8 , numElements );
  mesh.elementTypes = zeros( 1 , numElements );
  groups = zeros(1,smesh.numGroups);

  % Second pass over structured mesh collecting elements and their groups.
  % Nodes indices are determined from the map constructed in the first pass.
  elementIdx = 1;
  for i = 1:Nx
    for j = 1:Ny
      for k = 1:Nz
        if( size( smesh.elements , 4 ) >= 1 )
          if( smesh.elements(i,j,k,1) ~= 0 )
            % Cell volume (i,j,k,1).         
            mesh.elements(1,elementIdx) = nodeMap(i,j,k);
            mesh.elements(2,elementIdx) = nodeMap(i+1,j,k);
            mesh.elements(3,elementIdx) = nodeMap(i+1,j+1,k);
            mesh.elements(4,elementIdx) = nodeMap(i,j+1,k);
            mesh.elements(5,elementIdx) = nodeMap(i,j,k+1);
            mesh.elements(6,elementIdx) = nodeMap(i+1,j,k+1);
            mesh.elements(7,elementIdx) = nodeMap(i+1,j+1,k+1);
            mesh.elements(8,elementIdx) = nodeMap(i,j+1,k+1);   
            mesh.elementTypes(elementIdx) = 104;   
            groupIdx = smesh.elements(i,j,k,1);
            groups(end+1,groupIdx) = elementIdx;
            elementIdx = elementIdx + 1;
          end % if
        end % if  
        if( size( smesh.elements , 4 ) >= 2 )
          if( smesh.elements(i,j,k,2) ~= 0 )
            % xy boundary surface (i,j,k,2).
            mesh.elements(1,elementIdx) = nodeMap(i,j,k);
            mesh.elements(2,elementIdx) = nodeMap(i+1,j,k);
            mesh.elements(3,elementIdx) = nodeMap(i+1,j+1,k);
            mesh.elements(4,elementIdx) = nodeMap(i,j+1,k);   
            mesh.elementTypes(elementIdx) = 13;          
            groupIdx = smesh.elements(i,j,k,2);
            groups(end+1,groupIdx) = elementIdx;                
            elementIdx = elementIdx + 1;
          end % if
        end % if
        if( size( smesh.elements , 4 ) >= 3 )        
          if( smesh.elements(i,j,k,3) ~= 0 )
            % yz boundary surface (i,j,k,3).
            mesh.elements(1,elementIdx) = nodeMap(i,j,k);
            mesh.elements(2,elementIdx) = nodeMap(i,j+1,k);
            mesh.elements(3,elementIdx) = nodeMap(i,j+1,k+1);
            mesh.elements(4,elementIdx) = nodeMap(i,j,k+1);    
            mesh.elementTypes(elementIdx) = 13;      
            groupIdx = smesh.elements(i,j,k,3);
            groups(end+1,groupIdx) = elementIdx;
            elementIdx = elementIdx + 1;
          end %if
        end % if 
        if( size( smesh.elements , 4 ) >= 4 )
          if( smesh.elements(i,j,k,4) ~= 0 )
            % zx boundary surface (i,j,k,4).
            mesh.elements(1,elementIdx) = nodeMap(i,j,k);
            mesh.elements(2,elementIdx) = nodeMap(i+1,j,k);
            mesh.elements(3,elementIdx) = nodeMap(i+1,j,k+1);
            mesh.elements(4,elementIdx) = nodeMap(i,j,k+1);  
            mesh.elementTypes(elementIdx) = 13;            
            groupIdx = smesh.elements(i,j,k,4);
            groups(end+1,groupIdx) = elementIdx;
            elementIdx = elementIdx + 1;
          end %if
        end % if
        if( size( smesh.elements , 4 ) >= 5 )
          if( smesh.elements(i,j,k,5) ~= 0 )
            % x edge (i,j,k,5).
            mesh.elements(1,elementIdx) = nodeMap(i,j,k);
            mesh.elements(2,elementIdx) = nodeMap(i+1,j,k);  
            mesh.elementTypes(elementIdx) = 1;            
            groupIdx = smesh.elements(i,j,k,5);
            groups(end+1,groupIdx) = elementIdx;
            elementIdx = elementIdx + 1;
          end % if           
        end % if
        if( size( smesh.elements , 4 ) >= 6 )
          if( smesh.elements(i,j,k,6) ~= 0 )
            % y edge (i,j,k,6).
            mesh.elements(1,elementIdx) = nodeMap(i,j,k);
            mesh.elements(2,elementIdx) = nodeMap(i,j+1,k);  
            mesh.elementTypes(elementIdx) = 1;            
            groupIdx = smesh.elements(i,j,k,6);
            groups(end+1,groupIdx) = elementIdx;
            elementIdx = elementIdx + 1;
          end % if           
        end % if
        if( size( smesh.elements , 4 ) >= 7 )
          if( smesh.elements(i,j,k,7) ~= 0 )
            % z edge (i,j,k,7).
            mesh.elements(1,elementIdx) = nodeMap(i,j,k);
            mesh.elements(2,elementIdx) = nodeMap(i,j,k+1);  
            mesh.elementTypes(elementIdx) = 1;            
            groupIdx = smesh.elements(i,j,k,7);
            groups(end+1,groupIdx) = elementIdx;
            elementIdx = elementIdx + 1;
          end % if           
        end % if
      end % for
    end % for
  end % for 
  mesh.elements = sparse( mesh.elements );

  % Assemble groups.
  for groupIdx=1:smesh.numGroups
    groupVec = unique( nonzeros( groups(:,groupIdx) ) );
    mesh.groups(1:length(groupVec),groupIdx) = groupVec;
  end % for
  mesh.groups = sparse( mesh.groups );

end % function

function [ normals , bboxes , barycentres ] = meshCalcElemProp( mesh , groupNames )
%
% meshCalcElemProp - calculate element properties: normal vector, AABB and barycentre.
%
% [ normals , bboxes , barycentres ] = meshCalcElemProp( mesh [, groupNames ] )
%
% Inputs:
%
% mesh         - structure containing the unstructured mesh. See help for meshReadAmelet().
% groupNames{} - cell array of strings, containing names of groups to calculate. 
%                Default: all entities are written.
% 
% Outputs:
%
% normals()     - (3,numElements) real array of normal vectors for elements.
%                 Set to zero if not in a requested group.
% bboxes()      - (6,numElements) real array of element bounding boxes (xlo,ylo,zlo,xhi,yhi,zhi).
%                 Set to zero if not in a requested group.
% barycentres() - (3,numElements) real array of barycentre coordinates.
%                 Set to zero if not in a requested group.

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
% Date: 23/07/2013
% Version: 1.0.0

  if( nargin == 1 )
    groupNames = {};
  end % if

  % Element types, indexed by AMELET element type.
  elementTypesData = meshElementTypes();

  % Load element type data and create table.
  [ r , c ] = find( elementTypesData );
  r = unique( sort( r ) );
  elementTable = [ r , full( elementTypesData(r,:) ) ]; 

  % Initialise to zero.
  normals = zeros( 3 , mesh.numElements );
  bboxes = zeros( 6 , mesh.numElements );
  barycentres = zeros( 3 , mesh.numElements );

  if( isempty( groupNames ) )

    % Output all groups.
    groupIdx = 1:mesh.numGroups;

    % Find all elements in mesh.
    elementIdx = 1:mesh.numElements;

  else

    % Find group indices.
    groupIdx = [];

    for k=1:length( groupNames )

      thisGroupIdx = [];

      for idx=1:mesh.numGroups
        if( strcmpi( mesh.groupNames{idx} , groupNames{k} ) )
          thisGroupIdx = idx;
          break;
        end % if
      end % for

      % Abort if not found.
      if( isempty( thisGroupIdx ) )
        error( 'Group name "%s" not defined in mesh' , groupNames{k} );
      else
        groupIdx = [ groupIdx , thisGroupIdx ];
      end % if

    end % for

    elementIdx = nonzeros( mesh.groups(:,groupIdx) );

  end % if

  % Number of elements.
  numElements = length( elementIdx );

  % All nodes in list.
  nodeIdx = (1:mesh.numNodes)';
  numNodes = mesh.numNodes;

  % Output elements by type using vectorised method.
  for typeIdx=1:size( elementTable , 1 )
    thisElementType = elementTable(typeIdx,1);
    thisNumNodes = elementTable(typeIdx,2);
    % See if any elements of this type.
    thisIdx = find( mesh.elementTypes(elementIdx) == thisElementType );
    if( isempty( thisIdx ) )
      continue;
    end % if
    % Get the first three nodes of the elements.
    thisNodes = full( mesh.elements(1:thisNumNodes,elementIdx(thisIdx)) );
    % Flatten index array and lookup the coordinates.
    nodeCoords = mesh.nodes( 1:3 , reshape( thisNodes , [ 1 , thisNumNodes * length( thisIdx ) ] ) );
    % Unflatten: nodeCoords(i,j,k) - i-th coord of j-th node of k-th element.
    nodeCoords = full( reshape( nodeCoords , [ 3 , thisNumNodes , length( thisIdx ) ] ) );
    % Normal vector.
    if( thisNumNodes >= 3 )
      n = squeeze( cross( nodeCoords(:,3,:) - nodeCoords(:,2,:) , nodeCoords(:,1,:) - nodeCoords(:,2,:) ,1 ) );
      % Normalise and pack into output array.
      %normals(1:3,elementIdx(thisIdx)) = bsxfun(@rdivide , n , norm( n , 'cols' ) );
      normals(1:3,elementIdx(thisIdx)) = bsxfun(@rdivide , n , sqrt( sum( n.^2 , 1 ) ) );  
    else
      % No normal for nodes and linear elements.
      normals(1:3,elementIdx(thisIdx)) = nan( 3 , length ( elementIdx(thisIdx) ) );
    end % if
    % Element bounding boxes.
    if( nargout >= 2 )
      bbl = squeeze( min( nodeCoords , [] , 2 ) );
      bbh = squeeze( max( nodeCoords , [] , 2 ) );
      bboxes(1:3,elementIdx(thisIdx)) = bbl;
      bboxes(4:6,elementIdx(thisIdx)) = bbh;
    end % if
    % Element barycentres.
    if( nargout >= 3 )
      barycentres(1:3,elementIdx(thisIdx)) = squeeze( sum( nodeCoords , 2 ) ) ./ thisNumNodes;
    end % if

  end % for

end % function

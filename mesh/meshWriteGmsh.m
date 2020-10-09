function meshWriteGmsh( mshFileName , mesh  , groupNames )
%
% meshWriteGmsh - Write a mesh into an ASCII format Gsmh file.
%
% Usage:
%
% meshWriteGmsh( mshFileName , mesh [ , groupNames ] )
%
% Inputs:
%
% mshFileName  - string, name of gmsh mesh file to create.
% mesh         - structure containing the unstructured mesh. See help for meshReadAmelet().
% groupNames{} - cell array of strings, containing names of groups to write. 
%                Default: all entities are written.
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
% Date: 23/08/2010
% Version: 1.0.0

% Author: M. Berens
% Date: 12/07/2013
% Version: 2.0.0 - Optimised element output.

  isDeleteNodes = 1;
  isRenumberNodes = 1;

  if( nargin == 2 )
    groupNames = {};
  end % if

  % Mapping of AMELET element types to Gmsh types.
  [ mapGmsh2Amelet , mapAmelet2Gmsh ] = meshAmeletGmshElementTypeMaps();

  % Element types, indexed by AMELET element type.
  elementTypesData = meshElementTypes();

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
  fprintf( 'Found %d elements to output\n' , numElements );

  % Find element tags.
  elementTags = zeros(2,mesh.numElements);
  for idx=1:length(groupIdx)
    elementTags(1,nonzeros(mesh.groups(:,groupIdx(idx)))) = groupIdx(idx);
    elementTags(2,nonzeros(mesh.groups(:,groupIdx(idx)))) = groupIdx(idx);
  end % for

  if( isDeleteNodes )
    % Find node indices referenced by elements.
    nodeIdx = unique( nonzeros( mesh.elements(:,elementIdx) ) );
    numNodes = length( nodeIdx );
  else
    % All nodes in list.
    nodeIdx = (1:mesh.numNodes)';
    numNodes = mesh.numNodes;
  end % if
  fprintf( 'Found %d nodes to output\n' , numNodes );

  % Node map for renumbering.
  if( isRenumberNodes )
    nodeMap = sparse( 1 , max( [ 1 , max( nodeIdx ) ] ) );
    nodeMap(nodeIdx) = 1:numNodes;
  end % if

  % Open the gmsh mesh file.
  [ fout , msg ] = fopen ( mshFileName , 'w' );
  if ( fout < 0 ) 
    error( '%s: %s' , mshFileName , msg );
    return;
  end %if

  fprintf( 'Opened msh file %s.\n' , mshFileName );

  %
  % MeshFormat.
  %
  fprintf( fout , '$MeshFormat\n' );
  fprintf( fout ,'%.1f %d %d\n' , 2.2 , 0 , 8 );
  fprintf( fout , '$EndMeshFormat\n' );

  fprintf( 'Wrote mesh format.\n' );

  %
  % PhysicalNames.
  %
  if( length(groupIdx) > 0 )
    fprintf( fout , '$PhysicalNames\n' );
    fprintf( fout ,'%d\n' , length(groupIdx) );
    for idx=1:length(groupIdx)
      fprintf( fout ,'%d %d "%s"\n' , mesh.groupTypes(groupIdx(idx)) , groupIdx(idx) , mesh.groupNames{groupIdx(idx)} );
    end % for
    fprintf( fout , '$EndPhysicalNames\n' );
  end % if

  fprintf( 'Wrote physical names.\n' );

  %
  % Nodes.
  %
  fprintf( fout , '$Nodes\n' );
  fprintf( fout , '%d\n' , numNodes );
  % [FIXME] Deal with 1D, 2D, 3D cases!
  fprintf( fout ,'%d %e %e %e\n' , [ nodeIdx' ; mesh.nodes(:,nodeIdx) ] );
  fprintf( fout , '$EndNodes\n' );
  fprintf( 'Wrote nodes.\n' );

  %
  % Elements.
  %
  fprintf( fout , '$Elements\n' );
  fprintf( fout , '%d\n' , numElements );

  % Load element type data and create table.
  [ r , c ] = find( elementTypesData );
  r = unique( sort( r ) );
  elementTable = [ r , full( elementTypesData(r,:) ) ]; 

  % Output elements by type using vectorised method.
  for typeIdx=1:size( elementTable , 1 )
    thisAmeletElementType = elementTable(typeIdx,1);
    thisElementType =  full( mapAmelet2Gmsh(thisAmeletElementType) );
    thisNumNodes = elementTable(typeIdx,2);
    if( thisNumNodes > size( mesh.elements , 1 ) )
      continue;
    end % if
    thisIdx = find( mesh.elementTypes(elementIdx) == thisAmeletElementType );
    if( isempty( thisIdx ) )
      continue;
    end % if
    thisTags = elementTags(1:2,elementIdx(thisIdx));
    thisNumTags = size( thisTags , 1 );
    if( isRenumberNodes )
      thisNodes = full( mesh.elements(1:thisNumNodes,elementIdx(thisIdx)) );
      newNodes = nodeMap( reshape( thisNodes , [ 1 , thisNumNodes * length( thisIdx ) ] ) );
      thisNodes = full( reshape( newNodes , [ thisNumNodes , length( thisIdx ) ] ) );
    else
      thisNodes = full( nonzeros( mesh.elements(1:thisNumNodes,elementIdx(thisIdx)) ) );
    end % if
    x = [ elementIdx(thisIdx) ; thisElementType .* ones( size( thisIdx ) ) ; ...
          thisNumTags .* ones( size( thisIdx ) ) ; thisTags ; thisNodes ];
    fmt = [ repmat( '%d ' , [ 1 , 3 + thisNumTags + thisNumNodes ] )  , '\n' ];
    fprintf( fout ,fmt , x );
  end % for

  fprintf( fout , '$EndElements\n' );

  fprintf( 'Wrote elements.\n' );

  fclose( fout );

  fprintf( 'Closed file.\n' );

end % function

function meshWriteGmshSlow( mshFileName , mesh  , groupNames )
%
% meshWriteGmshSlow - Write a mesh into a Gsmh file. 
%
% Usage:
%
% meshWriteGmshSlow( mshFileName , mesh [ , groupNames ] )
%
% Inputs:
%
% mshFileName  - string, name of gmsh mesh file to create.
% mesh         - structure containing the unstructured mesh. See help for meshReadAmelet().
%
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

  % Element types: Indexed by AMELET element type!
  elementTypesData = meshElementTypes();

  if( nargin == 2 )
    groupNames = {};
  end % if

  % Mapping of AMELET element types to Gmsh types.
  elementTypesMap = sparse( 200 ,  1 );
  elementTypesMap(1)   =  1; % bar2
  elementTypesMap(11)  =  2; % tri3
  elementTypesMap(13)  =  3; % quad4
  elementTypesMap(101) =  4; % tetra4
  elementTypesMap(104) =  5; % hexa8
  elementTypesMap(103) =  6; % penta6
  elementTypesMap(102) =  7; % pyra2
  elementTypesMap(2)   =  8; % bar3
  elementTypesMap(12)  =  9; % tri6
  elementTypesMap(108) = 11; % tetra10
  elementTypesMap(199) = 15; % point - not in AMELET
  elementTypesMap(109) = 17; % hexa20

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

  % Find node indices referenced by elements.
  numNodes = mesh.numNodes;
  fprintf( 'Found %d nodes to output\n' , numNodes );

  % Open the gmsh mesh file.
  [ fout , msg ] = fopen ( mshFileName , 'w' );
  if ( fout < 0 ) 
    error( '%s: %s' , mshFileName , msg );
    return;
  end %if

  fprintf( 'Opened msh file %s.\n' , mshFileName );

  % MeshFormat.
  fprintf( fout , '$MeshFormat\n' );
  fprintf( fout ,'%.1f %d %d\n' , 2.2 , 0 , 8 );
  fprintf( fout , '$EndMeshFormat\n' );

  fprintf( 'Wrote mesh format.\n' );

  % PhysicalNames.
  if( length(groupIdx) > 0 )
    fprintf( fout , '$PhysicalNames\n' );
    fprintf( fout ,'%d\n' , length(groupIdx) );
    for idx=1:length(groupIdx)
      fprintf( fout ,'%d %d "%s"\n' , mesh.groupTypes(groupIdx(idx)) , groupIdx(idx) , mesh.groupNames{groupIdx(idx)} );
    end % for
    fprintf( fout , '$EndPhysicalNames\n' );
  end % if

  fprintf( 'Wrote physical names.\n' );

  % Nodes.
  fprintf( fout , '$Nodes\n' );
  fprintf( fout , '%d\n' , numNodes );

  % [FIXME] Deal with 1D, 2D, 3D cases!
  % x = [ 1:numNodes , mesh.nodes ];
  % fprintf( fout ,'%d %e %e %e\n' , x );
  for idx=1:numNodes
    fprintf( fout ,'%d %e %e %e\n' , idx , mesh.nodes(1,idx) , mesh.nodes(2,idx) , mesh.nodes(3,idx) );
  end % for
  % clear x;
  fprintf( fout , '$EndNodes\n' );

  fprintf( 'Wrote nodes.\n' );

  % Elements.
  fprintf( fout , '$Elements\n' );
  fprintf( fout , '%d\n' , numElements );

  for idx=1:length(elementIdx)
    thisNumNodes =  elementTypesData(mesh.elementTypes(elementIdx(idx)),1); 
    thisElementType =  elementTypesMap(mesh.elementTypes(elementIdx(idx)));
    thisTags = elementTags(1:2,elementIdx(idx));
    thisNumTags = length( thisTags ); 
    fprintf( fout ,'%d %d %d' , elementIdx(idx) , nonzeros( thisElementType ) , thisNumTags );
    if( thisNumTags > 0 )
      fprintf( fout ,' %d' , thisTags );
    end % if
    fprintf( fout ,' %d' , full( nonzeros( mesh.elements(1:thisNumNodes,elementIdx(idx)) ) ) );
    fprintf( fout ,'\n' );
  end % for
  fprintf( fout , '$EndElements\n' );

  fprintf( 'Wrote elements.\n' );

  fclose( fout );

  fprintf( 'Closed file.\n' );

end % function

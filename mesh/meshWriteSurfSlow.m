function meshWriteSurfSlow( surfFileName , mesh , groupNames )
%
% meshWriteSurfSlow: Export surface elements from mesh into a CONCEPT surf file.
% 
% Usage:
%
% meshWriteSurfSlow( surfFileName , mesh [ , groupNames ] )
%
% Inputs:
%
% surfFileName - string, name of CONCEPT surf file to create.
% mesh         - structure containing the unstructured mesh. See help for meshReadAmelet().
% groupNames{} - cell array of strings, names of groups to write.
%                Default: All compatible elements in the mesh are written.
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
% Date: 30/09/2012
% Version: 1.0.0

  elementTypesData = meshElementTypes();

  if( nargin == 2 )
    groupNames = '';
  end % if
  
  % Now write out to CONCEPT SURF file.
  [ fout , msg ] = fopen ( surfFileName , 'w' );
  if ( fout < 0 ) 
    error( '%s: %s' , surfFileName , msg );
    return;
  end %if

  fprintf( 'Opened surf file %s.\n' , surfFileName );

  if( isempty( groupNames ) )

    % Find all face elements in mesh.
    faceTypeIdx = find( elementTypesData(:,2) == 2 );
    faceElementIdx = [];
    for k=1:length( faceTypeIdx )
      faceElementIdx = [ faceElementIdx , find( mesh.elementTypes == faceTypeIdx(k) ) ];
    end % for
 
  else
 
    % Find group indices.
    groupIdx = [];

    for k=1:length( groupNames )

      thisGroupIdx = [];

      for idx=1:mesh.numGroups
        if( strcmpi( mesh.groupNames{idx} , groupNames{k} ) )
          thisGroupIdx = idx;
          groupType = mesh.groupTypes(idx);
          break;
        end % if
      end % for

      % Abort if not found.
      if( isempty( thisGroupIdx ) )
        error( 'Group name "%s" not defined in mesh' , groupNames{k} );
      else
        groupIdx = [ groupIdx , thisGroupIdx ];
      end % if

      % Must be a surface group.
      if( groupType ~= 2 )
        error( 'Group name "%s" is not a surface type group' , groupNames{k} );
      end % if 

    end % for
 
    faceElementIdx = nonzeros( mesh.groups(:,groupIdx) );

  end % if

  % Number of elements.
  numElements = length( faceElementIdx );
  fprintf( 'Found %d elements to output\n' , numElements );

  % Find node indices referenced by elements.
  nodeIdx = unique( nonzeros( mesh.elements(:,faceElementIdx) ) );
  numNodes = length( nodeIdx );
  fprintf( 'Found %d nodes to output\n' , numNodes );

  % Header line with number of nodes and elements.
  fprintf( fout , '%d %d\n' , numNodes , numElements );

  fprintf( 'Wrote header.\n' );

  % List of nodes and create node map.
  nodeMap = sparse( 1, max( [ max( nodeIdx ) , 1 ] ) );

  for k=1:length( nodeIdx )
    idx = nodeIdx(k);
    nodeMap(idx) = k; 
    fprintf( fout , '%e %e %e\n' , mesh.nodes(1,idx) , mesh.nodes(2,idx) , mesh.nodes(3,idx) );
  end % for

  fprintf( 'Wrote nodes.\n' );

  % Write elements - surf only supports tri3, quad4.
  for k=1:length( faceElementIdx )
    idx = faceElementIdx(k);
    elementType = mesh.elementTypes(idx);
    switch( elementType )
    case 11 % tri3
      elements = nonzeros( mesh.elements(1:3,idx) );
      fprintf( fout , '%d %d %d 0\n' , full(nodeMap(elements(1))) , full(nodeMap(elements(2))) , full(nodeMap(elements(3))) );
    case 13 % quad4
      elements = nonzeros( mesh.elements(1:4,idx) );
      fprintf( fout , '%d %d %d %d\n' , full(nodeMap(elements(1))) , full(nodeMap(elements(2))) , full(nodeMap(elements(3))) , full(nodeMap(elements(4))) );
    otherwise
      error( 'Unsupported element type %d' , elementType );
    end % switch
  end % for

  fprintf( 'Wrote elements.\n' );

  fclose( fout );

  fprintf( 'Closed file.\n' );

end % function


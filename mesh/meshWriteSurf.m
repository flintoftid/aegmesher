function meshWriteSurf( surfFileName , mesh , groupNames )
%
% meshWriteSurf: Export surface elements from mesh into a CONCEPT surf file.
% 
% Usage:
%
% meshWriteSurf( surfFileName , mesh [ , groupNames ] )
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

  isDeleteNodes = 1;
  isRenumberNodes = 1;

  % Element types: Indexed by AMELET element type!
  elementTypesData = meshElementTypes();

  if( nargin == 2 )
    groupNames = {};
  end % if

  % Find elements to output.
  tic();
  if( isempty( groupNames ) )

    tri3ElementIdx = find( mesh.elementTypes == 11 );
    quad4ElementIdx = find( mesh.elementTypes == 13 );
    elementIdx = [ tri3ElementIdx , quad4ElementIdx ];
 
  else
 
    % Find group indices.
    groupIdx = [];

    for k=1:length( groupNames )

      thisGroupIdx = [];

      for idx=1:mesh.numGroups
        if( strcmpi( mesh.groupNames{idx} , groupNames{k} ) )
          thisGroupIdx = idx;
          groupType = mesh.groupTypes(idx);
          if( groupType ~= 2 )
            % Must be a surface group.
            error( 'Group name "%s" is not a surface type group' , groupNames{k} );
          end % if 
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
 
    % List of all face elements indices.
    allElementIdx = nonzeros( mesh.groups(:,groupIdx) );

    % Check all are tri3 or quad4.
    tri3ElementIdx = allElementIdx(find( mesh.elementTypes(allElementIdx) == 11 ));
    quad4ElementIdx = allElementIdx(find( mesh.elementTypes(allElementIdx) == 13 ));
    elementIdx = [ tri3ElementIdx , quad4ElementIdx ];

    if( length( allElementIdx ) ~= length( tri3ElementIdx ) + length( quad4ElementIdx ) )
      error( 'Requested groups contain invalid non-tri3/quad4 elements' );
    end % if

  end % if

  % Number of elements.
  numElements = length( elementIdx );
  fprintf( 'Found %d elements to output in %.2f seconds.\n' , numElements , toc() );

  % Nodes.
  tic();
  if( isDeleteNodes )
    % Find node indices referenced by elements.
    nodeIdx = unique( nonzeros( mesh.elements(:,elementIdx) ) );
    numNodes = length( nodeIdx );
  else
    % All nodes in list.
    nodeIdx = (1:mesh.numNodes)';
    numNodes = mesh.numNodes;
  end % if

  % Node map for renumbering.
  if( isRenumberNodes )
    nodeMap = sparse( 1 , max( [ 1 , max( nodeIdx ) ] ) );
    nodeMap(nodeIdx) = 1:numNodes;
  end % if

  fprintf( 'Found %d nodes to output in %.2f seconds.\n' , numNodes , toc() );

  % Now write out to CONCEPT SURF file.
  [ fout , msg ] = fopen ( surfFileName , 'w' );
  if ( fout < 0 ) 
    error( '%s: %s' , surfFileName , msg );
    return;
  end %if

  fprintf( 'Opened surf file %s.\n' , surfFileName );

  % Header line with number of nodes and elements.
  fprintf( fout , '%d %d\n' , numNodes , numElements );

  fprintf( 'Wrote header.\n' );

  % Write the nodes.
  tic();
  fprintf( fout ,'%e %e %e\n' , mesh.nodes(:,nodeIdx) );
  fprintf( 'Wrote %d nodes in %.2f seconds.\n' , numNodes , toc() );

  % Write triangles.
  if( ~isempty( tri3ElementIdx ) )
    thisNumNodes = 3;
    if( isRenumberNodes )
      thisNodes = full( mesh.elements(1:thisNumNodes,tri3ElementIdx) );
      newNodes = nodeMap( reshape( thisNodes , [ 1 , thisNumNodes * length( tri3ElementIdx ) ] ) );
      thisNodes = full( reshape( newNodes , [ thisNumNodes , length( tri3ElementIdx ) ] ) );
    else
      thisNodes = full( nonzeros( mesh.elements(1:thisNumNodes,tri3ElementIdx) ) );
    end % if
    thisNodes = [ thisNodes ; zeros( 1 , size( thisNodes , 2 ) ) ];
    thisNumNodes = thisNumNodes + 1;
    fmt = [ repmat( '%d ' , [ 1 , thisNumNodes ] )  , '\n' ];
    fprintf( fout ,fmt , thisNodes );
  end % if

  % Write quadrangles.
  if( ~isempty( quad4ElementIdx ) )
    thisNumNodes = 4;
    if( isRenumberNodes )
      thisNodes = full( mesh.elements(1:thisNumNodes,quad4ElementIdx) );
      newNodes = nodeMap( reshape( thisNodes , [ 1 , thisNumNodes * length( quad4ElementIdx ) ] ) );
      thisNodes = full( reshape( newNodes , [ thisNumNodes , length( quad4ElementIdx ) ] ) );
    else
      thisNodes = full( nonzeros( mesh.elements(1:thisNumNodes,quad4ElementIdx) ) );
    end % if
    fmt = [ repmat( '%d ' , [ 1 , thisNumNodes ] )  , '\n' ];
    fprintf( fout ,fmt , thisNodes ); 
  end % if
 
  fprintf( 'Wrote elements %d elements in %.2f seconds.\n' , numElements , toc() );

  fclose( fout );

  fprintf( 'Closed file.\n' );

end % function

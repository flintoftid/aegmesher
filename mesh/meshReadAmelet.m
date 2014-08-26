function [ mesh ] = meshReadAmelet( h5FileName , meshGroupName , meshName )
%
% meshReadAmelet - Read an unstructured mesh from an AMELET-HDF file.
%
% Usage:
%
% [ mesh ] = meshReadAmelet( h5FileName , meshGroupName , meshName )
%
% Inputs:
%
% h5FileName    - string, name of AMELET-HDF file to read.
% meshGroupName - string, name of mesh group to read. 
% meshName      - string, name of mesh to read.
%
% Outputs:
%
% mesh - structure containing an unstructured mesh modelled on the AMELET-HDF format [1]:
%
%        .dimension         - integer, dimension of mesh: 1, 2 or 3.
%        .numNodes          - integer, number of nodes.
%        .nodes()           - real(dimension,numNodes), array of node coordinates [arb].
%                             nodes(i,j) gives the i-th coordinate of the j-th node.
%        .numElements       - integer, number of elements.
%        .elementTypes()    - integer(1,numElements), array of AMELET-HDF element types,
%                             Some common types are:
%
%                             1   - bar2
%                             11  - tri3
%                             13  - quad4
%                             101 - tetra4
%                             104 - hexa8
%                             199 - point (extension, not in AMELET-HDF)
%
%        .elements()        - integer(var,numElements), sparse array of element node indices.
%                             elements(i,j) gives the i-th node index (into the nodes array) of 
%                             the j-th element.
%        .numGroups         - integer, number of groups.
%        .groupNames{}      - string{numGroups}, cell array of group names.
%        .groupTypes()      - integer(numGroups), array of AMELET-HDF group types:
%
%                             0 - node
%                             1 - edge
%                             2 - face
%                             3 - volume
%
%        .groups()          - integer(var,numGroups), sparse array of node/element indices.
%                             groups(i,j) gives the index of the i-th element (into the elements
%                             array) of the j-th group.
%        .numGroupGroups    - integer, number of groups of groups.
%        .groupGroupNames{} - string{numGroupGroups}, cell array of group group names.
%        .groupGroups()     - integer(var,numGroupGroup), sparse array of group of group indices.
%                             groupGroup(i,j) gives the i-th index (into the groups array) of the
%                             j-th group of groups. Hierarchical group of groups are NOT SUPPORTED.
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
% Date: 21/06/2010
% Version: 1.0.0
%
% Author: I. D Flintoft
% Date: 14/07/2013
% Version: 2.0.0 - Dramatically improved performance.

% Requirements:
%
% 1. The command line HDF5 utilties h5ls, h5totxt and h5dump must be available
%    in the current command path visible to the system function.
%
% Limitations:
%
% 1. No sanity checking is done on the AMELET-HDF5 file and there is little
%    diagnostic information provided. Hoefully a compliant AMELET-HDF files
%    will be read in correctly. However, any lack of conformance in the file
%    may/will produce indefinite results, possibly including the silent 
%    creation of an incorrect mesh output - user beware.
% 2. In order to improve performance only element with up to maxNumElementNodes
%    are supported. This can be changed at the top of the file.
% 3. Recursive "groups of groups" are not supported. 
%
%
% References:
%
% [1] C. Giraudon, “Amelet-HDF Documentation”, Release 1.5.3, Axessim, 15 November, 2011.
%

  % Element types: Indexed by AMELET element type!
  elementTypesData = meshElementTypes();
  maxNumElementNodes = 8;

  % Initialise mesh.
  mesh.dimension = NaN;
  mesh.numNodes = 0;
  mesh.nodes = [];
  mesh.numElements = 0;
  mesh.elementTypes = [];
  mesh.elements = [];
  mesh.numGroups = 0;
  mesh.groupNames = {};
  mesh.groupTypes = [];
  mesh.groups = [];
  mesh.numGroupGroups = 0;
  mesh.groupGroupNames = {};
  mesh.groupGroups = [];
  
  % Read in the nodes.
  tic();
  tmpFileName = tempname;
  cmd = sprintf( 'h5totxt -d "mesh/%s/%s/nodes" -s "," -o "%s" "%s"' , meshGroupName , meshName , tmpFileName , h5FileName );
  [ status , output ] = system( cmd );
  if( status ~= 0 )
    error( 'Error reading nodes from %s' , h5FileName );
  end % if
  mesh.nodes = csvread( tmpFileName )';
  mesh.numNodes = size( mesh.nodes , 2 );
  mesh.dimension = size( mesh.nodes , 1 );
  delete( tmpFileName );
  fprintf( 'Read %d nodes from %s in %.2f seconds.\n' , mesh.numNodes , h5FileName , toc() );

  % Get the mesh elements - AMELET-HDF packs the elements into a 1D array.
  tic();
  tmpFileName = tempname;
  cmd = sprintf( 'h5totxt -d "mesh/%s/%s/elementNodes" -s "," -o "%s" "%s"' , meshGroupName , meshName , tmpFileName , h5FileName );
  [ status , output ] = system( cmd );
  if( status ~= 0 )
    error( 'Error reading element nodes from %s' , h5FileName );
  end % if
  elementNodes = csvread( tmpFileName )';
  delete( tmpFileName );
  
  tmpFileName = tempname;
  cmd = sprintf( 'h5totxt -d "mesh/%s/%s/elementTypes" -s "," -o "%s" "%s"' , meshGroupName , meshName , tmpFileName , h5FileName );
  [ status , output ] = system( cmd );
  if( status ~= 0 )
    error( 'Error reading element types from %s' , h5FileName );
  end % if
  mesh.elementTypes = csvread( tmpFileName )';
  mesh.numElements = size( mesh.elementTypes , 2 );
  elements = zeros( maxNumElementNodes , mesh.numElements );
  delete( tmpFileName );

  % Unpack element nodes into 2D array. Don't use sparse array otherwise performance very poor.
  elementNumNodes = full( elementTypesData(mesh.elementTypes,1) );
  nextIdx = 1;
  for elementIdx=1:mesh.numElements
    thisNumNodes = elementNumNodes(elementIdx);
    % Beware - AMELET-HDF is indexed from zero, not one!
    elements(1:thisNumNodes,elementIdx) = 1 + double( elementNodes(nextIdx:(nextIdx+thisNumNodes-1))' );
    nextIdx = nextIdx + thisNumNodes;
  end % for

  % Defense work.
  assert( nextIdx - 1 == length( elementNodes ) );

  % Verify the element nodes are in the required range.
  all( unique( elements(:) ) <= mesh.numNodes );
  all( unique( elements(:) ) >= 0 );
  
  % Now collapse element node array into sparse array.
  mesh.elements = sparse( elements );
  
  fprintf( 'Read %d elements from %s in %.2f seconds.\n' , mesh.numElements , h5FileName , toc() );

  % Get groups.
  tic();
  cmd = sprintf( 'h5ls "%s/mesh/%s/%s/group"' , h5FileName , meshGroupName , meshName );
  [ status , output ] = system( cmd );
  if( status ~= 0 )
    error( 'Error reading groups from %s' , h5FileName );
  end % if

  if( ~isempty( output ) )
    
    % Parse out group names - this may not be general enough.
    [ mesh.groupNames ] = strread( output , '%s %*s %*s' );
    mesh.numGroups = length( mesh.groupNames );
    mesh.groups = sparse( 1 , mesh.numGroups );
    mesh.groupTypes = zeros( 1 , mesh.numGroups );

    for groupIdx=1:mesh.numGroups     

      groupName = mesh.groupNames{groupIdx};
      % Get group type from "type" attribute.
      cmd = sprintf( 'h5dump -a "mesh/%s/%s/group/%s/type" %s' , meshGroupName , meshName , groupName , h5FileName );
      [ status , output ] = system( cmd );
      if( status ~= 0 )
        error( 'Error reading group type from %s' , h5FileName );
      end % if

      % Type should be scalar string.
      [ tokens , matches ] = regexp( output , '\(0\)\: "(\w+)\\?.*"' , 'tokens' , 'match' );
      thisType = tokens{1}{1};
      if( strcmp( thisType , 'element' ) )
        % Get group entity type from group attribute.    
        cmd = sprintf( 'h5dump -a "mesh/%s/%s/group/%s/entityType" %s' , meshGroupName , meshName , groupName , h5FileName );
        [ status , output ] = system( cmd );
        if( status ~= 0 )
          error( 'Error reading groups from %s' , h5FileName );
        end % if
        % Entity type should be scalar string.
        [ tokens , matches ] = regexp( output , '\(0\)\: "(\w+)\\?.*"' , 'tokens' , 'match' );
        thisEntityType = tokens{1}{1};
        switch( thisEntityType )
        case 'edge'
          mesh.groupTypes(groupIdx) = 1;    
        case 'face'
          mesh.groupTypes(groupIdx) = 2;
        case 'surface'
          % Workaround for common error in AMELET-HDF files.
          thisEntityType = 'face';
          mesh.groupTypes(groupIdx) = 2;
        case 'volume'
          mesh.groupTypes(groupIdx) = 3;
        otherwise
          error( 'Invalid entity type %s for group %s' , thisEntityType , groupName );
        end % switch
      elseif( strcmp( thisType , 'node' ) )
        mesh.groupTypes(groupIdx) = 0;
        % This isn't part of AMELET-HDF but may be useful.
        thisEntityType = 'node';
      else
        error( 'Invalid type %s for group %s' , thisType , groupName  );
      end % if
      % Get group indices.
      tmpFileName = tempname;
      cmd = sprintf( 'h5totxt -d "mesh/%s/%s/group/%s" -s "," -o "%s" "%s"' , meshGroupName , meshName , groupName , tmpFileName , h5FileName );
      [ status , output ] = system( cmd );
      if( status ~= 0 )
        error( 'Error reading nodes from %s' , h5FileName );
      end % if
      % Beware - AMELET-HDF is indexed from zero, not one!
      targetIdx = 1 + csvread( tmpFileName );
      numTargets = length( targetIdx );
      delete( tmpFileName );
      % Validate target entities.
      if( strcmp( thisEntityType , 'node' ) )
        % Targets are nodes.
        if( any( targetIdx > mesh.numNodes ) || any( targetIdx <= 0 ) )
          error( 'Invalid node indices in node group %s' , mesh.groupNames{groupIdx} );
        end % if
      else
        % Targets are elements.
        if( any( targetIdx > mesh.numElements ) || any( targetIdx <= 0 ) )
          error( 'Invalid element indices in element group %s' , mesh.groupNames{groupIdx} );
        end % if    
        % Check element types match.
        types = unique( mesh.elementTypes(targetIdx) );
        if( any( nonzeros( elementTypesData(types,2) ) ~= mesh.groupTypes(groupIdx) ) )
          error( 'Invalid element types in element group %s' , mesh.groupNames{groupIdx} );
        end % if       
      end % if

      % Pack group element indices into mesh sparse array.
      mesh.groups(1:numTargets,groupIdx) = targetIdx; 

    end % for
 
    fprintf( 'Read %d groups from %s in %.2f seconds.\n' , mesh.numGroups , h5FileName , toc() );

  else

    fprintf( 'No groups in %s\n' , h5FileName );
      
  end % if

  % Get groups of groups.
  tic();
  cmd = sprintf( 'h5ls "%s/mesh/%s/%s/groupGroup"' , h5FileName , meshGroupName , meshName );
  [ status , output ] = system( cmd );
  if( status ~= 0 )
    error( 'Error reading groups of groups from %s' , h5FileName );
  end % if

  if( ~isempty( output ) )
  
    [ mesh.groupGroupNames ] = strread( output , '%s %*s %*s' );
    mesh.numGroupGroups = length( mesh.groupGroupNames );
    mesh.groupGroups = sparse( 1 , mesh.numGroupGroups );

    for groupGroupIdx=1:mesh.numGroupGroups

      % Parse out group of group names - this may not be general enough.
      thisGroupGroupName = mesh.groupGroupNames{groupGroupIdx};
      cmd = sprintf( 'h5ls -d -S "%s/mesh/%s/%s/groupGroup/%s"' , h5FileName , meshGroupName , meshName , thisGroupGroupName );
      [ status , output ] = system( cmd );
      if( status ~= 0 )
        error( 'Error reading group of groups from %s' , thisGroupGroupName , h5FileName );
      end % if 
      % Should be one string for each group of groups.
      [ tokens , matches ] = regexp( output , ' "(\w+)[%20]*"' , 'tokens' , 'match' );
      targetNames = [ tokens{1,:} ]';
      numTargets = length( targetNames );
      % Find target group indices.
      targetIdx = [];
      for k=1:numTargets
        thisTargetIdx = [];
        thisTargetName = targetNames{k};
        for groupIdx=1:mesh.numGroups
          if( strcmp( mesh.groupNames{groupIdx} , thisTargetName ) )
            thisTargetIdx = groupIdx;
            break;
          end % if
        end % if
        if( isempty( thisTargetIdx ) )
          warning( 'Recursive groups of groups are not supported.' );
          error( 'Invalid group indices in group of groups %s' , mesh.groupGroupNames{groupGroupIdx} );
        else
          targetIdx = [ targetIdx , thisTargetIdx ]; 
        end % if
      end % for
      mesh.groupGroups(1:numTargets,groupGroupIdx) = targetIdx'; 

    end % for
  
    fprintf( 'Read %d groups of groups from %s in %.2f seconds.\n' , mesh.numGroupGroups , h5FileName , toc() );
  
  else
  
    fprintf( 'No groups of groups in %s.\n' , h5FileName );

  end % if

end % function

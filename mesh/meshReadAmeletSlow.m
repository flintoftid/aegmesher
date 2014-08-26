function [ mesh ] = meshReadAmeletSlow( h5FileName , meshGroupName , meshName , groupTypes )
%
% meshReadAmeletSlow - Read an unstructured mesh from an AMELET-HDF file.
%
% Usage:
%
% [ mesh ] = meshReadAmeletSlow( h5FileName , meshName [, groupTypes ] )
%
% Inputs:
%
% h5FileName    - string, name of AMELET HDF file to read.
% meshGroupName - string, name of mesh group to read. 
% meshName      - string, name of mesh to read.
% groupTypes()  - integer(numGroups), array of group types.
%                 This parameters is to enable a work around for the lack of 
%                 support in octave for importing HDF attributes. By default 
%                 all groups are assumed to be face element groups. If this 
%                 is not the group types *must* be specified manually using
%                 this parameter.
%
% Outputs:
%
% mesh - structure containing an unstructured mesh modelled on the AMELET-HDF format [1]:
%
%        .dimension         - integer, dimension of mesh: 1, 2 or 3.
%        .numNodes          - integer, number of nodes.
%        .nodes()           - real(dimension,numNodes), array of node coordinates.
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

% Requirements:
%
% 1. This function only works in recent version of octave. MATLAB handles
%    HDF5 completely differently.
%
% Limitations:
%
% 1. Recursive "groups of groups" are not supported. 
% 2. Integer sparse arrays are not supported so the sparse arrays as implemented as type double. 
% 3. Octave HDF5 support is somewhat flakey, particularly with regard to reading in strings, both
%    as data names and data itself.:
%    a. Group names that do not begin with a letter of underscore are prefixed with an initial '_' 
%       not present in the HDF5 file since octave fields must begin with a letter/_.
%    b. Spaces at end of string data element are corrupted.
% 4. Writing to AMELET-HDF is impossible with the current octave funcrionality. 
%
% References:
%
% [1] C. Giraudon, “Amelet-HDF Documentation”, Release 1.5.3, Axessim, 15 November, 2011.
%

  % Element types: Indexed by AMELET element type!
  elementTypesData = meshElementTypes();

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
  
  % Load the AMELET HDF file.
  try
    h5 = load( '-hdf5' , h5FileName );
   fprintf( 'Loaded HDF5 file %s.\n' , h5FileName );
  catch
    error( 'Failed to load HDF5 file %s' , h5FileName );
  end % try

  % Find mesg group and mesh name.
  if( isfield( h5.mesh, meshGroupName ) )
    fprintf( 'Found mesh group %s.\n' , meshGroupName );
    if( isfield( h5.mesh.(meshGroupName) , meshName ) )
      h5mesh = h5.mesh.(meshGroupName).(meshName);
      fprintf( 'Found mesh %s.\n' , meshName );
    else
      error( 'Cannot find mesh "%s" in file %s' , meshName , h5FileName );
    end % if
    h5mesh = h5.mesh.(meshGroupName).(meshName);
  else
    error( 'Cannot find mesh group "%s" in file %s' , meshGroupName , h5FileName );
  end % if

  % Get the mesh nodes and dimensionality.
  mesh.nodes = h5mesh.nodes;
  mesh.numNodes = size( mesh.nodes , 2 );
  mesh.dimension = size( mesh.nodes , 1 );

  fprintf( 'Loaded %d nodes of dimension %d.\n' , mesh.numNodes , mesh.dimension );

  % Get the mesh elements.
  mesh.elementTypes = h5mesh.elementTypes;
  mesh.numElements = size( mesh.elementTypes , 2 );
  mesh.elements = sparse(1,mesh.numElements);

  % AMELET packs the elements into a 1D array.
  nextIdx = 1;
  for elementIdx=1:mesh.numElements
    numNodes = nonzeros( elementTypesData(mesh.elementTypes(elementIdx),1) );
    % Beware - AMELET is indexed from zero, not one!
    mesh.elements(1:numNodes,elementIdx) = 1 + double( h5mesh.elementNodes(nextIdx:(nextIdx+numNodes-1))' );
    nextIdx = nextIdx + numNodes;
  end % for

  assert( nextIdx - 1 == length( h5mesh.elementNodes ) );

  fprintf( 'Loaded %d elements.\n' , mesh.numElements );

  % Verify the elements
  all( unique( nonzeros( mesh.elements ) ) <= mesh.numNodes );
  all( unique( nonzeros( mesh.elements ) ) >= 0 );

  % Get groups.
  if( isfield( h5mesh , 'group' ) )

    mesh.groupNames = fieldnames( h5mesh.group );
    mesh.numGroups = length( mesh.groupNames );
    mesh.groups = sparse(1,mesh.numGroups);

    % Kludge to deal with lack of attributes in octave HDF5 "interface".
    if( nargin == 3 )
      mesh.groupTypes = 2 .* ones( 1 , mesh.numGroups );
      warning( 'Assuming all groups are of type 2 (face)' );
    elseif( length( groupTypes ) ~=  mesh.numGroups )
      error( 'Mismatch between number of user supplied group types (%d) and number of groups found (%d)' , ...
             length( groupTypes ) , mesh.numGroups );
    else
      mesh.groupTypes = groupTypes;
    end % if

    for groupIdx=1:mesh.numGroups
      % Beware - AMELET is indexed from zero, not one!
      targetIdx = 1 + double( h5mesh.group.(mesh.groupNames{groupIdx})' );
      numTargets = length( targetIdx );
      if( mesh.groupTypes(groupIdx) == 0 )
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
      mesh.groups(1:numTargets,groupIdx) = targetIdx; 
    end % for

    fprintf( 'Loaded %d groups.\n' , mesh.numGroups );

  end % if

  % Groups of groups.
  if( isfield( h5mesh , 'groupGroup' ) )

    mesh.groupGroupNames = fieldnames( h5mesh.groupGroup );
    mesh.numGroupGroups = length( mesh.groupGroupNames );
    mesh.groupGroups = sparse(1,mesh.numGroupGroups);

    warning( 'Importing of groups of groups disabled due to octave bug' );

    return;

    for groupGroupIdx=1:mesh.numGroupGroups
      targetNames = cellstr( h5mesh.groupGroup.(mesh.groupGroupNames{groupGroupIdx}) );
      numTargets = length( targetNames );
      targetIdx = [];
      % Find target group indices.
      for k=1:numTargets
        thisTargetIdx = [];
        thisTargetName = targetNames{k};
        % Deal with prepended underscores for names not beginning with letter/underscore.
        if( ~isalpha( thisTargetName(1) ) && thisTargetName(1) ~= '_' )
          thisTargetName = [ '_' , thisTargetName(1) ];  
        end % if
        for groupIdx=1:mesh.numGroups
          if( strcmpi( mesh.groupNames{groupIdx} , thisTargetName ) )
            thisTargetIdx = groupIdx;
            break;
          end % if
        end % if
        if( isempty( thisTargetIdx ) )
          warning( 'Recursive groups of groups are not supported.' );
          error( 'Invalid group indices in group group %s' , mesh.groupGroupNames{groupGroupIdx} );
        else
          targetIdx = [ targetIdx , thisTargetIdx ]; 
        end % if
      end % for
      mesh.groupGroups(1:numTargets,groupGroupIdx) = targetIdx; 
    end % for

    fprintf( 'Loaded %d group groups.\n' , mesh.numGroupGroups );

  end % if

end % function


function [ mesh ] = meshReadGmsh( mshFileName , groupFormat )
%
% meshReadGmsh - Read an ASCII format Gmsh mesh.
%
% Usage:
%
% [ mesh ] = meshReadGmsh( mshFileName [ , groupFormat ] )
%
% Inputs:
%
% mshFileName  - string, name of gmsh mesh file to read.
% groupFormat  - integer, type of groups to read:
%
%                1 - create group for each Gmsh physical group (default).
%                2 - create group for each Gmsh entity group.
%                3 - create group for each Gmsh physical and entity group.
%
% Outputs:
%
% mesh - structure containing the unstructured mesh. See help for meshReadAmelet().
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
% Date: 16/06/2010
% Version 1.0.0
%
% Author: M. Berens
% Date: 08/07/2013
% Version 2.0.0 - Corrected errors in semantics of entity/physical groups.
%
% Author: I. D Flintoft
% Date: 12/07/2013
% Version 2.1.0 - Greatly improved performance of element reading by not using sparse arrays.

  if( nargin == 1 )
    groupFormat = 1;
  end % if

  % Maximum number of nodes and tags an element can have.
  maxNumNodes = 8;
  maxNumTags = 3;

  % Mapping of Gmsh element types to AMELET types.
  [ mapGmsh2Amelet , mapAmelet2Gmsh ] = meshAmeletGmshElementTypeMaps();

  % Element types, indexed by AMELET element type!
  elementTypesData = meshElementTypes();

  % Initialise mesh.
  mesh.dimension = NaN;
  mesh.numNodes = 0;
  mesh.nodes = [];
  mesh.numElements = 0;
  mesh.elementTypes = [];
  mesh.elements = [];
  if groupFormat == 0 || groupFormat == 2 % Use settings
    mesh.numEntityGroups = 0;
    mesh.entityGroupTypes = [];
    mesh.entityGroups = [];
  end % if
  if groupFormat == 0 || groupFormat == 1 % Use settings
    mesh.numPhyGroups = 0;
    mesh.phyGroupNames = {};
    mesh.phyGroupTypes = [];
    mesh.phyGroups = [];
  end % if

  numPhysicalNames = 0;

  % Open the gmsh mesh file.
  [ fin , msg ] = fopen ( mshFileName , 'r' );
  if ( fin < 0 )
    error( '%s: %s' , mshFileName , msg );
    return;
  end %if

  fprintf( 'Opened msh file %s.\n' , mshFileName );

  % Top level grammar of ASCII .msh format is a series of sections
  % opened by $<Tag> and closed by $End<Tag> where <Tag> is a case
  % sensitive alphanumeric string.
  while ( ~feof( fin ) )
    
    line = strtrim( fgetl( fin ) );
    
    % See if we have a tag.
    if( line(1) ~= '$' )
      % Shouldn't happen. Blank lines not allowed.
      error( 'syntax error in file' );
    else
      % Get tag and construct end tag.
      tag = line;
      endTag =  [ '$End' , tag(2:end) ];
    end % if
    
    switch( tag )
      case '$MeshFormat'
            
        % Mesh format section:
        % $MeshFormat
        % version-number file-type data-size
        % $EndMeshFormat
        %
        % version-number - float.
        % file-type      - integer, equal to 0 in the ASCII file format.
        % data-size      - integer, currently only data-size = sizeof(double) is supported.

        tic();            

        line = strtrim( fgetl( fin ) );
        [ fields , count ] = sscanf( line , '%f %d %d ' , [ 3 ] );
        if( count == 3 )
          meshVersion = fields(1);
          fileType = fields(2);
          dataSize = fields(3);
        else
           error( 'Failed to parse $MeshFormat section.' );
        end % if
            
        % We only support version 2.0 and greater.
        if( meshVersion < 2.0 )
          error( 'Only mesh formats >= 2.0 are supported.' );
        end % if
            
        % We only support ASCII type.
        if( fileType ~= 0 )
          error( 'Only ASCII file types are supported.' );
        end % if
            
        % Skip to end of section.
        while ( ~feof( fin ) && ~strcmp( line , endTag ) )
          line = strtrim( fgetl( fin ) );
        end % while
            
        fprintf( 'Mesh version %f in %.2f seconds.\n' , meshVersion , toc() );
        drawnow

      case '$Nodes'
            
        % Nodes section.
        % $Nodes
        % number-of-nodes
        % node-number x-coord y-coord z-coord
        % ...
        % $EndNodes
        %
        % number-of-nodes         - integer, number of nodes in the mesh.
        % node-number             - integer>=0, index of the n-th node in the mesh.
        % x-coord y-coord z-coord - float, X, Y and Z coordinates of the n-th node.
            
        tic();

        [ mesh.numNodes , count ] = fscanf( fin , '%d ' , [ 1 ] );
        if( count ~= 1 )
          error( 'Failed to read number of nodes.' );
        end % if
            
        nodeNumbers = zeros( 1 , mesh.numNodes );
        nodeMap = sparse( 10 , 1 );
            
        [ fields , count ] = fscanf( fin , '%d %e %e %e ' , [ 4 , mesh.numNodes ] );
            
        if( count ~= 4 * mesh.numNodes )
          error( 'Failed to %d read nodes.' , mesh.numNodes );
        else
          nodeNumbers(1:mesh.numNodes) = fields(1,1:mesh.numNodes);
          nodeMap(fields(1,1:mesh.numNodes)) = 1:mesh.numNodes;
          mesh.nodes(1:3,1:mesh.numNodes) = fields(2:4,1:mesh.numNodes);
          clear fields;
        end % if
            
        fprintf( 'Read %d nodes in %.2f seconds.\n' , mesh.numNodes , toc() );
        drawnow

        % [FIXME] Guess mesh dimension. Need to determine is all
        % nodes are colinear or in a plane.
        yAllZeros = all( mesh.nodes(2,:) == 0 );
        zAllZeros = all( mesh.nodes(3,:) == 0 );
        if( zAllZeros )
          if( yAllZeros )
            mesh.dimension = 1;
          else
            mesh.dimension = 2;
          end % if
        end % if
            
        while ( ~feof( fin ) && ~strcmp( line , endTag ) )
          line = strtrim( fgetl( fin ) );
        end % while.
            
      case '$Elements'
            
        % Elements section.
        % $Elements
        % number-of-elements
        % elm-number elm-type number-of-tags < tag > ... node-number-list
        % ...
        % $EndElements
        %
        % elm-number       - integer>=0, index of the element in the mesh.
        % elm-type         - integer, geometrical type of the element:
        % number-of-tags   - integer, number of integer tags that follow for the element.
        %                    A zero tag is equivalent to no tag.
        % tag1, tag2,...   - integer list of tags.
        %                    tag1 - physical entity number
        %                    tag2 - elementary entity number
        %                    tag3 - number of mesh partitions to which element belongs
        %                    tag4 ... mesh partition numbers
        % node-number-list - integers, list of the node numbers of the element.
            
        tic();

        [ mesh.numElements , count ] = fscanf( fin , '%d ' , [ 1 ] );
        if( count ~= 1 )
          error( 'Failed to read number of elements.' );
        end % if
            
        % Preallocate element number map and element array.
        elementMap = sparse( 2 * mesh.numElements , 1 );
        elements = zeros( 3 + maxNumTags + maxNumNodes , mesh.numElements );

        % Read elements one by one into array. Array will be padded by
        % zeros for non-existant nodes which is OK because node numbering
        % begins at one in Gmsh.
        for elementIdx=1:mesh.numElements
                
          line = strtrim( fgetl( fin ) );
          [ fields , count ] = sscanf( line , '%d' );

          if( count < 3 )
            error( 'Failed to read element number, type and number of tags' );
          elseif( count > 3 + maxNumTags + maxNumNodes )
            error( 'Too many tags and/or nodes for fast reader' );                
          else
            elements(1:count,elementIdx) = fields;
          end % if
              
        end % for

        % Extract number and types.
        elementNumbers = elements(1,:);
        elementMap(elementNumbers) = 1:mesh.numElements;
        mesh.elementTypes = full( mapGmsh2Amelet( elements(2,:) ) )';

        % Get number of tags - must be same for all elements in fast reader.
        elementNumTags = unique( elements(3,:) );
        if( length( elementNumTags(:) ) ~= 1 )
          error( 'All elements must have same number of tags for fast reader' );
        else
          elementNumTags = elementNumTags(1);
        end %if

        if( elementNumTags > maxNumTags )
          error( 'Maximum number of tags (%d) exceeded (%d)' , maxNumTags , elementNumTags );     
        end % if

        elementTags = elements(4:(4+elementNumTags-1),:);

        % Get expected number of nodes from element type table.
        elementNumNodes = full( elementTypesData(mesh.elementTypes,1) );

        % Get the elements nodes, padded with zeros for non-existant nodes.
        elementNodes = elements((4+elementNumTags):end,:);
        clear elements;

        % To deal with 0 not being a valid index when applying the node map 
        % we have to shift every index by +1 and then by -1 apfter mapping.
        tmpNodeMap = [ 1; full( nodeMap ) + 1 ];
        for nodeIdx=1:size( elementNodes , 1 )
          newNodes(nodeIdx,:) = tmpNodeMap(elementNodes(nodeIdx,:)+1)-1;
        end % for
           
        % The elements nodes are now packed as a sparse array into the structure.
        mesh.elements = sparse( newNodes );

        clear tmpNodeMap , newNodes;

        fprintf( 'Read %d elements in %.2f seconds.\n' , mesh.numElements , toc() );
        drawnow

        while ( ~feof( fin ) && ~strcmp( line , endTag ) )
          line = strtrim( fgetl( fin ) );
        end % while.
            
      case '$PhysicalNames'
            
        % Physical names section.
        % $PhysicalNames
        % number-of-names
        % physical-dimension physical-number "physical-name"
        % $EndPhysicalNames
        %
        % numberof-names     - integer>=0, number of physical names.
        % physical-dimension - integer indication dimension of elements in grouping:
        %                      0 - node, 1 - line, 2 -face, 3 - volume
        % physical-number    - integer, reference number of named group. Used as
        %                      tag1 on all elements in grouping.
        % "physical-name"    - quotedstring, nanme of grouping
            
        tic();

        [ numPhysicalNames , count ] = fscanf( fin , '%d ' , [ 1 ] );
        if( count ~= 1 )
          error( 'Failed to read number of physical names.' );
        end % if
            
        physicalNames = cell( 1 , numPhysicalNames );
        physicalNameNumbers = zeros( 1 , numPhysicalNames );
        physicalNameMap = sparse(1,1);
        physicalNameTypes = zeros( 1 , numPhysicalNames );
            
        % Read physical names one by one.
        for nameIdx=1:numPhysicalNames
                
          line = strtrim( fgetl( fin ) );
          
          % Get dimension/type, number and name.
          [ fields , count , errMsg , nextIdx ] = sscanf( line , '%d %d ' );
                
          if( count ~= 2 )
            error( 'Failed to read physical name' );
          else
            quotedName = strtrim( line(nextIdx:end) );
            physicalNames{nameIdx} = quotedName(2:end-1);
            physicalNameTypes(nameIdx) = fields(1);
            physicalNameNumbers(nameIdx) = fields(2);
            physicalNameMap(fields(2)) = nameIdx;
          end % if
                
        end % for
            
        fprintf( 'Read %d physical names in %.2f seconds.\n' , numPhysicalNames , toc() );
        drawnow

        while ( ~feof( fin ) && ~strcmp( line , endTag ) )
          line = strtrim( fgetl( fin ) );
        end % while.
            
      otherwise
            
        % Sections we don't want to look at are skipped.
        fprintf( 'Skipping section type: %s.' , tag );
        while ( ~feof( fin ) && ~strcmp( line , endTag ) )
          line = strtrim( fgetl( fin ) );
        end % while
            
    end % switch

  end %while

  fclose( fin );
  fprintf( 'Closed file.\n' );
  drawnow

  % Note node, line, face and volume element types have different namespaces in gmsh!

  tic();

  lastEntityElementIdx = 0;
  lastPhysicalElementIdx = 0;

  % Find node type elements.
  nodeElementIdx = find( mesh.elementTypes == 199 );

  % Find node type entity  groups.
  nodeElementEntityGroupNumbers = unique( nonzeros( elementTags(2,nodeElementIdx) ) );
  numNodeElementEntityGroups = length( nodeElementEntityGroupNumbers );
  nodeElementEntityGroupIdx = lastEntityElementIdx + (1:numNodeElementEntityGroups);
  lastEntityElementIdx = lastEntityElementIdx + numNodeElementEntityGroups;

  % Find node type physical groups.
  nodeElementPhysicalGroupNumbers = unique( nonzeros( elementTags(1,nodeElementIdx) ) );
  numNodeElementPhysicalGroups = length( nodeElementPhysicalGroupNumbers );
  nodeElementPhysicalGroupIdx = lastPhysicalElementIdx + (1:numNodeElementPhysicalGroups);
  lastPhysicalElementIdx = lastPhysicalElementIdx + numNodeElementPhysicalGroups;

  % Find line type groups.
  lineTypeIdx = find( elementTypesData(:,2) == 1 );
  lineElementIdx = [];
  for k=1:length( lineTypeIdx )
    lineElementIdx = [ lineElementIdx , find( mesh.elementTypes == lineTypeIdx(k) ) ];
  end % for

  % Find line type entity groups.
  lineElementEntityGroupNumbers = unique( nonzeros( elementTags(2,lineElementIdx) ) );
  numLineElementEntityGroups = length( lineElementEntityGroupNumbers );
  lineElementEntityGroupIdx = lastEntityElementIdx + (1:numLineElementEntityGroups);
  lastEntityElementIdx = lastEntityElementIdx + numLineElementEntityGroups;

  % Find line type physical groups.
  lineElementPhysicalGroupNumbers = unique( nonzeros( elementTags(1,lineElementIdx) ) );
  numLineElementPhysicalGroups = length( lineElementPhysicalGroupNumbers );
  lineElementPhysicalGroupIdx = lastPhysicalElementIdx + (1:numLineElementPhysicalGroups);
  lastPhysicalElementIdx = lastPhysicalElementIdx + numLineElementPhysicalGroups;

  % Find face type groups.
  faceTypeIdx = find( elementTypesData(:,2) == 2 );
  faceElementIdx = [];
  for k=1:length( faceTypeIdx )
    faceElementIdx = [ faceElementIdx , find( mesh.elementTypes == faceTypeIdx(k) ) ];
  end % for

  % Find face type entity groups.
  faceElementEntityGroupNumbers = unique( nonzeros( elementTags(2,faceElementIdx) ) );
  numFaceElementEntityGroups = length( faceElementEntityGroupNumbers );
  faceElementEntityGroupIdx = lastEntityElementIdx + (1:numFaceElementEntityGroups);
  lastEntityElementIdx = lastEntityElementIdx + numFaceElementEntityGroups;

  % Find face type physical groups.
  faceElementPhysicalGroupNumbers = unique( nonzeros( elementTags(1,faceElementIdx) ) );
  numFaceElementPhysicalGroups = length( faceElementPhysicalGroupNumbers );
  faceElementPhysicalGroupIdx = lastPhysicalElementIdx + (1:numFaceElementPhysicalGroups);
  lastPhysicalElementIdx = lastPhysicalElementIdx + numFaceElementPhysicalGroups;

  % Find volume type groups.
  volumeTypeIdx = find( elementTypesData(:,2) == 3 );
  volumeElementIdx = [];
  for k=1:length( volumeTypeIdx )
    volumeElementIdx = [ volumeElementIdx , find( mesh.elementTypes == volumeTypeIdx(k) ) ];
  end % for

  % Find volume type entity groups.
  volumeElementEntityGroupNumbers = unique( nonzeros( elementTags(2,volumeElementIdx) ) );
  numVolumeElementEntityGroups = length( volumeElementEntityGroupNumbers );
  volumeElementEntityGroupIdx = lastEntityElementIdx + (1:numVolumeElementEntityGroups);
  lastEntityElementIdx = lastEntityElementIdx + numVolumeElementEntityGroups;

  % Find volume type physical groups.
  volumeElementPhysicalGroupNumbers = unique( nonzeros( elementTags(1,volumeElementIdx) ) );
  numVolumeElementPhysicalGroups = length( volumeElementPhysicalGroupNumbers );
  volumeElementPhysicalGroupIdx = lastPhysicalElementIdx + (1:numVolumeElementPhysicalGroups);
  lastPhysicalElementIdx = lastPhysicalElementIdx + numVolumeElementPhysicalGroups;

  elementPhysicalGroupIdx = [ nodeElementPhysicalGroupIdx, lineElementPhysicalGroupIdx, faceElementPhysicalGroupIdx, volumeElementPhysicalGroupIdx ];

  fprintf( 'Identified all groups and types in %.2f seconds.\n' , toc() );
  drawnow

  if( groupFormat == 2 || groupFormat == 3 )

    tic();

    % Create entity groups.
    numEntityGroups = numNodeElementEntityGroups + numLineElementEntityGroups + numFaceElementEntityGroups + numVolumeElementEntityGroups;
    allEntityGroupNumbers = [ nodeElementEntityGroupNumbers ; lineElementEntityGroupNumbers ; ...
                              faceElementEntityGroupNumbers ; volumeElementEntityGroupNumbers ];
    entityGroupNumbers(1:numEntityGroups) = allEntityGroupNumbers;
    entityGroupMap = sparse(1,1);
    entityGroupMap(allEntityGroupNumbers) = 1:numEntityGroups;
    entityGroupTypes(1:numEntityGroups) = [ zeros(numNodeElementEntityGroups,1)   ; ones(numLineElementEntityGroups,1)      ; ...
                                            2.*ones(numFaceElementEntityGroups,1) ; 3.*ones(numVolumeElementEntityGroups,1) ];
    entityGroups = sparse( 1 , numEntityGroups );
    entityGroupNames = cell( 1 , numEntityGroups );
    
    % Add default group names. 
    counter = 1;
    for k=1:length(nodeElementEntityGroupIdx)
      idx = nodeElementEntityGroupIdx(k);
      entityGroupNames{idx} = sprintf( 'Point-%d' , counter );
      counter = counter + 1;
    end % if
    counter = 1;
    for k=1:length(lineElementEntityGroupIdx)
      idx = lineElementEntityGroupIdx(k);
      entityGroupNames{idx} = sprintf( 'Line-%d' , counter );
      counter = counter + 1;
    end % if
    counter = 1;
    for k=1:length(faceElementEntityGroupIdx)
      idx = faceElementEntityGroupIdx(k);
      entityGroupNames{idx} = sprintf( 'Surface-%d' , counter );
      counter = counter + 1;
    end % if
    counter = 1;
    for k=1:length(volumeElementEntityGroupIdx)
      idx = volumeElementEntityGroupIdx(k);
      entityGroupNames{idx} = sprintf( 'Volume-%d' , counter );
      counter = counter + 1;
    end % if

    % Add nodes to node groups.
    for k=1:numNodeElementEntityGroups
        groupIdx = nodeElementEntityGroupIdx(k);
        idx = find( elementTags(2,nodeElementIdx) == entityGroupNumbers(groupIdx) );
        nodeIdx = nodeElementIdx(idx);
        entityGroups(1:length(nodeIdx),groupIdx) = nodeIdx';
        counter = counter + 1;
    end % for

    % Add lines to line groups.
    for k=1:numLineElementEntityGroups
        groupIdx = lineElementEntityGroupIdx(k);
        idx = find( elementTags(2,lineElementIdx) == entityGroupNumbers(groupIdx) );
        lineIdx = lineElementIdx(idx);
        entityGroups(1:length(lineIdx),groupIdx) = lineIdx';
        counter = counter + 1;
    end % for

    % Add faces to face groups.
    for k=1:numFaceElementEntityGroups
        groupIdx = faceElementEntityGroupIdx(k);
        idx = find( elementTags(2,faceElementIdx) == entityGroupNumbers(groupIdx) );
        faceIdx = faceElementIdx(idx);
        entityGroups(1:length(faceIdx),groupIdx) = faceIdx';
        counter = counter + 1;
    end % for
    
    % Add volumes to volume groups.
    for k=1:numVolumeElementEntityGroups
        groupIdx = volumeElementGroupIdx(k);
        idx = find( elementTags(2,volumeElementIdx) == entityGroupNumbers(groupIdx) );
        volumeIdx = volumeElementIdx(idx);
        entityGroups(1:length(volumeIdx),groupIdx) = volumeIdx';
        counter = counter + 1;
    end % for
     
    fprintf( 'Created entity groups in %.2f seconds.\n' , toc() );
    drawnow

  end % if

  if( groupFormat == 1 || groupFormat == 3 )

    tic();

    % Create physical groups.
    numPhysicalGroups = numNodeElementPhysicalGroups + numLineElementPhysicalGroups + numFaceElementPhysicalGroups + numVolumeElementPhysicalGroups;
    allPhysicalGroupNumbers = [ nodeElementPhysicalGroupNumbers ; lineElementPhysicalGroupNumbers ; faceElementPhysicalGroupNumbers ; volumeElementPhysicalGroupNumbers ];
    physicalGroupNumbers(1:numPhysicalGroups) = allPhysicalGroupNumbers;
    physicalGroupMap = sparse(1,1);
    physicalGroupMap = 1:numPhysicalGroups;
    physicalGroupTypes(1:numPhysicalGroups) = [ zeros(numNodeElementPhysicalGroups,1)   ; ones(numLineElementPhysicalGroups,1)      ; ...
                                                2.*ones(numFaceElementPhysicalGroups,1) ; 3.*ones(numVolumeElementPhysicalGroups,1) ];
    physicalGroups = sparse( 1 , numPhysicalGroups );
    physicalGroupNames = cell(1,numPhysicalGroups);
    
    % Add default physical group names.
    counter = 1;
    for k=1:lastPhysicalElementIdx
        physicalGroupNames{k} = sprintf( 'PhysicalObject-%d' , counter );
        counter = counter + 1;
    end % if
    
    % Add objects to physical groups.
    for k=1:lastPhysicalElementIdx
        groupIdx = elementPhysicalGroupIdx(k);
        idx = find( elementTags(1,:) == physicalNameNumbers(groupIdx) );
        physicalGroups(1:length(idx),groupIdx) = idx';
    end % for

    % Add physical names to physical groups
    for nameIdx=1:numPhysicalNames
        thisNameNumber = physicalNameNumbers(nameIdx);
        thisName = physicalNames{nameIdx};
        physicalGroupNames{nameIdx} = thisName;
   end % format

   fprintf( 'Created physical groups in %.2f seconds.\n' , toc() );
   drawnow

  end % if

  tic();

  if( groupFormat == 1 )

    % Output physical groups.
    mesh.numGroups = numPhysicalGroups;
    mesh.groupNames = physicalGroupNames;
    mesh.groupTypes = physicalGroupTypes;
    mesh.groups = physicalGroups;

  elseif( groupFormat == 2 )

    % Output entity groups.
    mesh.numGroups = numEntityGroups;
    mesh.groupNames = entityGroupNames;
    mesh.groupTypes = entityGroupTypes;
    mesh.groups = entityGroups;

  elseif( groupFormat == 3 )

    % Merge and output physical and entity groups.
    mesh.numGroups = numPhysicalGroups + numEntityGroups;
    mesh.groupNames(1:numPhysicalGroups) = physicalGroupNames;
    mesh.groupNames((numPhysicalGroups+1):(numPhysicalGroups+numEntityGroups)) = entityGroupNames;
    mesh.groupTypes(1:numPhysicalGroups) = physicalGroupTypes;
    mesh.groupTypes((numPhysicalGroups+1):(numPhysicalGroups+numEntityGroups)) = entityGroupTypes;
    mesh.groups(:,1:numPhysicalGroups) = physicalGroups;
    mesh.groups(:,(numPhysicalGroups+1):(numPhysicalGroups+numEntityGroups)) = entityGroups;

  end % if

  fprintf( 'Mapped output groups in %.2f seconds.\n' , toc() );
  drawnow

end % function

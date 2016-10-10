function [ smesh ] = meshMapGroups( mesh , groupNamesToMap , lines , options )
%
% meshMapGroups - Maps unstructured mesh onto a structured mesh.
%
% [ smesh ] = meshMapGroups( mesh , groupNamesToMap , lines , options )
%
% Inputs:
%
% mesh            - structure containing the unstructured mesh. See help for meshReadAmelet().
%
% groupNamesToMap - string{}, names of groups to map.
% 
% lines           - structure containing the structured mesh lines:
%
%                   .x()       - real(Nx) vector of mesh line coordinates in x-direction [arb].
%                   .y()       - real(Ny) vector of mesh line coordinates in y-direction [arb].
%                   .z()       - real(Nz) vector of mesh line coordinates in z-direction [arb].
%
% options         - structure containing meshing options.
%
% Outputs:
%
% smesh - structure containing a structured mesh modelled on the AMELET-HDF format [1]:
%
%        .dimension         - integer, dimension of mesh: 1, 2 or 3.
%        .x()               - real(Nx) vector of mesh line coordinates in x-direction.
%        .y()               - real(Ny) vector of mesh line coordinates in y-direction.
%        .z()               - real(Nz) vector of mesh line coordinates in z-direction.
%        .numGroups         - integer, number of groups.
%        .groupNames{}      - string{numGroups}, cell array of group names.
%        .groupTypes()      - integer(numGroups), array of AMELET-HDF group types:
%
%                             0 - node
%                             1 - edge
%                             2 - face
%                             3 - volume
%
%        .groups{}          - cell array of bounding boxes of structured mesh elements for
%                             each group. groups{groupIdx} is an nx6 array of structured mesh
%                             indices of the bounding box corners of the elements in the group,
%                             groups{groupIdx}(bboxIdx,coordIdx):
%
%                               coordIdx = 1: ilo
%                               coordIdx = 2: jlo
%                               coordIdx = 3: klo
%                               coordIdx = 4: ihi
%                               coordIdx = 5: jhi
%                               coordIdx = 6: khi
%
%                             The boundng box can be single element (node,edge,face,cell)
%                             or multiple elements (line,surface,volume).
%              
%        .numGroupGroups    - integer, number of groups of groups.
%        .groupGroupNames{} - string{numGroupGroups}, cell array of group group names.
%        .groupGroups()     - integer(var,numGroupGroup), sparse array of group of group indices.
%                             groupGroup(i,j) gives the i-th index (into the groups array) of the
%                             j-th group of groups. Hierarchical group of groups are NOT SUPPORTED.

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
% Date: [FIXME]
% Version: 1.0.0

  % Stencils for structured mesh elemental bounding box types.
  bboxStencils = [ 0 , 0 , 0 ; ....   % Node
                   1 , 0 , 0 ; ...    % x-edge
                   0 , 1 , 0 ; ...    % y-edge  
                   0 , 0 , 1 ; ...    % z-edge
                   1 , 1 , 0 ; ...    % xy-face
                   0 , 1 , 1 ; ...    % yz-face  
                   1 , 0 , 1 ; ...    % zx-face                   
                   1 , 1 , 1 ];       % cell   
                   
  % Get group indices of groups to be mapped.
  if( isempty( groupNamesToMap ) )
    groupNamesToMap = mesh.groupNames;
    groupIdxToMap = 1:mesh.numGroups;
  else
    groupIdxToMap = meshGetGroupIndices( mesh , groupNamesToMap );
  end % if
  numGroupsToMap = length( groupIdxToMap );
  
  % Sort groups to be mapped into precedence order.
  precedence = zeros( 1 , numGroupsToMap );
  for groupIdx=1:numGroupsToMap
    precedence(groupIdx) = meshGetGroupOption( groupIdxToMap(groupIdx) , options , 'precedence' );
  end % for
  [ ~ , idx ] = sort( precedence );
  groupIdxToMap = groupIdxToMap(idx);
  groupNamesToMap = groupNamesToMap(idx);
  groupTypesToMap = mesh.groupTypes(groupIdxToMap);

  fprintf( 'Mapping %d groups\n' , numGroupsToMap );
      
  % Create empty structured mesh.  
  smesh.lines = lines;
  smesh.dimension = mesh.dimension;
  smesh.groups = {};
  smesh.numGroups = 0;
  smesh.groupNames = {};
  smesh.groupTypes = [];

  % [FIXME] Add groupGroup - need to only include mapped groups.

  % AABB of computational volume.
  linesBBox = [ lines.x(1) , lines.y(1) , lines.z(1) , lines.x(end) , lines.y(end) , lines.z(end) ];
  fprintf( 'Computational volume AABB: [%g,%g,%g,%g,%g,%g]\n' , linesBBox );
      
  % Map groups in precedence order onto structured mesh.
  for newGroupIdx=1:numGroupsToMap

    % Name and index of group in unstructured mesh.
    thisGroupName = groupNamesToMap{newGroupIdx};
    thisGroupIdx = groupIdxToMap(newGroupIdx);
    fprintf( 'Mapping group "%s" (index %d)\n' , thisGroupName , thisGroupIdx );
    
    % Get this group's option structure.
    thisOptions = meshGetGroupOptions( thisGroupIdx , options );

    if( strcmp( thisOptions.type , 'VOLUME' ) || strcmp( thisOptions.type , 'SURFACE' ) || strcmp( thisOptions.type , 'CLOSED_SURFACE' ) || strcmp( thisOptions.type , 'THICK_SURFACE' ) )
      % Create BVH for group's elements.  
      [ fbvh , elementMap ] = meshBuildFBVH( mesh , { thisGroupName } , thisOptions );
      % Get AABB of group in physical units.
      objBBox = fbvh(1).bbox;
    else
      objBBox = meshGetGroupAABB( mesh , thisGroupIdx );  
    end % if
    
    % For thick surfaces expand AABB to include thickness of group.
    % Need cells inside thick surface to be included in ray-casting volume!
    if( strcmp( thisOptions.type , 'THICK_SURFACE' ) )
      objBBox(1) = objBBox(1) - thisOptions.thickness;  
      objBBox(2) = objBBox(2) - thisOptions.thickness;  
      objBBox(3) = objBBox(3) - thisOptions.thickness;  
      objBBox(4) = objBBox(4) + thisOptions.thickness;  
      objBBox(5) = objBBox(5) + thisOptions.thickness;  
      objBBox(6) = objBBox(6) + thisOptions.thickness;  
    end % if
    
    fprintf( '  Group AABB: [%g,%g,%g,%g,%g,%g]\n' , objBBox );
    
    % Determine minimally enclosing AABB of the group on the structured grid computational volume.
    % All the group's elements are within or on the mesh lines with these mesh indices.
    % This AABB can be exactly coincident with the group's AABB, i.e. with no 'padding' and can be
    % smaller than the group's AABB if the computational volume does not span the group.
    imin = max( [ find( lines.x <= objBBox(1) ) , 1 ] );
    imax = min( [ find( lines.x >= objBBox(4) ) , length( lines.x ) ] );
    jmin = max( [ find( lines.y <= objBBox(2) ) , 1 ] );
    jmax = min( [ find( lines.y >= objBBox(5) ) , length( lines.y ) ] );
    kmin = max( [ find( lines.z <= objBBox(3) ) , 1 ] );
    kmax = min( [ find( lines.z >= objBBox(6) ) , length( lines.z ) ] );    
    idxBBox = [ imin , jmin , kmin , imax , jmax , kmax ];
    fprintf( '  Mapped cell index AABB: [%d,%d,%d,%d,%d,%d]\n' , idxBBox );
    fprintf( '  Mapped cell AABB: [%g,%g,%g,%g,%g,%g]\n' , ... 
             lines.x(idxBBox(1)) , lines.y(idxBBox(2)) , lines.z(idxBBox(3)) ,...
             lines.x(idxBBox(4)) , lines.y(idxBBox(5)) , lines.z(idxBBox(6)) );

    % Map groups onto structured mesh by type.
    switch( thisOptions.type )    
    case 'VOLUME'
      fprintf( '  Group is a volume object\n' );
      % Solid volume object - mesh group type must be a (closed) surface. 
      if( mesh.groupTypes(thisGroupIdx) ~= 2 )
        error( 'Cannot map group type with types other than 2 (surface) as a volume object' ,  mesh.groupTypes(groupIdx) );
      end % if
      % Check group maps to non-zero volume on structured mesh. 
      if( idxBBox(4) <= idxBBox(1) || idxBBox(5) <= idxBBox(2) || idxBBox(6) <= idxBBox(3) )
        % This should only happen if group AABB has zero volume.
        fprintf( '  Group has no cells within computational volume - ignoring\n' )
      else
        % Map the group. Use the new group index in the structured mesh.
        % Cells at imax, jmax, kmax will not be used for volumetric objects.
        smesh.numGroups = smesh.numGroups + 1;
        isInside = meshVolumeMapGroup( mesh , fbvh , elementMap , lines , objBBox , idxBBox , thisOptions );
        % Add to structured mesh.
        flatIdx = find( isInside );
        [ i , j , k ] = ind2sub( size( isInside ) , flatIdx );
        smesh.groups{smesh.numGroups} = [ imin + i - 1 , jmin + j - 1 , kmin + k - 1 , ...
          imin + i - 1 + bboxStencils(8,1) , jmin + j - 1 + bboxStencils(8,2) , kmin + k - 1 + bboxStencils(8,3) ];
        clear isInside flatIdx i j k
        % Relabel group as volumetric on the structured mesh.
        smesh.groupTypes(smesh.numGroups) = 3;
        smesh.groupNames{smesh.numGroups} = thisGroupName;
      end % if
    case 'SURFACE'
      fprintf( '  Group is a surface object\n' );
      smesh.numGroups = smesh.numGroups + 1;
      % Surface object - mesh group type must be a surface. 
      if( mesh.groupTypes(thisGroupIdx) ~= 2 )
        error( 'Cannot map group type with types other than 2 (surface) as a surface object' ,  mesh.groupTypes(groupIdx) );
      end % if
      % Map the group. Use the new group index in the structured mesh.
      [ isXY , isYZ , isZX ] = meshSurfaceMapGroup( mesh , fbvh , elementMap , lines , objBBox , idxBBox , thisOptions );
      % Careful - if third dimension is 1 size only returns two dimension!
      arraySize = [ size( isXY , 1 ) , size( isXY , 2 ) , size( isXY , 3 ) ];
      % Add to structured mesh.
      flatIdx = find( isXY );   
      [ iXY , jXY , kXY ] = ind2sub( arraySize , flatIdx );    
      bboxXY = [ imin + iXY - 1 , jmin + jXY - 1 , kmin + kXY - 1 , ...
        imin + iXY - 1 + bboxStencils(5,1) , jmin + jXY - 1 + bboxStencils(5,2) , kmin + kXY - 1 + bboxStencils(5,3) ];
      flatIdx = find( isYZ );
      [ iYZ , jYZ , kYZ ] = ind2sub( arraySize , flatIdx );  
      bboxYZ = [ imin + iYZ - 1 , jmin + jYZ - 1 , kmin + kYZ - 1 , ...
        imin + iYZ - 1 + bboxStencils(6,1) , jmin + jYZ - 1 + bboxStencils(6,2) , kmin + kYZ - 1 + bboxStencils(6,3) ]; 
      flatIdx = find( isZX );
      [ iZX , jZX , kZX ] = ind2sub( arraySize , flatIdx );
      bboxZX = [ imin + iZX - 1 , jmin + jZX - 1 , kmin + kZX - 1 , ...
        imin + iZX - 1 + bboxStencils(7,1) , jmin + jZX - 1 + bboxStencils(7,2) , kmin + kZX - 1 + bboxStencils(7,3) ];      
      smesh.groups{smesh.numGroups} = [ bboxXY ; bboxYZ ; bboxZX ];
      clear isXY isYZ isZX flatIdx iXY jXY kXY iYZ jYZ kYZ iZX jZX kZX bboxXY bboxYZ bboxZX
      % Relabel group as a surface group on the structured mesh.
      smesh.groupTypes(smesh.numGroups) = 2;
      smesh.groupNames{smesh.numGroups} = thisGroupName;
    case 'CLOSED_SURFACE'
      fprintf( '  Group is a closed surface object\n' );
      % Mesh group type must be a (closed) surface. 
      if( mesh.groupTypes(thisGroupIdx) ~= 2 )
        error( 'Cannot map group type with types other than 2 (surface) as a solid object' ,  mesh.groupTypes(groupIdx) );
      end % if
      % Check group maps to non-zero volume on structured mesh. 
      if( idxBBox(4) <= idxBBox(1) || idxBBox(5) <= idxBBox(2) || idxBBox(6) <= idxBBox(3) )
        % This should only happen if group AABB has zero volume.
        fprintf( '  Group has no cells within computational volume - ignoring\n' )
      else
        % Map the group as a solid.
        % Cells at imax, jmax, kmax will not be used for volumetric objects.
        smesh.numGroups = smesh.numGroups + 1;
        isInside = meshVolumeMapGroup( mesh , fbvh , elementMap , lines , objBBox , idxBBox , thisOptions );
        % Remap as surface object.
        [ isXY , isYZ , isZX ] = meshVolumeGroup2SurfaceGroup( isInside , idxBBox , thisOptions );
        % Careful - if third dimension is 1 size only returns two dimension!
        arraySize = [ size( isXY , 1 ) , size( isXY , 2 ) , size( isXY , 3 ) ];
        % Add to structured mesh.
        flatIdx = find( isXY );   
        [ iXY , jXY , kXY ] = ind2sub(arraySize , flatIdx );    
        bboxXY = [ imin + iXY - 1 , jmin + jXY - 1 , kmin + kXY - 1 , ...
          imin + iXY - 1 + bboxStencils(5,1) , jmin + jXY - 1 + bboxStencils(5,2) , kmin + kXY - 1 + bboxStencils(5,3) ];
        flatIdx = find( isYZ );
        [ iYZ , jYZ , kYZ ] = ind2sub( arraySize , flatIdx );  
        bboxYZ = [ imin + iYZ - 1 , jmin + jYZ - 1 , kmin + kYZ - 1 , ...
          imin + iYZ - 1 + bboxStencils(6,1) , jmin + jYZ - 1 + bboxStencils(6,2) , kmin + kYZ - 1 + bboxStencils(6,3) ]; 
        flatIdx = find( isZX );
        [ iZX , jZX , kZX ] = ind2sub( arraySize , flatIdx );
        bboxZX = [ imin + iZX - 1 , jmin + jZX - 1 , kmin + kZX - 1 , ...
          imin + iZX - 1 + bboxStencils(7,1) , jmin + jZX - 1 + bboxStencils(7,2) , kmin + kZX - 1 + bboxStencils(7,3) ];      
        smesh.groups{smesh.numGroups} = [ bboxXY ; bboxYZ ; bboxZX ];      
        clear isXY isYZ isZX iXY jXY kXY iYZ jYZ kYZ iZX jZX kZX bboxXY bboxYZ bboxZX
        % Relabel group as a surface group on the structured mesh.
        smesh.groupTypes(smesh.numGroups) = 2;
        smesh.groupNames{smesh.numGroups} = thisGroupName;
      end % if
    case 'THICK_SURFACE'
      fprintf( '  Group is a thick surface object\n' );
      % Mesh group type must be a (closed) surface. 
      if( mesh.groupTypes(thisGroupIdx) ~= 2 )
        error( 'Cannot map group type with types other than 2 (surface) as a thick surface object' ,  mesh.groupTypes(groupIdx) );
      end % if
      % Check group maps to non-zero volume on structured mesh. 
      if( idxBBox(4) <= idxBBox(1) || idxBBox(5) <= idxBBox(2) || idxBBox(6) <= idxBBox(3) )
        % This should only happen if group AABB has zero volume.
        fprintf( '  Group has no cells within computational volume - ignoring\n' )
      else
        % Map the group as a solid.
        % Cells at imax, jmax, kmax will not be used for volumetric objects.
        smesh.numGroups = smesh.numGroups + 1;
        isInside = meshVolumeMapSurfaceGroup( mesh , fbvh , elementMap , lines , objBBox , idxBBox , thisOptions );
        % Add to structured mesh.
        flatIdx = find( isInside );
        [ i , j , k ] = ind2sub( size( isInside ) , flatIdx );
        smesh.groups{smesh.numGroups} = [ imin + i - 1 , jmin + j - 1 , kmin + k - 1 , ...
          imin + i - 1 + bboxStencils(8,1) , jmin + j - 1 + bboxStencils(8,2) , kmin + k - 1 + bboxStencils(8,3) ];
        clear isInside flatIdx i j k
        % Relabel group as a volume group on the structured mesh.
        smesh.groupTypes(smesh.numGroups) = 3;
        smesh.groupNames{smesh.numGroups} = thisGroupName;
      end % if
    case 'LINE'
      fprintf( '  Group is a line object\n' );
      smesh.numGroups = smesh.numGroups + 1;
      % Line object - mesh group type must be a line. 
      if( mesh.groupTypes(thisGroupIdx) ~= 1 )
        error( 'Cannot map group type with types other than 1 (line) as a line object' ,  mesh.groupTypes(groupIdx) );
      end % if
      % Map the group. Use the new group index in the structured mesh.
      [ isX , isY , isZ ] = meshLineMapGroup( mesh , thisGroupIdx , lines , objBBox , idxBBox , thisOptions );
      % Careful - if third dimension is 1 size only returns two dimension!
      arraySize = [ size( isX , 1 ) , size( isX , 2 ) , size( isX , 3 ) ];
      % Add to structured mesh.
      flatIdx = find( isX );   
      [ iX , jX , kX ] = ind2sub( arraySize , flatIdx );    
      bboxX = [ imin + iX - 1 , jmin + jX - 1 , kmin + kX - 1 , ...
        imin + iX - 1 + bboxStencils(2,1) , jmin + jX - 1 + bboxStencils(2,2) , kmin + kX - 1 + bboxStencils(2,3) ];
      flatIdx = find( isY );
      [ iY , jY , kY ] = ind2sub( arraySize , flatIdx );  
      bboxY = [ imin + iY - 1 , jmin + jY - 1 , kmin + kY - 1 , ...
        imin + iY - 1 + bboxStencils(3,1) , jmin + jY - 1 + bboxStencils(3,2) , kmin + kY - 1 + bboxStencils(3,3) ]; 
      flatIdx = find( isZ );
      [ iZ , jZ , kZ ] = ind2sub( arraySize , flatIdx );
      bboxZ = [ imin + iZ - 1 , jmin + jZ - 1 , kmin + kZ - 1 , ...
        imin + iZ - 1 + bboxStencils(4,1) , jmin + jZ - 1 + bboxStencils(4,2) , kmin + kZ - 1 + bboxStencils(4,3) ];      
      smesh.groups{smesh.numGroups} = [ bboxX ; bboxY ; bboxZ ];
      clear isX isY isZ iX jX kX iY jY kY iZ jZ kZ bboxX bboxY bboxZ
      % Relabel group as line on the structured mesh.
      smesh.groupTypes(smesh.numGroups) = 1;
      smesh.groupNames{smesh.numGroups} = thisGroupName;
    case 'POINT'
      fprintf( '  Group is mapped as a node object\n' );
      smesh.numGroups = smesh.numGroups + 1;
      % Map the all the nodes in the group regardless of type.
      smesh.groups{smesh.numGroups} = meshNodeMapGroup( mesh , thisGroupIdx , lines , objBBox , idxBBox , thisOptions ); 
      % Relabel group as a node group on the structured mesh.
      smesh.groupTypes(smesh.numGroups) = 0;
      smesh.groupNames{smesh.numGroups} = thisGroupName;
    case 'BBOX'
      fprintf( '  Group is mapped as a AABB object\n' );
      smesh.numGroups = smesh.numGroups + 1;
      % [FIXME] This is not accurate enough. Probably need to map
      % properly depending on type.
      smesh.groups{smesh.numGroups} = idxBBox; 
      % Relabel group as a AABB group on the structured mesh.
      smesh.groupTypes(smesh.numGroups) = 4;
      smesh.groupNames{smesh.numGroups} = thisGroupName;       
    otherwise
      error( 'Invalid object type %s' , thisOptions.type );
    end % switch

  end % for
  
  % Add computational volume to mesh.
  %[ smesh ] = meshAddCompVol( smesh );

end % function

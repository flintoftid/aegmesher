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
% smesh - structure containing a structured mesh:
%
%         .dimension          - integer, dimension of mesh: 1, 2 or 3.
%         .x()                - real(Nx) vector of mesh line coordinates in x-direction.
%         .y()                - real(Ny) vector of mesh line coordinates in y-direction.
%         .z()                - real(Nz) vector of mesh line coordinates in z-direction.
%         .elements()         - integer(Nx,Ny,Nz,4) array of cell entities. element(i,j,k,m) 
%                               gives the group index (into the groups array) of the m-th 
%                               entity in cell (i,j,k). m takes the values:
%
%                               1 - cell's volume
%                               2 - cell's lower xy face
%                               3 - cell's lower yz face
%                               4 - cell's lower zx face
%                               5 - cell's lower x edge
%                               6 - cell's lower y edge
%                               7 - cell's lower z edge
%                               8 - cell's lower node
%
%         .numGroups         - integer, number of groups.
%         .groupNames{}      - string{numGroups}, cell array of group names.
%         .groupTypes()      - integer(numGroups), array of AMELET-HDF group types:
%
%                              0 - node
%                              1 - edge
%                              2 - face
%                              3 - volume
%
%         .numGroupGroups    - integer, number of groups of groups.
%         .groupGroupNames{} - string{numGroupGroups}, cell array of group group names.
%         .groupGroups()     - integer(var,numGroupGroup), sparse array of group of group indices.
%                              groupGroup(i,j) gives the i-th index (into the groups array) of the
%                              j-th group of groups. Hierarchical group of groups are NOT SUPPORTED.
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
% Date: [FIXME]
% Version: 1.0.0

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
  
  % Determine size of integer required to hold largest group index. 
  if( numGroupsToMap < 2^8 - 1 )
    cellTypeStr = 'int8';
  elseif( numGroupsToMap < 2^16 - 1 )
    cellTypeStr = 'int16';
  elseif( numGroupsToMap < 2^32 - 1 )
    cellTypeStr = 'int32';
  else
    error( 'Too many groups to mesh' );
  end % if

  fprintf( 'Mapping %d groups using "%s" type array\n' , numGroupsToMap , cellTypeStr );
      
  % Create empty structured mesh.  
  smesh.lines = lines;
  smesh.dimension = mesh.dimension;
  smesh.elements = zeros( length( lines.x ) , length( lines.y ) , length( lines.z ) , 7 , cellTypeStr );
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

    % Create BVH for group's elements.
    [ fbvh , elementMap ] = meshBuildFBVH( mesh , { thisGroupName } , thisOptions );

    % Get AABB of group in physical units.
    objBBox = fbvh(1).bbox;
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
        fprintf( '  Group has no cells within computational volume - ignoring' )
      else
        % Map the group. Use the new group index in the structured mesh.
        % Cells at imax, jmax, kmax will not be used for volumetric objects.
        smesh.numGroups = smesh.numGroups + 1;
        isInside = meshVolumeMapGroup( mesh , fbvh , elementMap , lines , objBBox , idxBBox , thisOptions );
        smesh.elements(imin:imax,jmin:jmax,kmin:kmax,1) = ...
          smesh.elements(imin:imax,jmin:jmax,kmin:kmax,1) .* ~isInside + smesh.numGroups .* isInside;
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
      smesh.elements(imin:imax,jmin:jmax,kmin:kmax,2) = ...
        smesh.elements(imin:imax,jmin:jmax,kmin:kmax,2) .* ~isXY + smesh.numGroups .* isXY;
      smesh.elements(imin:imax,jmin:jmax,kmin:kmax,3) = ...
        smesh.elements(imin:imax,jmin:jmax,kmin:kmax,3) .* ~isYZ + smesh.numGroups .* isYZ;
      smesh.elements(imin:imax,jmin:jmax,kmin:kmax,4) = ...
        smesh.elements(imin:imax,jmin:jmax,kmin:kmax,4) .* ~isZX + smesh.numGroups .* isZX;
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
        fprintf( '  Group has no cells within computational volume - ignoring' )
      else
        % Map the group as a solid. Use the new group index in the structured mesh.
        % Cells at imax, jmax, kmax will not be used for volumetric objects.
        smesh.numGroups = smesh.numGroups + 1;
        isInside = meshVolumeMapGroup( mesh , fbvh , elementMap , lines , objBBox , idxBBox , thisOptions );
        % Remap as surface object.
        [ isXY , isYZ , isZX ] = meshVolumeGroup2SurfaceGroup( isInside , idxBBox , thisOptions );
        smesh.elements(imin:imax,jmin:jmax,kmin:kmax,2) = ...
        smesh.elements(imin:imax,jmin:jmax,kmin:kmax,2) .* ~isXY + smesh.numGroups .* isXY;
        smesh.elements(imin:imax,jmin:jmax,kmin:kmax,3) = ...
        smesh.elements(imin:imax,jmin:jmax,kmin:kmax,3) .* ~isYZ + smesh.numGroups .* isYZ;
        smesh.elements(imin:imax,jmin:jmax,kmin:kmax,4) = ...
        smesh.elements(imin:imax,jmin:jmax,kmin:kmax,4) .* ~isZX + smesh.numGroups .* isZX;
        % Relabel group as surface on the structured mesh.
        smesh.groupTypes(smesh.numGroups) = 2;
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
      smesh.elements(imin:imax,jmin:jmax,kmin:kmax,5) = ...
        smesh.elements(imin:imax,jmin:jmax,kmin:kmax,5) .* ~isX + smesh.numGroups .* isX;
      smesh.elements(imin:imax,jmin:jmax,kmin:kmax,6) = ...
        smesh.elements(imin:imax,jmin:jmax,kmin:kmax,6) .* ~isY + smesh.numGroups .* isY;
      smesh.elements(imin:imax,jmin:jmax,kmin:kmax,7) = ...
        smesh.elements(imin:imax,jmin:jmax,kmin:kmax,7) .* ~isZ + smesh.numGroups .* isZ;
      smesh.groupTypes(smesh.numGroups) = 1;
      smesh.groupNames{smesh.numGroups} = thisGroupName;
    case 'POINT'
      fprintf( '  Group is a point object\n' );
      fprintf( '  *** Ignoring unsupported object type %s ***\n' , thisOptions.type );
    case 'BBOX'
      fprintf( '  Not mapping BBOX type group\n' );
    otherwise
      error( 'Invalid object type %s' , thisOptions.type );
    end % switch

  end % for
  
end % function

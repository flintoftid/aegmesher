function meshWriteVulture( mshFileName , smesh , options )
%
% meshWriteVulture - Writes structured mesh in Vulture input mesh format.
%
% Usage:
%
% meshWriteVulture( mshFileName, smesh , options )
%
% Inputs:
%
% mshFileName         - string, name of Vulture mesh file to create.
% smesh               - structure containing the  structured mesh created by meshMap.m:
%
%   .dimension        - dimension of mesh: 1, 2 or 3.
%   .x()              - (length: i) grid position in x- direction
%   .y()              - (length: j) grid position in y- direction
%   .z()              - (length: k) grid position in z- direction
%   .element()        - (numElements) integer array of (AMELET) element types.
%   .numEntityGroups  - number of groups.
%   .groupNames{}     - (numEntityGroups) cell array of group names.
%   .groupTypes()     - (numEntityGroups) integer array of (AMELET group) types:
%                       0 - nodes, 1 - edge, 2 - face, 3 - volume
%   .groups()         - (numEntityGroups x var) sparse array of node/element indices.
%
% options             - user defined control information.
%
%  In addition to the meshing options this exporter recognises the following options: 
%
%    .export.useMaterialNames  - boolean, use material names (if true) or group
%                                names (if false) for materials in exported mesh.
%    .export.scaleFactor       - real scalar, scale factor for mesh.
%
% Materials:
%
% The exporter names the materials according to the material name or group name
% and provides a basic type directive mapping this to the material name. These
% type directives will need to be set correctly by the user, as described in the 
% Vulture user manual [1].
% 
% References:
%
% [1] I. D. Flintoft, "Vulture FDTD code user manual", Vulture version 0.7.0,
%     mesh version 1.0.0, 23 November, 2016. 
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

% Author: M. Berens and I. D. Flintoft
% Date: 12/10/2013
% Version 1.0.0

% Note - mesh line indices have to be reduced by 1 since Vulture uses zero 
% based arrays!

  % Directives for group types.
  directiveString = { 'TW' , 'TB' , 'MB' };
  
  % Mesh lines.
  x = options.export.scaleFactor .* smesh.lines.x;
  y = options.export.scaleFactor .* smesh.lines.y;
  z = options.export.scaleFactor .* smesh.lines.z;

  % Get material names.
  for groupIdx=1:smesh.numGroups
    if( strcmp( options.group(groupIdx).physicalType , 'MATERIAL' ) ) 
      matNames{groupIdx} = meshGetGroupOption( groupIdx , options , 'materialName' );    
    else
      matNames{groupIdx} = 'NA';      
    end % if
    if( options.export.useMaterialNames )
      names{groupIdx} = matNames{groupIdx};
    else
      names{groupIdx} = smesh.groupNames{groupIdx};
    end % if
  end % for

  % Create vulture mesh file.
  fprintf( 'Opening vulture mesh file %s...\n' , mshFileName );
  [ fout , msg ] = fopen ( mshFileName , 'w' );
  if ( fout < 0 )
    error( '%s: %s' , mshFileName , msg );
  end % if

  % Write vulture mesh file.
  fprintf( 'Opened msh file %s.\n' , mshFileName );
  fprintf( fout , 'VM 1.0.0\n' );
  fprintf( fout , '#\n# Section 1\n#\n' );
  fprintf( fout , 'DM %3d %3d %3d\n', length( x ) - 1 , length( y ) - 1 , length( z ) - 1 );
  fprintf( fout , 'GS\n' );
  fprintf( fout , '#\n# Section 2\n#\n' );
  % [FIXME] Use fmin/fmax to determine modulated Gaussian parameters.
  fprintf( fout , 'WF wf1 GAUSSIAN_PULSE\n' );

  % Write out sources.
  for groupIdx=1:smesh.numGroups
    if( strcmp( options.group(groupIdx).physicalType , 'SOURCE' ) )
      bboxes = smesh.groups{groupIdx};
      for bboxIdx=1:size( bboxes , 1 )  
        fprintf( fout , 'EX %3d %3d %3d %3d %3d %3d %s\n' , ...
                 bboxes(bboxIdx,1) - 1 , bboxes(bboxIdx,4) - 1 , ...
                 bboxes(bboxIdx,2) - 1 , bboxes(bboxIdx,5) - 1 , ...
                 bboxes(bboxIdx,3) - 1 , bboxes(bboxIdx,6) - 1 , ...
                 names{groupIdx} );
      end % for
    end % if
  end % for

  % Write out observers.
  for groupIdx=1:smesh.numGroups
    if( strcmp( options.group(groupIdx).physicalType , 'OBSERVER' ) )
      bboxes = smesh.groups{groupIdx};
      for bboxIdx=1:size( bboxes , 1 )  
        fprintf( fout , 'OP %3d %3d %3d %3d %3d %3d %s\n' , ...
                 bboxes(bboxIdx,1) - 1 , bboxes(bboxIdx,4) - 1 , ...
                 bboxes(bboxIdx,2) - 1 , bboxes(bboxIdx,5) - 1 , ...
                 bboxes(bboxIdx,3) - 1 , bboxes(bboxIdx,6) - 1 , ...
                 names{groupIdx} );
      end % for
    end % if
  end % for

  % Write out material types. 
  for groupIdx=1:smesh.numGroups
    if( strcmp( options.group(groupIdx).physicalType , 'MATERIAL' ) )
      switch( smesh.groupTypes(groupIdx) )
      case 3
        fprintf( fout , 'MT %s %s\n', names{groupIdx} , matNames{groupIdx} );
      case 2
        fprintf( fout , 'BT %s %s\n', names{groupIdx} , matNames{groupIdx} );
      case 1
        fprintf( fout , 'WT %s %s\n', names{groupIdx} , matNames{groupIdx} );
      otherwise
        ;
      end % switch
    end % if
  end % for

  % Write out material selectors.
  for groupIdx=1:smesh.numGroups
    if( strcmp( options.group(groupIdx).physicalType , 'MATERIAL' ) )
      groupType = smesh.groupTypes(groupIdx);
      if( groupType == 0 )
        continue;
      end % if
      bboxes = smesh.groups{groupIdx};
      for bboxIdx=1:size( bboxes , 1 )  
        fprintf( fout , '%s %3d %3d %3d %3d %3d %3d %s\n' , directiveString{groupType} , ...
                 bboxes(bboxIdx,1) - 1 , bboxes(bboxIdx,4) - 1 , ...
                 bboxes(bboxIdx,2) - 1 , bboxes(bboxIdx,5) - 1 , ...
                 bboxes(bboxIdx,3) - 1 , bboxes(bboxIdx,6) - 1 , ...
                 names{groupIdx} );    
      end % for bboxIdx
    end % if
  end % for groupIdx
  
  fprintf( fout , 'GE\n' );
  
  % [FIXME] Estimate minimium number of time steps from mesh dimensions and waveform.
  fprintf( fout , '#\n# Section 3\n#\n' );
  fprintf( fout , 'NT 10000\n' );

  % If we don't use XL/YL/ZL mesh will start at (0,0,0) and outputs
  % mesh/data may not match input mesh. Need MO card support in vulture
  % to allow for offset origin.
  %switch( options.mesh.meshType )
  %case 'CUBIC'
  %  d = mean( [ diff( x ) , diff( y ) , diff( z ) ] );
  %  fprintf( fout , 'MS %g %g %g\n', d );
  %  fprintf( fout , 'MO %g %g %g\n', x(1) , y(1) , z(1) );
  %case 'UNIFORM'
  %  dx = mean( diff( x ) );
  %  dy = mean( diff( y ) );
  %  dz = mean( diff( z ) );
  %  fprintf( fout , 'MS %g %g %g\n', dx , dy , dz );
  %  fprintf( fout , 'MO %g %g %g\n', x(1) , y(1) , z(1) );
  %case 'NONUNIFORM'
    fprintf( fout , 'XL\n' );
    fprintf( fout , '%g\n', x );
    fprintf( fout , 'YL\n' );
    fprintf( fout , '%g\n', y );
    fprintf( fout , 'ZL\n' );
    fprintf( fout , '%g\n', z ); 
  %end % switch

  % Close vulture mesh file.
  fclose( fout );
  fprintf( 'Closed vulture mesh file %s.\n' , mshFileName );

end % function

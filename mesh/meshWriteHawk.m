function meshWriteHawk( mshFileName , smesh , options )
%
% meshWriteHawk - Writes structured mesh in Hawk input mesh format.
%
% Usage:
%
% meshWriteHawk( mshFileName, smesh , options )
%
% Inputs:
%
% mshFileName         - string, name of Hawk mesh file to create.
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
%  In addition to the meshing options this exporter recogises the following options: 
%
%    .export.useMaterialNames  - boolean, use material names (if true) or group
%                                names (if false) for materials in exported mesh.
%    .export.scaleFactor       - real scalar, scale factor for mesh.
%
% Materials:
%
% The material parameters should be defined in an ASCII text file called `materials.asc'.
% The file should contain one line for each material. Empty lines and comments are not
% supported. Currently only arbitrary reflection and transmission surface materials are
% supported.
%
% The valid formats of the material specification lines are:
%
% <materialName> <rho_lo> <tau_high_to_low> <rho_high tau_low_to_high> <rho_high>
%
% for surface materials and
%
% <materialName> <eps_r> <mu_r> <sigma> <r_m> <r_0>
%
% for volumetric materials.
%
% See the Hawk user manual for the specficiation of these parameters [1].
%
% References:
%
% J. F. Dawson and S. J. Porter, "A user’s guide to the HAWK Transmission 
% Line Matrix Package", version 1.3, Department of Electronics,
% University of York, Heslington, UK, September, 1999.
%

% This file is part of aegmesher.
%
% aegmesher structured mesh generator and utilities.
% Copyright (C) 2016 Ian Flintoft
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

% Author: I. D. Flintoft
% Date: 21/11/2016
% Version 1.0.0

  % Physical constants.
  c0 = 299792458;                  
  mu0 = 4 * pi * 1e-7;             
  eps0 = 1.0 / ( mu0 * c0 * c0 );
  eta0 = sqrt( mu0 / eps0 );

  % Thin boundary (TB) types for arbitrary reflection/transmission 
  % parameters in x, y and z normal directions.
  surfType = [ 16 , 17 , 15 ];

  % Function to determine the normal direction of a bounding box.
  % Returns: 0 - not a surface, 1 - x, 2 - y, 3 - z.
  function normalDirection = bboxNormal( bbox )
    %             V  Syz Szx Lz  Sxy Ly  Lx   P
    direction = [ 0 , 1 , 2 , 0 , 3 , 0 , 0 , 0 ];
    isXequal = ( bbox(1) == bbox(4) );
    isYequal = ( bbox(2) == bbox(5) );
    isZequal = ( bbox(3) == bbox(6) );
    mask = 1 + isXequal + 2 * isYequal + 4 * isZequal;
    normalDirection = direction(mask);
  end % function

  % Mesh lines.
  x = options.export.scaleFactor .* smesh.lines.x;
  y = options.export.scaleFactor .* smesh.lines.y;
  z = options.export.scaleFactor .* smesh.lines.z;

  % Get material parameters from input file `materials.asc`.
  % [FIXME] This is not very robust.
  fp = fopen( 'materials.asc' , 'r' );
  data = textscan( fp , '%s %f %f %f %f \n' );
  matDBnames = data{1};
  matDBparams = cell2mat( data(:,2:end) );
  fclose( fp );

  % Get material names used in mesh.
  for groupIdx=1:smesh.numGroups
    if( strcmp( options.group(groupIdx).physicalType , 'MATERIAL' ) ) 
      matNames{groupIdx} = meshGetGroupOption( groupIdx , options , 'materialName' );   
      matIdx = find( ismember( matDBnames , matNames{groupIdx} ) );
      if( ~isempty( matIdx ) )
        matParamStr{groupIdx} = matDBparams(matIdx,:);
      else
        error( 'material %s not in' , matNames{groupIdx} );
      end % if
    else
      matNames{groupIdx} = 'NA';   
      matParamStr{groupIdx} = '';
    end % if
    if( options.export.useMaterialNames )
      names{groupIdx} = matNames{groupIdx};
    else
      names{groupIdx} = smesh.groupNames{groupIdx};
    end % if
  end % for

  % Check mesh type and get mesh size.
  switch( options.mesh.meshType )
  case 'CUBIC'
    d = mean( [ diff( x ) , diff( y ) , diff( z ) ] );
  otherwise
    error( 'Hawk only supports cubic meshes' );
  end % switch

  % Create hawk mesh file.
  fprintf( 'Opening hawk mesh file %s...\n' , mshFileName );
  [ fout , msg ] = fopen ( mshFileName , 'w' );
  if ( fout < 0 )
    error( '%s: %s' , mshFileName , msg );
  end % if

  % Write hawk mesh file.
  fprintf( 'Opened msh file %s.\n' , mshFileName );
  fprintf( fout , 'CE %s\n' , mshFileName );
  fprintf( fout , 'DM %3d %3d %3d\n', length( x ) - 1 , length( y ) - 1 , length( z ) - 1 );
  fprintf( fout , 'BR %g %g %g %g %g %g\n', 0 , 0 , 0 , 0 , 0 , 0 );

  % Write out sources.
  % [FIXME] This needs to know semantic of different source types.
  for groupIdx=1:smesh.numGroups
    if( strcmp( options.group(groupIdx).physicalType , 'SOURCE' ) )
      warning( 'source export not fully implemented yet!' ):
      bboxes = smesh.groups{groupIdx};
      for bboxIdx=1:size( bboxes , 1 )  
        fprintf( fout , 'EX %3d %3d %3d %3d %3d %3d 1 1.0\n' , ...
                 bboxes(bboxIdx,1) , bboxes(bboxIdx,4) - 1 , ...
                 bboxes(bboxIdx,2) , bboxes(bboxIdx,5) - 1 , ...
                 bboxes(bboxIdx,3) , bboxes(bboxIdx,6) - 1 , ...
                 names{groupIdx} );
      end % for
    end % if
  end % for

  % Write out observers.
  for groupIdx=1:smesh.numGroups
    if( strcmp( options.group(groupIdx).physicalType , 'OBSERVER' ) )
      bboxes = smesh.groups{groupIdx};
      for bboxIdx=1:size( bboxes , 1 )  
        fprintf( fout , 'OP %3d %3d 1 %3d %3d 1 %3d %3d 1\n' , ...
                 bboxes(bboxIdx,1) , bboxes(bboxIdx,4) - 1 , ...
                 bboxes(bboxIdx,2) , bboxes(bboxIdx,5) - 1 , ...
                 bboxes(bboxIdx,3) , bboxes(bboxIdx,6) - 1 , ...
                 names{groupIdx} );
      end % for
    end % if
  end % for

  % Write out material selectors.
  % [FIXME] This is a prototype implementation. Needs to be made
  % moe data driven (offset patterns) and vectorised. 
  for groupIdx=1:smesh.numGroups
    if( strcmp( options.group(groupIdx).physicalType , 'MATERIAL' ) )
      groupType = smesh.groupTypes(groupIdx);
      if( groupType == 0 )
        continue;
      end % if
      bboxes = smesh.groups{groupIdx};
      switch( groupType )
      case 1
        % Linear materials - not supported.
        warning( 'wire groups not supported by Hawk - ignoring group %s' , names{groupIdx} );
        continue;
      case 2
        % Surface materials - TB.
        for bboxIdx=1:size( bboxes , 1 )
          normalDirection = bboxNormal( bboxes(bboxIdx,:) );
          switch( normalDirection )
          case 1
            fprintf( fout , 'TB %3d %3d %3d %3d %3d %3d %2d 1\nTE %g %g %g %g\n' , ...
                     bboxes(bboxIdx,1) , bboxes(bboxIdx,4) , ...
                     bboxes(bboxIdx,2) , bboxes(bboxIdx,5) - 1 , ...
                     bboxes(bboxIdx,3) , bboxes(bboxIdx,6) - 1 , ...
                     surfType(normalDirection) , matParamStr{groupIdx}(1:4) );
          case 2
            fprintf( fout , 'TB %3d %3d %3d %3d %3d %3d %2d 1\nTE %g %g %g %g\n' , ...
                     bboxes(bboxIdx,1) , bboxes(bboxIdx,4) - 1 , ...
                     bboxes(bboxIdx,2) , bboxes(bboxIdx,5) , ...
                     bboxes(bboxIdx,3) , bboxes(bboxIdx,6) - 1 , ...
                     surfType(normalDirection) , matParamStr{groupIdx}(1:4) );          
          case 3
            fprintf( fout , 'TB %3d %3d %3d %3d %3d %3d %2d 1\nTE %g %g %g %g\n' , ...
                     bboxes(bboxIdx,1) , bboxes(bboxIdx,4) - 1 , ...
                     bboxes(bboxIdx,2) , bboxes(bboxIdx,5) , ...
                     bboxes(bboxIdx,3) , bboxes(bboxIdx,6) - 1 , ...
                     surfType(normalDirection) , matParamStr{groupIdx}(1:4) );          
          otherwise
            assert( false );
          end %switch
        end % for bboxIdx        
      case 3
        % Volume materials - MB.
        for bboxIdx=1:size( bboxes , 1 )  
          fprintf( fout , 'MB %3d %3d %3d %3d %3d %3d %g %g %g 0 0\n' , ...
                   bboxes(bboxIdx,1) , bboxes(bboxIdx,4) - 1 , ...
                   bboxes(bboxIdx,2) , bboxes(bboxIdx,5) - 1 , ...
                   bboxes(bboxIdx,3) , bboxes(bboxIdx,6) - 1 , ...
                   matParamStr{groupIdx}(1:2) , matParamStr{groupIdx}(3) * eta0 * d );
        end % for bboxIdx
      otherwise
        ;
      end % switch
    end % if
  end % for groupIdx
  
  % End of geometry marker.
  fprintf( fout , 'GE\n' );
  
  % [FIXME] Estimate minimium number of time steps from mesh dimensions and waveform.
  fprintf( fout , 'NT 10000\n' );
  fprintf( fout , 'OT 0 10000\n' );
  
  % Mesh size.
  fprintf( fout , 'MS %g\n', d );

  % Post-procssing points.
  isObserver = false;
  for groupIdx=1:smesh.numGroups
    if( strcmp( options.group(groupIdx).physicalType , 'OBSERVER' ) )
      bboxes = smesh.groups{groupIdx};
      for bboxIdx=1:1
        fprintf( fout , 'PP %3d %3d %3d %3d %3d %3d 1\n' , ...
                 bboxes(bboxIdx,1) , bboxes(bboxIdx,4) - 1 , ...
                 bboxes(bboxIdx,2) , bboxes(bboxIdx,5) - 1 , ...
                 bboxes(bboxIdx,3) , bboxes(bboxIdx,6) - 1 , ...
                 names{groupIdx} );
      end % for
      isObserver = true;
      % Only write PP for first OP.
      break;
    end % if
  end % for
  
  % Must be a PP for ghawk to work - add one if required.
  if( ~isObserver )
    fprintf( fout , 'PP 1 1 1 1 1 1 1\n' );   
  end % if
  
  % Close hawk mesh file.
  fprintf( fout , 'EN\n' );
  fclose( fout );
  fprintf( 'Closed hawk mesh file %s.\n' , mshFileName );

end % function

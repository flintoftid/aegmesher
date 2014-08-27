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
% options             - user defined control information
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

% Author: M. Berens
% Date: 12/10/2013
% Version 1.0.0

% Note - mesh line indices have to be reduced by 1 since Vulture uses zero 
% based arrays!

  % Mesh lines.
  x = smesh.lines.x;
  y = smesh.lines.y;
  z = smesh.lines.z;

  if( options.vulture.useMaterialNames )
    names = {};
    for groupIdx=1:smesh.numGroups
      names{groupIdx} = meshGetGroupOption( groupIdx , options , 'materialName' );
    end % for
  else
    names = smesh.groupNames;
  end % if

  % Sanitise names. 
  %materialName = cell2mat( smesh.groupNames(1) );
  %materialName = regexprep( materialName , '[^\w'']' , '' );

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
  fprintf( fout , 'DM %d %d %d\n', length( x ) - 1 , length( y ) - 1 , length( z ) - 1 );
  fprintf( fout , 'GS\n' );
  fprintf( fout , '#\n# Section 2\n#\n' );
  % [FIXME] Use fmin/fmax to determine differentiated Gaussian parameters.
  fprintf( fout , 'WF wf1 GAUSSIAN_PULSE\n' );
  % [FIXME] Better way to put in dummy source?
  fprintf( fout , 'EX  0 2 1 1 0 2 source EZ wf1 1.0\n' );

  for groupIdx=1:smesh.numGroups
    switch( smesh.groupTypes(groupIdx) )
    case 3
      fprintf( fout , 'MT %s PEC\n', names{groupIdx} );
    case 2
      fprintf( fout , 'BT %s PEC\n', names{groupIdx} );
    case 1
      fprintf( fout , 'WT %s PEC\n', names{groupIdx} );
    otherwise
      ;
    end % switch
  end % for

  % Handle material blocks if there exists a solid/ solid-surface object.
  if( size( smesh.elements , 4 ) >= 1 )
    numMB = length( find( smesh.elements(:,:,:,1) ~= 0 ) );
    if( numMB > 0 )
      for i = 1:size(smesh.elements,1)-1
        for j = 1:size(smesh.elements,2)-1
          for k = 1:size(smesh.elements,3)-1
            if( smesh.elements(i,j,k,1) ~= 0 )
              fprintf( fout , 'MB %d %d %d %d %d %d %s\n' , [ i , i + 1 , j , j + 1 , k , k + 1 ] - 1 , names{smesh.elements(i,j,k,1)} );
            end % if
          end % for
        end % for
      end % for
    end % if
  end %if
  
  % Handle TB if there exists a surface object.
  if( size( smesh.elements , 4 ) >= 2 )
    numTB = length( find( smesh.elements(:,:,:,2) ~= 0 ) );
    if( numTB > 0 )
      for i = 1:size(smesh.elements,1)-1
        for j = 1:size(smesh.elements,2)-1
          for k = 1:size(smesh.elements,3)
            if( smesh.elements(i,j,k,2) ~= 0 )
              fprintf( fout , 'TB %d %d %d %d %d %d %s\n' , [ i , i + 1 , j , j + 1 , k , k ] - 1 , names{smesh.elements(i,j,k,2)} );
            end % if    
          end % for
        end % for
      end % for
    end % if
  end %if 
  if( size( smesh.elements , 4 ) >= 3 )   
    numTB = length( find( smesh.elements(:,:,:,3) ~= 0 ) );
    if( numTB > 0 )
      for i = 1:size(smesh.elements,1)
        for j = 1:size(smesh.elements,2)-1
          for k = 1:size(smesh.elements,3)-1
            if( smesh.elements(i,j,k,3) ~= 0 )
              fprintf( fout , 'TB %d %d %d %d %d %d %s\n' , [ i , i , j , j + 1 , k , k + 1 ] - 1 , names{smesh.elements(i,j,k,3)} ); 
            end % if
          end % for
        end % for
      end % for
    end % if
  end %if
  if( size( smesh.elements , 4 ) >= 4 )  
    numTB = length( find( smesh.elements(:,:,:,4) ~= 0 ) );
    if( numTB > 0 )
      for i = 1:size(smesh.elements,1)-1
        for j = 1:size(smesh.elements,2)
          for k = 1:size(smesh.elements,3)-1
            if( smesh.elements(i,j,k,4) ~= 0 )
              fprintf( fout , 'TB %d %d %d %d %d %d %s\n' , [ i , i + 1 , j , j , k , k + 1 ] - 1 , names{smesh.elements(i,j,k,4)} );
            end % if
          end % for
        end % for
      end % for
    end % if
  end %if
  
  % Handle TW if there exists a line object.
  if( size( smesh.elements , 4 ) >= 5 )
    numTW = length( find( smesh.elements(:,:,:,5) ~= 0 ) );
    if( numTW > 0 )
      for i = 1:size(smesh.elements,1)-1
        for j = 1:size(smesh.elements,2)-1
          for k = 1:size(smesh.elements,3)
            if( smesh.elements(i,j,k,5) ~= 0 )
              fprintf( fout , 'TW %d %d %d %d %d %d %s\n' , [ i , i + 1 , j , j , k , k ] - 1 , names{smesh.elements(i,j,k,5)} );
            end % if    
          end % for
        end % for
      end % for
    end % if
  end %if 
  if( size( smesh.elements , 4 ) >= 6 )
    numTW = length( find( smesh.elements(:,:,:,6) ~= 0 ) );
    if( numTW > 0 )
      for i = 1:size(smesh.elements,1)-1
        for j = 1:size(smesh.elements,2)-1
          for k = 1:size(smesh.elements,3)
            if( smesh.elements(i,j,k,6) ~= 0 )
              fprintf( fout , 'TW %d %d %d %d %d %d %s\n' , [ i , i , j , j + 1 , k , k ] - 1 , names{smesh.elements(i,j,k,6)} );
            end % if    
          end % for
        end % for
      end % for
    end % if
  end %if 
  if( size( smesh.elements , 4 ) >= 7 )
    numTW = length( find( smesh.elements(:,:,:,7) ~= 0 ) );
    if( numTW > 0 )
      for i = 1:size(smesh.elements,1)-1
        for j = 1:size(smesh.elements,2)-1
          for k = 1:size(smesh.elements,3)
            if( smesh.elements(i,j,k,7) ~= 0 )
              fprintf( fout , 'TW %d %d %d %d %d %d %s\n' , [ i , i , j , j , k , k + 1 ] - 1 , names{smesh.elements(i,j,k,7)} );
            end % if    
          end % for
        end % for
      end % for
    end % if
  end %if 

  % [FIXME] Add dummy observber?
  % fprintf( fout , 'OP  0 2 1 1 0 2 output1 .....\n' );
  
  fprintf( fout , 'GE\n' );
  
  % [FIXME] Estimate minimium number of time steps from mesh dimensions and waveform.
  fprintf( fout , '#\n# Section 3\n#\n' );
  fprintf( fout , 'NT 100\n' );

  % If we don't use XL/YL/ZL mesh will start at (0,0,0) and outputs
  % mesh/data may not match input mesh.
  %switch( options.mesh.meshType )
  %case 'CUBIC'
  %  d = mean( [ diff( x ) , diff( y ) , diff( z ) ] );
  %  fprintf( fout , 'MS %f %f %f\n', d );
  %case 'UNIFORM'
  %  dx = mean( diff( x ) );
  %  dy = mean( diff( y ) );
  %  dz = mean( diff( z ) );
  %  fprintf( fout , 'MS %f %f %f\n', dx , dy , dz );
  %case 'NONUNIFORM'
    fprintf( fout , 'XL\n' );
    fprintf( fout , '%f\n', x );
    fprintf( fout , 'YL\n' );
    fprintf( fout , '%f\n', y );
    fprintf( fout , 'ZL\n' );
    fprintf( fout , '%f\n', z );  
  %end % switch

  % Close vulture mesh file.
  fclose( fout );
  fprintf( 'Closed vulture mesh file %s.\n' , mshFileName );

end % function
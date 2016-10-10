function meshWriteWire( wireFileName , mesh , groupNames )
%
% meshWriteWire: Export wire elements from mesh into a CONCEPT wire file.
% 
% Usage:
%
% meshWriteWire( wireFileName , mesh [ , groupNames ] )
%
% Inputs:
%
% wireFileName - string, name of CONCEPT wire file to create.
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
  
  % Now write out to CONCEPT wire file.
  [ fout , msg ] = fopen ( wireFileName , 'w' );
  if ( fout < 0 ) 
    error( '%s: %s' , wireFileName , msg );
    return;
  end %if

  fprintf( 'Opened wire file %s.\n' , wireFileName );

  if( isempty( groupNames ) )

    % Find all face elements in mesh.
    lineTypeIdx = find( elementTypesData(:,2) == 1 );
    lineElementIdx = [];
    for k=1:length( lineTypeIdx )
      lineElementIdx = [ lineElementIdx , find( mesh.elementTypes == lineTypeIdx(k) ) ];
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
      if( groupType ~= 1 )
        error( 'Group name "%s" is not a line type group' , groupNames{k} );
      end % if 

    end % for
 
    lineElementIdx = nonzeros( mesh.groups(:,groupIdx) );

  end % if

  % Number of elements.
  numElements = length( lineElementIdx );
  fprintf( 'Found %d elements to output\n' , numElements );

  % Header line with number of line elements.
  fprintf( fout , '%d\n' , numElements );

  fprintf( 'Wrote header.\n' );

  % Write elements - surf only supports tri3, quad4.
  for k=1:length( lineElementIdx )
    idx = lineElementIdx(k);
    elementType = mesh.elementTypes(idx);
    switch( elementType )
    case 1 % bar2
      elements = nonzeros( mesh.elements(1:2,idx) );
      fprintf( fout , '%e %e %e %e %e %e\n' , mesh.nodes(1,elements(1)) , mesh.nodes(2,elements(1)) ,mesh.nodes(3,elements(1)) , ...
                                              mesh.nodes(2,elements(2)) , mesh.nodes(2,elements(2)) ,mesh.nodes(3,elements(2)) );
    case 2 % bar3
      elements = nonzeros( mesh.elements(1:3,idx) );
      fprintf( fout , '%e %e %e %e %e %e\n' , mesh.nodes(1,elements(1)) , mesh.nodes(2,elements(1)) ,mesh.nodes(3,elements(1)) , ...
                                              mesh.nodes(1,elements(3)) , mesh.nodes(2,elements(3)) ,mesh.nodes(3,elements(3)) );
    otherwise
      error( 'Unsupported element type %d' , elementType );
    end % switch
  end % for

  fprintf( 'Wrote elements.\n' );

  fclose( fout );

  fprintf( 'Closed file.\n' );

end % function


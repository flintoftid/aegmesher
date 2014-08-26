function [ groupIdx ] = meshGetGroupIndices( mesh , groupNames )
%
% meshGetGroupIndices - Get indices of named groups in a mesh.
% 
% [ groupIdx ] = meshGetGroupIndices( mesh , groupNames )
%
% Inputs:
%
% mesh         - structure containing the unstructured mesh. See help for meshReadAmelet().
% groupNames{} - cell array of strings of nmaes of groupsd to find.
%
% Outputs:
%
% groupIdx() - integer array of corresponding group indices.
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

% Author: I. D. Flintoft
% Version 1.0.0

  groupIdx = [];

  for k=1:length( groupNames )

    thisGroupIdx = [];

    for idx=1:mesh.numGroups
      if( strcmp( mesh.groupNames{idx} , groupNames{k} ) )
        thisGroupIdx = idx;
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
    
end % function

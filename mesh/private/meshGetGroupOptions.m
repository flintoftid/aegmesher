function [ groupOptions ] = meshGetGroupOptions( groupIdx , options )
%
% meshGetGroupOptions - Get all options for a mesh group.
% 
% [ groupOptions ] = meshGetGroupOption( groupIdx )
%
% Inputs:
%
% groupIdx   - scalar integer, index of group to find option for.
% options    - structure containing options - see help for meshSetDefaultOptions.
%
% Outputs:
%
% groupOptions - structure containing group options - see help for 
%                meshSetDefaultOptions.
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
% Date: 25/07/2013
% Version: 1.0.0

  groupOptions = options.default;
  optionNames = fieldnames( options.default );

  for optIdx=1:length( optionNames )
    if( isfield( options.group(groupIdx) , optionNames{optIdx} ) )
      optionValue = getfield( options.group(groupIdx) , optionNames{optIdx} );
      if( ~isempty( optionValue ) )
        groupOptions = setfield( groupOptions , optionNames{optIdx} , optionValue );
      end % if   
    end % if
  end % for

end % function

function [ optionValue ] = meshGetGroupOption( groupIdx , options , optionName )
%
% meshGetGroupOption - Get value of single option for a mesh group.
% 
% [ optionValue ] = meshGetGroupOption( groupIdx , options , optionName )
%
% Inputs:
%
% groupIdx   - scalar integer, index of group to find option for.
% options    - structure containing options - see help for meshSEtDefaultOptions.
% optionName - string, name of option to find value for. 
%
% Outputs:
%
% optionValue - value of option.
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

  if( isfield( options.group(groupIdx) , optionName ) )
    optionValue = getfield( options.group(groupIdx) , optionName );
    if( isempty( optionValue ) )
      if( isfield( options.default , optionName ) )
        optionValue = getfield( options.default , optionName );
      else
        error( 'Invalid option %s' , optionName );
      end % if
    end % if
  else
    error( 'Unknown group index %d' , groupIdx );
  end % if

end % function

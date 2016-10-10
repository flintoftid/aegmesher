function meshGmsh2Wire( wireFileName , mshFileName , groupNames )
%
% meshGmsh2wire: Export wires from a Gmsh mesh into a CONCEPT wire file.
%
% Usage:
%
% meshGmsh2Wire( wireFileName , mshFileName , [ , groupNames ] )
%
% Inputs:
%
% wireFileName - string, name of CONCEPT wire file to create.
% mshFileName  - string, name of gmsh mesh file to read.
% groupNames{} - cell array of strings, names of surfaces to export.
%                Default: export all supported surface elements.
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
% Date: 19/10/2012
% Version: 1.0.0

  [ mesh ] = meshReadGmsh( mshFileName );

  if( nargin == 2 )
    meshWriteWire( wireFileName , mesh );
  else
    meshWriteWire( wireFileName , mesh , groupNames );
  end % if

end % function

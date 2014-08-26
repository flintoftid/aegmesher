function meshGmsh2Surf( surfFileName , mshFileName , groupNames )
%
% meshGmsh2Surf: Export surfaces from a Gsmh mesh into a CONCEPT surf file.
%
% Usage:
%
% meshGmsh2Surf( surfFileName , mshFileName , [ , groupNames ] )
%
% Inputs:
%
% surfFileName - string, name of CONCEPT surf file to create.
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
% Date: 30/09/2012
% Version: 1.0.0

  [ mesh ] = meshReadGmsh( mshFileName );

  if( nargin == 2 )
    groupNames = {};
  end % if

  meshWriteSurf( surfFileName , mesh , groupNames );

end % function


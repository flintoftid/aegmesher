function meshSurf2Gmsh( mshFileName , surfFileName , groupName )
%
% meshSurf2Gmsh: Export surfaces a CONCEPT surf file to a Gmsh file.
%
% Usage:
%
% meshSurf2Gmsh( mshFileName , surfFileName , [ , groupName ] )
%
% Inputs:
%
% mshFileName  - string, name of gmsh mesh file to create.
% surfFileName - string, name of CONCEPT surf file to read.
% groupName    - string, name of surface, default 'Surface-1'
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
% Date: 04/08/2014
% Version: 1.0.0

  if( nargin == 2 )
    groupName = 'Surface-1';
  end % if
  
  [ mesh ] = meshReadSurf( surfFileName , groupName );

  meshWriteGmsh( mshFileName , mesh );

end % function

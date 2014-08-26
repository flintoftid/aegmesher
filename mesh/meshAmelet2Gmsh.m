function meshAmelet2Gmsh( mshFileName , h5FileName , meshGroupName , meshName )
%
% meshAmelet2Gsmh - Convert an AMELET-HDF mesh into a Gmsh mesh. 
%
% Usage:
%
% meshAmelet2Gmsh( mshFileName , h5FileName , meshGroupName , meshName )
%
% Inputs:
%
% mshFileName   - string, name of gmsh mesh file to create.
% h5FileName    - string, name of AMELET HDF file to read.
% meshGroupName - string, name of mesh group to read. 
% meshName      - string, name of mesh to read.
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
% Date: 28/06/2010
% Version: 1.0.0

  [ mesh ] = meshReadAmelet( h5FileName , meshGroupName , meshName );
  meshWriteGmsh( mshFileName , mesh );

end % function

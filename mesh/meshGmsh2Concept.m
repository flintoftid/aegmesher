function meshGmsh2Concept( mshFileName )
%
% meshGmsh2Concept: Export surfaces and wires from a Gsmh mesh 
%                   into CONCEPT surf.1 and wire.0 files.
%
% Usage:
%
% meshGmsh2Concept( mshFileName )
%
% Inputs:
%
% mshFileName  - string, name of gmsh mesh file to read.
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
  meshWriteSurf( 'surf.1' , mesh );
  meshWriteWire( 'wire.0' , mesh );

end % function

function meshAmelet2GmshSlow( mshFileName , h5FileName , meshGroupName , meshName , groupTypes )
%
% meshAmelet2GsmhSlow: Convert an AMELET mesh into a Gmsh mesh. 
%
% Usage:
%
% meshAmelet2GmshSlow( mshFileName , h5FileName , meshGroupName , meshName [, groupTypes ] )
%
% Inputs:
%
% mshFileName   - string, name of gmsh mesh file to create.
% h5FileName    - string, name of AMELET HDF file to read.
% meshGroupName - string, name of mesh group to read. 
% meshName      - string, name of mesh to read.
% groupTypes()  - integer(numGroups), array of group types.
%                 This parameters is to enable a work around for the lack of 
%                 support in octave for importing HDF attributes. By default 
%                 all groups are assumed to be face element groups. If this 
%                 is not the group types *must* be specified manually using
%                 this parameter.

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
%
% Limitations:
%
% This function uses meshReadAmelet() that only work with Octave.
%

  if( nargin == 4 )
    [ mesh ] = meshReadAmelet( h5FileName , meshGroupName , meshName );
    meshWriteGmsh( mshFileName , mesh );
  elseif( nargin == 5 )
    [ mesh ] = meshReadAmelet( h5FileName , meshGroupName , meshName , groupTypes );
    meshWriteGmsh( mshFileName , mesh );
  else
    error( 'Expecting 4 or 5 arguments and received %d' , nargin );
  end % if

end % function

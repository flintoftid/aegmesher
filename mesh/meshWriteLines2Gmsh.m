function meshWriteLines2Gmsh( fileName , lines , objectMesh )
%
% meshWriteLines2Gmsh - Write structured mesh lines into an unstructured
%                       representation in a Gmsh file, optionally merged with 
%                       another unstructured mesh.
%
% Usage:
%
% meshWriteLines2Gmsh( fileName , lines [ , objectMesh ] )
%
% Inputs:
%
% fileName   - string, pathname of the Gmsh file to create.
% lines      - structure containing mesh lines.
% objectMesh - structure containing the unstructured mesh. If absent
%              only the lines are rendered.
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

% Author: M. Berens
% Date: 12/10/2013
% Version 1.0.0

% Author: I. D. Flintoft
% Date: 31/10/2013
% Version 1.1.0
% Refactored mesh merging into separate function.
% Changed group names to match vulture.
% Changed semantics of unstructured mesh surface elements to match Vulture.

  % Short cuts.
  x = lines.x;
  y = lines.y;
  z = lines.z;

  % Create empty structured mesh.
  smesh = [];
  smesh.dimension = 3;
  smesh.lines = lines;
  smesh.elements = zeros( length( x ) , length( y ) , length( z ) , 4 , 'int8' );
  smesh.numGroups = 0;
  smesh.groupNames = {};
  smesh.groupTypes = [];

  % Create six element groups for the representation of each cube face.
  smesh.numGroups = 6;
  smesh.groupNames{1} = 'ZLO';
  smesh.groupNames{2} = 'ZHI';
  smesh.groupNames{3} = 'YLO';
  smesh.groupNames{4} = 'YHI';
  smesh.groupNames{5} = 'XLO';
  smesh.groupNames{6} = 'XHI';

  % Group type of the cube faces are set as surface (groupTypes = 2).
  smesh.groupTypes(1:6) = 2;

  % ZLO plane.
  smesh.elements(1:end-1,1:end-1,1,2) = 1;
  % ZHI plane.
  smesh.elements(1:end-1,1:end-1,end,2) = 2;
  % YLO plane.
  smesh.elements(1:end-1,1,1:end-1,4) = 3;
  % YHI plane.
  smesh.elements(1:end-1,end,1:end-1,4) = 4;
  % XLO plane.
  smesh.elements(1,1:end-1,1:end-1,3) = 5;
  % XHI plane.
  smesh.elements(end,1:end-1,1:end-1,3) = 6;

  % Convert mesh lines into unstructured mesh.
  [ lineMesh ] = meshSmesh2Unmesh( smesh );
  clear smesh;

  % Add combine unstrucured mesh of object and mesh lines.
  if( nargin == 3 )
    [ mesh ] = meshMergeUnstructured( lineMesh , objectMesh );
  else
    mesh = lineMesh;
  end % if

  % Create Gmsh file with unstructured mesh of object and mesh lines
  meshWriteGmsh( fileName , mesh );

end % function

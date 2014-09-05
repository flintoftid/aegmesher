function meshTutorialExample()
%
% meshTutorialExample - Driver for the tutorial example.
%
% Usage:
%
% meshTutorialExample()
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
% Date: 03/09/2014
% Version 1.0.0
   
  % Import the unstructured mesh.
  [ mesh ] = meshReadGmsh( 'tutorial.msh' );

  % Save the unstructured mesh to a mat file.
  meshSaveMesh( 'tutorial_input_mesh.mat' , mesh );

  % Set the default meshing options.
  % For each object we do not use density constraints but give a range of mesh size - equal for a cubic mesh.
  [ options ] = meshSetDefaultOptions( mesh.numGroups , 'useDensity' , false , 'dmin' , 1e-2 , 'dmax' , 1e-2 );

  % We will generate a uniform cubic mesh.
  options.mesh.meshType = 'CUBIC';
  
  % The computational volume is not specified in the input mesh.
  options.mesh.useMeshCompVol = false;
  
  % The computational volume is defined here by its bounding box.
  options.mesh.compVolAABB = [ 0.0 , 0.0 , 0.0 , 0.5 , 0.6 , 0.3 ];
  
  % Do not use mesh density contraints the computational (free space around the objects).
  options.mesh.useDensity = false ;
  
  % So we must give the constraints on mesh size - equal for a cubic mesh.
  options.mesh.dmin = 1e-2;
  options.mesh.dmax = 1e-2;  

  % Construct to list of group names to be mapped onto the structured mesh.
  groupNamesToMap = { 'A1' , 'EN' , 'PA' , 'PB' , 'SW' }; 
  
  % Get the index of each group in the input mesh.
  groupIdxToMap = meshGetGroupIndices( mesh , groupNamesToMap );
  idxA1 = groupIdxToMap(1);
  idxEN = groupIdxToMap(2);
  idxPA = groupIdxToMap(3);
  idxPB = groupIdxToMap(4);  
  idxSW = groupIdxToMap(5);
  
  % 
  % Now for each group to be meshed we provide the mapping options.
  %
  
  % Physical group A1 - closed surface of volumetric object.
  options.group(idxA1).type = 'VOLUME';
  options.group(idxA1).materialName = 'LS22';
  
  % Physical group EN - open metal surface.
  options.group(idxEN).type = 'SURFACE';
  options.group(idxEN).materialName = 'PEC';
  
  % Physical group PA - wire.
  options.group(idxPA).type = 'LINE';
  options.group(idxPA).materialName = 'PEC';
  
  % Physical group PB - wire.
  options.group(idxPB).type = 'LINE';
  options.group(idxPB).materialName = 'PEC';

  % Physical group SW - wire.
  options.group(idxSW).type = 'LINE';
  options.group(idxSW).materialName = 'PEC';
  
  % Generate mesh lines.
  [ lines ] = meshCreateLines( mesh , groupNamesToMap , options );
   
  % Map the groups onto the structured mesh.
  [ smesh ] = meshMapGroups( mesh , groupNamesToMap , lines , options );
  
  % Save the structured mesh to a mat file. 
  meshSaveMesh( 'tutorial_structured_mesh.mat' , smesh );
  
  % Convert the structured mesh back into unstructured format.
  [ unmesh ] = meshSmesh2Unmesh( smesh );
  
  % Export unstructured format of the structured mesh into Gmsh format.
  meshWriteGmsh( 'tutorial_structured_mesh.msh' , unmesh );

  % Export the structured mesh to the target solver.
  options.vulture.useMaterialNames = false;
  meshWriteVulture( 'vulture.mesh' , smesh , options );

end % function

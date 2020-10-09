function meshJet()
% Author: I. D. Flintoft
% Date: 29/09/2016
% Version 1.0.0
   
  testName = 'Jet';
  
  % Import unstructured mesh.
  [ mesh ] = meshReadGmsh( [ testName , '.msh' ] );
  
  % Save the unstructured mesh.
  meshSaveMesh( [ testName , '_input_mesh' , '.mat' ] , mesh );

  % Set meshing options using function is test source directory.
  [ options ] = meshSetDefaultOptions( mesh.numGroups , 'useDensity' , false , 'dmin' , 2 , 'dmax' , 2 );
  options.mesh.meshType = 'CUBIC';
  options.mesh.useMeshCompVol = false;
  options.mesh.useDensity = false;
  options.mesh.dmin = 2;
  options.mesh.dmax = 2;  
 
  groupNamesToMap = { 'Jet' }; 
  groupIdxToMap = meshGetGroupIndices( mesh , groupNamesToMap );
  idxJet = groupIdxToMap(1);
  options.group(idxJet).type = 'SURFACE';
  options.group(idxJet).materialName = 'PEC';
  
  % Generate mesh lines.
  [ lines ] = meshCreateLines( mesh , groupNamesToMap , options );
   
  % Map groups onto structured mesh.
  [ smesh ] = meshMapGroups( mesh , groupNamesToMap , lines , options );
  
  % Save the structured mesh. 
  meshSaveMesh( [ testName , '_structured_mesh' , '.mat' ] , smesh );
  
  % Convert structured mesh into unstructured format.
  [ unmesh ] = meshSmesh2Unmesh( smesh );
  
  % Export structured mesh in Gmsh format.
  meshWriteGmsh( 'structuredMesh.msh' , unmesh );

end % function

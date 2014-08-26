function  [ groupNamesToMap , options ] = meshTestCube( mesh )

  [ options ] = meshSetDefaultOptions( mesh.numGroups , 'useDensity' , false , 'dmin' , 10e-2 , 'dmax' , 10e-2 );

  options.mesh.meshType = 'CUBIC';
  options.mesh.useMeshCompVol = false;
  options.mesh.useDensity = false;
  options.mesh.dmin = 10e-2;
  options.mesh.dmax = 10e-2;  

  groupNamesToMap = { 'Cube' }; 
  groupIdxToMap = meshGetGroupIndices( mesh , groupNamesToMap );
  
  % Cube.
  idxCube = groupIdxToMap(1);
  options.group(idxCube).type = 'VOLUME';
  options.group(idxCube).materialName = 'PEC';

end % function

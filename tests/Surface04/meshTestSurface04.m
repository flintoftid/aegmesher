function [ groupNamesToMap , options ] = meshTestSurface04( mesh )

  [ options ] = meshSetDefaultOptions( mesh.numGroups , 'materialName' , 'FREE_SPACE' );

  options.mesh.useMeshCompVol = false;
  options.mesh.useDensity = false;
  options.mesh.dmin = 0.05;  
  options.mesh.dmax = 0.05;  

  groupNamesToMap = { 'Surface04' }; 
  groupIdxToMap = meshGetGroupIndices( mesh , groupNamesToMap );

  idxSurface04 = 1;
  options.group(idxSurface04).materialName = 'PEC';
  options.group(idxSurface04).type = 'SURFACE';
  
end % function

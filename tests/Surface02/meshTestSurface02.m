function [ groupNamesToMap , options ] = meshTestSurface02( mesh )

  [ options ] = meshSetDefaultOptions( mesh.numGroups , 'materialName' , 'FREE_SPACE' );

  options.mesh.useMeshCompVol = false;
  options.mesh.useDensity = false;
  options.mesh.dmin = 0.1;  
  options.mesh.dmax = 0.1;  

  groupNamesToMap = { 'Surface02' }; 
  groupIdxToMap = meshGetGroupIndices( mesh , groupNamesToMap );

  idxSurface02 = 1;
  options.group(idxSurface02).materialName = 'PEC';
  options.group(idxSurface02).type = 'SURFACE';

end % function

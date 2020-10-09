function [ groupNamesToMap , options ] = meshTestSurface03( mesh )

  [ options ] = meshSetDefaultOptions( mesh.numGroups , 'materialName' , 'FREE_SPACE' );

  options.mesh.useMeshCompVol = false;
  options.mesh.useDensity = false;
  options.mesh.dmin = 0.2;  
  options.mesh.dmax = 0.2;  

  groupNamesToMap = { 'Surface03' }; 
  groupIdxToMap = meshGetGroupIndices( mesh , groupNamesToMap );

  idxSurface03 = 1;
  options.group(idxSurface03).materialName = 'PEC';
  options.group(idxSurface03).type = 'SURFACE';

end % function

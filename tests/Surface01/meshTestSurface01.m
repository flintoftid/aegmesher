function [ groupNamesToMap , options ] = meshTestSurface01( mesh )

  [ options ] = meshSetDefaultOptions( mesh.numGroups , 'materialName' , 'FREE_SPACE' );

  options.mesh.useMeshCompVol = false;
  options.mesh.useDensity = false;
  options.mesh.dmin = 0.1;  
  options.mesh.dmax = 0.1; 

  groupNamesToMap = { 'Surface01' }; 
  groupIdxToMap = meshGetGroupIndices( mesh , groupNamesToMap );

  idxSurface01 = 1;
  options.group(idxSurface01).materialName = 'PEC';
  options.group(idxSurface01).type = 'SURFACE';
  
end % function


function [ groupNamesToMap , options ] = meshTestSolid01( mesh )

  [ options ] = meshSetDefaultOptions( mesh.numGroups );

  options.mesh.useMeshCompVol = false;
  options.mesh.useDensity = true;
  options.mesh.Dmin = 10;  
  options.mesh.Dmax = 20;  
  options.mesh.minFreq = 1e6;
  options.mesh.maxFreq = 100e6;

  groupNamesToMap = { 'Solid01' }; 
  groupIdxToMap = meshGetGroupIndices( mesh , groupNamesToMap );

  idxSolid01 = 1;
  options.group(idxSolid01).materialName = 'FREE_SPACE';
  options.group(idxSolid01).type = 'VOLUME';

end % function


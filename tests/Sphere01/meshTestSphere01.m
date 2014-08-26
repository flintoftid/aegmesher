function [ groupNamesToMap , options ] = meshTestSphere01( mesh )

  [ options ] = meshSetDefaultOptions( mesh.numGroups );

  options.mesh.useMeshCompVol = false;
  options.mesh.useDensity = true;
  options.mesh.Dmin = 10;  
  options.mesh.Dmax = 20;  
  options.mesh.minFreq = 1e3;
  options.mesh.maxFreq = 2e6;

  groupNamesToMap = { 'Sphere01' }; 
  groupIdxToMap = meshGetGroupIndices( mesh , groupNamesToMap );

  idxSphere01 = 1;
  options.group(idxSphere01).materialName = 'FREE_SPACE';
  options.group(idxSphere01).type = 'VOLUME';
  %options.group(idxSphere01).rayDirections = 'z';
  %options.group(idxSphere01).reduceMethod = 'DICTATOR';
  
end % function

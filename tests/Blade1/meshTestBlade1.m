function [ groupNamesToMap , options ] = meshTestBlade1( mesh )

  [ options ] = meshSetDefaultOptions( mesh.numGroups , 'useDensity' , false , 'dmin' , 1e-2 , 'dmax' , 1e-2 );

  options.mesh.meshType = 'CUBIC';
  options.mesh.useMeshCompVol = false;
  %options.mesh.compVolAABB = [ 0.0 , 0.0 , 0.0 , 0.5 , 0.6 , 0.3 ];
  options.mesh.useDensity = false ;
  options.mesh.dmin = 1e-2;
  options.mesh.dmax = 1e-2;  

  groupNamesToMap = { 'GroundPlane' , 'Blade' , 'FeedBlock' , 'FeedLine' , 'Dielectric' }; 
  groupIdxToMap = meshGetGroupIndices( mesh , groupNamesToMap );
  
  % Ground plane.
  idxGroundPlane = groupIdxToMap(1);
  options.group(idxGroundPlane).type = 'SURFACE';
  options.group(idxGroundPlane).materialName = 'PEC';
  
  % Blade.
  idxBlade = groupIdxToMap(2);
  options.group(idxBlade).type = 'SURFACE';
  options.group(idxBlade).materialName = 'PEC';
  
  % Feed block.
  idxFeedBlock = groupIdxToMap(3);
  options.group(idxFeedBlock).type = 'VOLUME';
  options.group(idxFeedBlock).materialName = 'PEC';

  % Feed line.
  idxFeedLine = groupIdxToMap(4);
  options.group(idxFeedLine).type = 'LINE';
  options.group(idxFeedLine).materialName = 'PEC';
  
  % Dielectric.
  idxDielectric = groupIdxToMap(5);
  options.group(idxDielectric).type = 'VOLUME';
  options.group(idxDielectric).materialName = 'LS22';
  options.group(idxDielectric).rayDirections = 'xyz';
  options.group(idxDielectric).reduceMethod = 'DICTATOR';
  options.group(idxDielectric).isUseInterpResolver = true;

end % function


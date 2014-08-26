function [ groupNamesToMap , options ] = meshTestWireBox( mesh )

  [ options ] = meshSetDefaultOptions( mesh.numGroups , 'useDensity' , false , 'dmin' , 1e-2 , 'dmax' , 1e-2 );

  options.mesh.meshType = 'CUBIC';
  options.mesh.useMeshCompVol = false;
  options.mesh.compVolAABB = [ 0.0 , 0.0 , 0.0 , 0.5 , 0.6 , 0.3 ];
  options.mesh.useDensity = false ;
  options.mesh.dmin = 1e-2;
  options.mesh.dmax = 1e-2;  

  groupNamesToMap = { 'A1' , 'A2' , 'EN' , 'GP' , 'PA' , 'PB' , 'CW' }; 
  groupIdxToMap = meshGetGroupIndices( mesh , groupNamesToMap );
  
  % Physical group A1.
  idxA1 = groupIdxToMap(1);
  options.group(idxA1).type = 'VOLUME';
  options.group(idxA1).materialName = 'LS22';
  
  % Physical group A2.
  idxA2 = groupIdxToMap(2);
  options.group(idxA2).type = 'VOLUME';
  options.group(idxA2).materialName = 'LS22';
  
  % Physical group EN.
  idxEN = groupIdxToMap(3);
  options.group(idxEN).type = 'SURFACE';
  options.group(idxEN).materialName = 'PEC';

  % Physical group GP.
  idxGP = groupIdxToMap(4);
  options.group(idxGP).type = 'SURFACE';
  options.group(idxGP).materialName = 'PEC';
  %options.group(idxGP).epsRayEnds = 1e-3;
  
  % Physical group PA.
  idxPA = groupIdxToMap(5);
  options.group(idxPA).type = 'LINE';
  options.group(idxPA).materialName = 'PEC';
  
  % Physical group PB.
  idxPB = groupIdxToMap(6);
  options.group(idxPB).type = 'LINE';
  options.group(idxPB).materialName = 'PEC';

  % Physical group CW.
  idxCW = groupIdxToMap(7);
  options.group(idxCW).type = 'LINE';
  options.group(idxCW).materialName = 'PEC';

end % function

function [ groupNamesToMap , options ] = meshTestPlane01( mesh )

  [ options ] = meshSetDefaultOptions( mesh.numGroups , 'useDensity' , false , 'dmin' , 10e-2 , 'dmax' , 10e-2 , 'isUseInterpResolver' , true );

  options.mesh.meshType = 'CUBIC';
  options.mesh.useDensity = false;
  options.mesh.dmin = 10e-2;
  options.mesh.dmax = 10e-2;
  options.mesh.isPlot = false;
  options.vulture.useMaterialNames = false;

  groupNamesToMap = { 'Plane01' , 'CompVolume' }; 
  groupIdxToMap = meshGetGroupIndices( mesh , groupNamesToMap );

  % plane1.
  idxPlane1 = groupIdxToMap(1);
  options.group(idxPlane1).type = 'THICK_SURFACE';
  options.group(idxPlane1).thickness = 42e-2;
  options.group(idxPlane1).materialName = 'PEC';
  options.group(idxPlane1).rayDirections = 'x';

  % CV.
  idxCV = groupIdxToMap(2);
  options.group(idxCV).type = 'BBOX';
  options.group(idxCV).materialName = 'FREE_SPACE';

end % function


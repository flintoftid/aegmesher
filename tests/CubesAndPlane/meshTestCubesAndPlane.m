function [  groupNamesToMap , options ] = meshTestCubesAndPlane( mesh )

  [ options ] = meshSetDefaultOptions( mesh.numGroups , 'useDensity' , false , 'dmin' , 5e-2 , 'dmax' , 10e-2 , 'isUseInterpResolver' , true );

  options.mesh.meshType = 'CUBIC';
  options.mesh.lineAlgorithm = 'OPTIM1';
  options.mesh.costAlgorithm = 'RMS';
  options.mesh.epsCoalesceLines = 4e-3;
  options.mesh.minFreq = 1e6;
  options.mesh.maxFreq = 3e9;
  options.mesh.isPlot = false;
  options.mesh.epsCoalesceLines = 1e-4;
  options.mesh.epsCompVol = 0;
  options.vulture.useMaterialNames = false;

  groupNamesToMap = { 'cube1' , 'cube2' , 'cube3' , 'plane1' , 'CompVolume' }; 
  groupIdxToMap = meshGetGroupIndices( mesh , groupNamesToMap );

  % cube1.
  idxCube1 = groupIdxToMap(1);
  options.group(idxCube1).type = 'SURFACE';
  options.group(idxCube1).materialName = 'PEC';
  options.group(idxCube1).rayDirections = 'x';
 
  % cube2.
  idxCube2 = groupIdxToMap(2);
  options.group(idxCube2).type = 'VOLUME';
  options.group(idxCube2).materialName = 'PEC';
  options.group(idxCube2).rayDirections = 'y';

  % cube3.
  idxCube3 = groupIdxToMap(3);
  options.group(idxCube3).type = 'VOLUME';
  options.group(idxCube3).materialName = 'PEC';
  options.group(idxCube3).rayDirections = 'z';

  % plane1.
  idxPlane1 = groupIdxToMap(4);
  options.group(idxPlane1).type = 'SURFACE';
  options.group(idxPlane1).materialName = 'PEC';
  options.group(idxPlane1).rayDirections = 'x';

  % CV.
  idxCV = groupIdxToMap(5);
  options.group(idxCV).type = 'BBOX';
  options.group(idxCV).materialName = 'FREE_SPACE';

end % function


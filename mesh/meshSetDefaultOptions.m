function [ options ] = meshSetDefaultOptions( numGroups , varargin )
%
% meshSetDefaultOptions - Set default options.
%
% [ options ] = meshSetDefaultOptions( numGroups , varargin )
%
% Inputs:
%
% numGroups - integer. number of groups to set options for.
% varargin  - pairs of option names and values to overide the defaults.
%
%             optionName  - string
%             optionValue - appropriate value of option. 
%
% Outputs:
%
% options - structure containing global and group specific options:
%
%           [FIXME]
%

% 
% This file is part of aegmesher.
%
% aegmesher structured mesh generator and utilities.
% Copyright (C) 2014 Ian Flintoft, Michael Berens & John Dawson
%
% aegmesher is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% aegmesher is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with aegmesher.  If not, see <http://www.gnu.org/licenses/>.
% 

% Author: I. D. Flintoft
% Date: [FIXME]
% Version 1.0.0

  % Per group options defaults.
  options.default = struct( 'type'                  , 'VOLUME'    , ...
                            'physicalType'          , 'MATERIAL'  , ...
                            'materialName'          , 'PEC'       , ...
                            'useDensity'            , true        , ...
                            'Dmin'                  , 10          , ...
                            'Dmax'                  , 20          , ...
                            'dmin'                  , 1e-2        , ...
                            'dmax'                  , 1e-2        , ...
                            'thickness'             , 0.0         , ...
                            'isValidNormals'        , false       , ...
                            'isInvertNormals'       , false       , ...
                            'precedence'            , 1           , ...
                            'weight'                , 1           , ...                            
                            'rayDirections'         , 'xyz'       , ...
                            'reduceMethod'          , 'CONCENSUS' , ...                           
                            'splitMethod'           , 'SAH'       , ...
                            'maxDepth'              , 15          , ...
                            'minNumElemPerNode'     , 5000        , ...
                            'maxNumElemPerNode'     , Inf         , ...
                            'isPlot'                , false       , ...
                            'isInfiniteRay'         , true        , ...
                            'epsParallelRay'        , 1e-12       , ...
                            'isTwoSidedTri'         , true        , ...
                            'isIncludeRayEnds'      , true        , ...
                            'epsRayEnds'            , 1e-6        , ...
                            'epsUniqueIntersection' , 1e-6        , ...
                            'isUseInterpResolver'   , false       , ...
                            'epsResolver'           , 1e-12       , ...
                            'isUnresolvedInside'    , true        ); 

  % Per group option names.
  optionNames = fieldnames( options.default );

  % Set if valid number of arguments for default options.
  numVarArgs = length( varargin );
  if( rem( numVarArgs , 2 ) ~= 0 )
    error( 'invalid odd number of parameter/value pairs' );
  end % if

  % Update user defined per group default options.
  for optIdx=1:2:numVarArgs
    optName = varargin{optIdx};
    if( isfield( options.default , optName ) )
      options.default.(optName) = varargin{optIdx+1};
    else
      error( 'Invalid default option %s' , optName );
    end % if
  end % if

  % Set default options for all groups.
  options.group = [];
  
  for optIdx=1:length( optionNames )
    options.group = setfield( options.group , {numGroups} , optionNames{optIdx} , [] );
  end % for

  % Mesh line generation options.
  options.mesh.meshType = 'CUBIC';
  options.mesh.lineAlgorithm = 'OPTIM1';
  options.mesh.costAlgorithm = 'RMS';
  options.mesh.epsCoalesceLines = 1e-4;
  options.mesh.useMeshCompVol = true;
  options.mesh.compVolName = 'CompVolume';
  options.mesh.compVolAABB = [];
  options.mesh.compVolIsTight = [ false , false , false , false , false , false ];  
  options.mesh.useDensity = true;
  options.mesh.Dmin = 10;
  options.mesh.Dmax = 20;
  options.mesh.dmin = [];
  options.mesh.dmax = [];      
  options.mesh.epsCompVol = 1e-6;
  options.mesh.maxRatio = 1.5;
  options.mesh.maxAspect = 2.0;
  options.mesh.minFreq = 1e6;
  options.mesh.maxFreq = 3e9;
  options.mesh.numFreqSamp = 50;
  options.mesh.maxOptimTime = 5;
  options.mesh.maxOptimEvals = 10000;
  options.mesh.costFuncTol = 1e-6;
  options.mesh.isPlot = false;

  % Vulture export options.
  options.export.useMaterialNames = false;
  options.export.scaleFactor = 1.0;

end % function

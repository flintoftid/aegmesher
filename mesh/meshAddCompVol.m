function [ smesh ] = meshAddCompVol( smesh )
%
% meshAddCompVol - Add computational volume surface to structured mesh.
%
%
% [ smesh ] = meshAddCompVol( smesh )
%
% Inputs:
%
% smesh - structured mesh.
%
% Outputs:
%
% smesh - structured mesh.
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
% Date: 16/08/2014
% Version 1.0.0

  % Add computational volume groups.
  idxCompVolXLO = smesh.numGroups + 1;
  smesh.groupNames{idxCompVolXLO} = 'CompVolumeXLO';
  idxCompVolXHI = smesh.numGroups + 2;
  smesh.groupNames{idxCompVolXHI} = 'CompVolumeXHI';
  idxCompVolYLO = smesh.numGroups + 3;
  smesh.groupNames{idxCompVolYLO} = 'CompVolumeYLO';
  idxCompVolYHI = smesh.numGroups + 4;
  smesh.groupNames{idxCompVolYHI} = 'CompVolumeYHI';
  idxCompVolZLO = smesh.numGroups + 5;
  smesh.groupNames{idxCompVolZLO} = 'CompVolumeZLO';
  idxCompVolZHI = smesh.numGroups + 6;
  smesh.groupNames{idxCompVolZHI} = 'CompVolumeZHI';
  
  smesh.groupTypes(idxCompVolXLO:idxCompVolZHI) = 2;
  smesh.numGroups = smesh.numGroups + 6;

  % ZLO plane.
  smesh.elements(1:end-1,1:end-1,1,2) = idxCompVolZLO;
  % ZHI plane.
  smesh.elements(1:end-1,1:end-1,end,2) = idxCompVolZHI;
  % YLO plane.
  smesh.elements(1:end-1,1,1:end-1,4) = idxCompVolYLO;
  % YHI plane.
  smesh.elements(1:end-1,end,1:end-1,4) = idxCompVolYHI;
  % XLO plane.
  smesh.elements(1,1:end-1,1:end-1,3) = idxCompVolXLO;
  % XHI plane.
  smesh.elements(end,1:end-1,1:end-1,3) = idxCompVolXHI;

end % function

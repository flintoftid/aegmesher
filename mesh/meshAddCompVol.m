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

  Nx = length( smesh.lines.x );
  Ny = length( smesh.lines.y );
  Nz = length( smesh.lines.z );
  i = 1:Nx;
  j = 1:Ny;
  k = 1:Nz;
  [ ii , jj , kk ] = meshgrid( 1 , j(1:Ny-1) , k(1:Nz-1) );
  smesh.numGroups = smesh.numGroups + 1;
  smesh.groupTypes(smesh.numGroups) = 2;
  smesh.groupNames{smesh.numGroups} = 'CV_XLO';
  smesh.groups{smesh.numGroups} = [ ii(:) , jj(:) , kk(:) , ii(:) , jj(:) + 1 , kk(:) + 1 ];
  [ ii , jj , kk ] = meshgrid( Nx , j(1:Ny-1) , k(1:Nz-1) );
  smesh.numGroups = smesh.numGroups + 1;
  smesh.groupTypes(smesh.numGroups) = 2;
  smesh.groupNames{smesh.numGroups} = 'CV_XHI';
  smesh.groups{smesh.numGroups} = [ ii(:) , jj(:) , kk(:) , ii(:) , jj(:) + 1 , kk(:) + 1 ];
  [ ii , jj , kk ] = meshgrid( i(1:Nx-1) , 1 , k(1:Nz-1) );
  smesh.numGroups = smesh.numGroups + 1;
  smesh.groupTypes(smesh.numGroups) = 2;
  smesh.groupNames{smesh.numGroups} = 'CV_YLO';
  smesh.groups{smesh.numGroups} = [ ii(:) , jj(:) , kk(:) , ii(:) + 1 , jj(:) , kk(:) + 1 ];
  [ ii , jj , kk ] = meshgrid( i(1:Nx-1) , Ny , k(1:Nz-1) );
  smesh.numGroups = smesh.numGroups + 1;
  smesh.groupTypes(smesh.numGroups) = 2;
  smesh.groupNames{smesh.numGroups} = 'CV_YHI';
  smesh.groups{smesh.numGroups} = [ ii(:) , jj(:) , kk(:) , ii(:) + 1 , jj(:) , kk(:) + 1 ];  
  [ ii , jj , kk ] = meshgrid( i(1:Nx-1) , j(1:Ny-1) , 1 );
  smesh.numGroups = smesh.numGroups + 1;
  smesh.groupTypes(smesh.numGroups) = 2;
  smesh.groupNames{smesh.numGroups} = 'CV_ZLO';
  smesh.groups{smesh.numGroups} = [ ii(:) , jj(:) , kk(:) , ii(:) + 1 , jj(:) + 1 , kk(:) ];
  [ ii , jj , kk ] = meshgrid( i(1:Nx-1) , j(1:Ny-1) , Nz );
  smesh.numGroups = smesh.numGroups + 1;
  smesh.groupTypes(smesh.numGroups) = 2;
  smesh.groupNames{smesh.numGroups} = 'CV_ZHI';
  smesh.groups{smesh.numGroups} = [ ii(:) , jj(:) , kk(:) , ii(:) + 1 , jj(:) + 1 , kk(:) ];
  
end % function

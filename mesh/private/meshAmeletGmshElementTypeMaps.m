function [ mapGmsh2Amelet , mapAmelet2Gmsh ] = meshAmeletGmshElementTypeMaps()
%
% meshAmeletGmshElementTypeMaps - return mappings between AMELET-HDF and
%                                 Gmsh element types.
%
% [ mapGmsh2Amelet , mapAmelet2Gmsh ] = meshAmeletGmshElementTypeMaps()
%
% Outputs:
%
% mapGmshToAmelet  - sparse array, mapGmsh2Amelet(gmshElemIdx) = ameletElemIdx 
% mapAmelet2Gmsh   - sparse array, mapAmelet2Gmsh(ameletElemIdx) = gmshElemIdx 
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

% Author: I. D Flintoft
% Date: 15/07/2013
% Version: 1.0.0

  mapGmsh2Amelet = sparse( 20 ,  1 );
  
  % Mapping of Gmsh element types to AMELET-HDF types.
  mapGmsh2Amelet(1)  =   1; % bar2
  mapGmsh2Amelet(2)  =  11; % tri3
  mapGmsh2Amelet(3)  =  13; % quad4
  mapGmsh2Amelet(4)  = 101; % tetra4
  mapGmsh2Amelet(5)  = 104; % hex8
  mapGmsh2Amelet(6)  = 103; % penta6
  mapGmsh2Amelet(7)  = 102; % pyra2
  mapGmsh2Amelet(8)  =   2; % bar3
  mapGmsh2Amelet(9)  =  12; % tri6
  mapGmsh2Amelet(11) = 108; % tetra10
  mapGmsh2Amelet(15) = 199; % point - not in AMELET
  mapGmsh2Amelet(17) = 109; % hexa20

  % Mapping of AMELET-HDF element types to Gmsh types.
  idx = nonzeros( mapGmsh2Amelet(:) );
  [ r , c ] = find( mapGmsh2Amelet );
  mapAmelet2Gmsh = sparse( max( idx ) ,  1 );
  mapAmelet2Gmsh(idx) = r;

end % function

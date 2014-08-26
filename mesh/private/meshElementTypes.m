function [ elementTypesData ] = meshElementTypes()
%
% meshElementTypes: Return sparse array containing mesh
%                   element number of nodes and dimensionalities. 
%              
% [ elementTypesData ] = meshElementTypes()
%
% Outputs:
%
% elementTypesData - (var x 2) sparse array containing:
%
%                    elementTypesData(typeNumber,1) - number of nodes for type
%                    elementTypesData(typeNumber,2) - dimensionality of type
%    
%                    where typeNumber is the AMELET type number of the element.
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
% Date: 17/06/2010
% Version: 1.0.0

  % Element type: number of nodes and group type.
  % Indexed by AMELET element type!
  elementTypesData = sparse( 200 , 2 );
  elementTypesData(  1,1:2) = [  2 , 1 ]; % bar2
  elementTypesData(  2,1:2) = [  3 , 1 ]; % bar3
  elementTypesData( 11,1:2) = [  3 , 2 ]; % tri3
  elementTypesData( 12,1:2) = [  6 , 2 ]; % tri6
  elementTypesData( 13,1:2) = [  4 , 2 ]; % quad4
  elementTypesData(101,1:2) = [  4 , 3 ]; % tetra4
  elementTypesData(102,1:2) = [  2 , 3 ]; % pyra2
  elementTypesData(103,1:2) = [  6 , 3 ]; % penta6
  elementTypesData(104,1:2) = [  8 , 3 ]; % hexa8
  elementTypesData(108,1:2) = [ 10 , 3 ]; % tetra10
  elementTypesData(109,1:2) = [ 20 , 3 ]; % hexa20
  elementTypesData(199,1:2) = [  1 , 0 ]; % point - not in AMELET

end % function

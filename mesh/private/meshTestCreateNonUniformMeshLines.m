function meshTestCreateNonUniformMeshLines()
% meshTestCreateNonUniformMeshLines - test nonuniform mesh line generation

% Version 1.0.0 - Cubic and uniform meshes only.
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

  X       = [ 1.0  , 2.0  , 3.0  , 4.4  , 5.0  , 5.2  , 5.7  , 8.3  , 8.9  , 10.0 ];
  Xweight = [ 1.0  , 1.0  , 1.0  , 1.0  , 1.0  , 1.0  , 1.0  , 1.0  , 1.0  ,  1.0 ];  
  dmin    = [ 0.01 , 0.01 , 0.01 , 0.01 , 0.01 , 0.01 , 0.01 , 0.01 , 0.01 ];
  dmax    = [ 0.05 , 0.04 , 0.01 , 0.02 , 0.03 , 0.03 , 0.04 , 0.06 , 0.04 ];
  
  dirChar = 'x';
  
  options.maxRatio = 1.025;
  
  [ x ] = meshCreateNonUniformMeshLines( X , Xweight , dmin , dmax , dirChar , options );

end % function


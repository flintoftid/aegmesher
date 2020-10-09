function meshTestCreateNonUniformMeshLinesMB()
% meshTestCreateNonUniformMeshLinesMB - test nonuniform mesh line generation

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
  
  meshGroup = [ 1.0 , 2.0 , 0.05 ; ...
                2.0 , 3.0 , 0.04 ; ...
                3.0 , 4.4 , 0.01 ; ...
                4.4 , 5.0 , 0.02 ; ...
                5.0 , 5.2 , 0.03 ; ...
                5.2 , 5.7 , 0.03 ; ...
                5.7 , 8.3 , 0.04 ; ...
                8.3 , 8.9 , 0.06 ; ...
                8.9 , 10.0 , 0.04 ];
  
  dirChar = 'x';
  options.maxRatio = 1.3;
  
  [ x ] = meshCreateNonUniformMeshLinesMB( meshGroup , options.maxRatio , dmin(1) , 0.08 , dirChar );
  %[ x ] = meshCreateNonUniformMeshInterval( meshGroup , options.maxRatio , dmin(1) , 0.08 , dirChar );
  
  figure();
  xc = [];
  dc = [];
  mc = [];
  for i=1:size( meshGroup , 1 )
    xc = [ xc ; meshGroup(i,1) ; meshGroup(i,2) ];
    dc = [ dc ; meshGroup(i,3) ; meshGroup(i,3) ];
    mc = [ mc ;        dmin(1) ;        dmin(1) ];
  end % for
  plot( xc , dc , 'r-o;{\Delta x}_{max};' , 'markerSize' , 5 , 'markerFaceColor' , 'red' , 'lineWidth' , 4 );  
  hold on;
  plot( xc , mc , 'g-o;{\Delta x}_{min};' , 'markerSize' , 5 , 'markerFaceColor' , 'green' , 'lineWidth' , 4 );    
  plot( x(1:end-1) , diff( x ) , 'b-o;{\Deltax }_i;' , 'markerSize' , 3 , 'markerFaceColor' , 'blue' , 'lineWidth' , 2 );
  legend( 'location' , 'northwest' );
  xlabel( sprintf( 'mesh line coordinate, %s_i' , dirChar ) );
  ylabel( 'mesh size, \Delta x_i' );
  title( sprintf( 'r_{max} = %.2f' , options.maxRatio ) );
  grid on;

  print( '-depsc2' , 'intervals.eps' );
  hold off;
  
end % function

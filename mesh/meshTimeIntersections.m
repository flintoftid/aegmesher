function meshTimeIntersections( maxNumElements )
%
% meshTimeIntersections - Time intersection routines and calculate
%                         cost mode lfor tuning BVH.
%
% Usage:
%
% meshTimeIntersections( maxNumElements )
%
% Inputs:
%
% maxNumElements - integer, maximum number of elements in tests.
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
% Date: 12/08/2014
% Version 1.0.0


  options.isInfiniteRay = true;
  options.epsParallelRay = 1e-12;
  options.isTwoSidedTri = true;
  options.isIncludeRayEnds = true;
  options.epsRayEnds = 1e-12;

  numElements = unique( floor( logspace( log10(1) , log10(maxNumElements) , 30 ) ) );

  times1 = zeros( size( numElements ) );
  percent1 = zeros( size( numElements ) );
  times2 = zeros( size( numElements ) );
  percent2 = zeros( size( numElements ) );
  times3 = zeros( size( numElements ) );
  percent3 = zeros( size( numElements ) );
  
  for idx=1:length( numElements )

    thisNumElements = numElements(idx);

    vert1 = rand( 3 , thisNumElements );
    vert2 = rand( 3 , thisNumElements );
    vert3 = rand( 3 , thisNumElements );
    origin = [ 0 ; 0 ; 0 ];
    dir = [ 1 ; 1 ; 1 ];

    % Use function which requires taking transposes and using repmat externally.
    tic();
    %profile( 'on' );
    vert1t = vert1';
    vert2t = vert2';
    vert3t = vert3';
    origins = repmat( origin' , thisNumElements , 1 );
    dirs = repmat( dir' , thisNumElements , 1 );
    [ isIntersect1 , tt1 , u1 , v1 , isFrontFacing1 ] = ...
       meshTriRayIntersection1( origins , dirs , vert1t , vert2t , vert3t , options );
    %profile( 'off' );
    %P1 = profile( 'info' );
    %profile( 'clear');
    times1(idx) = toc();
    percent1(idx) = 100 * sum( isIntersect1 ) / thisNumElements;

    % Use which requires taking transposes externally and uses repmat internally.
    tic();
    %profile( 'on' );
    vert1t = vert1';
    vert2t = vert2';
    vert3t = vert3';
    [ isIntersect2 , tt2 , u2 , v2 , isFrontFacing2 ] = ...
      meshTriRayIntersection2( origin' , dir' , vert1t , vert2t , vert3t , options );
    %profile( 'off');
    %P2 = profile( 'info' );
    %profile( 'clear');
    times2(idx) = toc();
    percent2(idx) = 100 * sum( isIntersect2 ) / thisNumElements;
    assert( all( isIntersect2 == isIntersect1 ) );
    assert( all( abs( tt2 - tt1 ) < 100 * eps ) );
    assert( all( abs( u2 - u1 ) < 100 * eps ) );
    assert( all( abs( v2 - v1 ) < 100 * eps ) );
    assert( all( isFrontFacing2 == isFrontFacing1 ) );
    
    % Use function that doesn't require taking transpose and uses repmat/bsxfun internally.
    tic();
    %profile( 'on' );
    [ isIntersect3 , tt3 , u3 , v3 , isFrontFacing3 ] = ...
       meshTriRayIntersection3( origin , dir , vert1 , vert2 , vert3 , options );
    %profile( 'off');
    %P3 = profile( 'info' );
    %profile( 'clear');
    times3(idx) = toc();
    percent3(idx) = 100 * sum( isIntersect3 ) / thisNumElements;
    assert( all( isIntersect3' == isIntersect1 ) );
    assert( all( abs( tt3' - tt1 ) < 100 * eps ) );
    assert( all( abs( u3' - u1 ) < 100 * eps ) );
    assert( all( abs( v3' - v1 ) < 100 * eps ) );
    assert( all( isFrontFacing3' == isFrontFacing1 ) );
    
  end % for
  
  % Fit to t_tri = a * sqrt( N^2 + Nc^2 ) model
  %T = times.^2;
  %N = numElements.^2;
  %p = polyfit( N , T , 1)
  %a = sqrt( p(1) )
  %Nc = sqrt( p(2) ) / a;
  %f=@(p,x) p(1) * sqrt( x^2 + p(2)^2 );
  fval=@(p,x) p(1) * sqrt( x.^2 + p(2)^2 );
  if( exist('OCTAVE_VERSION') )
    popt1 = nonlin_curvefit( fval , [ 1e-7 ; 500 ] , numElements , times1 );
  else
    popt1 = lsqcurvefit( fval , [ 1e-7 ; 500 ], numElements , times1 );
  end % if
  a1 = popt1(1);
  Nc1 = popt1(2);

  if( exist('OCTAVE_VERSION') )
    popt2 = nonlin_curvefit( fval , [ 1e-7 ; 500 ] , numElements , times2 );
  else
    popt2 = lsqcurvefit( fval , [ 1e-7 ; 500 ], numElements , times2 );
  end % if
  a2 = popt2(1);
  Nc2 = popt2(2);
  
  if( exist('OCTAVE_VERSION') )
    popt3 = nonlin_curvefit( fval , [ 1e-7 ; 500 ] , numElements , times3 );
  else
    popt3 = lsqcurvefit( fval , [ 1e-7 ; 500 ], numElements , times3 );
  end % if
  a3 = popt3(1);
  Nc3 = popt3(2);
  
  %
  % Ray-AABB timing.
  %

  bbox = [ 0 , 0 , 0 , 1 , 1 , 1 ];
  invDir = 1 ./ dir;
  dirIsNeg = 3 .* ( dir < 0 );
  mint = -Inf;
  maxt = Inf;
  tic();  
  for idx=1:1000
    [ isIntersection ] = meshBBoxRayIntersection( origin , dir , invDir , dirIsNeg , bbox, options );
  end % for
  timeAABB = toc() / 1000;
  
  % Normalised traversal cost.
  traversalCost1 = timeAABB / a1;
  traversalCost2 = timeAABB / a2;
  traversalCost3 = timeAABB / a3;
    
  % Normalised model.
  fprintf( '\nNormalised cost model 1:\n\n' );
  fprintf( 'costIntersect = sqrt(N^2 + %d^2)\n' , floor( Nc1 ) );
  fprintf( 'costTraversal = %d\n' , floor( traversalCost1 ) );
  fprintf( '\n' );
  fprintf( '\nNormalised cost model 2:\n\n' );
  fprintf( 'costIntersect = sqrt(N^2 + %d^2)\n' , floor( Nc2 ) );
  fprintf( 'costTraversal = %d\n' , floor( traversalCost2 ) );
  fprintf( '\n' );
  fprintf( '\nNormalised cost model 3:\n\n' );
  fprintf( 'costIntersect = sqrt(N^2 + %d^2)\n' , floor( Nc3 ) );
  fprintf( 'costTraversal = %d\n' , floor( traversalCost3 ) );
  fprintf( '\n' );  
  
  %
  % Plots.
  %

  figure(1);
  hl1 = loglog( numElements , times1 , 'r-o' );
  hold on;
  hl2 = loglog( numElements , a1 .* sqrt( numElements.^2 + Nc1.^2 ) , 'b-' );
  hl3 = loglog( numElements , times1 ./ numElements , 'g-^' );
  hl4 = loglog( numElements , timeAABB .* ones( size( numElements ) ) , 'b-' );
  hxl = xlabel( 'Number of elements' );
  hyl = ylabel( 'Time (s)' );
  key2 = sprintf( 'Total ray-elements cost model: %.1e * sqrt(N^2 + %d^2)' , a1 , floor( Nc1 ) );
  key4 = sprintf( 'Single ray-AABB intersect time: %.1e * %d' , a1 , floor( traversalCost1 ) );
  hlg = legend( 'Total ray-elements intersect time' , key2 , 'Single ray-element intersect time' , key4 , 'location' , 'northwest' );
  axis( [ 1e0 , 1e7 , 1e-8 , 1e3 ] );
  hti = title( 'meshTriRayIntersection1() Timing Test' );
  print( '-depsc' , 'meshTimeIntersection-model1.eps' );
  hold off;

  figure(2);
  hl1 = loglog( numElements , times2 , 'r-o' );
  hold on;
  hl2 = loglog( numElements , a2 .* sqrt( numElements.^2 + Nc2.^2 ) , 'b-' );
  hl3 = loglog( numElements , times2 ./ numElements , 'g-^' );
  hl4 = loglog( numElements , timeAABB .* ones( size( numElements ) ) , 'b-' );
  hxl = xlabel( 'Number of elements' );
  hyl = ylabel( 'Time (s)' );
  key2 = sprintf( 'Total ray-elements cost model: %.1e * sqrt(N^2 + %d^2)' , a2 , floor( Nc2 ) );
  key4 = sprintf( 'Single ray-AABB intersect time: %.1e * %d' , a2 , floor( traversalCost2 ) );
  hlg = legend( 'Total ray-elements intersect time' , key2 , 'Single ray-element intersect time' , key4 , 'location' , 'northwest' );
  axis( [ 1e0 , 1e7 , 1e-8 , 1e3 ] );
  hti = title( 'meshTriRayIntersection2() Timing Test' );
  print( '-depsc' , 'meshTimeIntersection-model2.eps' );
  hold off;
  
  figure(3);
  hl1 = loglog( numElements , times3 , 'r-o' );
  hold on;
  hl2 = loglog( numElements , a3 .* sqrt( numElements.^2 + Nc3.^2 ) , 'b-' );
  hl3 = loglog( numElements , times3 ./ numElements , 'g-^' );
  hl4 = loglog( numElements , timeAABB .* ones( size( numElements ) ) , 'b-' );
  hxl = xlabel( 'Number of elements' );
  hyl = ylabel( 'Time (s)' );
  key2 = sprintf( 'Total ray-elements cost model: %.1e * sqrt(N^2 + %d^2)' , a3 , floor( Nc3 ) );
  key4 = sprintf( 'Single ray-AABB intersect time: %.1e * %d' , a3 , floor( traversalCost3 ) );
  hlg = legend( 'Total ray-elements intersect time' , key2 , 'Single ray-element intersect time' , key4 , 'location' , 'northwest' );
  axis( [ 1e0 , 1e7 , 1e-8 , 1e3 ] );
  hti = title( 'meshTriRayIntersection3() Timing Test' );
  print( '-depsc' , 'meshTimeIntersection-model3.eps' );
  hold off;

  figure(4);
  hl1 = loglog( numElements , times1 , 'r-o' );
  hold on;
  hl2 = loglog( numElements , times2 , 'b-^' );
  hl3 = loglog( numElements , times3 , 'g-*' );
  hxl = xlabel( 'Number of elements' );
  hyl = ylabel( 'Time (s)' );
  hlg = legend( 'Transposed/repmat' , 'Transposed/Direct' , 'Direct/Direct' );
  hti = title( 'meshTriRayIntersection timing test' );
  print( '-depsc' , 'meshTimeIntersection-comp.eps' );
  hold off;

  figure(5);
  hl1 = semilogx( numElements , percent1 , 'r-o' );
  hold on;
  hxl = xlabel( 'Number of elements' );
  hyl = ylabel( 'Percent intersections (%)' );
  hti = title( 'meshTriangleRayIntersection() Timing Test' );
  print( '-depsc' , 'meshTimeIntersection-percent.eps' );
  hold off;
  
  figure(6);
  hl1 = semilogx( numElements , times2 ./ times1 , 'r-o' );
  hold on;
  hl2 = semilogx( numElements , times3 ./ times1 , 'b-^' );
  hl3 = semilogx( numElements , times3 ./ times2 , 'g-*' );
  hxl = xlabel( 'Number of elements' );
  hyl = ylabel( 'Relative speed (-)' );
  hlg = legend( '2/1' , '3/1' , '3/2' );
  hti = title( 'TriangleRayIntersection timing test' );
  print( '-depsc' , 'meshTimeIntersection-ratio.eps' );
  hold off;

end % function

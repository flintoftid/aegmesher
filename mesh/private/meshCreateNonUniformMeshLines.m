function [ x ] = meshCreateNonUniformMeshLines( X , Xweight , dmin , dmax , dirChar , options )
%
% meshCreateNonUniformMeshLines - Generate a set nonuniform mesh lines that optimally fit a
%                                 set of constraint points.
% 
% [ x ] = meshCreateNonUniformMeshLines( X , Xweight , dmin , dmax , dirChar , options )
%
% Inputs:
%
% X         - vector of constraint points [m].
% Xweight   - vector of constraint point weighting factors [-].
% dmin      - vector of minimum mesh sizes [m].
% dmax      - vector of maximum mesh sizes [m].
% dirChar   - char, direction: 'x', 'y' or 'z'.
% options   - structure containing options:
% 
%             .maxRatio - maximum ratio between neighbouring mesh cells, >=1.
%
% Outputs:
%
% x()  - vector of mesh lines [m].
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

% Author: M. Berens
% Date: 15/07/2013
% Version 1.0.0

% Author: I. D. Flintoft
% Date: 30/10/2013
% Version 1.1.0
% Refactored option handling and provide more general decompostion
% of algorithm into functions.

% Author: I. D. Flintoft
% Date: 10/02/2016
% Version 1.2.0
% Integrate new algorithm from APM paper with improvements.

  function [ x ] = meshDivideInterval( xLeft , xRight , dmaxLeft , dmaxRight , dmaxInterval , maxRatio )
  %
  % Function to divide interval between xLeft and xRight into subintervals dx(i) i=1,...,N such that 
  %
  % dmaxLeft / maxRatio <= dx(1) <=  dmaxLeft
  % dmaxRight / maxRatio <= dx(N) <=  dmaxRight
  % 1 / maxRatio <= dx(i+1) / dx(i) <= maxRatio
  % dx(i) <= dmaxInterval
  % sum( dx(i) ) = xRight - xLeft
  % N is minimised, which should ensure dx(i) approaches dmaxInterval if possible.
  
    % Input contract.
    assert( dmaxLeft <= dmaxInterval );
    assert( dmaxRight <= dmaxInterval );  
    assert( xRight - xLeft >= dmaxInterval );
    assert( maxRatio >= 1 );
    
xLeft
xRight
dmaxLeft
dmaxRight
dmaxInterval
maxRatio  
L = xRight - xLeft

%      %
%      N_A_min = max( [ 0.0 , floor( 1 + log10( dmaxInterval / dmaxLeft ) / log10( maxRatio ) ) ] )
%      L_A_min = maxRatio * dmaxLeft * ( 1 - maxRatio^N_A_min ) / ( 1 - maxRatio )
%      
%      N_B_min = max( [ 0.0 , floor( 1 + log10( dmaxInterval / dmaxRight ) / log10( maxRatio ) ) ] )
%      L_B_min = maxRatio * dmaxRight * ( 1 - maxRatio^N_B_min ) / ( 1 - maxRatio )
%      
%      N_M_min = floor( ( L - L_A_min - L_B_min ) / dmaxInterval )
%      L_M_min = N_M_min * dmaxInterval
%      dx_M = dmaxInterval .* ones( 1 , N_M_min );
%      
%      residual = L - L_M_min - L_A_min - L_B_min
%      L_A = L_A_min + 0.5 * residual
%      L_B = L_B_min + 0.5 * residual
%      
%    N_A = N_A_min + 1  
%    func=@(r) 1 - L_A / dmaxLeft * ( 1 - r ) - r^N_A;
%    r_A = fzero( func , [ 1.0 + 100 * eps  , maxRatio ] ) 
%    dx_A = maxRatio * dmaxLeft .* r_A.^(0:N_A_min-1)
%    
%    N_B = N_B_min + 1  
%    func=@(r) 1 - L_B / maxRatio * ( 1 - r ) - r^N_B;
%    r_B = fzero( func , [ 1.0 + 100 * eps  , maxRatio ] ) 
%    dx_B = fliplr( maxRatio * dmaxRight .* r_B.^(0:N_B_min-1) )
%    
%    N_M = N_M_min
%    
%      % Put together.
%      N = N_A + N_M + N_B
%      dx = [ dx_A , dx_M , dx_B ]
%   length(dx)   
%   
%      % Construct mesh lines from intervals, avoiding rounding error at right end.
%      x = xLeft + cumsum( dx );
%      x(end) = xRight;
%   x   
 
% y = [ N_A  ,  N_B ,  N_M ,  r_A ,  r_B ]
%     [ y(1) , y(2) , y(3) , y(4) , y(5) ] 
r_max = 1.5;
L = 1.0;
d_max = 0.05;
d_L = 0.01;
d_R = 0.01;

phi = @(y) floor( y(1) ) + floor( y(2) ) + floor( y(3) );
lb = [   1 ;   1 ;   1 ; 1 +10 *eps ; 1 +10 *eps ];
ub = [ Inf ; Inf ; Inf ;     r_max ;     r_max ];
h1 = @(y) d_L * ( 1 - y(4)^floor( y(1) ) ) * ( 1 - y(5) ) + ...
          d_R * ( 1 - y(5)^floor( y(2) ) ) * ( 1 - y(4) ) + ...
          ( y(3) * d_max - L ) * ( 1 - y(4) ) * ( 1 - y(5) ) 
%h2 = @(y) 45.5 - sqrt (0.184 * sum (x)^2 + x(2)^2);
%h  = @(y) [h1(y); h2(y)];
h  = @(y) [ h1(y) ];
y0 = [ 2 ; 2 ; 2 ; r_max ; r_max ];
y  = sqp ( y0 , phi , [] , h , lb , ub , 100 , 1e-8 ); 

    % Output contract.
    %assert( dx(1) >=  dmaxLeft / maxRatio && dx(1) <= dmaxLeft );
    %assert( dx(N) >=  dmaxRight / maxRatio && dx(N) <= dmaxRight );
    assert( all( dx(2:N) ./ dx(1:N-1) <= maxRatio ) && all( dx(1:N-1) ./ dx(2:N) <= maxRatio ) );
    assert( all( diff( x ) <= dmaxInterval ) );
    assert( sum( dx ) == xRight - xLeft )
    assert( N >= 1 );
    
  end % function
      
  % Function to grow interval of size d over distance L with ratio r.
  % growInterval=@(d,L,r) d .* r.^( floor( log10( 1 - L ./ d .* ( 1 - r ) ) ./ log10( r ) ) );
  growInterval=@(d,L,r) d .* r.^( log10( 1 - L ./ d .* ( 1 - r ) ) ./ log10( r ) );
  
  % Number of mesh intervals.
  numIntervals = numel( dmax );
  
  % Number of points.
  numPoints = numIntervals + 1;

  % Edge refinement factor for intervals.
  edgeRefinement = 1.0 .* ones( size( dmax ) );
    
  % Sanity check.
  assert( numPoints == numel( X ) );
  assert( numPoints == numel( Xweight ) );
  assert( numIntervals == numel( dmin ) );  
  
  % Plot input constraints.
  xx = zeros( 1 , 2 * numPoints - 2 );
  xx(1) = X(1);
  xx(2:2:end-2) = X(2:end-1);
  xx(3:2:end-1) = X(2:end-1);
  xx(end) = X(end);
  dd = [ dmax ; dmax ];
  dd = dd(:)';
  
  figure(1);
  plot( xx , dd , 'r-o' );  
  xlabel( sprintf( '%s' , dirChar ) );
  ylabel( 'd_{max}' );
  grid on;

  % Maximum for sub-interval cannot be larger than the interval length.
  intervalLengths = diff( X );
  dmax = min( [ dmax ; intervalLengths ] , [] , 1 );
  
  % Determine maximum mesh size allowed at each constraint point by growth of mesh size from each
  % interval according to the maximum allowed mesh size ratio.
  dmaxAtXAll = zeros( numIntervals , numPoints );
  for intervalIdx = 1:numIntervals
    % Grow interval to left.
    dmaxAtXAll(intervalIdx,1:intervalIdx-1) = edgeRefinement(intervalIdx) .* ...
      growInterval( dmax(intervalIdx) , X(intervalIdx) - X(1:intervalIdx-1) , options.maxRatio );
    % Maximum for interval.
    dmaxAtXAll(intervalIdx,intervalIdx:intervalIdx+1) =  edgeRefinement(intervalIdx) .* dmax(intervalIdx);
    % Grow interval to right.
    dmaxAtXAll(intervalIdx,intervalIdx+2:end) = edgeRefinement(intervalIdx) .* ...
      growInterval( dmax(intervalIdx) , X(intervalIdx+2:end) - X(intervalIdx+1) , options.maxRatio );
  end % for

  % At each mesh point select the smallest allowed maximum mesh size.
  dmaxAtX = min( dmaxAtXAll , [] , 1 );

  % Plot mesh szie growth and maximum size contrainht according to all intervals.
  figure(2);
  plot( X , dmaxAtXAll );
  hold on;
  plot( X , dmaxAtX , 'ko' , 'lineWidth' , 3 , 'markerSize' , 10 );   
  plot( xx , dd , 'r-' , 'lineWidth' , 4 );  
  xlabel( sprintf( '%s' , dirChar ) );
  ylabel( 'd_{max}' );
  ylim( [ 1e-3 , 1e-1 ] );
  grid on;
  hold off;

  % Check each interval is viable, i.e. mesh sizes on each side can be respected
  % with regard to maximum ratio and length in case where we do not try to grow to 
  % maximum allowed sub-interval. If this can't be done already in trouble.
  for intervalIdx = 1:numIntervals
    xLeft = X(intervalIdx);
    xRight = X(intervalIdx+1);
    L = xRight - xLeft;
    dmaxLeft = dmaxAtX(intervalIdx);
    dmaxRight = dmaxAtX(intervalIdx+1);
  end % for   
  
  % Iterate over the intervals from left to right and locally 
  % subdivide each interval between constraint points
  % according to the mesh constraints on it end points and on
  % the interval.
  % Sub-intervals next to interval boundaries should be no
  % more than maxRatio/2 different to constraint to ensure
  % change across interval boundaries is less than maxRatio.
  x = X(1);
  for intervalIdx = 1:numIntervals
    xLeft = X(intervalIdx);
    xRight = X(intervalIdx+1);
    dmaxLeft = dmaxAtX(intervalIdx);
    dmaxInterval = dmax(intervalIdx);
    dmaxRight = dmaxAtX(intervalIdx+1);
    xInterval = meshDivideInterval( xLeft , xRight , dmaxLeft , dmaxRight , dmaxInterval , options.maxRatio );
    x = [ x , xInterval(2:end) ];
  end % for  

  % Plot mesh szie growth and maximum size contrainht according to all intervals.
  figure(3);
  plot( X , dmaxAtXAll );
  hold on;
  plot( X , dmaxAtX , 'ko' , 'lineWidth' , 3 , 'markerSize' , 10 );   
  plot( xx , dd , 'r-' , 'lineWidth' , 4 );
  plot( x(2:end) , diff( x ) , 'b-' , 'lineWidth' , 4 );  
  xlabel( sprintf( '%s' , dirChar ) );
  ylabel( 'd_{max}' );
  ylim( [ 1e-3 , 1e-1 ] );
  grid on;
  hold off;
  
  % We may have one too many cells at bottom/top end - remove them.
  %x(x - dopt + options.epsCompVol > X(end)) = [];
  %x(x + dopt - options.epsCompVol < X(1)) = [];

  % Final report. 
  fprintf( '  dmin = %g dmax = %g dmean =%g\n' ,  min( x ) , max( x ) , mean( x ) );
  fprintf( '  N%s = %d\n' , dirChar , length( x ) ); 

  % Check mesh lines span the constraint points.
  %assert( x(1) - options.epsCompVol <= X(1) );
  %assert( x(1) + dopt > X(1) );
  %assert( x(end) + options.epsCompVol >= X(end) );
  %assert( x(end) - dopt <= X(end) );

end % function

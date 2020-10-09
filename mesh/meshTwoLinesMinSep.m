function [ isParallel , d , t1 , t2 , p1 , p2 ] = meshTwoLinesMinSep( line1end1 , line1end2 , line2end1 , line2end2 , isFinite )
%
% meshTwoLionesMinSep - find the minimum separation between two infinite
%                       or finite lines.
%
% [ d , t1 , t2 , p1 , p2 ] = meshTwoLionesMinSep( line1end1 , line1end2 , ...
%                                            line2end1 , line2end2 [ , isFinite ] )
%
%
% Inputs:
% 
% line1end1() - real(1x3) vector of coordinates of end 1 of line 1.
% line1end2() - real(1x3) vector of coordinates of end 2 of line 1.
% line2end1() - real(1x3) vector of coordinates of end 1 of line 2.
% line2end2() - real(1x3) vector of coordinates of end 2 of line 2.
% isFinite    - boolean indiciating if lines should be consider finite 
%               Default is false.
%
% Outputs:
%
% isParallel - boolean indicating if lines are parallel.
% d          - real, minimum separation of the two lines.
% t1         - line parameter of the minimum separation point on line 1.
% t2         - line parameter of the minimum separation point on line 2.
% p1         - real(1x3) position vector of minimum separation point on line 1.
% p2         - real(1x3) position vector of minimum separation point on line 2.
%

  epsParallel = 1e-12;
  
  isParallel = false;
  d = [];
  t1 = [];
  t2 = [];
  p1 = [];
  p2 = [];
  
  % Default - lines are infinite.
  if( nargin == 4 )
    isFinite = false;
  end % if
  
  % Vectors along each line.
  dir1 = line1end2 - line1end1;
  dir2 = line2end2 - line2end1;

  % Unit vectors along each line.
  unit1 = dir1 ./ norm( dir1 );
  unit2 = dir2 ./ norm( dir2 );
  
  % Unit vector normal to both line directions.
  ndir = cross( unit1 , unit2 );

  % If denominator is 0, lines are parallel
  denom = norm( ndir )^2;

  if( denom < epsParallel )
    isParallel = true;
    return;
  end % if
  
  % Determinants.
  t = ( line2end1 - line1end1 );
  det1 = det( [ t ; unit2 ; ndir ] );
  det2 = det( [ t ; unit1 ; ndir ] );

  % Line parameters.
  t1 = det1 / denom;
  t2 = det2 / denom;

  % Points.
  p1 = line1end1 + ( unit1 * t1 );
  p2 = line2end1 + ( unit2 * t2 );
  
  % Clamp results to line segments if finite.
  if( isFinite )
  
    if( t1 < 0 )
      p1 = line1end1;
      t1 = 0;
    elseif( t1 > norm( dir1 ) )
      p1 = line1end2;
      t1 = norm( dir1 );
    end % if

    if( t2 < 0 )
      p2 = line2end1;
      t2 = 0;
    elseif( t2 > norm( dir2 ) )
      p2 = line2end2;
      t2 = norm( dir2 );
    end %if
    
  end % if
  
  % Minimum separation distance.
  d = norm( p1 - p2 );

  t1 = t1 / norm( dir1 );
  t2 = t2 / norm( dir2 );
  
end % function

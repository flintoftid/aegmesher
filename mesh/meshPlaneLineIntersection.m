function [ isIntersection , t , p ] = meshPlaneLineIntersection( planeNormal , planePoint , lineEnd1 , lineEnd2 , isFinite )
%
% meshPlaneLineIntersection - find point of intersection between a plane and line.
%
% [ isIntersection , t , p ] = meshPlaneLineIntersection( planeNormal , planePoint , lineEnd1 , lineEnd2 )
%
% Inputs:
%
% planeNormal() - real(1x3) normal vector of the plane.
% planePoint()  - real(1x3) position vector of a point on the plane.
% lineEnd1()    - real(1x3) postion vector of end 1 of line.
% lineEnd2(0    - real(1x3) postion vector of end 2 of line.
% isFinite      - boolean indiciating if lines should be consider finite 
%                 Default is false.
%
% Outputs:
%
% isIntersection - boolean indicating if plane and line intersect.
% t              - real, line parameter at intersection point.
%                  If line lies in plane t is empty.
% p()            - real(1x3) position vector of intersection point.
%                  If line lies in plane p is empty.
%

  epsParallel = 1e-6;
  
  t = [];
  p = [];
  isIntersection = false;

  % Default - line is infinite.
  if( nargin == 4 )
    isFinite = false;
  end % if
  
  dir = lineEnd2 - lineEnd1;
  
  w = lineEnd1 - planePoint;
  D = dot( planeNormal ,dir );
  N = -dot( planeNormal , w );
    
  if( abs( D ) < epsParallel )
    % The segment is parallel to plane
    if( N == 0 )           
      % The segment lies in plane.
      isIntersection = true;
      return;
    else
      % The segement doesn't lie in the plane.
      isIntersection = false;
      return;
    end % if
  end % if

  % Intersection point.
  t = N / D;
  p = lineEnd1 + t .* dir;

  if( isFinite && ( t < 0 || t > 1 ) )
    % Intersection point is outside the segment.
    isIntersection = false;
  else
    isIntersection = true;
  end % if

end % function

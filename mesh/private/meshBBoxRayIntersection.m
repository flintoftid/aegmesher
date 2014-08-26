function [ isIntersection , tmin , tmax ] = meshBBoxRayIntersection( origin , dir , invDir , dirIsNeg , bbox , options )
% 
% meshBBoxRayIntersection - Determine if a ray intersects an axis-aligned bounding-box (AABB).
%
% [ isIntersection , tmin , tmax ] = meshBBoxRayIntersection( origin , dir , invDir , dirIsNeg , bbox [ , options ] )
%
% Inputs:
%
% origin()   - (3) real vector of ray origin coordinates.    
% dir()      - (3) real vector of ray direction vectors.
% invDir()   - (3) real vector of ray inverse directions.
% dirIsNeg() - (3) boolean vector indicating if directions are negative.
% bbox() -     (6) real vector containing AABB.
% options - structure containing additional customisation options:
%
%          .isInfiniteRay  -  boolean scalar, indicating whether to treat the rays r(t) = origin + t * dir
%                             as infinite or finite segments:
% 
%                             true  - treat as an infinite ray with -Inf < t < Inf (default).
%                             false - treat as a line segment with 0 <= t <= 1.
%
%          .isIncludeRayEnds - boolean scalar, indicating whether to include border points of segments 
%                              (ignored if isInfiniteRay is true):
%
%                              true - borders points (t=0,1) are included, with a margin of option.epsRayEnds. 
%                              true - borders points (t=0,1) are excluded, with margin of option.epsRayEnds.
%
%          .epsRayEnds       - real scalar, tolerance on inclusion of 'segment' border points relative to 
%                              barycentric coordinates ( 0 <= t,u,v <= 1). (default = 1e-10).
%
% Outputs:
%
% isIntersection - boolean scalar indicting if AABB intersects ray.
% tmin           - real scalar, if intersection found gives distance from rays origin to entry point.
% tmax           - real scalar, if intersection found gives distance from rays origin to exit point.
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
% Date: 23/07/2013
% Version: 1.0.0

  % Default options.
  isInfiniteRay = true;
  isIncludeRayEnds = true;
  epsRayEnds = 1e-10;

  % Parse options.
  % [FIXME] Parsing these costs about on NTC1 model 5%!
  if( nargin >= 6 )
    if( isfield( options , 'isInfiniteRay' ) )
      isInfiniteRay = options.isInfiniteRay;
    end % if
    if( isfield( options , 'isIncludeRayEnds' ) )
      isIncludeRayEnds = options.isIncludeRayEnds;
    end % if
    if( isfield( options , 'epsRayEnds' ) )
      epsRayEnds = options.epsRayEnds;  
    end % if
  end % if

  % Tolerance for including border points of segments.
  if( isIncludeRayEnds )
    zero = epsRayEnds;
  else
    zero = -epsRayEnds;
  end % if

  tmin  = ( bbox(1+dirIsNeg(1)) - origin(1) ) * invDir(1);
  tmax  = ( bbox(4-dirIsNeg(1)) - origin(1) ) * invDir(1);
  tymin = ( bbox(2+dirIsNeg(2)) - origin(2) ) * invDir(2);
  tymax = ( bbox(5-dirIsNeg(2)) - origin(2) ) * invDir(2);

  if( ( tmin > tymax ) || ( tymin > tmax ) )
    isIntersection = false;
    return;
  end % if
  if( tymin > tmin )
    tmin = tymin;
  end % if
  if( tymax < tmax )
    tmax = tymax;
  end % if
    
  tzmin = ( bbox(3+dirIsNeg(3)) - origin(3) ) * invDir(3);
  tzmax = ( bbox(6-dirIsNeg(3)) - origin(3) ) * invDir(3);

  if( ( tmin > tzmax ) || ( tzmin > tmax ) )
    isIntersection = false;
    return;
  end % if

  if( tzmin > tmin )
    tmin = tzmin;
  end % if
  if( tzmax < tmax )
    tmax = tzmax;
  end % if

  if( isInfiniteRay )
    isIntersection = ( tmin < Inf ) && ( tmax > -Inf );
    else 
    isIntersection = ( tmax >= -zero && tmin <= 1.0 + zero );
  end % if

end % function

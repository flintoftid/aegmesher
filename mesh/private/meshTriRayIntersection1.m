function [ isIntersect , t , u , v , isFrontFacing ] = meshTriRayIntersection1( orig , dir , vert0 , vert1 , vert2 , options )
%
% meshTriRayIntersection1 - Find intersection of a ray with a set of triangles.
%
% Usage: [ isIntersect , t , u , v , isFrontFacing ] = meshTriRayIntersection1( orig , dir , vert0 , vert1 , vert2 , options )
%
% Inputs:
%
% n is the number of triangles.
%
% orig()  - real(nx3), array of ray origin coordinates.    
% dir()   - real(nx3), array of ray direction vectors coordinates.
% vert0() - real(nx3), array of triangle first vertex coordinates.
% vert1() - real(nx3), array of triangle second vertex coordinates.
% vert2() - real(nx3), array of triangle third vertex coordinates.
% options - structure containing additional customisation options:
%
%          .isInfiniteRay  -  boolean scalar, indicating whether to treat the rays r(t) = origin + t * dir
%                             as infinite or finite segments:
% 
%                             true  - treat as an infinite ray with -Inf < t < Inf (default).
%                             false - treat as a line segment with 0 <= t <= 1.
%
%          .epsParallelRay -  real scalar, giving the tolerance on tests for rays parallel to triangles. 
%                             The value should be of the order 
%
%                               options.epsParallelRay = maxSide^2 * maxDir * epsAngle
%
%                             where maxSide is the maximum linear triangle size, maxDir is the maximum 
%                             length of dir (equal to 1 if dir is normalised) and epsAngle << pi/2 is 
%                             a small angle (in radians) such that if the angle between the ray and normal 
%                             is within the range ( pi/2 - epsAngle , pi/2 + epsAngle ) the triangle will 
%                             be taken as parallel to the ray and ignored (default = 1e-10, e.g triangle 
%                             maxSide = 1mm and epsAngle = 5/1000 of a degree with maxDir = 1). See [4, ch. 2.4.4].
%
%          .isTwoSidedTri   - boolean scalar, indicating whether to treat triangles as one- or two-sided:
%
%                             true  - Intersections with both front and back facing triangles 
%                                     are counted (default). 
%                             false - Only intersections with 'front' facing triangles are 
%                                     counted and intersections with back facing triangles 
%                                     are ignored.
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
% isIntersect()   - (N) boolean vector, indicting if element intersects ray.
% t()             - (N) real vector indicating distance from the ray's origin to the intersection points.
% u(),v()         - (N) real vectors giving barycentric coordinates of the intersection points.   
% isFrontFacing() - (N) boolean vector indicating if intersections are on front-facing elements. If 
%                   options.isTwoSidedTri is false these should all be true.
%

% Author: Jarek Tuszynski (jaroslaw.w.tuszynski@saic.com).
% License: BSD license (http://en.wikipedia.org/wiki/BSD_licenses).

% References:
%
% [1] "Fast, minimum storage ray-triangle intersection". Tomas M�ller and 
%     Ben Trumbore. Journal of Graphics Tools, 2(1):21--28, 1997. 
%     http://www.graphics.cornell.edu/pubs/1997/MT97.pdf
% [2] http://fileadmin.cs.lth.se/cs/Personal/Tomas_Akenine-Moller/raytri/
% [3] http://fileadmin.cs.lth.se/cs/Personal/Tomas_Akenine-Moller/raytri/raytri.c
% [4] J. Hill, "Efficient implementation of mesh generation and FDTD simulation of
%     electromagnetic fields", PhD thesis, Worcester Polytechnic Institute, August, 1996.
%


  % Verify that inputs are in correct format.
  if( size( orig  , 1 ) == 3 && size( orig  , 2 ) ~= 3 ) , orig  = orig'  ; end
  if( size( dir   , 1 ) == 3 && size( dir   , 2 ) ~= 3 ) , dir   = dir'   ; end
  if( size( vert0 , 1 ) == 3 && size( vert0 , 2 ) ~= 3 ) , vert0 = vert0' ; end
  if( size( vert1 , 1 ) == 3 && size( vert1 , 2 ) ~= 3 ) , vert1 = vert1' ; end
  if( size( vert2 , 1 ) == 3 && size( vert2 , 2 ) ~= 3 ) , vert2 = vert2' ; end
  if( any( size( orig ) ~= size( vert0) ) || ...
      any( size( orig ) ~= size( vert1) ) || ...
      any( size( orig ) ~= size( vert2) ) || ...
      any( size( orig ) ~= size( dir  ) ) )
    error('All input vectors have to be of the same size.');
  end % if

  if( size( orig , 2 ) ~=3 )
    error('All input vectors have to be in Nx3 format.');
  end % if

  % Default options.
  isInfiniteRay = true;
  epsParallelRay   = 1e-10;
  isTwoSidedTri = true;
  isIncludeRayEnds = true;
  epsRayEnds = 1e-10;

  % Parse options.
  if( nargin > 5 )
    if( isfield( options , 'isInfiniteRay' ) )
      isInfiniteRay = options.isInfiniteRay;
    end % if
    if( isfield( options , 'epsParallelRay' ) )
      epsParallelRay = options.epsParallelRay;  
    end % if
    if( isfield( options , 'isTwoSidedTri' ) )
      isTwoSidedTri = options.isTwoSidedTri;
    end % if
    if( isfield( options , 'isIncludeRayEnds' ) )
      isIncludeRayEnds = options.isIncludeRayEnds;
    end % if
    if( isfield( options , 'epsRayEnds' ) )
      epsRayEnds = options.epsRayEnds;  
    end % if
  end % if

  % Initialize default output.
  isIntersect = false( size( orig , 1 ) , 1 );
  t = zeros( size( orig , 1 ) , 1 ); 
  u = t; 
  v = t;

  % Find faces parallel to the ray.
  % Find vectors for two edges sharing vert0.
  edge1 = vert1 - vert0;              
  edge2 = vert2 - vert0;
  % Distance from vert0 to ray origin.
  tvec  = orig - vert0;
  % Begin calculating determinant - also used to calculate u parameter.
  % pvec = bsxfun( @cross, dir , edge2 );
  pvec = cross( dir , edge2 , 2 );
  % Determinant of the matrix M = dot( edge1 , pvec ).
  det = sum( edge1 .* pvec , 2 );  
  % Boolean indicating if elements are "front facing".
  isFrontFacing = det > epsParallelRay;
  % If determinant is near zero then ray lies in the plane of the triangle.
  % det = ||edge1|| ||edge2|| ||dir|| cos( alpha )
  % If dir normalised ||dir||=1. If dir a segment could be size of object AABB.
  % ||edge1/2|| could be very small to significant proportion of object AABB.
  % cos( pi/2 - epsAngle ) ~ epsAngle
  % abs( det ) c.f. ||edge1|| ||edge2|| ||dir|| epsAngle.
  % Norms expensive to determine but product could have huge range. 
  % [FIXME] This simple heuristic requires detailed understanding and consistency
  % of tolerances epsRayEnds, epsParallelRay!
  %rownorm = @(X,P) sum( abs( X ).^P , 2 ).^(1/P);
  %rownorm2 = @(X) sqrt( sum( X.^2 , 2 ) );
  %rownorm2 = @(X) sqrt( X(:,1) .* X(:,1) + X(:,2) .* X(:,2) + X(:,3) .* X(:,3) );
  %epsParallelRay = 1e-4;
  %parallel = ( abs( det ) < rownorm2( edge1 ) .* rownorm2( edge2 ) .* rownorm2( dir ) .* epsParallelRay );
  parallel = ( abs( det ) < epsParallelRay );

  % If all parallel then no intersections.
  if( all( parallel ) )
    return; 
  end % if 

  % Tolerance for including border points of segments.
  if( isIncludeRayEnds )
    zero = epsRayEnds;
  else
    zero = -epsRayEnds;
  end % if

  % Different behaviour depending on one or two sided triangles.
  if( isTwoSidedTri )
    % Treat triangles as two sided.
    % Change to avoid division by zero.
    det( parallel ) = 1;
    % Calculate u parameter used to test bounds.
    u = sum( tvec .* pvec ,2 ) ./ det;                   
    % Mask which allows performing next 2 operations only when needed.
    ok = ( ~parallel & u >= -zero & u <= 1.0 + zero );    
    % If all ray/plane intersections are outside the triangle then no intersections. 
    if( ~any( ok ) )
      return; 
    end % if
    % Prepare to test v parameter.
    qvec = cross( tvec(ok,:) , edge1(ok,:) , 2 );
    % Calculate v parameter used to test bounds.
    v(ok,:) = sum( dir(ok,:) .* qvec , 2 ) ./ det(ok,:); 
    isIntersect = ( v >= -zero & u + v <= 1.0 + zero & ok );  
    if( nargout == 1 && isInfiniteRay )
      return
    end % if
    t(ok,:) = sum( edge2(ok,:) .* qvec , 2 ) ./ det(ok,:);
    if( isInfiniteRay )
      return; 
    end % if
    % Intersection between origin and destination.
    isIntersect = (isIntersect & t >= -zero & t <= 1.0 + zero );
  else
    % Treat triangles as one sided.
    % Calculate u parameter used to test bounds.
    u = sum( tvec .* pvec , 2 );                   
    % Mask which allows performing next 2 operations only when needed.
    ok = ( isFrontFacing & u >= 0.0 & u <= det );        
    % If all ray/plane intersections are outside the triangle then no intersections. 
    if( ~any( ok ) )
      return; 
    end % if
    % Prepare to test v parameter.
    qvec = cross( tvec(ok,:) , edge1(ok,:) , 2 );
    % Calculate v parameter used to test bounds.
    v(ok,:) = sum( dir(ok,:) .* qvec , 2 );        
    isIntersect = ( det > epsParallelRay & u >= -zero & v >= -zero & u + v <= det * ( 1 + zero ) );
    if( nargout == 1 && isInfiniteRay )
      return; 
    end % if
    t(ok,:)  = sum( edge2(ok,:) .* qvec , 2 );     
    inv_det = zeros( size( det ) );
    inv_det(ok,:) = 1 ./ det(ok,:);
    % Calculate t - distance from origin to the intersection in |dir| units.
    t = t .* inv_det;  
    u = u .* inv_det;
    v = v .* inv_det;
    if( isInfiniteRay ) 
      return; 
    end % if
    % Intersection between origin and destination.
    isIntersect = ( isIntersect & t >= -zero & t <= 1.0 + zero ); 
  end % if

end % function

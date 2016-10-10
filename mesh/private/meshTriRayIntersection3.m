function [ isIntersect , t , u , v , isFrontFacing ] = meshTriRayIntersection3( orig , dir , vert0 , vert1 , vert2 , options )
%
% meshTriRayIntersection3 - Find intersection of a ray with a set of triangles.
%
% Usage: [ isIntersect , t , u , v , isFrontFacing ] = meshTriRayIntersection3( orig , dir , vert0 , vert1 , vert2 , options )
%
% Inputs:
%
% n is the number of triangles.
%
% orig()  - real(3x1), array of ray origin coordinates.    
% dir()   - real(3x1), array of ray direction vectors coordinates.
% vert0() - real(3xn), array of triangle first vertex coordinates.
% vert1() - real(3xn), array of triangle second vertex coordinates.
% vert2() - real(3xn), array of triangle third vertex coordinates.
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
% isIntersect()    - boolean(1xn) vector, indicting if triangle intersects ray.
% t()              - real(1xn) vector giving ray parameters at intersection points.
% u(),v()          - real(1xn) vector giving triangle barycentric coordinates of intersection points.   
% isFrontFacing()  - boolean(1xn) vector indicating if intersections are on front-facing elements. If 
%                    options.isTwoSidedTri is false these should all be true.

% Author: Jarek Tuszynski (jaroslaw.w.tuszynski@saic.com).
% License: BSD license (http://en.wikipedia.org/wiki/BSD_licenses).
%
% Modiifed by I. D. Flintoft to use native array index order of mesh format.

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

  % Default options.
  isInfiniteRay = true;
  epsParallelRay = 1e-10;
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

  % Number of triangles.
  numTriangles = size( vert0 , 2 );

  % Initialise outputs to default values for no intersection.
  isIntersect = false( 1 , numTriangles );
  t = zeros( 1 , numTriangles ); 
  u = zeros( 1 , numTriangles ); 
  v = zeros( 1 , numTriangles );
  isFrontFacing = false( 1 , numTriangles );

  % Two edges of triangles with common point.
  edge1 = vert1 - vert0;              
  edge2 = vert2 - vert0;

  % Calculate the determinant.
  % Using bsxfun here is very very slow.
  % pvec = bsxfun( @cross, dir , edge2 );
  dirs = repmat( dir , 1 , numTriangles );
  pvec = cross( dirs , edge2 );
  det = sum( edge1 .* pvec );

  % If the determinant is near zero then the ray lies in the plane of the triangle.
  % det = ||edge1|| ||edge2|| ||dir|| cos( alpha )
  % If dir normalised ||dir||=1. If dir a segment could be size of object AABB.
  % ||edge1/2|| could be very small to significant proportion of object AABB.
  % cos( alpha ) = cos( pi/2 - epsAngle ) ~ epsAngle
  % abs( det) c.f. ||edge1|| ||edge2|| ||dir|| epsAngle.
  % Norms expensive to determine but product have huge range. 
  % [FIXME] This simple heuristic requires detailed understanding and consistency
  % of tolerances epsRayEnds, epsParallelRay!

  % Boolean indicating if elements are "front facing".
  isFrontFacing = det > epsParallelRay;

  % Boolean indicating if triangle and ray are parallel.  
  isParallel = ( abs( det ) < epsParallelRay );

  % If all triangles are parallel then there are no intersections.
  if( all( isParallel ) )
    return; 
  end % if 

  % Tolerance for including end points of ray.
  if( isIncludeRayEnds )
    zero = epsRayEnds;
  else
    zero = -epsRayEnds;
  end % if
  
  % Distance from common vertex to ray origin.
  % tvec = bsxfun( @minus , orig , vert0 );
  origs = repmat( orig , 1 , numTriangles );
  tvec = origs - vert0;

  % The algorithm has different behaviour depending on one or two sided triangles.
  if( isTwoSidedTri )

    % Treat triangles as two sided. Intersections for front and rear facing
    % triangles are both considered valid.

    % Change to avoid division by zero.
    det( isParallel ) = 1;
    
    % Calculate u coordinate.
    u = sum( tvec .* pvec ) ./ det;     
    
    % Find triangle which are still feasible for intersection with ray.
    isFeasible = ( ~isParallel & u >= -zero & u <= 1.0 + zero ); 

    if( ~any( isFeasible ) )
      return; 
    end % if

    qvec = cross( tvec(:,isFeasible) , edge1(:,isFeasible) , 1 );
    
    % Calculate v coordinate.
    % v(isFeasible) = sum( bsxfun( @times , dir , qvec ) ) ./ det(:,isFeasible);
    v(isFeasible) = sum( dirs(:,isFeasible) .* qvec ) ./ det(:,isFeasible);
    
    % See which triangles are intersected by ray.
    isIntersect = ( v >= -zero & u + v <= 1.0 + zero & isFeasible );  

    % Calculate t for intersecting triangles.  
    t(isFeasible) = sum( edge2(:,isFeasible) .* qvec ) ./ det(:,isFeasible);

  else
  
    % Treat triangles as one sided. Intersections with rear facing trianlges
    % are culled.
    
    % Calculate u coordinate.
    u = sum( tvec .* pvec );   

    % Find front facing triangles which are still feasible for intersection with ray given u.
    isFeasible = ( isFrontFacing & u >= 0.0 & u <= det );
    if( ~any( isFeasible ) )
      return; 
    end % if
   
    qvec = cross( tvec(:,isFeasible) , edge1(:,isFeasible) );
    
    % Calculate v coordinate.
    % v(isFeasible) = sum( bsxfun( @times , dir , qvec ) );
    v(isFeasible) = sum( dirs(:,isFeasible) .* qvec );    

    % See which triangles are intersected by ray.
    isIntersect = ( isFrontFacing & u >= -zero & v >= -zero & u + v <= det * ( 1 + zero ) );
    
    % t(isFeasible,:)  = dot( edge2(isFeasible,:) , qvec , 2 );
    t(isFeasible)  = sum( edge2(:,isFeasible) .* qvec );
    
    inv_det = zeros( size( det ) );
    inv_det(:,isFeasible) = 1 ./ det(:,isFeasible);
    
    % Renormalise barycentric coordinates.
    t = t .* inv_det;  
    u = u .* inv_det;
    v = v .* inv_det;

  end % if

  % If ray is infinite job is done.
  if( isInfiniteRay )
    return; 
  end % if

  % For finite rays check t is within bounds of ray.
  isIntersect = ( isIntersect & t >= -zero & t <= 1.0 + zero );

end % function


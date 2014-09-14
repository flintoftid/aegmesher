function [ isIntersect , t , v , w , isFrontFacing ] = meshTriRayIntersection4( orig , dir , vert0 , vert1 , vert2 , options )
%
% meshTriRayIntersection4 - Find intersection of a ray with a set of triangles.
%
% Usage: [ isIntersect , t , u , v , isFrontFacing ] = meshTriRayIntersection4( orig , dir , vert0 , vert1 , vert2 , options )
%
% Inputs:
%
% n is the number of triangles.
%
% orig()  - real(1x3), array of ray origin coordinates.    
% dir()   - real(1x3), array of ray direction vectors coordinates.
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
% isIntersect()   - boolean(1xn) vector, indicting if triangle intersects ray.
% t()             - real(1xn) vector giving ray parameters at intersection points.
% u(),v()         - real(1xn) vector giving triangle barycentric coordinates of intersection points.   
% isFrontFacing() - boolean(1xn) vector indicating if intersections are on front-facing elements. If 
%                   options.isTwoSidedTri is false these should all be true.
%

%
% Sven Woop, Carsten Benthin and Ingo Wald, "Watertight Ray/Triangle Intersection", 
% Journal of Computer Graphics Techniques, Vol. 2, No. 1, 2013. http://jcgt.org
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
  numTriangles = size( vert0 , 1 );

  % Initialise outputs to default values for no intersection.
  isIntersect = false( numTriangles , 1 );
  t = zeros( numTriangles , 1 ); 
  u = zeros( numTriangles , 1 ); 
  v = zeros( numTriangles , 1 );
  w = zeros( numTriangles , 1 );
  isFrontFacing = false( numTriangles , 1 );

  % Calculate dimension where the ray direction is maximal.
  [ ~ , kz ] = max( abs( dir ) );
  kx = kz + 1; 
  if( kx == 4 ) 
    kx = 1;
  end % if
  ky = kx + 1; 
  if( ky == 4 ) 
    ky = 1;
  end % if
  
  % Swap kx and ky dimension to preserve winding direction of triangles.
  if( dir(kz) < 0.0 ) 
    tmp = kx;
    kx = ky;
    ky = tmp;
  end % if
  
  % Calculate shear constants.
  Sx = dir(kx) / dir(kz);
  Sy = dir(ky) / dir(kz);
  Sz = 1.0 / dir(kz);

  % Replicate origins and shear constants.
  origs = repmat( orig , numTriangles , 1 );
  Sx = repmat( Sx , numTriangles , 1 );
  Sy = repmat( Sy , numTriangles , 1 );
  Sz = repmat( Sz , numTriangles , 1 );
  
  % Calculate vertices relative to ray origin.
  A = vert0 - origs;
  B = vert1 - origs;
  C = vert2 - origs;

  % Perform shear and scale of vertices.
  Ax = A(:,kx) - Sx .* A(:,kz);
  Ay = A(:,ky) - Sy .* A(:,kz);
  Bx = B(:,kx) - Sx .* B(:,kz);
  By = B(:,ky) - Sy .* B(:,kz);
  Cx = C(:,kx) - Sx .* C(:,kz);
  Cy = C(:,ky) - Sy .* C(:,kz);

  % Calculate scaled barycentric coordinates.
  U = Cx .* By - Cy .* Bx;
  V = Ax .* Cy - Ay .* Cx;
  W = Bx .* Ay - By .* Ax;

  % Perform edge tests. Moving this test before and at the end of the previous conditional gives higher performance.
  if( isTwoSidedTri )
    isEdge = ( U < 0.0 | V < 0.0 | W < 0.0 ) & ( U > 0.0 | V > 0.0 | W > 0.0 );
  else
    isEdge = ( U < 0.0 | V < 0.0 | W < 0.0 ); 
  end % if
    
  isIntersect = ~isEdge;
  
  if( all( ~isIntersect ) ) 
    return;
  end % if

  % Calculate determinant.
  det = U + V + W;

  isParallel = ( det == 0.0 );
  isIntersect = ( isIntersect & ~isParallel );
  
  if( all( ~isIntersect ) ) 
    return;
  end % if

  % Calculate scaled z−coordinates of vertices and use them to calculate the hit distance.
  Az = Sz .* A(:,kz);
  Bz = Sz .* B(:,kz);
  Cz = Sz .* C(:,kz);
  T = U .* Az + V .* Bz + W .* Cz;

  det_sign = sign( det );
 
   % If ray is not infinite check t is within bounds of ray.
  if( ~isInfiniteRay )
    if( isTwoSidedTri )
      isOutside = ( ( T .* det_sign < 0.0 ) | ( T .* det_sign > det .* det_sign ) );
    else
      isOutside = ( T < 0.0  | T > det );
    end % if
    isIntersect = ( isIntersect & ~isOutside );
  end % if 
  
  if( all( ~isIntersect ) ) 
    return;
  end % if

  % Normalize U, V, W and T.
  invDet = zeros( size( det ) );
  invDet(isIntersect) = 1 ./ det(isIntersect);
  u = U .* invDet;
  v = V .* invDet;
  w = W .* invDet;
  t = T .* invDet;  
  isFrontFacing = ( det_sign == 1 );

end % function

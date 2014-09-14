function [ t , elementIdx , isIntersectEdge , isFrontFacing ] = meshIntersectFBVH( mesh , fbvh , elementMap , origin , dir , options )
%
% meshIntersectFBVH - Find intersections between elements stored in a FBVH and a ray. 
%
% [ t , elementIdx , isIntersectEdge , isFrontFacing ] = meshIntersectFBVH( mesh , fbvh , elementMap , ray [ ,options] )
%
% Inputs:
%
% mesh         - structure containing the unstructured mesh. See help for meshReadAmelet().
% fbvh         - struct array containing flattened BVH - see help for meshBuildFBVH().
% elementMap() - (numElements) integer array containing element indices - see help for meshBuildFBVH().
% origin()     - (3) real vector of coordinates of origin.
% dir()        - (3) real vector of unit direction vector.
% options      - structure containing options for intersection function - see help for meshTriRayIntersection().
%
% Outputs:
%
% t()               - (numIntersections) real vector, ray's parameter values at intersection points.
% elementIdx()      - (numIntersections) integer vector of corresponding intersected element indices.
% isIntersectEdge() - (numIntersections) boolean vector indicating if intersection is on edge of elements.
% isFrontFacing()   - (numIntersections) boolean vector indicating if intersections are on front-facing elements.
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

%
% Limitations:
%
% 1. Only supports triangular surface elements!
%
% Notes:
%
% 1. Ray's that are in the plane of an element are counted as NOT intersecting by the
%    meshTriRayIntersection function.
%
% References:
%
% [1] M. Pharr and G. Humphreys, "Physically based rendering - from theory to implementation", Morgan Kaupmann, 2004.
%

  % Default options.
  epsRayEnds = 1e-10;

  % Parse options.
  if( nargin >= 5 )
    if( isfield( options , 'epsRayEnds' ) )
      epsRayEnds = options.epsRayEnds; 
    else
      options.epsRayEnds = epsRayEnds;
    end % if
  end % if

  % Vectors of intersection parameters and elements intersected.
  t = [];
  elementIdx = []; 
  isIntersectEdge = [];
  isFrontFacing = [];

  % Stack holding next node to process.
  todo = [];
  todoOffset = 0;

  % Current node to process.
  nodeNum = 1;

  % Ray properties.
  invDir = 1 ./ dir;
  dirIsNeg = 3 .* ( dir < 0 );

  % We only support triangles in the mesh.
  if( any( mesh.elementTypes( elementMap ) ~= 11 ) )
   error( 'Non-triangular elements not supported!' ); 
  end % if

  % Non-recursive stack based tree-walking algorithm.
  while( true )
    if( meshBBoxRayIntersection( origin , dir , invDir , dirIsNeg , fbvh(nodeNum).bbox , options ) )
      % Node AABB intersects the ray.
      if( fbvh(nodeNum).numElements > 0 )
        % Intersected a leaf node - intersect ray with all node's elements.
        % Get list of elements in node.
        thisElementIdx = elementMap((fbvh(nodeNum).offset):(fbvh(nodeNum).offset+fbvh(nodeNum).numElements - 1));
        % Node numbers of elements' vertices.
        node1 = mesh.elements(1,thisElementIdx);
        node2 = mesh.elements(2,thisElementIdx);
        node3 = mesh.elements(3,thisElementIdx);
        % Coordinates of vertices. These transposes are potentially expensive, however we need 
        % column-major order indexing for performance of @cross in meshTriRayIntersection2().
        vert1 = mesh.nodes(1:3,node1)';
        vert2 = mesh.nodes(1:3,node2)';
        vert3 = mesh.nodes(1:3,node3)';
        % Test  for intersections #1.
        origins = repmat( origin , fbvh(nodeNum).numElements , 1 );
        dirs = repmat( dir , fbvh(nodeNum).numElements , 1 );
        [ isIntersect , tt , u , v , isFront ] = meshTriRayIntersection1( origins , dirs , vert1 , vert2 , vert3 , options );
        % Test  for intersections #2.      
        %[ isIntersect , tt , u , v , isFront ] = meshTriRayIntersection2( origin , dir , vert1 , vert2 , vert3 , options );
        % Test  for intersections #3.      
        %[ isIntersect , tt , u , v , isFront ] = meshTriRayIntersection3( origin , dir , vert1' , vert2' , vert3' , options );       
        % Test  for intersections #4.      
        %[ isIntersect , tt , u , v , isFront ] = meshTriRayIntersection4( origin , dir , vert1 , vert2 , vert3 , options );        
        % Find hits.
        hitIdx = find( isIntersect );
        % Keep intersected elements.
        elementIdx = [ elementIdx , thisElementIdx(hitIdx) ];
        % Keep intersection points.
        t = [ t , tt(hitIdx)' ]; 
        % Keep note of which intersected elements are front facing.
        isFrontFacing = [ isFrontFacing , isFront(hitIdx)' ]; 
        % Determine if we hit an edge/corner using barycentric coordinates and keep. 
        % [FIXME] could this be extracted more efficiently in meshTriRayIntersection()?
        isEdge = ( u(hitIdx) < epsRayEnds ) | ( v(hitIdx) < epsRayEnds ) | ( u(hitIdx)+ v(hitIdx) > 1 - epsRayEnds );
        isIntersectEdge = [ isIntersectEdge , isEdge' ];
        % Set next node to visit from stack. 
        if( todoOffset == 0 )
          break;
        else
          nodeNum = todo(todoOffset);
          todoOffset = todoOffset - 1;
        end % if
      else
        % Intersected an interior node - add right child to stack and set next node to left child.
        todoOffset = todoOffset + 1;
        todo(todoOffset) = fbvh(nodeNum).offset;
        nodeNum = nodeNum + 1;
      end % if
    else
      % Node does not intersect ray - set next node to visit from stack.
      if( todoOffset == 0 )
        break ;
      else
        nodeNum = todo(todoOffset);
        todoOffset = todoOffset - 1;
      end % if
    end % if

  end % while

end % function


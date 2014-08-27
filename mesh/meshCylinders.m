function [ mesh ] = meshCylinders( endPoints , radius , numSides )
%
% meshCylinders - create an simple triangular mesh of a number of 
%                 cylinders defined by their axis end-points and
%                 radius.
%                
% Inputs:
%
% endPoints - (6 x numCyliners) real array of end-point coordinates.
%             endPoints(1:3,j) are the x, y and z coordinates for one
%             end of the axis of cylinder j and endPoints(4:6,j) are
%             the coordinates of the other end.
% radius    - real scalar, cylinder radius [m].
% numSides  - integer scalar, number of side of the regular polygon used
%             to render the cylinder. Must be >= 3.
%
% Outputs:
%
% mesh     - structure containing the unstructured mesh. See help for meshReadAmelet().
%
% Notes:
%
% 1. No attempt is made to deal with overlapping cylinders.
%

% 
% This file is part of aegmesher.
%
% aegmesher structured mesh generator and utilities.
% Copyright (C) 2014 Ian Flintoft
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
% Date: [FIXME]
% Version: 1.0.0

  numCylinders = size( endPoints , 2 );
  numNodesPerCylinder = ( 2 * numSides + 2 ); 
  numTrianglesPerCylinder = 4 * numSides;

  mesh.dimension = 3;
  mesh.numNodes = numNodesPerCylinder * numCylinders;
  mesh.nodes = zeros( 3 , mesh.numNodes );
  mesh.numElements = numTrianglesPerCylinder * numCylinders;
  elements = zeros( 3 , mesh.numElements );
  mesh.elementTypes = 11 .* ones( 1 ,  mesh.numElements );
  mesh.numGroups = 1;
  mesh.groupNames = { 'Cylinders' };
  mesh.groupTypes = [ 2 ];
  mesh.groups = sparse( 1:mesh.numElements );
  mesh.numgroupGroups = 0;
  mesh.groupGroupNames = {};
  mesh.groupGroups = sparse( [] );

  % Node coordinates on perimeter of lower end-cap in local coordinates.
  phip = 2 * pi / numSides .* (0:(numSides-1));
  rpA = [ radius .* cos( phip ) ; radius .* sin( phip ) ;  0.0 .* phip ];

  % Stencil for cylinder's elements (triangles). Use right-hand rule for outward normal.
  elementNodeStencil = [];
  for sideIdx=1:numSides
    sideIdx1 = rem( sideIdx , numSides ) + 1;
    elementNodeStencil = [ elementNodeStencil ; ...
                         sideIdx             , sideIdx1            , sideIdx + numSides ; ...
                         sideIdx1            , sideIdx1 + numSides , sideIdx + numSides ; ...
                         sideIdx1            , sideIdx             , 1 + 2 * numSides   ; ...
                         sideIdx  + numSides , sideIdx1 + numSides , 2 + 2 * numSides   ];
  end % for
  elementNodeStencil = elementNodeStencil';

  for cylIdx = 1:numCylinders;

    % End-points of cylinder axis.
    rA = endPoints(1:3,cylIdx);
    rB = endPoints(4:6,cylIdx);

    % Vector along axis.
    rAB = rB - rA;

    % Length of cylinder.
    h = norm( rAB );
 
    % Unit vector in direction of axis.
    n = ( rAB ) ./ h;

    % Spherical angles of cylinder axis.
    theta = acos( n(3) );
    phi = atan2( n(2) , n(1 ) );
 
    % Rotation matrices to align z-axis with cylinder axis.
    cos_phi = cos( phi );
    sin_phi = sin( phi );
    cos_theta = cos( theta );
    sin_theta = sin( theta );  
    Ry = [ cos_theta , 0 , sin_theta ; 0 , 1 , 0 ; -sin_theta , 0 , cos_theta ];
    Rz = [ cos_phi , -sin_phi , 0 ; sin_phi , cos_phi , 0 ; 0 , 0 , 1 ];

    % Location of cylinder's "upper" endpoint in local coordinates with rA at origin.
    rpB = rpA + [ zeros( 2 , numSides ) ; h .* ones( 1 , numSides ) ];
   
    % Node coordinates in this cylinder's local coordinates.
    thisNodes = [ rpA , rpB , [ 0 ; 0 ; 0 ] , [ 0 ; 0 ; h ] ];

    % Transform node local coordinates to global coordinates.
    mesh.nodes(1:3,(cylIdx-1)*numNodesPerCylinder+(1:numNodesPerCylinder)) = bsxfun(@plus , rA , Rz * Ry * thisNodes );

    % Add elements using stencil.
    thisCylinderElementIndices = ( cylIdx - 1 ) * numTrianglesPerCylinder + (1:numTrianglesPerCylinder);
    thisCylinderNodeOffset = ( cylIdx - 1 ) * numNodesPerCylinder;
    elements(1:3,thisCylinderElementIndices) = thisCylinderNodeOffset + elementNodeStencil;
 
  end % for

  % Sparsify elements array.
  mesh.elements = sparse( elements );

end % function

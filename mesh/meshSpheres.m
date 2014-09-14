function [ mesh ] = meshSpheres( centres , radii , numSides )
%
% meshspheres - create an simple triangular mesh of a number of 
%               spheres defined by their centres and radii.
%                
% Inputs:
%
% centres  - (3 x numSpheres) real array of centre coordinates.
% radii    - (3 x numSpheres) real scalar, sphere radius [m].
% numSides - integer scalar, number of side of the regular polygon used
%             to render the sphere. Must be >= 3.
%
% Outputs:
%
% mesh     - structure containing the unstructured mesh. See help for meshReadAmelet().
%
% Notes:
%
% 1. No attempt is made to deal with overlapping spheres.
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

  function [ vertices , faces ] = createElements( N , radius )
  %
  % Function to create vertices and faces for a sphere of given
  % radius centred on origin. Uses N "side" per line of latitude 
  % and longitude.

    % Step in theta and phi.
    d_theta = pi / N;
    d_phi = 2 * pi / N;
    
    % Theta angles of vertices.
    theta = linspace( d_theta, pi - d_theta , N - 1 );
    
    % North and south pole are vertex 1 and 2.
    vertices = [ 0 , 0 , radius ; 0 , 0 , -radius ];
    
    % Save vertix indices of first line of longitude.
    startVertexIdx = ( size( vertices , 1 ) + 1 ):( size( vertices , 1 ) + length( theta ) );
     
    % Create vertices on first line of longitude.
    x = radius .* sin( theta );
    y = radius .* sin( theta ) .* 0.0;      
    z = radius * cos( theta );
    vertices = [ vertices ; x' , y' , z' ];
    faces = [];

    % Iterate over lines of longitude.
    for phiIdx=1:(N-1)
    
      % Create new vertices.
      phi = phiIdx * d_phi;
      x = radius .* sin( theta ) .* cos( phi );
      y = radius .* sin( theta ) .* sin( phi );      
      z = radius * cos( theta );
      
      % Get indices of new vertices.
      newVertexIdx = ( size( vertices , 1 ) + 1 ):( size( vertices , 1 ) + length( theta ) );
      vertices = [ vertices ; x' , y' , z' ];

      % Create faces between current and last line of longitude.
      faces = [ faces ; 1 , newVertexIdx(2)-N, newVertexIdx(1) , NaN ; ...
        newVertexIdx(1:N-2)' , newVertexIdx(1:N-2)' - ( N - 1 )  , newVertexIdx(1:N-2)' - ( N - 2 ) , newVertexIdx(1:N-2)' + 1 ; ...
        newVertexIdx(N-2)+1 , newVertexIdx(N-2) - ( N - 2 )  , 2 , NaN ];

    end % for
  
    % Create faces between last line of longitude and the first.
    phi = N * d_phi;
    newVertexIdx = ( size( vertices , 1 ) + 1 ):( size( vertices , 1 ) + length( theta ) );
    faces = [ faces ; 1 , newVertexIdx(2)-N, startVertexIdx(1) , NaN ; ...
      startVertexIdx(1:N-2)' , newVertexIdx(1:N-2)' - ( N - 1 )  , newVertexIdx(1:N-2)' - ( N - 2 ) , startVertexIdx(1:N-2)' + 1 ; ...
      startVertexIdx(N-2)+1 , newVertexIdx(N-2) - ( N - 2 )  , 2 , NaN ];

    % Sanity check.
    idx = find( ~isnan(faces ) );      
    assert( all( unique(sort(faces(idx)))' == 1:(2+(N-1)*N) ) );
 
  end % function



  numSpheres = size( centres , 1 );

  lastNodeIdx = 0;
  lastElementIdx = 0;
  elements = [];
  mesh.nodes =[];
  mesh.elementTypes = [];

  for sphereIdx=1:numSpheres

    % Mesh sphere at origin.
    [ vertices , faces ] = createElements( numSides , radii(sphereIdx) );
    thisNumNodes = size( vertices , 1 );
    thisNumElements = size( faces , 1 );
    
    % Move vertices to correct centre.
    thisNodes = bsxfun( @plus , vertices , centres(sphereIdx,:) );
    mesh.nodes(1:3,lastNodeIdx+(1:thisNumNodes)) = thisNodes';
    
    % Add elements.
    triIdx = find( isnan( faces(:,4) ) );
    quadIdx = find( ~isnan( faces(:,4) ) ); 
    elements(1:3,lastElementIdx+triIdx) = lastNodeIdx+ faces(triIdx,1:3)';
    elements(1:4,lastElementIdx+quadIdx) = lastNodeIdx+ faces(quadIdx,1:4)';
    mesh.elementTypes(lastElementIdx+triIdx) = 11;
    mesh.elementTypes(lastElementIdx+quadIdx) = 13;  

    lastNodeIdx = lastNodeIdx + thisNumNodes;
    lastElementIdx = lastElementIdx + thisNumElements;

  end % for

  mesh.dimension = 3;
  mesh.numNodes = lastNodeIdx;
  mesh.numElements = lastElementIdx;
  
  % Sparsify elements array.
  mesh.elements = sparse( elements );
  
  mesh.numGroups = 1;
  mesh.groupNames = { 'Spheres' };
  mesh.groupTypes = [ 2 ];
  mesh.groups = sparse( mesh.numElements , 1 );
  mesh.groups(1:mesh.numElements,1) = (1:mesh.numElements)';
  mesh.numgroupGroups = 0;
  mesh.groupGroupNames = {};
  mesh.groupGroups = sparse( [] );
  
end % function

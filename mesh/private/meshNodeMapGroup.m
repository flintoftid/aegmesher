function [ nodeIndices ] = meshNodeMapGroup( mesh , groupIdx , lines , objBBox , idxBBox , options )
%
% meshNodeMaproup - Map all nodes in a group onto a structured mesh. Nodes are mapped as
%                   floating point indices to allow referencing positions anywhere in the mesh.
%
% [ nodeIndices ] = meshNodeMapGroup( mesh , groupIdx , lines , objBBox , idxBBox , options )
%
% Inputs:
%
% mesh       - structure containing the unstructured mesh. See help for meshReadAmelet().
% groupIdx   - scalar integer, index of group to map.
% lines      - structures contains mesh lines - see help for meshCreateLines.
% objBBox()  - real(6), AABB of group in real unit.
% idxBBox()  - integer(6), indeix AABB of group on structured mesh. 
% options    - structure containing options for intersection function - see help for meshTriRayIntersection().
%
% Outputs:
%
% nodeIndices() - real(nx3) array nodeBbox(nodeIdx,coordIdx) of bounding boxes of 
%                 structured mesh nodes for mapped group:
%
%                   coordIdx = 1: i
%                   coordIdx = 2: j
%                   coordIdx = 3: k
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
% Date: 01/09/2014
% Version: 1.0.0

%
% Algorithm:
%
% The parametrised line in the x-direction using mesh line x(i) as the origin is 
%
% x = x(i) + lambda * dx(i)
%
% where dx(i) = x(i+1) - x(i). All points between x(i) and x(i+1) have parameters 
% lambda such that lambda >= 0 and lambda <= 1. For each node coordinate x(j) we therefore
% construct lambda(i,j) = ( x(j) - x(i) ) / dx(i) and find the lowest line index for
% which the condition on lambda is met.
%
  
  % Default options.
  isFloatNodeIndices = true;

  % Parse options.
  if( nargin >= 6 )
    if( isfield( options , 'isFloatNodeIndices' ) )
      isFloatNodeIndices = options.isFloatNodeIndices;  
    end % if
  end % if

  % Mesh lines relative to group's computational volume.     
  xLocal = lines.x(idxBBox(1):idxBBox(4));
  yLocal = lines.y(idxBBox(2):idxBBox(5));
  zLocal = lines.z(idxBBox(3):idxBBox(6));

  % Intersection of CV with group. This could be degenerate!
  cvAABB = [ xLocal(1) , yLocal(1) , zLocal(1) , xLocal(end) , yLocal(end) , zLocal(end) ];
  
  % Get element indices to be mapped.
  elementIdx = nonzeros( mesh.groups(:,groupIdx) );
  % Get nodes indices for all mapped elements.
  nodeIdx = unique( nonzeros( mesh.elements(:,elementIdx) ) );   

  % Get the nodes.
  nodes = mesh.nodes(:,nodeIdx);

  % Delete nodes outside the computational volume.
  outIdx = find( cvAABB(1) >= nodes(1,:) & cvAABB(2) >= nodes(2,:) & cvAABB(3) >= nodes(3,:) & ...
                 nodes(1,:) >= cvAABB(4) & nodes(2,:) >= cvAABB(5) & nodes(3,:) >= cvAABB(6) );  
  nodes(:,outIdx) = [];

  % Initialise mapped node index array.
  numNodes = size( nodes , 2 );
  nodeIndices = zeros( numNodes , 6 );
 
  % Mesh lines in direction referencable form.
  clines{1} = lines.x;
  clines{2} = lines.y;
  clines{3} = lines.z;
    
  % Mesh deltas in direction referencable form.
  dl{1} = diff( lines.x );
  dl{2} = diff( lines.y );
  dl{3} = diff( lines.z );

  % Map each direction separately.
  for dir = 1:3;
    % Get node parameters of each node coordinate relative to each mesh line.  
    lambdas = bsxfun( @rdivide , bsxfun( @ minus ,  nodes(dir,:)  , clines{dir}(1:end-1)' ) ,  dl{dir}' );
    % Find nearest mesh lines below each node coordinate.
    [ lineIdx , nodeIdx ] = find( lambdas >= 0 & lambdas <= 1 );
    % Find unique mesh lines - take one with lowest index.
    [ nodeIdx , idx ] = unique( nodeIdx );
    lineIdx = lineIdx(nodeIdx);
    assert( all( sort( nodeIdx' ) == 1:numNodes ) );
    % Get the corresponding lambdas for nodes' mesh lines.
    nodeLambdas = lambdas( sub2ind( size( lambdas ) , lineIdx, nodeIdx ) );
    % Assemble indices.
    if( isFloatNodeIndices )
      nodeIndices(:,dir) = lineIdx + nodeLambdas;
    else
      nodeIndices(:,dir) = floor( lineIdx );
    end % if
    % Pack into output array.
    nodeIndices(:,dir+3) = nodeIndices(:,dir);
    assert( nodeIndices(:,dir) <= length( clines{dir} ) );
  end % for dir
 
  assert( size( nodeIndices , 1 ) == numNodes );
  
  fprintf( '  Mapped group to %d structured nodes\n' , numNodes );
 
end % function

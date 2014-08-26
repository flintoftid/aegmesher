function [ isX , isY , isZ ] = meshLineMapGroup( mesh , groupIdx , lines , objBBox , idxBBox , options )
%
% meshLineMapGroup - Map a line group from an unstructured mesh onto a structured mesh.
%
% [ isX , isY , isZ ] = meshLineMapGroup( mesh , groupIdx , lines , objBBox , idxBBox , options )
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
% isX()       - boolean(nx,ny,nz), boolean isX(i,j,k) indicating whether the x-directed edge
%               from (i,j,k) to (i+1,j,k) belongs to the group been mapped. Note that the indices
%               are relative to the group's AABB in idxBBox.
% isY()       - boolean(nx,ny,nz), boolean isY(i,j,k) indicating whether the y-directed edge
%               from (i,j,k) to (i,j+1,k) belongs to the group been mapped. Note that the indices
%               are relative to the group's AABB in idxBBox.
% isZ()       - boolean(nx,ny,nz), boolean isZ(i,j,k) indicating whether the z-directed edge
%               from (i,j,k) to (i,j,k+1) belongs to the group been mapped. Note that the indices
%               are relative to the group's AABB in idxBBox.
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
% Date: 29/07/2014
% Version: 1.0.0
% Proof of concept line object mapper.
% Needs validation and optimisation/vecotrisation.

  % Range of segment sampling densities.
  options.minLineSegDensity = 2;
  options.maxLineSegDensity = 16;

  % Number of cells in group's sub-grid.
  numCells = idxBBox(4:6) - idxBBox(1:3) + 1;     

  % Includeness array for edges of mesh occupied by object.
  isX = false( numCells(1) , numCells(2) , numCells(3) );  
  isY = false( numCells(1) , numCells(2) , numCells(3) );  
  isZ = false( numCells(1) , numCells(2) , numCells(3) );  

  % Mesh lines relative to group's computational volume.     
  xLocal = lines.x(idxBBox(1):idxBBox(4));
  yLocal = lines.y(idxBBox(2):idxBBox(5));
  zLocal = lines.z(idxBBox(3):idxBBox(6));

  % Get groups elements
  elementIdx = nonzeros( mesh.groups(:,groupIdx) );

  % Extract line segments into full array.
  segments = full(mesh.elements(1:2,elementIdx));

%    % Get node counts. Currenlty we assume there are no closed loops 
%    % in the curve except for the case where the whole curve is closed.
%    nodeCount = ( sparse( segments , 1 , 1 ) );
%  
%    % Distinct end points should only occur once.
%    endNodeIdx = find( nodeCount == 1 );
%    
%    if( isempty( endNodeIdx ) )
%      % Must be a closed curve. Arbitrarily take first node as start/end point.
%      isClosed = true;
%      startNode = segments(1,1);
%      endNode = segments(1,1);
%      segment = segments(1,:);
%      lastNode = sum( segment .* ( segment ~= startNode ) );
%      segments(1,:) = [];
%      orderedNodes = [ startNode , lastNode ];
%      else
%      % Open curve.
%      isClosed = false;
%      startNode = endNodeIdx(1);
%      endNode = endNodeIdx(2);
%      lastNode = startNode;  
%      orderedNodes = [ startNode ];
%    end % if
%  
%    % Assemble segments into order. Assumes no internal loops.
%    while( ~isempty( segments ) )
%      idx = find( any( segments == lastNode , 2 ) );
%      assert( length( idx ) == 1 );
%      segment = segments(idx,:);
%      lastNode = sum( segment .* ( segment ~= lastNode ) );
%      orderedNodes = [ orderedNodes , lastNode ];
%      segments(idx,:) = [];
%    end % while  
%  
%    assert( lastNode == endNode );

  % Count number of structured edges added for this line object.
  edgeCount = 0;

  % Loop over segments of unstructured curve.
  for segIdx=1:size( segments , 2 )

    % Get node indices of segment.
    segBeginNodeIdx = segments(1,segIdx);
    segEndNodeIdx = segments(2,segIdx);    

    % Get coordinates of segment end points.
    segBeginNodeCoords = full( mesh.nodes( 1:3 , segBeginNodeIdx ) );
    segEndNodeCoords = full( mesh.nodes( 1:3 , segEndNodeIdx ) );
    
    % [FIXME] If one or both end points is outside the grid lines find
    % points of intersection with AABB of grid lines and truncate segment.
    
    % Closest point in structured mesh to beginning of segment. 
    [ xBegin , iBegin ] = min( abs( xLocal - segBeginNodeCoords(1) ) );
    [ yBegin , jBegin ] = min( abs( yLocal - segBeginNodeCoords(2) ) );
    [ zBegin , kBegin ] = min( abs( zLocal - segBeginNodeCoords(3) ) );
    % [FIXME] Deal with multiple eqidistant points? For now pick one with lowest indices.
    iBegin = iBegin(1);
    jBegin = jBegin(1);
    kBegin = kBegin(1);
    ijkBegin = [ iBegin , jBegin , kBegin ];
  
    % Closest point in structured mesh to end of segment.
    [ xEnd , iEnd ] = min( abs( xLocal - segEndNodeCoords(1) ) );
    [ yEnd , jEnd ] = min( abs( yLocal - segEndNodeCoords(2) ) );
    [ zEnd , kEnd ] = min( abs( zLocal - segEndNodeCoords(3) ) );
    % [FIXME] Deal with multiple eqidistant points? For now pick one with lowest indices.
    iEnd = iEnd(1);
    jEnd = jEnd(1);
    kEnd = kEnd(1);
    ijkEnd = [ iEnd , jEnd , kEnd ];

    % Direction vector of segment.
    segDir = segEndNodeCoords - segBeginNodeCoords;
    segLength = sqrt( sum( abs( segDir ).^2 ) );
    
    % If structured segment is degenerate move to next segment. 
    % Otherwise find smallest mesh internal internal within the segment's AABB.
    if( ijkBegin == ijkEnd )
      continue;
    else
      ilAABB = min( [ iBegin , iEnd ] );
      ihAABB = max( [ iBegin , iEnd ] );
      jlAABB = min( [ jBegin , jEnd ] );
      jhAABB = max( [ jBegin , jEnd ] );
      klAABB = min( [ kBegin , kEnd ] );
      khAABB = max( [ kBegin , kEnd ] );
      minMeshSize = min( [ diff( xLocal(ilAABB:ihAABB) ) , diff( yLocal(jlAABB:jhAABB) ) , diff( zLocal(klAABB:khAABB) ) ] );
    end % if

    % Determine initial sampling length of segment based on mesh line density.
    % Sample internal is half smallest mesh interval within segment's AABB.
    segmentDensity = options.minLineSegDensity;
    dt = min( [ 1.0 , 1.0 / ( segLength / minMeshSize * segmentDensity ) ] );
    
    % Set position in structured mesh to start of segment.
    iLast = iBegin;
    jLast = jBegin;
    kLast = kBegin;     
    tLast = 0.0;

    % Walk along the segment sampling points and checking for the
    % nearest structured mesh point.
    while( true )

      % Get parameter of next sample point. Don't walk off end!
      tCurrent = min( [ 1 , tLast + dt ] );
      
      % Coordinates of sample point.
      point = segBeginNodeCoords + tCurrent .* segDir;

      % Closest structured mesh point to sample point.
      [ xCurrent , iCurrent ] = min( abs( xLocal - point(1) ) );
      [ yCurrent , jCurrent ] = min( abs( yLocal - point(2) ) );
      [ zCurrent , kCurrent ] = min( abs( zLocal - point(3) ) );
      
      % [FIXME] Deal with multiple eqidistant points? For now pick one with lowest indices.
      iCurrent = iCurrent(1);
      jCurrent = jCurrent(1);
      kCurrent = kCurrent(1);

      % Determine index shifts for closest point in structured to sample point
      % relative to last node on segment in structured mesh.
      idxShift = [ iCurrent , jCurrent , kCurrent ] - [ iLast , jLast, kLast ];

      % Structured cell index should only change by -1, 0 or +1. Otherwise
      % we half the sampling increment (double the density) and try again.
      if( any( abs( idxShift ) > 1 ) )
        if( segmentDensity <= options.maxLineSegDensity )
          segmentDensity = 2 * segmentDensity;
          dt = 1.0 / ( segLength / minMeshSize * segmentDensity );
          fprintf( '  Segment density increased!\n' );
          continue;
        else
          error( 'Reached maximum segment sampling density - increase maximum density, increase output mesh density or reduce input mesh density' );
        end % if
      end % if

      % Add edges along the directions of the index shifts. 
      % When more then one direction changes simultaneously we currently
      % always traverse the edges in the same order: x, y then z. 
      % [FIXME] This will break symmetries - maybe should do all +1s first than all -1s?
      % [FIXME] Maybe we should randomise this?
      if(  idxShift(1) == -1 )
        isX(iCurrent,jLast,kLast) = true;
        edgeCount = edgeCount + 1;
        iLast = iCurrent;
      elseif( idxShift(1) == 1 )      
        isX(iLast,jLast,kLast) = true;
        edgeCount = edgeCount + 1;        
        iLast = iCurrent;
      end % if
      
      if(  idxShift(2) == -1 )
        isY(iLast,jCurrent,kLast) = true;
        edgeCount = edgeCount + 1;        
        jLast = jCurrent;
      elseif(  idxShift(2) == 1 )  
        isY(iLast,jLast,kLast) = true;
        edgeCount = edgeCount + 1;        
        jLast = jCurrent;        
      end % if

      if(  idxShift(3) == -1 )
        isZ(iLast,jLast,kCurrent) = true;
        edgeCount = edgeCount + 1;        
        kLast = kCurrent;            
      elseif(  idxShift(3) == 1 )  
        isZ(iLast,jLast,kLast) = true;
        edgeCount = edgeCount + 1;        
        kLast = kCurrent;       
      end % if

      % Should have reached the current sample point.
      assert( all( [ iLast , jLast , kLast ] == [ iCurrent , jCurrent , kCurrent ] ) );

      % Increment.
      iLast = iCurrent;
      jLast = jCurrent;
      kLast = kCurrent;
      tLast = tCurrent;
      
      % If we've just done the last sample point break out.
      if( tLast == 1 )
        break;
      end % if

    end % for
      
    % Should have reached the end of the segment.
    assert( all( [ iLast , jLast , kLast ] == ijkEnd ) );
  
  end % for

  fprintf( '  Mapped group to %d structured edges\n' , edgeCount );
  
end % function


function [ x ] = meshCreateNonUniformMeshLinesMB( meshGroup , ratio , L_min , BboxMeshDensity , direction )
%
% meshCreateNonUniformMeshInterval - Calculates a non-uniform mesh in between a fix interval.
%
% Usage:
%
% [ x ] = meshCreateNonUniformMeshLinesMB( meshGroup , ratio, L_min , BboxMeshDensity , direction )
%
% Inputs:
%
% meshGroup         - real array containing interval boundaries and dmax:
%
%                     meshGroup(i,1) low coordinate of i-th interval
%                     meshGroup(i,2) high coordinate of i-th interval
%                     meshGroup(i,3) maximum mesh size of i-th interval
%
% ratio             - real scalar defining global mesh ratio
% L_min             - real scalar defining global min mesh size
% BboxMeshDensity   - real scalar defining mesh density of free space between not overlapping objects
% direction         - string defining current x, y or z direction
%
% Outputs:
%
% x                 - real array containing non-uniform mesh lines
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
% Author: M. Berens
% Date: 12/10/2013
% Version 1.0.0

  % Global tolerance.
  eps = 10e-6;

  options.lineAlgorithm = 'OPTIM1';
  options.costAlgorithm = 'RMS';  
  options.maxOptimTime = 5;
  options.maxOptimEvals = 10000;
  options.costFuncTol = 1e-6;
  options.isPlot = false;
  options.epsCompVol = 1e-6;

  %
  % Create projection of intervals in dependance of max mesh size.
  %
  
  % Case 1: Intervalls are exactly overlapping.
  if( size( meshGroup(:,1:2) , 1 ) ~= size( unique( meshGroup(:,1:2) , 'rows' ) , 1 ) )
    
    if( size( unique( meshGroup(:,1:2) , 'rows' ) , 1 ) ~= 1 )
    
      % NOT all intervals are overlapping.    
      del = [];
      for i = 1: size(meshGroup(:,1:2),1)
        A = find( meshGroup(i,1) == meshGroup(:,1) );
        B = find( meshGroup(i,2) == meshGroup(:,2) );
        [ Lia , Locb ] = ismember( A , B , 'rows' );
        Locb = nonzeros( Locb );
        if( ~isempty( Locb ) && meshGroup(i,3) ~= min( meshGroup(A(Locb),3) ) )
          del = [ del i ];
        end % if
      end % for
      meshGroup(del,:) = [];
      clear A B Lia Locb del
        
    else 
    
      % ALL intervals are overlapping  
      eq = find( find( meshGroup(:,1) == unique( meshGroup(:,1) ) ) == find( meshGroup(:,2) == unique( meshGroup(:,2) ) ) );
       
      % Chose smallest mesh size for all intervalls.
      tmpMin = min( meshGroup(eq,3) ); 
      meshGroup(eq(1),:) = [ unique( meshGroup(:,1:2) , 'rows' ) , tmpMin ];
      meshGroup(eq(2:end),:) = [];       
      %[ x_tmp ] = meshCreateUniformMeshInterval( diff(meshGroup(1:2)) , meshGroup(3) , L_min );  
      %x = meshGroup(1) + x_tmp;
      [ x , ~ ] = meshCreateUniformMeshLines( meshGroup(1:2) , ones( size( meshGroup(1:2) ) ) , L_min ,  meshGroup(3) , direction , options );
      x(1) = meshGroup(1);
      x(end) = meshGroup(2);
      fprintf( 'Non-uniform mesh ratio in %c-direction is satisfied \n', direction );
      fprintf( 'Alignment with intervals in %c-direction is satisfied \n', direction );
      fprintf( 'Maximum mesh size of intervals in %c-direction is satisfied \n', direction );
      return;
        
    end % if
    
  end % if

  % Case 2: All intervalls have no thickness.
  if( ~all( diff(meshGroup(:,1:2),1,2) ) )
    %[ x_tmp ] = meshCreateUniformMeshInterval( diff( meshGroup(1:end,1) ) , max( meshGroup(:,3) ) , L_min );
    %x = meshGroup(1) + x_tmp;
    [ x , ~ ] = meshCreateUniformMeshLines( meshGroup(1:end,1) , ones( size( meshGroup(1:end,1) ) ) , L_min ,  max( meshGroup(:,3) ) , direction , options );
    x(1) =  meshGroup(1,1);
    x(end) =  meshGroup(end,1);    
    fprintf( 'Non-uniform mesh ratio in %c-direction is satisfied \n', direction );
    fprintf( 'Alignment with intervals in %c-direction is satisfied \n', direction );
    fprintf( 'Maximum mesh size of intervals in %c-direction is satisfied \n', direction );
    return;
    
  end % if
  
  % Case 3: Intervalls overlap in a normal way.
  constPointList = sort( [ meshGroup(:,1) ; meshGroup(:,2) ] );
  for i = 2:length( constPointList )
    tmp = ( meshGroup(:,1) < constPointList(i) ) == ( meshGroup(:,2) >= constPointList(i) );  
    if( ~any( tmp ) )
      % Free space gap in between objects.
      meshSizeList(i-1) = BboxMeshDensity;
    else
      meshSizeList(i-1) = min( meshGroup(tmp,3) );
    end % if
  end % for

  %
  % Identify the optimal mesh density at interval boundaries.
  %

  %
  % Step 1: Mesh density at interval boundaries defined by geometric progression -> "green points".
  %
  
  % Create 1D projection: meshGroup = [leftBoundary rightBoundary meshDensity].
  for i = 1:length( meshSizeList )
    meshGroup(i,:) = [ constPointList(i) , constPointList(i+1) , meshSizeList(i) ];
  end % for

  % Delete intervals with no thickness.
  if( any( meshGroup(1:end,1) == meshGroup(1:end,2) ) )
    meshGroup( find((meshGroup(1:end,1) == meshGroup(1:end,2)) == 1),:) = [];
  end % if

  meshGroup = sortrows(meshGroup,3);

  greenPoints = [];
  greenPointsLeft = ones( size(meshGroup,1) , size(meshGroup,1) , 2) * 9.9999;
  greenPointsRight = ones( size(meshGroup,1) , size(meshGroup,1) , 2) * 9.9999;
  redPoints = [];

  % Create GP for all neighbour intervals.
  % greenPointsLeft/greenPointsRight[:,:,1] = interval boundary
  % greenPointsLeft/greenPointsRight[:,:,2] = boundary mesh density
  for i = 1:size(meshGroup,1)
    
    N_min = [];
    N_max = [];
    Neighbor = [];
    dxA = [];
    
    if( meshGroup(i,1) == min( meshGroup(:,1) ) )
    
      % Left boundary.
        
      % Right neighbor intervals.
      Neighbor = find( meshGroup(:,1) >= meshGroup(i,2) );
      L = meshGroup(Neighbor,2) - meshGroup(Neighbor,1);
      dxA = meshGroup(i,3);
        
      for j = 1:length(Neighbor) 
        % Continue GP unilt last neighbour.
        if dxA/ratio < L(j) 
          % First cell in interval is bigger than interval itself.
          [ dDeltaMax r ] = geometricProgression( dxA, L(j), ratio );      
          if( isempty(dDeltaMax) )
            % GP fails.
            dDeltaMax = L;
          end % if       
          greenPointsRight(i,j,:) = [ meshGroup(Neighbor(j),2) , dDeltaMax(end) ];
        else
          % Set interval as one cell (could break ratio).
          dDeltaMax = L(j);
          greenPointsRight(i,j,:) = [ meshGroup(Neighbor(j),2) , dDeltaMax(end) ];
        end % if
        dxA = dDeltaMax(end);
      end % for
        
      continue;
        
    elseif( meshGroup(i,2) == max( meshGroup(:,2) ) )
    
      % Right boundary.
        
      % Left neighbor intervals.
      Neighbor = find( meshGroup(:,2) <= meshGroup(i,1) );
      L = meshGroup(Neighbor,2) - meshGroup(Neighbor,1);
      dxA = meshGroup(i,3);
        
      for j = 1:length(Neighbor) 
        % Continue GP unilt last neighbour.
        if( dxA / ratio < L(j) )
          % First cell in interval is bigger than interval itself.
          [ dDeltaMax r ] = geometricProgression( dxA , L(j) , ratio );               
          if( isempty( dDeltaMax ) )
            % GP fails.
            dDeltaMax = L;
          end; % if
          greenPointsLeft(i,j,:) = [ meshGroup(Neighbor(j),1) , dDeltaMax(end) ];
        else
          % Set interval as one cell (could break ratio).
          dDeltaMax = L(j); 
          greenPointsLeft(i,j,:) = [ meshGroup(Neighbor(j),1) , dDeltaMax(end) ];
        end % if
        dxA = dDeltaMax(end);
      end % for
        
      continue;

    end % if
    
    % Left neighbor intervals.
    
    Neighbor = find( meshGroup(:,2) <= meshGroup(i,1) );
    L = meshGroup(Neighbor,2) - meshGroup(Neighbor,1);
    % Sort neighbor intervals by order.
    [ tmp , order ] = sort( meshGroup(Neighbor,2) , 'descend' );
    Neighbor = Neighbor(order);
    L = L(order);
    clear tmp order
    
    dxA = meshGroup(i,3);
    
    for j = 1:length(Neighbor) 
      % Continue GP until last neighbor.
      if( dxA / ratio < L(j) )
        % First cell in interval is bigger than interval itself.
        [ dDeltaMax r ] = geometricProgression( dxA , L(j) , ratio );
        if( isempty( dDeltaMax) )
          % GP fails.
          dDeltaMax = L; 
        end % if
        greenPointsLeft(i,j,:) = [ meshGroup(Neighbor(j),1) , dDeltaMax(end) ];
      else
        % Set interval as one cell (could break ratio).
        dDeltaMax = L(j); 
        greenPointsLeft(i,j,:) = [ meshGroup(Neighbor(j),1) , dDeltaMax(end) ];
      end % if
      dxA = dDeltaMax(end);    
    end % for
    
    % Right neighbor intervals
    
    Neighbor = find( meshGroup(:,1) >= meshGroup(i,2) );
    L = meshGroup(Neighbor,2) - meshGroup(Neighbor,1);
    % Sort neighbor intervals by order.
    [ tmp , order ] = sort( meshGroup(Neighbor,2) , 'ascend' );
    Neighbor = Neighbor(order);
    L = L(order);
    clear tmp order
    
    dxA = meshGroup(i,3);
    
    for j = 1:length(Neighbor) 
      % Continue GP until last neighbor.
      if( dxA / ratio < L(j) )
        % First cell in interval is bigger than interval itself.
        [ dDeltaMax r ] = geometricProgression( dxA , L(j) , ratio );           
        if( isempty( dDeltaMax ) )
          % GP fails.
          dDeltaMax = L; 
        end; % if
        greenPointsRight(i,j,:) = [ meshGroup(Neighbor(j),2) , dDeltaMax(end) ];
      else
        % Set interval as one cell (could break ratio).
        dDeltaMax = L(j);
        greenPointsRight(i,j,:) = [ meshGroup(Neighbor(j),2) , dDeltaMax(end) ];
      end % if
      dxA = dDeltaMax(end);
    end % for
    
  end % for i

  clear tmp order

  %
  % Step 2: Mesh density at interval boundaries and middle parts defined by geometric 
  % progression and user definition ->"red points".
  %

  % Chose smallest GP solution for each interval boundary.
  % greenPoints = [boundary meshDensity]
  for i = 1:size( meshGroup , 1 )
    currentBoundary = meshGroup(i,1);
    greenPoints(i,1) = currentBoundary;
    greenPoints(i,2) = min( [ greenPointsLeft(  size( greenPointsLeft(:,:,1)  , 1 ) * size( greenPointsLeft(:,:,1)  , 2 ) + find( greenPointsLeft(:,:,1)  ==currentBoundary ) ) ; ...
                              greenPointsRight( size( greenPointsRight(:,:,1) , 1 ) * size( greenPointsRight(:,:,1) , 2 ) + find( greenPointsRight(:,:,1) ==currentBoundary ) ) ] );
  end % for

  % Chose smallest GP solution for last interval boundary on right side.
  currentBoundary = max( meshGroup(:,2) );
  greenPoints(end+1,1) = currentBoundary;
  greenPoints(end,2) = min( [ greenPointsLeft(  size( greenPointsLeft(:,:,1) , 1 )  * size( greenPointsLeft(:,:,1) , 2 )  + find( greenPointsLeft(:,:,1)  == currentBoundary ) ) ; ...
                              greenPointsRight( size( greenPointsRight(:,:,1) , 1 ) * size( greenPointsRight(:,:,1) , 2 ) + find( greenPointsRight(:,:,1) == currentBoundary ) ) ] );

  greenPoints = sortrows(greenPoints);

  clear greenPointsLeft greenPointsRight r

  % create red point array
  % redPoints = [leftIntervalBoundary rightIntervalBoundary leftBoundaryMeshDensity middlePartMeshDensity rightBoundaryMeshDensity]
  %
  % redPoints = ones(size(meshGroup,1),4)*99999;
  % first interval is the smallest one
  redPoints(1,:) = [ meshGroup(1,1) , meshGroup(1,2) , meshGroup(1,3) , meshGroup(1,3) ];

  for i = 2:size( meshGroup ,1 )
    redPoints(i,:) = [ meshGroup(i,1:2) ...
        min([ ...
          meshGroup(i,3) ...                                    % Mesh density of current interval.
          greenPoints(meshGroup(i,1) == greenPoints(:,1),2) ... % GP from the right and left.
          redPoints(meshGroup(i,1) == redPoints(:,2),4) ...     % Former smaller red points on the rigth side.
          redPoints(meshGroup(i,1) == redPoints(:,1),3) ...     % Former smaller red points on the left side.
        ]) ...
        min([ ...
          meshGroup(i,3) ...                                    % Mesh density of current interval.
          greenPoints(meshGroup(i,2) == greenPoints(:,1),2) ... % GP from the right and left.
          redPoints(meshGroup(i,2) == redPoints(:,2),4) ...     % Former smaller red points on the rigth side.
          redPoints(meshGroup(i,2) == redPoints(:,1),3) ...     % Former smaller red points on the left side.
        ]) ...
      ];
  end % for

  %
  % Step 3: Creating mesh lines.
  %
  
  redPoints(:,5) = redPoints(:,4);
  redPoints(:,4) = meshGroup(:,3);
  redPoints = sortrows( redPoints );
  x = [];

  % Solve local mesh problem.
  for i = 1:size( redPoints , 1 )
  
    x_tmp = [];
    currentRedPoint = redPoints(i,:);
    L = redPoints(i,2) - redPoints(i,1);
    
    dxA = currentRedPoint(3);
    dxmax = currentRedPoint(4);
    dxB = currentRedPoint(5);
    
    % Consider left side.
    % Minimum number of steps until mesh size is bigger than the maximum mesh size.
    % [FIXME] Should this be floor?
    i_A = floor( 1 + ( log( dxmax / dxA ) / log( ratio ) ) );
    %i_A = ceil( 1 + ( log( dxmax / dxA ) / log( ratio ) ) );
        
    % Size of the last mesh size.
    % dDeltaMaxLeft = dxA * ratio^(i_A - 1);
    
    % Length of GP on the left side of interval.
    L_A = dxA * ( 1 - ratio^i_A ) / ( 1 - ratio );
    
    % Minimum number of steps until mesh size is bigger than the maximum mesh size.
    % [FIXME] Should this be floor?
    i_B = floor( 1 + ( log( dxmax / dxB ) / log( ratio ) ) );
    %i_B = ceil( 1 + ( log( dxmax / dxB ) / log( ratio ) ) );
    
    % Size of the last mesh size.
    % dDeltaMaxRight = dxB * ratio^(i_B - 1);
    
    % Length of GP on the right side of interval.
    L_B = dxB * ( 1 - ratio^i_B ) / ( 1 - ratio );
     
    % Check if intersection point is inside the interval.
    if( ( L - L_B + L_A ) / 2 < 0 || ( L - L_B + L_A ) / 2 > L )
      dxmax = max( dxA,dxB );
      i_A = ceil( round( 1 + ( log( dxmax / dxA ) / log( ratio ) ) * 1e4 ) / 1e4 );
      L_A = dxA * ( 1 - ratio^i_A ) / ( 1 - ratio );
      i_B = ceil( round( 1 + ( log( dxmax / dxB ) / log( ratio ) ) * 1e4 ) / 1e4 );
      L_B = dxB * ( 1 - ratio^i_B ) / ( 1 - ratio );
    end % if
    
    if( L > L_A + L_B )
      % **** CASE 1 ****   
      % Create interval mesh with uniform part in the middle.
      
      % Length of the middle part.
      L_M = L - L_A - L_B;
      % Left GP.
      [ dDeltaLeft rA ] = geometricProgression( dxA , L - L_M - L_B , ratio );
      dDeltaLeft = unique( dDeltaLeft );
      % Right GP.
      [ dDeltaRight rB ] = geometricProgression( dxB , L - L_M - L_A , ratio );
      dDeltaRight = unique( dDeltaRight );
        
      % Middle part is too small for creating uniform mesh lines.
      % -> middle part will be neglected by using only GP.
      % --> this will marginally break the maximum mesh size.
      if( L_M < max( dDeltaLeft ) / ratio || L_M < max( dDeltaRight ) / ratio )
            
        x_tmp = 0;
        % Intersection point of left and right linear progressions.
        intersection = ( L - L_B + L_A ) / 2;
        % New left GP until intersection point.
        [ dDeltaLeft rA ] = geometricProgression( dxA , intersection , ratio );
        dDeltaLeft = unique( dDeltaLeft );
        % New right GP until intersection point.
        [ dDeltaRight rB ] = geometricProgression( dxB , L - sum( dDeltaLeft ) , ratio );
        dDeltaRight = unique( dDeltaRight );
        
        % Add left mesh lines.
        while( numel( dDeltaLeft ) ~= 0 )
          x_tmp = [ x_tmp x_tmp(end) + dDeltaLeft(1) ];
          dDeltaLeft(1) = [];
        end % while
        % Add right mesh lines.
        while( numel( dDeltaRight ) ~= 0 )
          x_tmp = [ x_tmp x_tmp(end) + dDeltaRight(end) ];
          dDeltaRight(end) = [];
        end % while
            
      else 
        % Create middle part.
            
        % Identify length of middle part
        deltaX = [ L - sum( [ dDeltaLeft , dDeltaRight ] ) ];
        % Create uniform mesh for the middle part.
        %[ x_tmp ] = meshCreateUniformMeshInterval( deltaX , dxmax , L_min );        
        [ x_tmp , ~ ] = meshCreateUniformMeshLines( [ 0.0 , cumsum( deltaX ) ] , ones( 1 , 1 + numel( deltaX ) ) , L_min ,  dxmax , direction , options );        
        x_tmp(1) = 0.0;
        x_tmp(end) = sum( deltaX );
        % If middle part is too small to satisfy the ratio condition.
        if( length( x_tmp ) == 2 && x_tmp(2) - x_tmp(1) + eps < dxmax / 2 )
          if( dxA < dxB )
            % Left GP.
            [ dDeltaLeft rB ] = geometricProgression( dxA , L - dxB , ratio );         
            if isempty( dDeltaLeft )
              [ dDeltaLeft rB ] = geometricProgression( dxA , L - L_M - L_B , ratio );
              x_tmpDiff = diff( [ x_tmp(1) , mean( x_tmp ) ] );
              dDeltaRight = [ dDeltaRight(1) - x_tmpDiff dDeltaRight(1) - x_tmpDiff ];
              x_tmp = dDeltaLeft(1);
            else
              dDeltaLeft = [ dxA , dDeltaLeft ];
              dDeltaLeft = unique( dDeltaLeft );
              x_tmp = sum( dDeltaLeft );
            end % if                      
          else
            % Right GP.
            [ dDeltaRight rB ] = geometricProgression( dxB , L - dxA , ratio );              
            if( isempty( dDeltaRight ) )
              [ dDeltaRight rB ] = geometricProgression( dxB , L - L_M - L_A , ratio );
              x_tmpDiff = diff( [ x_tmp(1) , mean( x_tmp ) ] );
              dDeltaRight = [ dDeltaRight(1) - x_tmpDiff dDeltaRight(1) - x_tmpDiff ];
              x_tmp = dDeltaLeft(1);
            else
              dDeltaRight = [ dxB , dDeltaRight ];
              dDeltaRight = unique( dDeltaRight );
              x_tmp = dDeltaLeft(1);
            end % if
          end % if
        else
          x_tmp = x_tmp + sum( dDeltaLeft );
        end % if
            
        % Check transition between GP parts and middle part.
        if( length( x_tmp ) > 1 )
          diff_x = diff( x_tmp );
        else 
          diff_x = x_tmp; 
        end
        diff_xLeft = dDeltaLeft;
        diff_xRight = dDeltaRight;
            
        if( min( diff_x ) ~= sum( dDeltaLeft ) && max( diff_x ) ~= deltaX )
        
          % Check if ratio is small enough between middle part and GP parts.
          while( (diff_x(1) / max( diff_xLeft ) - eps > ratio || diff_x(end) / max( diff_xRight ) - eps > ratio ) && L_min + eps < max( [ dDeltaLeft dDeltaRight ] ) )
            x_tmp = [];
            %[ x_tmp ] = meshCreateUniformMeshInterval( deltaX , min( dDeltaLeft , dDeltaRight ) , L_min );
            [ x_tmp , ~ ] = meshCreateUniformMeshLines( [ 0 , cumsum( deltaX ) ] , ones( 1 , 1 + numel( deltaX ) ) , L_min , min( [ dDeltaLeft , dDeltaRight ] ) , direction , options );   
            x_tmp(1) = 0.0;
            x_tmp(end) = sum( deltaX );
            if( length( x_tmp ) > 1 )
              diff_x = diff( x_tmp ); 
            else 
              diff_x = x_tmp; 
            end % if
            diff_xLeft = dDeltaLeft;
            diff_xRight = dDeltaRight;        
            if( length( x_tmp ) == 2 && x_tmp(2) - x_tmp(1) < dxmax / 2 )
              x_tmpDiff = diff( [ x_tmp(1) , mean( x_tmp ) ] );
              dDeltaLeft(1) = dDeltaLeft(1) + x_tmpDiff;
              dDeltaRight(1) = dDeltaRight(1) + x_tmpDiff;
              x_tmp = dDeltaLeft(1);
            else
              x_tmp = x_tmp + sum( dDeltaLeft );
            end % if
          end % while
                                
          % Check if ratio is big enough between middle part and GP parts.
          L_min_ = L_min;
          while( ( diff_x(1) / max( diff_xLeft ) + eps < 1 / ratio || diff_x(end) / max( diff_xRight ) + eps < 1 / ratio ) && L_min + eps < max( [ dDeltaLeft , dDeltaRight ] ) )
            L_min_ = L_min_ * ratio;
            % Exception.
            if( L_min_ > dxmax )
              % fprintf( 'Exception in %c-direction: impossible to satisfied ratio\n' , direction );
              break;
            end % if
            x_tmp = [];
            [ x_tmp ] = meshCreateUniformMeshInterval( deltaX , dxmax , L_min_ );
            [ x_tmp2 , ~ ] = meshCreateUniformMeshLines( [ 0 , cumsum( deltaX ) ] , ones( 1 , 1 + numel( deltaX ) ) , L_min_ , dxmax , direction , options );

 %format long
%0.0
%x_tmp(1)
%x_tmp2(1)
%x_tmp(end)
%x_tmp2(end)
%cumsum( deltaX )

            if( length( x_tmp ) > 1 )
              diff_x = diff( x_tmp ); 
            else 
              diff_x = x_tmp; 
            end % if
            diff_xLeft = dDeltaLeft;
            diff_xRight = dDeltaRight;
                    
            if( length( x_tmp ) == 2 && x_tmp(2) - x_tmp(1) < dxmax / 2 )
              x_tmpDiff = diff( [ x_tmp(1) , mean( x_tmp ) ] );
              dDeltaLeft(1) = dDeltaLeft(1) + x_tmpDiff;
              dDeltaRight(1) = dDeltaRight(1) + x_tmpDiff;
              x_tmp = dDeltaLeft(1);
            else
              x_tmp = x_tmp + sum( dDeltaLeft );
            end % if
          end % while
                                
          % If second while loop undo first while loop.
          % Idea: GP from smaller mesh size to bigger one.
          if( ( diff_x(1) / max( diff_xLeft ) - eps > ratio || diff_x(end) / max( diff_xRight ) - eps > ratio ) && L_min + eps < max( [ dDeltaLeft dDeltaRight ] ) )
            if( dxA < dxB )
              % Left GP.
              [ dDeltaLeft rB ] = geometricProgression( dxA , L - dxB , ratio );
              dDeltaLeft = unique( dDeltaLeft );
              x_tmp = dDeltaRight(1);
            else
              % Right GP.
              [ dDeltaRight rB ] = geometricProgression( dxB , L - dxA , ratio );
              dDeltaRight = unique( dDeltaRight );
              x_tmp = dDeltaLeft(1);
            end % if
          end % if
                 
          clear diff_x diff_xLeft diff_xRight L_min_
                
          % Check if uniform mesh fits EXACTLY into interval.
          if( sum( diff( x_tmp ) ) < deltaX )
            % Move last mesh line (this should not break the ratio).
            x_tmp(end) = x_tmp(end) + ( deltaX - sum( diff( x_tmp ) ) );
          end % if

        end % if
        
      end % if

      % Add left mesh lines.
      while( numel( dDeltaLeft ) ~= 0 )
        x_tmp = [ x_tmp(1) - dDeltaLeft(end) , x_tmp ];
        dDeltaLeft(end) = [];
      end % while
      % Add right mesh lines.
      while( numel( dDeltaRight ) ~= 0 )
        x_tmp = [x_tmp , x_tmp(end) + dDeltaRight(end) ];
        dDeltaRight(end) = [];
      end % if
        
    elseif( L_A + L_B >= L )
      % ****CASE 2 ****
      % Create interval mesh without uniform part in the middle.
    
      x_tmp = 0;
      % Intersection point of left and right linear progressions.
      intersection = ( L - L_B + L_A ) / 2;
      % New left GP until intersection point.
      [ dDeltaLeft rA ] = geometricProgression( dxA , intersection , ratio );
      dDeltaLeft = unique( dDeltaLeft );
      % New right GP until intersection point.
      [ dDeltaRight rB ] = geometricProgression( dxB , L - sum(dDeltaLeft) , ratio );
      dDeltaRight = unique(dDeltaRight);
        
      %         % if [dxA > intersection] or [dxB > L-sum(dDeltaLeft)] the g.p. will fail
      %         if dxA > intersection
      %             dDeltaLeft = [ dxA ];
      %             [ dDeltaRight rB ] = geometricProgression( dxB, L-dxA, ratio );
      % %             dDeltaRight = [ dxB dDeltaRight ];
      %             dDeltaRight = unique(dDeltaRight);
      %
      %         elseif dxB > L-sum(dDeltaLeft)
      %             dDeltaRight = [ dxB ];
      %             [ dDeltaLeft rA ] = geometricProgression( dxA, L-dxB, ratio );
      % %             dDeltaLeft = [ dxA dDeltaLeft ];
      %             dDeltaLeft = unique(dDeltaLeft);
      %
      %         end
          
      L_tmp = L;
      c = 0;
      % Check if transition of both g.p. parts does not break ratio.
      while( dDeltaRight(end) / dDeltaLeft(end) > ratio || dDeltaRight(end) / dDeltaLeft(end) < 1 / ratio )
        if( diff( [ dxB dxA ] ) < ( ratio * dxA + ratio * dxB ) / 2 )
          % dxA and dxB are similar
          corr1 = diff( [ dDeltaRight(end) , dDeltaLeft(end) ] ) / length( [ dDeltaLeft ] );
          corr2 = diff( [ dDeltaRight(end) , dDeltaLeft(end) ] ) / length( [ dDeltaRight ] );
          dDeltaLeft = dDeltaLeft - corr1;
          dDeltaRight = dDeltaRight + corr2;
          clear corr1 corr2
          break;
        else
          if( dxB < dxA )
            L_tmp = L_tmp - dxB;        
            if( L_tmp - dxA < 0 )
              % Unable to fix problem.
              [ dDeltaLeft rA ] = geometricProgression( dxA , intersection , ratio );
              dDeltaLeft = unique( dDeltaLeft );
              % New right GP until intersection point.
              [ dDeltaRight rB ] = geometricProgression( dxB , L - sum( dDeltaLeft ) , ratio );
              dDeltaRight = unique( dDeltaRight );
              break;
            end % if
            [ dDeltaRight rB ] = geometricProgression( dxB , L_tmp - dxA , ratio );
            c = c + 1;
            dDeltaRight = [ repmat( dxB , 1 , c ) , dDeltaRight ];
            dDeltaLeft = [ dxA ];
          else
            L_tmp = L_tmp - dxA;
            if( L_tmp -dxB < 0 )
              % Unable to fix problem.
              [ dDeltaLeft rA ] = geometricProgression( dxA , intersection , ratio );
              dDeltaLeft = unique( dDeltaLeft );
              % New right GP until intersection point.
              [ dDeltaRight rB ] = geometricProgression( dxB , L - sum( dDeltaLeft ) , ratio );
              dDeltaRight = unique( dDeltaRight );
              break;
            end % if
            [ dDeltaLeft rA ] = geometricProgression( dxA , L_tmp - dxB , ratio );
            c = c + 1;
            dDeltaLeft = [ repmat( dxA , 1 , c ) , dDeltaLeft ];
            dDeltaRight = [ dxB ];
          end % if
        end % if
      end % while
        
      clear L_tmp c

      % Add left mesh lines.
      while( numel( dDeltaLeft ) ~= 0 )
        x_tmp = [ x_tmp , x_tmp(end) + dDeltaLeft(1) ];
        dDeltaLeft(1) = [];
      end % while
      % Add right mesh lines.
      while( numel( dDeltaRight ) ~= 0 )
        x_tmp = [ x_tmp , x_tmp(end) + dDeltaRight(end) ];
        dDeltaRight(end) = [];
      end % while
      
    end % if
    
    % Create mesh line array.
    if( i == 1 )
      x = [ redPoints(1,1) + x_tmp ];
    else
      x_tmp = nonzeros( round( x_tmp * 10e10 ) / 10e10 )';
      x_tmp(isnan(x_tmp)) = [];
      x = [ x , x(end) + x_tmp ];
    end
    
  end % for

  %%%%%%%%%%%% PLOT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %         x = sort(unique(x));
  %         y = min(redPoints(:,1)):(max(redPoints(:,2))-min(redPoints(:,1)))/(length(x)-1):max(redPoints(:,2));
  %         bar(x,y,'b')
  %         grid on
  %         x;
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  %
  % Final check of ratio, alignment and dmax.
  %
  
  % Check ratio.
  diff_x = diff(x);
  x_test = round( nonzeros( diff_x(2:end) ./ diff_x(1:end-1)) * 10e6 ) / 10e6;
  if( any( x_test > ratio ) || any( x_test < 1/ratio ) )
    fprintf( 'Non-uniform mesh ratio in %c-direction is not satisfied - please check mesh lines manually\n', direction );
  else
    fprintf( 'Non-uniform mesh ratio in %c-direction is satisfied \n', direction );
  end % if

  % Check alignment.
  errorCheck = true;
  for i = 1:length( constPointList )
    if( ~any( ( round( constPointList(i) * 10e3 ) / 10e3 == round( x * 10e3 ) / 10e3 ) == 1 ) )
        fprintf( 'Alignment with intervals in %c-direction is not satisfied - please check constrained point at %c = %f \n' , direction , direction , constPointList(i) );
        errorCheck = false;
    end % if
  end % for 
  
  if( errorCheck == true )
    fprintf( 'Alignment with intervals in %c-direction is satisfied \n' , direction );
  end % if

  % Check dmax.
  errorCheck = true;
  for i = 1:length( constPointList ) - 1
    if( diff( x( (round( x * 10e5 ) / 10e5 >= round( constPointList(i) * 10e5 ) / 10e5 ) == ( round( x * 10e5 ) / 10e5 <= round( constPointList(i+1) * 10e5 ) / 10e5) ) ) >= meshSizeList(i) )
      fprintf( 'Maximum mesh size of intervals in %c-direction is not satisfied - please check interval number %i point \n' , direction , i );
      errorCheck = false;
    end
  end % for
  
  if( errorCheck == true )
    fprintf( 'Maximum mesh size of intervals in %c-direction is satisfied \n' , direction );
  end % if

end % function

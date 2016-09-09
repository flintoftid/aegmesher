function [ x ] = meshCreateNonUniformMeshInterval( meshGroup, ratio, L_min, BboxMeshDensity, direction )
%
% meshCreateNonUniformMeshInterval - calculates a non-uniform mesh in between a fix interval
%
% Usage:
%
% [ x ] = meshCreateNonUniformMeshInterval( meshGroup, ratio, L_min, BboxMeshDensity, direction  )
%
% Input:
%
% meshGroup         - real array containing interval boundaries and dmax
% ratio             - real scalar defining global mesh ratio
% L_min             - real scalar defining global min mesh size
% BboxMeshDensity   - real scalar defining mesh density of free space between not overlapping objects
% direction         - string defining current x, y or z direction
%
% Output:
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

% global tolerance
eps = 10e-6;
%
%% mesh of inner boundary
%
% create projection of intervals in dependance of max mesh size
%
% Case 1.: intervalls are exactly overlapping------------------------------
if size( meshGroup(:,1:2),1 ) ~= size( unique(meshGroup(:,1:2),'rows'),1 )
    
    % NOT all intervals are overlapping
    if size( unique(meshGroup(:,1:2),'rows'),1 ) ~= 1
        
        del = [];
        for i = 1: size(meshGroup(:,1:2),1)
            A = find(meshGroup(i,1) == meshGroup(:,1));
            B = find(meshGroup(i,2) == meshGroup(:,2));
            [Lia,Locb] = ismember(A,B,'rows');
            Locb = nonzeros(Locb);
            if ~isempty(Locb) && meshGroup(i,3) ~= min(meshGroup(A(Locb),3))
                del = [ del i ];
            end
        end
        meshGroup(del,:) = [];
        clear A B Lia Locb del
        
    else % ALL intervals are overlapping
        
        eq = find( find( meshGroup(:,1) == unique(meshGroup(:,1)) ) == find( meshGroup(:,2) == unique(meshGroup(:,2)) ));
        
        tmpMin = min(meshGroup(eq,3)); % chose smallest mesh size for all intervalls
        meshGroup(eq(1),:) = [unique(meshGroup(:,1:2),'rows') tmpMin];
        meshGroup(eq(2:end),:) = [];
        
        [ x_tmp ] = meshCreateUniformMeshInterval( diff(meshGroup(1:2)), meshGroup(3), L_min );
        
        x = meshGroup(1) + x_tmp;
        fprintf( 'Non-uniform mesh ratio in %c-direction is satisfied \n', direction)
        fprintf( 'Alignment with intervals in %c-direction is satisfied \n', direction)
        fprintf( 'Maximum mesh size of intervals in %c-direction is satisfied \n', direction)
        return
        
    end
end
%--------------------------------------------------------------------------
%
% all intervalls have no thickness-----------------------------------------
if ~all(diff(meshGroup(:,1:2),1,2))
    [ x_tmp ] = meshCreateUniformMeshInterval( diff(meshGroup(1:end,1)), max(meshGroup(:,3)), L_min );
    x = meshGroup(1) + x_tmp;
    fprintf( 'Non-uniform mesh ratio in %c-direction is satisfied \n', direction)
    fprintf( 'Alignment with intervals in %c-direction is satisfied \n', direction)
    fprintf( 'Maximum mesh size of intervals in %c-direction is satisfied \n', direction)
    return
end
%--------------------------------------------------------------------------
%
% intervalls overlap in a regular way---------------------------------------
constPointList = sort([meshGroup(:,1);meshGroup(:,2)]);
for i = 2:length(constPointList)
    tmp = ( meshGroup(:,1) < constPointList(i) ) == ( meshGroup(:,2) >= constPointList(i) );
    
    if ~any(tmp) % free space gap in between objects
        meshSizeList(i-1) = BboxMeshDensity;
    else
        meshSizeList(i-1) = min( meshGroup(tmp, 3));
    end
    
end
%--------------------------------------------------------------------------

%% identify optimal mesh densty
%
% identify the optimal mesh density at interval boundaries
%
%% step 1: mesh density at interval boundaries defined by geometric progression
% ->"green points"
%
% create 1D projection: meshGroup = [leftBoundary rightBoundary meshDensity]
for i = 1:length(meshSizeList)
    meshGroup(i,:) = [constPointList(i) constPointList(i+1) meshSizeList(i)];
end

% delete intervals with no thickness
if any(meshGroup(1:end,1) == meshGroup(1:end,2))
    meshGroup(find((meshGroup(1:end,1) == meshGroup(1:end,2)) == 1),:) = [];
end

meshGroup = sortrows(meshGroup,3);


greenPoints = [];
greenPointsLeft = ones(size(meshGroup,1),size(meshGroup,1),2)*9.9999;
greenPointsRight = ones(size(meshGroup,1),size(meshGroup,1),2)*9.9999;
redPoints = [];


% create g.p. for all neighbor intervals
% greenPointsLeft/greenPointsRight[:,:,1] = interval boundary
% greenPointsLeft/greenPointsRight[:,:,2] = boundary mesh density
for i = 1:size(meshGroup,1)
    
    N_min = [];
    N_max = [];
    Neighbor = [];
    dxA = [];
    
    if meshGroup(i,1) == min(meshGroup(:,1)) % left boundary
        
        % right neighbor intervals
        Neighbor = find(meshGroup(:,1) >= meshGroup(i,2));
        L = meshGroup(Neighbor,2) - meshGroup(Neighbor,1);
        dxA = meshGroup(i,3);
        
        for j = 1:length(Neighbor) % continue g.p. till last neighbor
            if dxA/ratio < L(j) % first cell in interval is bigger than interval itself
                [ dDeltaMax r ] = geometricProgression( dxA, L(j), ratio );
                
                if isempty(dDeltaMax); dDeltaMax = L; end; % if g.p. fails
                
                greenPointsRight(i,j,:) = [ meshGroup(Neighbor(j),2) dDeltaMax(end) ];
            else
                dDeltaMax = L(j); % set interval as one cell (could break ratio)
                greenPointsRight(i,j,:) = [ meshGroup(Neighbor(j),2) dDeltaMax(end) ];
            end
            dxA = dDeltaMax(end);
        end
        
        continue
        
    elseif meshGroup(i,2) == max(meshGroup(:,2)) % right boundary
        
        % left neighbor intervals
        Neighbor = find(meshGroup(:,2) <= meshGroup(i,1));
        L = meshGroup(Neighbor,2) - meshGroup(Neighbor,1);
        dxA = meshGroup(i,3);
        
        for j = 1:length(Neighbor) % continue g.p. till last neighbor
            if dxA/ratio < L(j) % first cell in interval is bigger than interval itself
                [ dDeltaMax r ] = geometricProgression( dxA, L(j), ratio );
                
                if isempty(dDeltaMax); dDeltaMax = L; end; % if g.p. fails
                
                greenPointsLeft(i,j,:) = [ meshGroup(Neighbor(j),1) dDeltaMax(end) ];
            else
                dDeltaMax = L(j); % set interval as one cell (could break ratio)
                greenPointsLeft(i,j,:) = [ meshGroup(Neighbor(j),1) dDeltaMax(end) ];
            end
            dxA = dDeltaMax(end);
        end
        
        continue
        
    end
    
    % left neighbor intervals
    Neighbor = find(meshGroup(:,2) <= meshGroup(i,1));
    L = meshGroup(Neighbor,2) - meshGroup(Neighbor,1);
    % sort neighbor intervals by order
    [tmp order] = sort(meshGroup(Neighbor,2),'descend');
    Neighbor = Neighbor(order);
    L = L(order);
    clear tmp order
    
    dxA = meshGroup(i,3);
    
    for j = 1:length(Neighbor) % continue g.p. till last neighbor
        if dxA/ratio < L(j) % first cell in interval is bigger than interval itself
            [ dDeltaMax r ] = geometricProgression( dxA, L(j), ratio );
            
            if isempty(dDeltaMax); dDeltaMax = L; end; % if g.p. fails
            
            greenPointsLeft(i,j,:) = [ meshGroup(Neighbor(j),1) dDeltaMax(end) ];
        else
            dDeltaMax = L(j); % set interval as one cell (could break ratio)
            greenPointsLeft(i,j,:) = [ meshGroup(Neighbor(j),1) dDeltaMax(end) ];
        end
        dxA = dDeltaMax(end);
        
    end
    % right neighbor intervals
    Neighbor = find(meshGroup(:,1) >= meshGroup(i,2));
    L = meshGroup(Neighbor,2) - meshGroup(Neighbor,1);
    % sort neighbor intervals by order
    [tmp order] = sort(meshGroup(Neighbor,2),'ascend');
    Neighbor = Neighbor(order);
    L = L(order);
    clear tmp order
    
    dxA = meshGroup(i,3);
    
    for j = 1:length(Neighbor) % continue g.p. till last neighbor
        if dxA/ratio < L(j) % first cell in interval is bigger than interval itself
            [ dDeltaMax r ] = geometricProgression( dxA, L(j), ratio );
            
            if isempty(dDeltaMax); dDeltaMax = L; end; % if g.p. fails
            
            greenPointsRight(i,j,:) = [ meshGroup(Neighbor(j),2) dDeltaMax(end) ];
        else
            dDeltaMax = L(j); % set interval as one cell (could break ratio)
            greenPointsRight(i,j,:) = [ meshGroup(Neighbor(j),2) dDeltaMax(end) ];
        end
        dxA = dDeltaMax(end);
    end
    
end
clear tmp order

%% step 2: mesh density at interval boundaries and middle parts defined by geometric progression and user definition
% ->"red points"
%
% chose smallest g.p. solution for each interval boundary
% greenPoints = [boundary meshDensity]
for i = 1:size(meshGroup,1)
    
    currentBoundary = meshGroup(i,1);
    greenPoints(i,1) = currentBoundary;
    greenPoints(i,2) = min( [greenPointsLeft( size(greenPointsLeft(:,:,1),1)*size(greenPointsLeft(:,:,1),2) + find(greenPointsLeft(:,:,1)==currentBoundary)); ...
        greenPointsRight( size(greenPointsRight(:,:,1),1)*size(greenPointsRight(:,:,1),2) + find(greenPointsRight(:,:,1)==currentBoundary))] );
    
end

% chose smallest g.p. solution for last interval boundary on right side
currentBoundary = max(meshGroup(:,2));
greenPoints(end+1,1) = currentBoundary;
greenPoints(end,2) = min( [greenPointsLeft( size(greenPointsLeft(:,:,1),1)*size(greenPointsLeft(:,:,1),2) + find(greenPointsLeft(:,:,1)==currentBoundary)); ...
    greenPointsRight( size(greenPointsRight(:,:,1),1)*size(greenPointsRight(:,:,1),2) + find(greenPointsRight(:,:,1)==currentBoundary))] );

greenPoints = sortrows(greenPoints);

clear greenPointsLeft greenPointsRight r

% create red point array
% redPoints = [leftIntervalBoundary rightIntervalBoundary leftBoundaryMeshDensity middlePartMeshDensity rightBoundaryMeshDensity]
%
% redPoints = ones(size(meshGroup,1),4)*99999;
% first interval is the smallest one
redPoints(1,:) = [ meshGroup(1,1) meshGroup(1,2) meshGroup(1,3) meshGroup(1,3) ];

for i = 2:size(meshGroup,1)
    redPoints(i,:) = [ meshGroup(i,1:2) ...
        min([ ...
        meshGroup(i,3) ...% mesh density of current interval
        greenPoints(meshGroup(i,1)==greenPoints(:,1),2) ...% gp from the right and left
        redPoints(meshGroup(i,1)==redPoints(:,2),4) ...% former smaller red points on the rigth side
        redPoints(meshGroup(i,1)==redPoints(:,1),3) ...% former smaller red points on the left side
        ]) ...
        min([ ...
        meshGroup(i,3) ...% mesh density of current interval
        greenPoints(meshGroup(i,2)==greenPoints(:,1),2) ...% gp from the right and left
        redPoints(meshGroup(i,2)==redPoints(:,2),4) ...% former smaller red points on the rigth side
        redPoints(meshGroup(i,2)==redPoints(:,1),3) ...% former smaller red points on the left side
        ]) ...
        ];
    
end

%% step 3: creating mesh lines
%
redPoints(:,5) = redPoints(:,4);
redPoints(:,4) = meshGroup(:,3);
redPoints = sortrows(redPoints);
x = [];

% solve local mesh problem
for i = 1:size(redPoints,1)
    x_tmp = [];
    currentRedPoint = redPoints(i,:);
    L = redPoints(i,2) - redPoints(i,1);
    
    dxA = currentRedPoint(3);
    dxmax = currentRedPoint(4);
    dxB = currentRedPoint(5);
    
    % consider left side
    % minimum number of steps until mesh size is bigger than the maximum mesh size
    i_A = ceil(1 + ( log(dxmax/dxA)/log(ratio) ));
    
    % size of the last mesh size
    %     dDeltaMaxLeft = dxA * ratio^(i_A - 1);
    
    % length of g.p. on the left side of interval
    L_A = dxA * (1 - ratio^i_A)/(1 - ratio);
    
    % minimum number of steps until mesh size is bigger than the maximum mesh size
    i_B = ceil(1 + ( log(dxmax/dxB)/log(ratio) ));
    
    % size of the last mesh size
    %     dDeltaMaxRight = dxB * ratio^(i_B - 1);
    
    % length of g.p. on the right side of interval
    L_B = dxB * (1 - ratio^i_B)/(1 - ratio);
    
    
    % check if intersection point is inside the interval-------------------
    if (L - L_B + L_A)/2 < 0 || (L - L_B + L_A)/2 > L
        dxmax = max(dxA,dxB);
        i_A = ceil( round( 1 + (log(dxmax/dxA)/log(ratio) )*1e4)/1e4 );
        L_A = dxA * (1 - ratio^i_A)/(1 - ratio);
        i_B = ceil( round( 1 + (log(dxmax/dxB)/log(ratio) )*1e4)/1e4 );
        L_B = dxB * (1 - ratio^i_B)/(1 - ratio);
    end
    %----------------------------------------------------------------------
    
    
    % CASE 1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if L > L_A + L_B % create interval mesh with uniform part in the middle
        % length of the middle part
        L_M = L - L_A - L_B;
        % left g.p.
        [ dDeltaLeft rA ] = geometricProgression( dxA, (L-L_M-L_B), ratio );
        dDeltaLeft = unique(dDeltaLeft);
        % right g.p.
        [ dDeltaRight rB ] = geometricProgression( dxB, (L-L_M-L_A), ratio );
        dDeltaRight = unique(dDeltaRight);
        
        % middle part is too small for creating uniform mesh lines
        % -> middle part will be neglected by using only g.p.
        % --> this will marginally break the maximum mesh size
        if L_M < max(dDeltaLeft)/ratio || L_M < max(dDeltaRight)/ratio
            
            x_tmp = 0;
            % intersection point of left and right linear progressions
            intersection = (L - L_B + L_A) / 2;
            % new left g.p. until intersection point
            [ dDeltaLeft rA ] = geometricProgression( dxA, intersection, ratio );
            dDeltaLeft = unique(dDeltaLeft);
            % new right g.p. until intersection point
            [ dDeltaRight rB ] = geometricProgression( dxB, L-sum(dDeltaLeft), ratio );
            dDeltaRight = unique(dDeltaRight);
            
            % add left mesh lines
            while numel(dDeltaLeft) ~= 0
                x_tmp = [ x_tmp x_tmp(end)+dDeltaLeft(1) ];
                dDeltaLeft(1) = [];
            end
            % add right mesh lines
            while numel(dDeltaRight) ~= 0
                x_tmp = [x_tmp x_tmp(end)+dDeltaRight(end)];
                dDeltaRight(end) = [];
            end
            
        else % create middle part
            
            % identify length of middle part
            deltaX = [ L-sum([dDeltaLeft dDeltaRight]) ];
            
            % create uniform mesh for the middle part
            [ x_tmp ] = meshCreateUniformMeshInterval( deltaX, dxmax, L_min );
            
            
            % if middle part is too small to satisfy the ratio condition
            if length(x_tmp) == 2 && x_tmp(2)-x_tmp(1)+eps < dxmax/2
                
                if dxA < dxB
                    % left g.p.
                    [ dDeltaLeft rB ] = geometricProgression( dxA, L-dxB, ratio );
                    
                    if isempty(dDeltaLeft)
                        [ dDeltaLeft rB ] = geometricProgression( dxA, (L-L_M-L_B), ratio );
                        x_tmpDiff = diff([ x_tmp(1) mean(x_tmp) ]);
                        dDeltaRight = [ dDeltaRight(1)-x_tmpDiff dDeltaRight(1)-x_tmpDiff ];
                        x_tmp = dDeltaLeft(1);
                    else
                        dDeltaLeft = [ dxA dDeltaLeft ];
                        dDeltaLeft = unique(dDeltaLeft);
                        x_tmp = sum(dDeltaLeft);
                    end
                    
                    
                else
                    % right g.p.
                    [ dDeltaRight rB ] = geometricProgression( dxB, L-dxA, ratio );
                    
                    if isempty(dDeltaRight)
                        [ dDeltaRight rB ] = geometricProgression( dxB, (L-L_M-L_A), ratio );
                        x_tmpDiff = diff([ x_tmp(1) mean(x_tmp) ]);
                        dDeltaRight = [ dDeltaRight(1)-x_tmpDiff dDeltaRight(1)-x_tmpDiff ];
                        x_tmp = dDeltaLeft(1);
                    else
                        dDeltaRight = [ dxB dDeltaRight ];
                        dDeltaRight = unique(dDeltaRight);
                        x_tmp = dDeltaLeft(1);
                    end
                    
                    
                end
            else
                x_tmp = x_tmp + sum(dDeltaLeft);
                
            end
            
            
            
            % check transition between g.p parts and middle part-----------
            if length(x_tmp) > 1; diff_x = diff(x_tmp); else diff_x = x_tmp; end
            diff_xLeft = dDeltaLeft;
            diff_xRight = dDeltaRight;
            
            if min(diff_x) ~= sum(dDeltaLeft) && max(diff_x) ~= deltaX
                % check if ratio is small enough between middle part and g.p. parts
                while (diff_x(1)/max(diff_xLeft)-eps > ratio || diff_x(end)/max(diff_xRight)-eps > ratio) && L_min+eps < max([dDeltaLeft dDeltaRight])
                    
                    x_tmp = [];
                    [ x_tmp ] = meshCreateUniformMeshInterval( deltaX, min(dDeltaLeft,dDeltaRight), L_min);
                    if length(x_tmp) > 1; diff_x = diff(x_tmp); else diff_x = x_tmp; end
                    diff_xLeft = dDeltaLeft;
                    diff_xRight = dDeltaRight;
                    
                    
                    if length(x_tmp) == 2 && x_tmp(2)-x_tmp(1) < dxmax/2
                        x_tmpDiff = diff([ x_tmp(1) mean(x_tmp) ]);
                        dDeltaLeft(1) = dDeltaLeft(1) + x_tmpDiff;
                        dDeltaRight(1) = dDeltaRight(1) + x_tmpDiff;
                        x_tmp = dDeltaLeft(1);
                    else
                        x_tmp = x_tmp + sum(dDeltaLeft);
                    end
                    
                    
                end
                
                
                % check if ratio is big enough between middle part and g.p. parts
                L_min_ = L_min;
                while ( diff_x(1)/max(diff_xLeft)+eps < 1/ratio || diff_x(end)/max(diff_xRight)+eps < 1/ratio ) && L_min+eps < max([dDeltaLeft dDeltaRight])
                    
                    L_min_ = L_min_*ratio;
                    % exception
                    if L_min_ > dxmax
%                     fprintf( 'Exception in %c-direction: impossible to satisfied ratio\n', direction)
                        break
                    end
                    x_tmp = [];
                    [ x_tmp ] = meshCreateUniformMeshInterval( deltaX, dxmax, L_min_ );
                    if length(x_tmp) > 1; diff_x = diff(x_tmp); else diff_x = x_tmp; end
                    diff_xLeft = dDeltaLeft;
                    diff_xRight = dDeltaRight;
                    
                    if length(x_tmp) == 2 && x_tmp(2)-x_tmp(1) < dxmax/2
                        x_tmpDiff = diff([ x_tmp(1) mean(x_tmp) ]);
                        dDeltaLeft(1) = dDeltaLeft(1) + x_tmpDiff;
                        dDeltaRight(1) = dDeltaRight(1) + x_tmpDiff;
                        x_tmp = dDeltaLeft(1);
                    else
                        x_tmp = x_tmp + sum(dDeltaLeft);
                    end
                    
                end
                
                
                % if second while loop undo first while loop---------------
                % idea: g.p. from smaller mesh size to bigger one
                if (diff_x(1)/max(diff_xLeft)-eps > ratio || diff_x(end)/max(diff_xRight)-eps > ratio) && L_min+eps < max([dDeltaLeft dDeltaRight])
                    if dxA < dxB
                        % left g.p.
                        [ dDeltaLeft rB ] = geometricProgression( dxA, L-dxB, ratio );
                        dDeltaLeft = unique(dDeltaLeft);
                        x_tmp = dDeltaRight(1);
                    else
                        % right g.p.
                        [ dDeltaRight rB ] = geometricProgression( dxB, L-dxA, ratio );
                        dDeltaRight = unique(dDeltaRight);
                        x_tmp = dDeltaLeft(1);
                    end
                end
                %----------------------------------------------------------
                
                clear diff_x diff_xLeft diff_xRight L_min_
                
                % check if uniform mesh fits EXACTLY into interval---------
                if sum(diff(x_tmp)) < deltaX
                    % move last mesh line (this should not break the ratio)
                    x_tmp(end) = x_tmp(end) + (deltaX - sum(diff(x_tmp)));
                end
                %----------------------------------------------------------
            end
        end
        %------------------------------------------------------------------
        
        % add left mesh lines
        while numel(dDeltaLeft) ~= 0
            x_tmp = [x_tmp(1)-dDeltaLeft(end) x_tmp];
            dDeltaLeft(end) = [];
        end
        % add right mesh lines
        while numel(dDeltaRight) ~= 0
            x_tmp = [x_tmp x_tmp(end)+dDeltaRight(end)];
            dDeltaRight(end) = [];
        end
        
        
        % CASE 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    elseif L_A + L_B >= L % create interval mesh without uniform part in the middle
        
        x_tmp = 0;
        % intersection point of left and right linear progressions
        intersection = (L - L_B + L_A) / 2;
        % new left g.p. until intersection point
        [ dDeltaLeft rA ] = geometricProgression( dxA, intersection, ratio );
        dDeltaLeft = unique(dDeltaLeft);
        % new right g.p. until intersection point
        [ dDeltaRight rB ] = geometricProgression( dxB, L-sum(dDeltaLeft), ratio );
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
        % check if transition of both g.p. parts does not break ratio------
        while dDeltaRight(end)/dDeltaLeft(end) > ratio || dDeltaRight(end)/dDeltaLeft(end) < 1/ratio
            if diff([dxB dxA]) < (ratio*dxA + ratio*dxB)/2 % dxA and dxB are similar
                
                corr1 = diff( [dDeltaRight(end) dDeltaLeft(end)] )/length([dDeltaLeft]);
                corr2 = diff( [dDeltaRight(end) dDeltaLeft(end)] )/length([dDeltaRight]);
                
                dDeltaLeft = dDeltaLeft - corr1;
                dDeltaRight = dDeltaRight + corr2;
                
                clear corr1 corr2
                break
                
            else
                if dxB < dxA
                    L_tmp = L_tmp - dxB;
                    
                    if L_tmp - dxA < 0 % unable to fix problem
                        [ dDeltaLeft rA ] = geometricProgression( dxA, intersection, ratio );
                        dDeltaLeft = unique(dDeltaLeft);
                        % new right g.p. until intersection point
                        [ dDeltaRight rB ] = geometricProgression( dxB, L-sum(dDeltaLeft), ratio );
                        dDeltaRight = unique(dDeltaRight);
                        break
                    end
                    
                    [ dDeltaRight rB ] = geometricProgression( dxB, L_tmp-dxA, ratio );
                    c = c + 1;
                    dDeltaRight = [ repmat(dxB,1,c) dDeltaRight ];
                    dDeltaLeft = [dxA];
                else
                    L_tmp = L_tmp - dxA;
                    
                    if L_tmp -dxB < 0 % unable to fix problem
                        [ dDeltaLeft rA ] = geometricProgression( dxA, intersection, ratio );
                        dDeltaLeft = unique(dDeltaLeft);
                        % new right g.p. until intersection point
                        [ dDeltaRight rB ] = geometricProgression( dxB, L-sum(dDeltaLeft), ratio );
                        dDeltaRight = unique(dDeltaRight);
                        break
                    end
                    
                    [ dDeltaLeft rA ] = geometricProgression( dxA, L_tmp-dxB, ratio );
                    c = c + 1;
                    dDeltaLeft = [ repmat(dxA,1,c) dDeltaLeft ];
                    dDeltaRight = [dxB];
                end
            end
        end
        clear L_tmp c
        %------------------------------------------------------------------
        
        % add left mesh lines
        while numel(dDeltaLeft) ~= 0
            x_tmp = [ x_tmp x_tmp(end)+dDeltaLeft(1) ];
            dDeltaLeft(1) = [];
        end
        % add right mesh lines
        while numel(dDeltaRight) ~= 0
            x_tmp = [x_tmp x_tmp(end)+dDeltaRight(end)];
            dDeltaRight(end) = [];
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % create mesh line array
    if i == 1
        x = [redPoints(1,1)+x_tmp];
    else
        x_tmp = nonzeros(round(x_tmp*10e10)/10e10)';
        x_tmp(isnan(x_tmp)) = [];
        x = [x x(end)+x_tmp];
    end
    
end

%%%%%%%%%%%% PLOT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         x = sort(unique(x));
%         y = min(redPoints(:,1)):(max(redPoints(:,2))-min(redPoints(:,1)))/(length(x)-1):max(redPoints(:,2));
%         bar(x,y,'b')
%         grid on
%         x;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Final check of ratio, alignment and dmax

% check ratio
diff_x = diff(x);
x_test = round(nonzeros(diff_x(2:end)./diff_x(1:end-1))*10e6)/10e6;
if any(x_test > ratio) || any(x_test < 1/ratio)
    fprintf( 'Non-uniform mesh ratio in %c-direction is not satisfied - please check mesh lines manually\n', direction)
else
    fprintf( 'Non-uniform mesh ratio in %c-direction is satisfied \n', direction)
end


% check alignment
errorCheck = true;
for i = 1:length(constPointList)
    if ~any((round(constPointList(i)*10e3)/10e3 == round(x*10e3)/10e3) == 1)
        fprintf( 'Alignment with intervals in %c-direction is not satisfied - please check constrained point at %c = %f \n', direction, direction, constPointList(i))
        errorCheck = false;
    end
end
if errorCheck == true
    fprintf( 'Alignment with intervals in %c-direction is satisfied \n', direction)
end


% check dmax
errorCheck = true;
for i = 1:length(constPointList)-1
    if diff( x( (round(x*10e5)/10e5 >= round(constPointList(i)*10e5)/10e5) == (round(x*10e5)/10e5 <= round(constPointList(i+1)*10e5)/10e5) ) ) >= meshSizeList(i)
        fprintf( 'Maximum mesh size of intervals in %c-direction is not satisfied - please check interval number %i point \n', direction, i)
        errorCheck = false;
    end
end
if errorCheck == true
    fprintf( 'Maximum mesh size of intervals in %c-direction is satisfied \n', direction)
end


end


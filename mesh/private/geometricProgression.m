function [ dDelta r ] = geometricProgression( dxA, L, ratio  )
%
% geometricProgression - calculates the geometric progression
%
% Usage:
%
% [ dDeltaMax r ] = geometricProgression( dxA, L, ratio  )
%
% Inputs:
%
% dxA           - float, initial start value vor g.p.
% L             - float, length of intervall for g.p.
% ratio         - float, common ratio for g.p. steps 
%
% Output:
%
% dDelta        - array, opt g.p. subintervals
% r             - float, opt ratio

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

% caclulate N from transformed g.p. equation: Sn = a*(ratio^N - 1) / (ratio - 1)
N = ceil( round((log(1 - (L/dxA) * (1 - ratio)))/(log(ratio))*1e10)/1e10   );

% exaption if length L is too small for values dxA and r
if N == 1
    r = 1;
    dDelta = L;
    return
end

% calculate opt ratio that grates mesh lines fitting exactly into L
if L/dxA ~= 2 % equation can not handle ratio 1 with two cells
    options = optimset('Display','off','FunValCheck','off');
    % find multiple solutions
    r(1) = fsolve( @(r)( 1-(r^N)-(L/dxA)+((r*L)/dxA) ), ratio, options );
    r(2) = fsolve( @(r)( 1-(r^N)-(L/dxA)+((r*L)/dxA) ), 1/ratio, options );
    r(round(r*1e5)/1e5 == 1) = []; % delete r=1 since algorithm can not handle this solution
    r = max(r);
    
    % fplot( @(r)( 1-(r^N)-(L/dxA)+((r*L)/dxA) ), [1/ratio ratio]); grid on
    
    if isnan(r)
        r = fminbnd( @(r)( -(1-(r^N)-(L/dxA)+((r*L)/dxA)) ) , 1/ratio, ratio);
    elseif isempty(r)
        r = 1;
        dDelta = L;
        return
    end
    % caclulate new N from with opt. ratio
    N_max = ceil( round((log(1 - (L/dxA) * (1 - r)))/(log(r))*1e4)/1e4  );
    % calculate subintervals out of calculated opt. parameter
    dDelta = r.^(1:N_max-1) * dxA;
else
    
    r = 1;
    % calculate subintervals out of calculated opt. parameter
    dDelta = r.^(1:N-1) * dxA;
end

dDelta = [ dxA dDelta ];


%% Final check
if round( sum(dDelta) *1e4 )/1e4 ~= round( L* 1e4 )/1e4 % g.p. failed
    
    dDelta = ( dDelta + diff( [sum(dDelta) L] )/length(dDelta) );
    
end


% 
% % try to fix ratio if calculation of opt ratio fails 
% if isnan(r) && round(N * dxA * 1e10)/1e10 == round(L* 1e10)/1e10
%     dDeltaMin = 1.^(1:N-1) * dxA;
%     dDelta = r.^(1:N-1) * dxA;
%     r(1:2) = 1;
% end
% 
% exeption if calculation of opt ratio fails
% if isnan(r)
%     r = fminbnd( @(r)( -(1-(r^N)-(L/dxA)+((r*L)/dxA)) ) , 1/ratio, ratio);
% end
% 
% PLOT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% fplot(@(r)( 1-(r^N)-(L/dxA)+((r*L)/dxA) ), [1/ratio ratio]); grid on
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


end


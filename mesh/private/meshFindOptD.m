function [ D_frac, fval ] = meshFindOptD( delta , D )
%
% meshFindOptD - find cell size that fits best into all deltas
%
% Usage:
%
% [ D_frac, fval ] = meshFindOptD( delta , D )
%
% Inputs:
%
% delta    - (numConPoints) real vector, difference of constraint point coordinates.
% D        - (numMeshSizes) real vector, set of possible mesh sizes.
%
% Outputs:
% 
% D_frac   - (numMeshSizes) real vector with the best mesh size in D.
% fval     - structure with different evaluation criteria:
%            .mean - real scalar, mean deviation.
%            .rms  - real scalar, root-mean-square deviation.
%            .max  - real scalar, maximum deviation.

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
% Date: 15/07/2013
% Version 1.0.0 - Cubic and uniform meshes only.

% initialize parameter 
D_frac = zeros(length(delta),length(D));

% identify best D for each delta
for i = 1:length(delta)
    D_frac(i,:) = mod(delta(i),D);
end

% calculate average of all calculated D
D_frac = sum(D_frac,1);
% D_frac = sum(D_frac,1)/length(delta);



% evaluation criteria
fval.mean = mean(D_frac);
fval.rms = sqrt(mean(D_frac.^2));
fval.max = max(D_frac);

end % function

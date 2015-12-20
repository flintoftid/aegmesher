function [ x ] = meshCreateNonUniformMeshLines( X , Xweight , dmin , dmax , dirChar , options )
%
% meshCreateNonUniformMeshLines - Generate a set nonuniform mesh lines that optimally fit a
%                                 set of constraint points.
% 
% [ x ] = meshCreateNonUniformMeshLines( X , Xweight , dmin , dmax , dirChar , options )
%
% Inputs:
%
% X         - vector of constraint points [m].
% Xweight   - vector of constraint point weighting factors [-].
% dmin      - vector of minimum mesh sizes [m].
% dmax      - vector of maximum mesh sizes [m].
% dirChar   - char, direction: 'x', 'y' or 'z'.
% options   - structure containing options:
% 
%             .lineAlgorithm  - algorithm for mesh-line genaration:
%                               'OPTIM2' - 2 stage optimsation. 
%                               'OPTIM1' - 1 stage optmisation.
%             .costAlgorithm  - algorithm for cost function for uniform/cubic mesh line genaration:
%                               'RMS'     - RMS deviation
%                               'MEAN'    - Average deviation
%                               'MAXIMUM' - Maximum deviation
%             .isPlot         - boolean indicating whether to plot statistics of deviations.
%             .maxOptimTime   - real, maximum optimisation time [s].
%             .maxOptimEvals  - integer, maximum number of cost function evaluations.
%             .costFuncTol    - real, stopping value for cost function.
%
% Outputs:
%
% x()  - vector of mesh lines [m].
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

% Author: M. Berens
% Date: 15/07/2013
% Version 1.0.0

% Author: I. D. Flintoft
% Date: 30/10/2013
% Version 1.1.0
% Refactored option handling and provide more general decompostion
% of algorithm into functions.

  % Order constraint points.
  [ X , idx ] = sort( X );
  Xweight = Xweight(idx);
  dmin = dmin(idx);
  dmax = dmax(idx);

  %
  % Based on John Dawson's outline "smallest first" algorithm.   
  %

  % Pass 0: Iterate over intervals in order and identify any inconsistencies
  % between dx_min/dx_max and interval lengths. Resolve by decreasing dx_max/dx_min
  % or by merging very close constraint points.
  
  % Pass 1: Iterate over intervals between mesh points in order of
  % increasing maximum mesh-size constraint and determine the minimum
  % and maximum cells sizes that could be reached in the centre of the
  % neighbouring intervals using the maximum cell ratio.
  
  % Pass 2: Project the tightest maximum cell size constraint on each 
  % interval and ensure dx_min <= dx_max.
  
  % Pass 3: Iterate over the intervals from left to right and locally 
  % subdivide each interval between constraint points
  % according to the mesh constraints on it end points.
  
  % We may have one too many cells at bottom/top end - remove them.
  x(x - dopt + options.epsCompVol > X(end)) = [];
  x(x + dopt - options.epsCompVol < X(1)) = [];

  % Final report. 
  fprintf( '  dmin = %g dmax = %g dmean =%g\n' ,  min( x ) , max( x ) , mean( x ) );
  fprintf( '  N%s = %d\n' , dirChar , length( x ) ); 

  % Check mesh lines span the constraint points.
  assert( x(1) - options.epsCompVol <= X(1) );
  assert( x(1) + dopt > X(1) );
  assert( x(end) + options.epsCompVol >= X(end) );
  assert( x(end) - dopt <= X(end) );

end % function

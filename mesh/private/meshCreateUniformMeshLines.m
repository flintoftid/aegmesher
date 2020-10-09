function [ x , dopt ] = meshCreateUniformMeshLines( X , Xweight , dmin , dmax , dirChar , options )
%
% meshCreateUniformMeshLines - Generate a set of uniform mesh lines that optimally fit a
%                              set of constraint points.
% 
% [ x , dopt ] = meshCreateUniformMeshLines( X , Xweight , dmin , dmax , options )
%
% Inputs:
%
% X         - vector of constraint points [m].
% Xweight   - vector of constraint point weighting factors [-].
% dmin      - minimum mesh size [m].
% dmax      - maximum mesh size [m].
% dirChar   - char, direction: 'x', 'y' or 'z'.
% options   - structure containing options:
% 
%             .lineAlgorithm  - algorithm for mesh-line generation:
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
%             .epsCompVol     - real, tolerance of computation volume fitting.
%
% Outputs:
%
% x()  - vector of mesh lines [m].
% dopt - optimal mesh size [m].
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

  function [ fval ] = objFcnD( d , X , Xweight , algorithm , isPlot )
  % Objective function for determining mesh size.

    % Intervals between constraint points.
    dX = diff( X );

    % Intervals in terms of mesh size.
    rX = dX ./ d;

    % Deviations of mesh intervals from integer multiples of mesh size.
    % We pack intervals from all coordinate directions into single array
    % so we can find globally best mesh size.
    deviations = abs( rX - round( rX ) );

    % Strategy is to minimise the deviations in some sense. 
    % If all deviations are zero then we have a perfect fit and cost function should be minimum.
    switch( algorithm )
    case 'RMS'
      % Method 1: RMS deviation.
      fval = sqrt( mean( deviations.^2 ) ); 
    case 'MEAN'
      % Method 2: Mean deviation.
      fval = mean( deviations );
    case 'MAXIMUM'
      % Method 3: Maximum deviation.
      fval = max( deviations );
    otherwise
      error( 'Invalid algorithm %d' , algorithm );
    end % switch

    % Plot PDF of deviations.
    if( isPlot )
      hist( deviations ,  [0 , 0.1 , 0.2 , 0.3 , 0.4 ,0.5 ] , 10 );
      title( sprintf( 'Mesh size residuals: fval=%e mean=%.3f std=%.3f median=%.3f mode=%.3f' , fval , mean( deviations ) , std( deviations ) , median( deviations ) , mode( deviations ) ) );
      xlabel( 'Fractional deviation (-)' );
      ylabel( 'Probability density functon (-)' );
    end % if

  end % function

  function [ fval ] = objFcnx0( x0 , X , Xweight , nx , d , algorithm , isPlot )
  % Objective function for determination of first mesh line coordinate.

    % The mesh lines.
    x = x0 + (0:nx) .* d;
  
    Nx = length( X );

    deviations = zeros( Nx ,1 );
    for i=1:Nx
      % Find mesh line closest to constraint point.
      [ dmin , idx ] = min( abs( X(i) - x ) ); 
      % Distance of constraint point from nearest mesh line.
      deviations(i) = abs( X(i) - x(idx) ); 
    end % for 

    % normalise deviations by mesh size.
    deviations = Xweight' .* deviations ./ d;

    % Strategy is to minimise the deviations in some sense. 
    % If all deviations are zero then we have a perfect fit and cost function should be minimum.

    switch( algorithm )
    case 'RMS'
      % Method 1: RMS deviation.
      fval = sqrt( mean( deviations.^2 ) );
    case 'MEAN'
      % Method 2: Mean deviation.
      fval = mean( deviations );
    case 'MAXIMUM'
      % Method 3: Maximum deviation.
      fval = max( deviations );
    otherwise
      error( 'Invalid algorithm %d' , algorithm );
    end % switch

    % Plot PDF of deviations.
    if( isPlot )
      hist( deviations ,  [0 , 0.1 , 0.2 , 0.3 , 0.4 ,0.5 ] , 10 );
      title( sprintf( 'Initial point residuals: fval=%e mean=%.3f std=%.3f median=%.3f mode=%.3f' , fval , mean( deviations ) , std( deviations ) , median( deviations ) , mode( deviations ) ) );
      xlabel( 'Fractional deviation (-)' );
      ylabel( 'Probability density functon (-)' );
    end % if

  end % function

  function [ fval ] = objFcnAll( p , X , Xweight , algorithm , isPlot )
  % Objective function for simultaneous determination of all parameters.

    d = p(1);
    x0 = p(2);

    % Mesh line index ranges.
    imin = floor( ( X(1) - x0 ) / d );
    imax = ceil( ( X(end) - x0 ) / d );

    % The mesh lines.
    x = x0 + (imin:imax) .* d;

    % Residual between each line and nearest constraint point.
    rX = Xweight .* min( abs( bsxfun( @minus , X , x' ) ) , [] , 1 );

    % Combined deviations normalised by mesh size.
    deviations = rX / d; 

    % Strategy is to minimise the deviations in some sense. 
    % If all deviations are zero then we have a perfect fit and cost function should be minimum.
    switch( algorithm )
    case 'RMS'
      % Method 1: RMS deviation.
      fval = sqrt( mean( deviations.^2 ) );
    case 'MEAN'
      % Method 2: Mean deviation.
      fval = mean( deviations );
    case 'MAXIMUM'
      % Method 3: Maximum deviation.
      fval = max( deviations );
    otherwise
      error( 'Invalid algorithm %d' , algorithm );
    end % switch

    % Plot PDF of deviations.
    if( isPlot )
      hist( deviations ,  [0 , 0.1 , 0.2 , 0.3 , 0.4 ,0.5 ] , 10 );
      title( sprintf( 'Residuals: fval=%e mean=%.3f std=%.3f median=%.3f mode=%.3f' , fval , mean( deviations ) , std( deviations ) , median( deviations ) , mode( deviations ) ) );
      xlabel( 'Fractional deviation (-)' );
      ylabel( 'Probability density functon (-)' );
    end % if

  end % function

  % Number of samples for global minimisation of cost functions.
  numSamples = 1000;

  % Order constraint points.
  [ X , idx ] = sort( X );
  Xweight = Xweight(idx);

  % Find mesh lines.
  switch( options.lineAlgorithm )
  case 'OPTIM2'
    % Use two stage optmisation approach consisting of 2 1-D optimisation problems:
    % 1. Find optimum mesh-size to simultaneously fit intervals between constraint 
    %    points. Weights of constraints points are not used.
    % 2. Find optimum starting point of mesh lines. Weights of constraint points 
    %    are used but could adversely affect results since the mesh-size is already fixed.

    % Sample objective function for mesh size.
    d = linspace( dmin , dmax , numSamples );
    for k=1:length( d )
      of1(k) = objFcnD( d(k) , X , Xweight , options.costAlgorithm , false );
    end % for

    % Plot objective function over requested range.
    if( options.isPlot )
      figure();
      plot( d , of1 , 'r-o' );
      title( 'Objective function for global determination of mesh size' );
      xlabel( 'Mesh size, d (m)' );
      ylabel( 'Objective function (m)' );
    end % if

    % Estimate global minimum from the samples. If there is a tie pick the biggest mesh size. 
    [ of1sorted , idx ] = sort( of1 );
    dsorted = d(idx);
    [ fval , idx2 ] = min( of1sorted ); 
    dopt0 = dsorted(idx2);

    % Find optimum global mesh size using *local* improvement algorithm.
   [ dopt , fval , info ] = fminbnd( @(d) objFcnD( d , X , Xweight , options.costAlgorithm , false ) , 0.99 * dopt0  , 1.01 * dopt0 );
    if( dopt < 0.999 * dmin || dopt > 1.001 * dmax )
      error( '  *** Local minimiser has gone bonkers! ***' );
    end % if

    % Plot optimum distribution of deviations.
    if( options.isPlot )
      figure();
      [ val ] = objFcnD( dopt , X , Xweight , options.costAlgorithm , true );
    end % if

    % Now the mesh size is fixed determine the required number of mesh lines in each direction
    % to span the constraint points. We add one to allow the search for the first mesh line to 
    % be up to dopt lower than the lowest constrait point.
    nx = ceil( ( X(end) - X(1) ) / dopt ) + 1;

    % Ranges for initial coordinate in each direction.
    % Maybe need to make interval slighlty less than dopt.
    % Try: ( 1 - eps ) * dopt
    x0min = X(1) - dopt;
    x0max = X(1);

    % Sample objective function for each direction.
    x0 = linspace( x0min , x0max , numSamples );
    for k=1:length( x0 )
      of2x(k) = objFcnx0( x0(k) , X , Xweight , nx , dopt , options.costAlgorithm , false );
    end % for

    % Plot objective function for each direction.
    if( options.isPlot )
      figure();
      plot( x0 - x0min , of2x , 'r-' );
      hold on; 
      legend( 'x' , 'y' , 'z' );
      title( 'Objective function for determination of mesh line offset' );
      xlabel( 'Initial mesh point , d0 -dmin (m)' );
      ylabel( 'Objective function (m)' );
      hold off;
    end % if

    % Estimate optimum initial points.
    [ x0opt , fval , info ] = fminbnd( @(x0) objFcnx0( x0 , X , Xweight , nx , dopt , options.costAlgorithm , false ) , x0min , x0max );

    % Plot distributions of deviations for optimum initial points.
    if( options.isPlot )
      figure();
      objFcnx0( x0opt , X , Xweight , nx , dopt , options.costAlgorithm , true );
    end % if

    % We now have the mesh lines!
    x = x0opt + (0:nx) .* dopt;

  case 'OPTIM1'
    % Use one stage optmisation approach consisting of a 2-D optimisation problem.
    % Mesh-size and starting coordinate are simultaneously optimised. Constraint point 
    % weights are used and should be more effective than 'OPTIM2' approach.

    % Determine bounds on optmisation paramters.
    x0min = X(1) - dmax;
    x0max = X(1);
    lb = [ dmin , x0min ];
    ub = [ dmax , x0max ];

    % Objective function and initial feasible point.
    objFcn=@(p) objFcnAll( p , X , Xweight , options.costAlgorithm , false );
    p0 = [ 0.5 * ( dmin + dmax ) , 0.5 * ( x0min + x0max ) ];

    % Perform optimisation.
    if( exist( 'OCTAVE_VERSION' ) )
      if( exist( 'nlopt_optimize' ) )
        nlopt.algorithm = NLOPT_LN_BOBYQA;
        %nlopt.algorithm = NLOPT_LN_NELDERMEAD;
        %nlopt.algorithm = NLOPT_LN_COBYLA;
        %nlopt.algorithm = NLOPT_GN_DIRECT_L;
        nlopt.stopval =   options.costFuncTol;
        nlopt.maxeval = options.maxOptimEvals;
        nlopt.maxtime = options.maxOptimTime;
        nlopt.min_objective = objFcn;   
        nlopt.lower_bounds = lb;
        nlopt.upper_bounds = ub;
        %nlopt.verbose = 1;
        [ popt , fval , retcode ] = nlopt_optimize( nlopt , p0 );
      else
        [ popt , fval , exitflag ] = sqp( p0 , objFcn , [] , [] , lb , ub , options.maxOptimEvals , options.costFuncTol );
      end %if
    else
      optFmincon = optimset( 'Algorithm' , 'sqp' , 'Display' , 'iter' );
      [ popt , fval , exitflag ] = fmincon( objFun , p0 , [] , [] , [] , [] , lb , ub , [] , optFmincon );     
    end % if
    
    dopt = popt(1);
    x0opt = popt(2);

    % Determine mesh lines.
    imin = floor( ( X(1) - x0opt ) / dopt );
    imax = ceil( ( X(end) - x0opt ) / dopt );
    x = x0opt + (imin:imax) .* dopt;

    % Plot distributions of deviations for optimum.
    if( options.isPlot )
      figure();
      objFcnAll( popt , X , Xweight , options.costAlgorithm , true );
    end % if

  otherwise

    error( 'unknown line generation algorithm: %s' , options.lineAlgorithm );

  end % switch

  % We may have one too many cells at bottom/top end - remove them.
  x(x - dopt + options.epsCompVol > X(end)) = [];
  x(x + dopt - options.epsCompVol < X(1)) = [];

  % Final report. 
  fprintf( '  d = %e (fval = %e)\n' ,  dopt , fval );
  fprintf( '  %s0 = %e\n' , dirChar , x0opt );
  fprintf( '  N%s = %d\n' , dirChar , length( x ) ); 

  % Check mesh lines span the constraint points.
  assert( x(1) - options.epsCompVol <= X(1) );
  assert( x(1) + dopt > X(1) );
  assert( x(end) + options.epsCompVol >= X(end) );
  assert( x(end) - dopt <= X(end) );

end % function

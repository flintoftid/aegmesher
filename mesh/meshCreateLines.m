function [ lines ] = meshCreateLines( mesh , groupNamesToAnalyse , options )
%
% meshCreateLines - Generate mesh lines by analysing unstructured mesh.
%
% Usage:
%
% [ lines ] = meshCreateLines( mesh , groupNamesToMap , options )
%
% Inputs:
%
% mesh                - structure containing the unstructured mesh. 
%                       See help for meshReadAmelet().
%
% groupNamesToAnalyse - string{}, names of groups to include in analysis.
% 
% options             - structure containing meshing options.
%
%                      .mesh.meshType         - string, type of mesh: 
%                                               'CUBIC', 'UNIFORM' or 'NONUNIFORM'
%                      .mesh.useMeshCompVol   - boolean, indicating whether to take computational 
%                                               volume from mesh group.
%                      .mesh.compVolName      - string, name of group to use for computational volume.
%                      .mesh.compVolAABB      - real vector(6), AABB of computational voulme if not 
%                                               taken from mesh group.
%                      .mesh.useDensity       - scalar boolean, inidicating whether to use mesh 
%                                               density or mesh size. 
%                      .mesh.maxRatio         - real scalar, maximum mesh interval ratio for 
%                                               nonuniform meshes.
%                      .mesh.maxAspect        - real, maximum aspect ratio for cells.
%                      .mesh.minFreq          - real scalar, minimum frequency [Hz].
%                      .mesh.maxFreq          - real scalar, maximum frequency [Hz].
%                      .mesh.numFreqSamp      - integer scalar, number of frequency samples for 
%                                               material properties.
%.                     .mesh.lineAlgorithm    - string, algorithm for line generation: 'OPTIM1', 'OPTIM2';
%                      .mesh.costAlgorithm    - string, cost function method: 'RMS', 'MEAN', 'MAXIMUM';
%                      .mesh.epsCoalesceLines - real, absolute distance within which constraint points 
%                                               are merged.
%                      .mesh.isPlot           - scalar boolean, whether to plot meshing parameters.
%
% Outputs:
%
% lines               - structure containing the structured mesh lines:
%
%                       .x()  - real(Nx) vector of mesh line coordinates in x-direction [arb].
%                       .y()  - real(Ny) vector of mesh line coordinates in y-direction [arb].
%                       .z()  - real(Nz) vector of mesh line coordinates in z-direction [arb].
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
% Version 1.0.0 - Cubic and uniform meshes.

% Author: I. D. Flintoft
% Date: 30/10/2013
% Version 1.1.0
% Refactored option handling and provide more general decompostion
% of algorithm into functions.

  % Function to process array of mesh size constraints. 
  function [ uniqX , Xweight , dx_min , dx_max ] = processConstraints( constraints , epsCoalesceLines )
    %
    % Process a set of constraints defined over separate intervals into a single ordered
    % set of constraints over the whole range of the intervals. 
    %
    % Inputs:
    %
    % constraints() - real(nx5) array of mesh line constraints. Each row specifies one 
    %                 constraint interval:
    %
    %                 constraints(:,1) - lowest coordinate of constraint interval.
    %                 constraints(:,2) - highest coordinate ofconstraint interval.
    %                 constraints(:,3) - minimum mesh size over interval.
    %                 constraints(:,4) - maximum mesh size over interval.
    %                 constraints(:,5) - weighting factor for interval, >=1.
    %
    % Outputs:
    %
    % uniqX()   - real(m) ordered vector of constraint points.
    % Xweight() - real(m) vector of weights for each constraint point.
    % dx_min()  - real(m-1) vector of minimim mesh sizes.
    %                       dx_min(i) applies between points uniqX(i) and uniqX(i+1).   
    % dx_max()  - real(m-1) vector of maximum mesh sizes.
    %                       dx_max(i) applies between points uniqX(i) and uniqX(i+1).
    % 

    numConstraints = size( constraints , 1 );
    numPoints = 2 * numConstraints;

    % Extract constraint point coordinates into row vector.
    XX = reshape( constraints(1:numConstraints,1:2) , [ 1 , numPoints ] );

    % Sort points into ascending coordinate order.
    [ sortedX , idxForMap ] = sort( XX );

    % Get reverse mapping.
    [ ~ , idxRevMap ] = sort( idxForMap );

    % Coalesce nearby points.
    % [FIXME] This is not transitive so this may cause problems!
    % [FIXME] epsCoalesceLines should be estimated from mesh requirements.
    [ uniqX , ~ , idxUniq ] = meshUniqueTol1( sortedX , epsCoalesceLines );

    uniqX = uniqX';
    numUniqPoints = length( uniqX );
    fprintf( 'Coalesced %d points out of %d\n' ,  length( sortedX ) - numUniqPoints , length( sortedX ) );

    % Coalescing could result in only a single constraint point if epsCoalesceLines is too large.
    if( length( uniqX ) < 2 )
      error( 'Coalescing produced only one constraint point - reduce option.mesh.epsCoalesceLines' );
    end % if

    % Map original constraint coordinates onto indices into the uniq coordinate array.
    constraints(1:numConstraints,1:2) = reshape( idxUniq(idxRevMap) , [ numConstraints , 2 ] );

    % Stack constraints for each pair of points into matrix. 
    dx_min = inf( numConstraints , numUniqPoints - 1 );
    dx_max = inf( numConstraints , numUniqPoints - 1 );
    weight = zeros( numConstraints , numUniqPoints - 1 );
    for c=1:numConstraints
      thisRange = constraints(c,1):(constraints(c,2)-1);
      dx_min(c,thisRange) = constraints(c,3);
      dx_max(c,thisRange) = constraints(c,4);
      weight(c,thisRange) = constraints(c,5);
    end % for

    % Project down constraints for all groups.
    dx_min = min( dx_min , [] , 1 );
    dx_max = min( dx_max , [] , 1 );
    weight = max( weight , [] , 1 );

    % Map weights onto constraint points rather than intervals.
    % The weight for each point is the largest weight of its adjacent intervals.
    Xweight(1) = weight(1);
    Xweight(2:(numUniqPoints-1)) = max( [ weight(1:(numUniqPoints-2)) ; weight(2:(numUniqPoints-1)) ] , [] , 1 );
    Xweight(numUniqPoints) = weight(numUniqPoints-1);

  end % function

  % Velocity of light in free-space.
  c0 = 299792458;

  % Initialise constraints AABBs.
  Xconstraints = [];
  Yconstraints = [];
  Zconstraints = [];     
      
  % Frequencies for sampling material parameters.
  f = linspace( options.mesh.minFreq , options.mesh.maxFreq , options.mesh.numFreqSamp );
 
  % Get group indices of groups to be analysed.
  if( isempty( groupNamesToAnalyse ) )
    groupNamesToAnalyse = mesh.groupNames;
    groupIdxToAnalyse = 1:mesh.numGroups;
  else
    groupIdxToAnalyse = meshGetGroupIndices( mesh , groupNamesToAnalyse );
  end % if
  numGroupsToAnalyse = length( groupIdxToAnalyse );
  groupTypesToAnalyse = mesh.groupTypes(groupIdxToAnalyse);

  % Get computational volume name if required.
  if( options.mesh.useMeshCompVol )
    compVolGroupName = options.mesh.compVolName;
  else
    compVolGroupName = '';  
  end % if
  
  compVolAABB = [];
  compVol_dmin = [];
  compVol_dmin = [];    
      
  fprintf( 'Analysing %d groups\n' , numGroupsToAnalyse );

  % Analyse each group in turn.
  for newGroupIdx=1:numGroupsToAnalyse

    % Name and index of group in unstructured mesh.
    thisGroupName = groupNamesToAnalyse{newGroupIdx};
        
    thisGroupIdx = groupIdxToAnalyse(newGroupIdx);
    fprintf( 'Analysing group "%s" (index %d)\n' , thisGroupName , thisGroupIdx );

    % Get this group's option structure.
    thisOptions = meshGetGroupOptions( thisGroupIdx , options );

    % Get AABB of group.
    thisAABB = meshGetGroupAABB( mesh , thisGroupIdx );
    fprintf( '  AABB: [%g,%g,%g,%g,%g,%g]\n' , thisAABB );
    
    % If using mesh density determine mesh size range for current group from frequency and material.
    if( thisOptions.useDensity )
      switch( thisOptions.materialName )
      case 'FREE_SPACE'
        % Free-space is handled directly.
        dmin = min( c0 ./ f ./ thisOptions.Dmax );
        dmax = min( c0 ./ f ./ thisOptions.Dmin );
      case { 'PEC' , 'PMC' }
        % PEC/PMC have zero internal fields and thus don't constrain the mesh size. 
        dmin = Inf;
        dmax = Inf;
      otherwise
        % Use material database to determine wavelength and skin depth in material. 
        if( exist( 'matLookUp' , 'file'  ) )
          [ epsc_r , muc_r ] = matLookUp( thisOptions.materialName , f );
        else
          error( 'UoY AEG material database package required to use density based mesh line creation' );
        end % if
        gamma = sqrt( epsc_r .* muc_r );
        alpha = real( gamma );
        beta =  imag( gamma );
        % Length scale is smallest of wavelength and skin depth. 
        lengthScale = min( [ 2 * pi ./ beta , 1 ./ alpha ] );
        dmin = min( lengthScale / thisOptions.Dmax );
        dmax = max( lengthScale / thisOptions.Dmin );
      end % switch
    else
      % If not using mesh density take mesh sizes directly from group's options.
      dmin = thisOptions.dmin;
      dmax = thisOptions.dmax;
    end % if

    % If this is the computation volume group keep its AABB and mesh size but don't
    % add to the constraints yet.
    if( strcmp( thisGroupName , compVolGroupName ) )
      compVolAABB = thisAABB;
      compVol_dmin = dmin;
      compVol_dmax = dmax;      
      continue;
    end % if
    
    % Add group's mesh requirements to list of constraints for each direction.
    weight = thisOptions.weight;
    Xconstraints = [ Xconstraints ; thisAABB(1) , thisAABB(4) , dmin , dmax , weight ];
    Yconstraints = [ Yconstraints ; thisAABB(2) , thisAABB(5) , dmin , dmax , weight ];
    Zconstraints = [ Zconstraints ; thisAABB(3) , thisAABB(6) , dmin , dmax , weight ];

    fprintf( '  dmin = %g\n' , dmin );
    fprintf( '  dmax = %g\n' , dmax );

  end % for

  % Determine the computational volume.
  if( options.mesh.useMeshCompVol )
    % Use computational volume group object from mesh. We should have
    % found this above.
    if( isempty( compVolAABB ) )
      error( 'mesh does not contain a computational volume group called %s' , compVolGroupName );    
    end % if
    fprintf( 'Computational volume AABB from mesh: [%g,%g,%g,%g,%g,%g]\n' , compVolAABB );  
  elseif( ~isempty( options.mesh.compVolAABB ) )
    % Use computational volume specified in options.
    compVolAABB = options.mesh.compVolAABB;
    fprintf( 'Computational volume AABB from options: [%g,%g,%g,%g,%g,%g]\n' , compVolAABB );     
    % In this case we also need mesh size of the computational volume from the user.
    if( options.mesh.useDensity )
      % Free-space is assumed.
      compVol_dmin = min( c0 ./ f ./ options.mesh.Dmax );
      compVol_dmax = min( c0 ./ f ./ options.mesh.Dmin );
    else
      % If not using mesh density take mesh sizes directly from options.
      compVol_dmin = options.mesh.dmin;
      compVol_dmax = options.mesh.dmax;
    end % if
  else
    % Use minimal AABB of objects as computational volume.
    compVolAABB = [ min( Xconstraints(:,1) ) , min( Yconstraints(:,1) ) , min( Zconstraints(:,1) ) , ...
                    max( Xconstraints(:,2) ) , max( Yconstraints(:,2) ) , max( Zconstraints(:,2) ) ];
    fprintf( 'Computational volume AABB from mininal AABB of objects: [%g,%g,%g,%g,%g,%g]\n' , compVolAABB );
    % In this case we also need mesh size of the computational volume from the user.
    if( options.mesh.useDensity )
      % Free-space is assumed.
      compVol_dmin = min( c0 ./ f ./ options.mesh.Dmax );
      compVol_dmax = min( c0 ./ f ./ options.mesh.Dmin );
    else
      % If not using mesh density take mesh sizes directly from options.
      compVol_dmin = options.mesh.dmin;
      compVol_dmax = options.mesh.dmax;
    end % if 
  end % if
 
  % Check computational volume has finite volume. 
  if( compVolAABB(4) <= compVolAABB(1) || compVolAABB(5) <= compVolAABB(2) || compVolAABB(6) <= compVolAABB(3) )
    error( 'Computational volume has zero or negative volume!' );
  end % if

  % Truncate constraints AABBs to computational volume
  % and delete constraint AABBs wholy outside the computational volume.
  idx = find( Xconstraints(:,1) < compVolAABB(1) );
  Xconstraints(idx,1) = compVolAABB(1);
  idx = find( Xconstraints(:,2) > compVolAABB(4) );
  Xconstraints(idx,2) = compVolAABB(4);
  idx = find( Xconstraints(:,1) > Xconstraints(:,2) );
  Xconstraints(idx,:) = [];  
  idx = find( Yconstraints(:,1) < compVolAABB(2) );
  Yconstraints(idx,1) = compVolAABB(2);
  idx = find( Yconstraints(:,2) > compVolAABB(5) );
  Yconstraints(idx,2) = compVolAABB(5);
  idx = find( Yconstraints(:,1) > Yconstraints(:,2) );
  Yconstraints(idx,:) = [];  
  idx = find( Zconstraints(:,1) < compVolAABB(3) );
  Zconstraints(idx,1) = compVolAABB(3);
  idx = find( Zconstraints(:,2) > compVolAABB(6) );
  Zconstraints(idx,2) = compVolAABB(6);
  idx = find( Zconstraints(:,1) > Zconstraints(:,2) );
  Zconstraints(idx,:) = [];  

  % Add the computational volume to the constraints.
  Xconstraints = [ compVolAABB(1) , compVolAABB(4) , compVol_dmin , compVol_dmax , 1 ];
  Yconstraints = [ compVolAABB(2) , compVolAABB(5) , compVol_dmin , compVol_dmax , 1 ];
  Zconstraints = [ compVolAABB(3) , compVolAABB(6) , compVol_dmin , compVol_dmax , 1 ];   

  % Process constraints in each direction.
  [ X , Xweight , dx_min , dx_max ] = processConstraints( Xconstraints , options.mesh.epsCoalesceLines );
  [ Y , Yweight , dy_min , dy_max ] = processConstraints( Yconstraints , options.mesh.epsCoalesceLines );
  [ Z , Zweight , dz_min , dz_max ] = processConstraints( Zconstraints , options.mesh.epsCoalesceLines );

  % Determine mesh lines from constraints.
  switch( options.mesh.meshType )    
  case 'CUBIC'
    dmin = min( [ dx_min , dy_min , dz_min ] );
    dmax = min( [ dx_max , dy_max , dz_max ] );
    fprintf( 'Finding CUBIC mesh with dmin=%g, dmax=%g\n' , dmin , dmax );
    [ lines ] = meshCreateCubicMeshLines( X , Y , Z , Xweight , Yweight , Zweight , dmin , dmax , options.mesh );
  case 'UNIFORM'
    dx_min = min( dx_min );
    dx_max = min( dx_max );
    dy_min = min( dy_min );
    dy_max = min( dy_max );
    dz_min = min( dz_min );
    dz_max = min( dz_max );
    fprintf( 'Finding UNIFORM mesh with dmin=[%g,%g,%g], dmax=[%g,%g,%g]\n' , dx_min , dy_min , dz_min , dx_max , dy_max , dz_max );
    [ lines.x , dx ] = meshCreateUniformMeshLines( X , Xweight , dx_min , dx_max , 'x' , options.mesh );
    [ lines.y , dy ] = meshCreateUniformMeshLines( Y , Yweight , dy_min , dy_max , 'y' , options.mesh );
    [ lines.z , dz ] = meshCreateUniformMeshLines( Z , Zweight , dz_min , dz_max , 'z' , options.mesh );
    % Report and check cell aspect ratios.
    minSize = min( [ dx , dy , dz ] );
    ratios = [ dx / minSize , dy / minSize , dz / minSize ];
    fprintf( '  Cell aspect ratios [%g,%g,%g]\n' , ratios );   
    if( max( ratios ) > options.mesh.maxAspect )
      warning( ' *** Cell aspect ratio exceeds bound ***\n' );
    end % if
  case 'NONUNIFORM'
    fprintf( 'Finding NONUNIFORM mesh with [%d,%d,%d] constraint points\n' , length( X ) , length( Y ) , length( Z ) );
    error( 'Unsupported mesh type %s' , options.mesh.meshType );
    %[ lines.x ] = meshCreateNonUniformMeshLines( X , Xweight , dx_min , dx_max , 'x' , options.mesh );
    %[ lines.y ] = meshCreateNonUniformMeshLines( Y , Yweight , dy_min , dy_max , 'y' , options.mesh );
    %[ lines.z ] = meshCreateNonUniformMeshLines( Z , Zweight , dz_min , dz_max , 'z' , options.mesh );
    % Report and check mesh quality factors.
  otherwise
    error( 'Invalid mesh type %s' , options.mesh.meshType );
  end % switch

  fprintf( 'Mapped computational volume AABB: [%g,%g,%g,%g,%g,%g]\n' , lines.x(1) , lines.y(1) , lines.z(1) , ...
                                                                lines.x(end) , lines.y(end) , lines.z(end) );

end % function

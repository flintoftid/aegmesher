function meshTestTimingSummary( isPlot , testNames )
%
% meshTestTimingSummary - Create summary of test results. 
%
% meshTestTimingSummary( isPlot )
%
% Inputs:
%
% isPlot - boolena, indicates if timing plots should be created.
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
% Date: 27/08/2014
% Version: 1.0.0

  % Summary file.
  fh_summ = fopen( 'summary.txt' , 'w' );
 
  % Header for table.
  fprintf( fh_summ , '# %12s %10s %10s %6s %6s %8s %6s %6s %6s %8s\n' , ...
           'Test Name' , '#Elements' , '#Cells' , 'Read' , 'Lines' , 'Map' , 'S2Un' , 'Save' , 'Write' , 'Vulture' );
             
  % Collect data and append to summary file.
  times = [];
  for testIdx = 1:length( testNames)
    % Function is run one level below the test folder so we need to look one level up!
    fh = fopen( [ '../' , testNames{testIdx} , '/' , testNames{testIdx} , '.times' ] , 'r' );
    if( fh == -1 )
      error( 'cannot open %s ' , [ '../' , testNames{testIdx} , '/' , testNames{testIdx} , '.times' ] );
    end % if
    [ ~ ] = fgetl( fh );
    thisTimes = fscanf( fh , '%f' , Inf );
    assert( length( thisTimes ) == 9 );
    fprintf( fh_summ , '  %12s %10d %10d %6.2f %6.2f %8.2f %6.2f %6.2f %6.2f %8.2f\n' , ...
             testNames{testIdx} , thisTimes );
    times = [ times ; thisTimes' ];
    fclose( fh );
  end % for

  fclose( fh_summ );

  if( isPlot )
  
    figure( 1 );
    loglog( times(:,1) , times(:,5) , 'ro' );
    hold on;
    loglog( times(:,1) , times(:,6) , 'b^' );  
    loglog( times(:,1) , times(:,9) , 'g*' );  
    xlabel( 'Number of unstructured elements (-)' );
    ylabel( 'Time (s)' );  
    title( 'Times versus number of unstructured elements' ); 
    legend( 'Mapping' , 'S2Un' , 'Vulture export' , 'location' , 'northwest' );
    print( '-depsc' , 'times_v_num_elem.eps' );
    hold off;
  
    figure( 2 );
    loglog( times(:,2) , times(:,5) , 'ro' );
    hold on;  
    loglog( times(:,2) , times(:,6) , 'b^' );  
    loglog( times(:,2) , times(:,9) , 'g*' );  
    xlabel( 'Number of structured cells (-)' );
    ylabel( 'Time (s)' );  
    legend( 'Mapping' , 'S2Un' , 'Vulture export' , 'location' , 'northwest' );
    title( 'Times versus number of structured cells' );
    print( '-depsc' , 'times_v_num_cells.eps' );
    hold off;
  
  end % if
  
end % function

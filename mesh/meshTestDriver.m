function meshTestDriver( testName , withVulture )
%
% meshTestDriver - Driver for testsuite.
%
% Usage:
%
% meshTestDriver( testName , withVulture )
%
% Inputs:
%
% testName - string, name of test. Input unstructured mesh in Gmsh format 
%            is expected to be in current directory with name <testName>.msh
% withVulture - string, 'ON' or 'OFF' indicating if Vulture mesh should be generated.
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

% Author: I. D. Flintoft
% Date: 12/08/2014
% Version 1.0.0

  fh_timing = fopen( [ testName , '.times' ] , 'w' );
  fprintf( fh_timing , '#' ); 
  labels = { '   Read' , '  Lines' , '    Map' , '   S2Un' , '   Save' , '  Write' , '  Vult.' , '#elements' , '   #cells' };
  for labelIdx=1:length( labels ) 
   fprintf( fh_timing , '%8s ' , labels{labelIdx} ); 
  end % for
  fprintf( fh_timing , '\n' );
  
  tic();
  [ mesh ] = meshReadGmsh( [ testName , '.msh' ] );
  time_read = toc();
  fprintf( '(T) Total mesh read time  %.2f s\n' , time_read ); 
  fprintf( fh_timing , ' %8.2f ' , time_read ); 
  
  [ groupNamesToMap , options ] = feval( [ 'meshTest' , testName ] , mesh );

  tic();
  [ lines ] = meshCreateLines( mesh , groupNamesToMap , options );
  time_lines = toc();
  fprintf( '(T) Total mesh line creation time %.2f s\n' , time_lines ); 
  fprintf( fh_timing , '%8.2f ' , time_lines ); 

  % meshWriteLines2Gmsh( 'lines.msh' , lines , mesh );
   
  tic();
  [ smesh ] = meshMapGroups( mesh , groupNamesToMap , lines , options );
  time_mapping = toc();
  fprintf( '(T) Total mesh mapping time %.2f s\n' , time_mapping ); 
  fprintf( fh_timing , '%8.2f ' , time_mapping ); 
  
  tic();
  [ unmesh ] = meshSmesh2UnmeshFast( smesh );
  time_convert = toc() ;
  fprintf( '(T) Total structured to unstructured mesh conversion time %.2f s\n' , time_convert ); 
  fprintf( fh_timing , '%8.2f ' , time_convert );
  
  tic();
  meshSaveMesh( [ testName , '.mat' ] , smesh );
  time_save = toc();
  fprintf( '(T) Total structured mesh save time %.2f s\n' , time_save ); 
  fprintf( fh_timing , '%8.2f ' , time_save );
  
  tic();
  meshWriteGmsh( 'structuredMesh.msh' , unmesh );
  time_write = toc();
  fprintf( '(T) Total structured unstructured mesh write time %.2f s\n' , time_write ); 
  fprintf( fh_timing , '%8.2f ' , time_write );  

  if( strcmp( withVulture , 'ON' ) )
 
    options.vulture.useMaterialNames = false;
    tic();
    meshWriteVulture( 'vulture.mesh' , smesh , options );
    time_vulture = toc();
    fprintf( '(T) Total vulture mesh export time  %.2f s\n' , time_vulture );     
    fprintf( fh_timing , '%8.2f ' , time_vulture );
  end % if

  fprintf( fh_timing , '%8d %8d ' , mesh.numElements , length( lines.x ) * length( lines.y ) * length( lines.z ) );

  fprintf( fh_timing , '\n' );
  fclose( fh_timing );

end % function

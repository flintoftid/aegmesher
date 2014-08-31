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
   
  % Import unstructured mesh.
  tic();
  [ mesh ] = meshReadGmsh( [ testName , '.msh' ] );
  times(1) = toc();
  fprintf( '(T) Total mesh read time  %.2f s\n' , times(1) ); 

  % Save the unstructured mesh.
  meshSaveMesh( [ testName , '_input_mesh' , '.mat' ] , mesh );

  % Set meshing options using function is test source directory.
  [ groupNamesToMap , options ] = feval( [ 'meshTest' , testName ] , mesh );

  % Generate mesh lines.
  tic();
  [ lines ] = meshCreateLines( mesh , groupNamesToMap , options );
  times(2) = toc();
  fprintf( '(T) Total mesh line creation time %.2f s\n' , times(2) ); 
   
  % Map groups onto structured mesh.
  tic();
  [ smesh ] = meshMapGroups( mesh , groupNamesToMap , lines , options );
  times(3) = toc();
  fprintf( '(T) Total mesh mapping time %.2f s\n' , times(3) ); 
  
  % Save the structured mesh. 
  tic();
  meshSaveMesh( [ testName , '_structured_mesh' , '.mat' ] , smesh );
  times(5) = toc();
  fprintf( '(T) Total structured mesh save time %.2f s\n' , times(5) ); 
  
  % Convert structured mesh into unstructured format.
  tic();
  [ unmesh ] = meshSmesh2Unmesh( smesh );
  times(4) = toc() ;
  fprintf( '(T) Total structured to unstructured mesh conversion time %.2f s\n' , times(4) ); 
  
  % Export structured mesh in Gmsh format.
  tic();
  meshWriteGmsh( 'structuredMesh.msh' , unmesh );
  times(6) = toc();
  fprintf( '(T) Total structured unstructured mesh write time %.2f s\n' , times(6) ); 

  if( strcmp( withVulture , 'ON' ) )

    % Export structured mesh in Vulture format.
    options.vulture.useMaterialNames = false;
    tic();
    meshWriteVulture( 'vulture.mesh' , smesh , options );
    times(7) = toc();
    fprintf( '(T) Total vulture mesh export time  %.2f s\n' , times(7) );     

  else
  
    times(7) = NaN;
      
  end % if
  
  % Write timings to file.
  fh_timing = fopen( [ testName , '.times' ] , 'w' );
  labels = { '#elements' , '   #cells' , '   Read' , '  Lines' , '    Map' , '   S2Un' , '   Save' , '  Write' , '  Vult.'  };
  fprintf( fh_timing , '# ' ); 
  for labelIdx=1:length( labels ) 
   fprintf( fh_timing , '%9s ' , labels{labelIdx} ); 
  end % for  
  fprintf( fh_timing , '\n' );
  fprintf( fh_timing , '  %9d %9d ' , mesh.numElements , length( lines.x ) * length( lines.y ) * length( lines.z ) );  
  fprintf( fh_timing , '%9.3f ' , times );   
  fprintf( fh_timing , '\n' );
  fclose( fh_timing );

end % function

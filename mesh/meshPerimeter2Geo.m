function meshPerimeter2Geo( geoFileName , meshType , boundaryPoints , boundPointMeshSize , constraintPoints , conPointMeshSize )
%
% meshPerimenter2Geo: Write a Gmsh input file to create a surface mesh from
%                     a set of boundary points describing its perimeter and
%                     a set of constraint points within its perimieter.
%
% Usage:
%
% meshPerimeter2Geo( geoFileName , meshType , boundaryPoints , boundPointMeshSize [ , constraintPoints [, conPointMeshSize ] ] )
%
% Inputs:
%
% geoFileName        - string, name of gmsh geo file to create (string).
% meshType           - string, type of mesh to create: 'tri3' or 'quad4'.
% boundaryPoints     - (Nb x 3) float, *ordered* array of Nb point coordinates 
%                      describing perimeter of surface. The last point is connected 
%                      to first automatically.
% boundPointMeshSize - (scalar or Nbx1) float array giving mesh size at
%                      each boundary point. If scalar all points have same mesh size.
% constraintPoints   - (Nc x 3) float array of point coordinates 
%                      describing constraint points within/on the boundary.
% conPointMeshSize   - (Nb x 1) float array giving mesh size at
%                      each boundary point. Defaults to first entry in boundPointMeshSize 
%                      array.
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

% Author: I. D Flintoft
% Date: 18/06/2010
% Version: 1.0.0

  numBoundPoints = size( boundaryPoints , 1 );

  % Expand boundary point mesh size if scalar provided.
  if( length( boundPointMeshSize ) == 1 )
    boundPointMeshSize = boundPointMeshSize .* ones( size( boundaryPoints , 1 ) , 1 );
  elseif( length( boundPointMeshSize ) ~= size( boundaryPoints , 1 ) )
    error( 'Invalid size for boundPointMeshSize: %d' , size( boundaryPoints , 1 ) );
  end % if

  % Expand constraint point mesh size if required.
  if( nargin >= 5 )
    numConPoints = size( constraintPoints , 1 );
    if( nargin >= 6 )
      if( length( conPointMeshSize ) == 1 )
        conPointMeshSzie = conPointMeshSize .* ones( size( constraintPoints , 1 ) , 1 );
      elseif( length( conPointMeshSize ) ~= size( constraintPoints , 1 ) )
        error( 'Invalid size for conPointMeshSize: %d' , size( constraintPoints , 1 ) );
      end % if
    else
      conPointMeshSize = boundPointMeshSize(1) .* ones( size( constraintPoints , 1 ) , 1 );
    end %if
  else
    numConPoints = 0;
  end % if

  % Open file.
  [ fout , msg ] = fopen ( geoFileName , 'w' );
  if ( fout < 0 ) 
    error( '%s: %s' , geoFileName , msg );
    return;
  end %if

  % Mesh type.
  if( strcmpi( meshType , 'quad4' ) )
    % "Quads for Delaunay" doesn't seem to work with constraints.
    if( numConPoints == 0 )
      fprintf( fout , 'Mesh.Algorithm = 8;\n' );
    else
      fprintf( fout , 'Mesh.Algorithm = 2;\n' );
    end % if
    fprintf( fout , 'Mesh.RecombinationAlgorithm = 1;\n' );
    fprintf( fout , 'Mesh.RecombineAll = 1;\n' );
    fprintf( fout , '\n' );
  elseif(  strcmpi( meshType , 'tri3' )  )
    fprintf( fout , 'Mesh.Algorithm = 2;\n' );
    fprintf( fout , 'Mesh.RecombineAll = 0;\n' );
    fprintf( fout , '\n' );
  else
    error( 'Invalid mesh type: %s' , meshType );
  end % if

  % Boundary points.
  for k=1:numBoundPoints
    fprintf( fout , 'Point(%d) = { %e , %e , %e , %e };\n' , ...
             k , boundaryPoints(k,1) , boundaryPoints(k,2) , boundaryPoints(k,3) , boundPointMeshSize(k) );
  end % for
  fprintf( fout , '\n' );

  % Constriant points.
  for k=1:numConPoints
    fprintf( fout , 'Point(%d) = { %e , %e , %e , %e };\n' , ...
             k + numBoundPoints , constraintPoints(k,1) , constraintPoints(k,2) , constraintPoints(k,3) , conPointMeshSize(k) );
  end % for
  fprintf( fout , '\n' );

  % Lines.
  for k=1:(numBoundPoints-1)
    fprintf( fout , 'Line(%d) = { %d , %d };\n' , k , k , k + 1 );
  end % for
  fprintf( fout , 'Line(%d) = { %d , %d };\n' , numBoundPoints , numBoundPoints , 1 );
  fprintf( fout , '\n' );

  entityNum = numBoundPoints + numConPoints + 1;
  lineLoopNum = entityNum;

  % Line loop for surface perimeter.
  fprintf( fout , 'Line Loop(%d) = { ' , entityNum );
  for k=1:(numBoundPoints-1)
    fprintf( fout , '%d, ' , k );
  end % for
  fprintf( fout , '%d };\n' , numBoundPoints );
  fprintf( fout , '\n' );

  % Surface.
  entityNum = entityNum + 1;
  surfNum = entityNum;

  fprintf( fout , 'Plane Surface(%d) = {%d};\n' , surfNum , lineLoopNum  );
  fprintf( fout , '\n' );

  % Constraints points.
  for k=1:numConPoints
    fprintf( fout , 'Point {%d} In Surface {%d};\n' , k + numBoundPoints , surfNum );
  end % for
  fprintf( fout , '\n' );

  fclose( fout );

end % function

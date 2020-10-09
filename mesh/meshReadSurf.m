function [ mesh ] = meshReadSurf( surfFileName , groupName )
%
% meshReadSurf: Read a CONCEPT surf file. 
%
% Usage:
%
% [ mesh ] = meshReadSurf( surfFileName [ , groupName ] )
%
% Inputs:
%
% surfFileName - string, name of CONCEPT surf file to read.
% groupName    - string, name of surface group to create.
%                Default: 'Surface-1'
% 
% Outputs:
%
% mesh - structure containing the unstructured mesh. See help for meshReadAmelet().
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
% Date: 30/09/2012
% Version: 1.0.0

  % Initialise mesh.
  mesh.dimension = 3;
  mesh.numNodes = 0;
  mesh.nodes = [];
  mesh.numElements = 0;
  mesh.elementTypes = [];
  mesh.elements = [];
  mesh.numGroups = 0;
  mesh.groupNames = cell(1,1);
  mesh.groupTypes = [];
  mesh.groups = [];

  if( nargin == 1 )
    groupName = 'Surface-1';
  end % if

  % Open CONCEPT SURF file.
  [ fin , msg ] = fopen ( surfFileName , 'r' );
  if ( fin < 0 ) 
    error( '%s: %s' , surfFileName , msg );
    return;
  end %if

  fprintf( 'Opened surf file %s.\n' , surfFileName );

  % Read header line with number of nodes and elements.
  [ fields , count ] = fscanf( fin , '%d' , [ 2 ] );
  if( count ~= 2 )
    error( 'Failed to read number of nodes and elements.' );
  else
    mesh.numNodes = fields(1);
    mesh.numElements = fields(2);
  end % if

  fprintf( 'Read header.\n' );

  % Read nodes.
  [ mesh.nodes , count ] = fscanf( fin , '%e' , [ 3 , mesh.numNodes ] );
  if( count ~= 3 * mesh.numNodes )
    error( 'Failed to read nodes' );
  end % if

  fprintf( 'Read %d nodes.\n' , mesh.numNodes );

  % Read elements.
  [ elements , count ] = fscanf( fin , '%d' , [ 4 , mesh.numElements ] );
  if( count ~= 4 * mesh.numElements )
    error( 'Failed to read elementts' );
  end % if

  junk = fgetl( fin );
  if( ~feof( fin ) )
    warning( 'Somethings left in surf file!' );
  end % if

  % Find triangles and quads.
  triIdx = find( elements(4,:) == 0 );
  numTriangles = length( triIdx );
  quadIdx = find( elements(4,:) ~= 0 );
  numQuads = length( quadIdx );
  
  assert( numTriangles + numQuads == mesh.numElements );

  mesh.elementTypes = zeros( 1 , mesh.numElements );
  mesh.elementTypes(triIdx) = 11;
  mesh.elementTypes(quadIdx) = 13;
  mesh.elements = sparse( 4 , mesh.numElements );
  mesh.elements(1:3,triIdx) = elements(1:3,triIdx);
  mesh.elements(1:4,quadIdx) = elements(1:4,quadIdx);

  fprintf( 'Read %d triangles and %d quads.\n' , numTriangles , numQuads );

  fclose( fin );

  fprintf( 'Closed surf file.\n' );

  % Add all elements to single surface group.
  mesh.numGroups = 1;
  mesh.groupTypes(1) = 2;
  mesh.groupNames{1} = groupName;
  mesh.groups = sparse(1,1);
  mesh.groups(1:mesh.numElements,1) = (1:mesh.numElements)';

end % function


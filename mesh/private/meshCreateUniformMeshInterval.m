function [ x ] = meshCreateUniformMeshInterval( deltaX , dmax , L_min )
%
% meshCreateUniformMeshInterval - calculates an uniform mesh in between a fix interval
%
% Usage:
%
% [ x ] = meshCreateUniformMeshInterval( deltaX ,dmax, L_min )
%
%
% Inputs:
%
% deltaX           - array, constrained points for mesh
% dmax             - float, biggest local mesh size.
% L_min            - float, smalles global mesh size 
%
% Output:
%
% x                - array, 1D uniform mesh

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

% initialize variables
x = [];
D_opt_X = [];
D_optX = [];

% define discret range of cell sizes in dependence of min/max control values
D = L_min:1e-7:dmax;

% find optimal mesh size
[ D_fracX, fvalX ] = meshFindOptD( deltaX, D );

% extract optimal cell size
D_opt_X(1,:) = D(D_fracX == min(D_fracX));
D_opt_X(2,:) = D_fracX(D_fracX == min(D_fracX));

% if more than one optimal solutions were found --> chose biggest one
D_optX = round( max(D_opt_X(1,:))*1e8 )/1e8;

% create 1D mesh with opt cell size
x = 0:D_optX:sum(deltaX);



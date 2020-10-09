function [ uniqX , i , j ] = meshUniqueTol1( x , tol )
%
% meshUniqueTol1 - Unique function with tolerance.
%
% [ uniqX , i , j ] = meshUniqueTol1( x , tol )
%
% Inputs:
%
% x(n) - real, vector 
% tol  - real, scalar, tolerance within  which to consider eleements unique.
%
% Outputs:
%
% uniqX(m) - unique elements of x.
% i(n)     - mapping such that x(i) = uniqX.
% j(m)     - mapping such that uniqX(j) = x.
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

% Based on outline by 'JudoWill' at
% http://stackoverflow.com/questions/1988535/return-unique-element-with-a-tolerance

  x = x(:);
  
  % Sort data.
  [ sortedX , idxSort  ] = sort( x );

  % Find index of elements whose difference is less than tolerance.
  idxUniq = diff( [-Inf ; sortedX ] ) > tol;
  
  % Get unique elements.
  uniqX = x(idxSort(idxUniq)); 

  % Location of original sorted elements in the unique list.
  j = cumsum(idxUniq);

  % Undo the sorting.
  i = idxSort(idxUniq);
  j(idxSort) = j;
  
end % function











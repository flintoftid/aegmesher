
# AEG Mesher: Known bugs

## Nonuniform mesh line creation disabled due to bugs

The non-uniform mesh line creation algorithm is currently disabled due to 
some bugs in the implementation. It will be reinstated once these issues are fixed.

## TIMING_intersect test fails on 32-bit Linux system

The asserts for the third implementation of the intersection
function fail - need bigger tolerances.

## Mapper fails with physically small objects

For example, the test case NonWovenMesh has overall dimensions
of 3mm x 3mm x 45 um. If metres are used instead of mm tolerances
are not sensible.

## Some _surfchk tests fails because gmsh regards repeated elements are invalid

These aren't really failures but a difference in semantics in the 
use of the gmsh file format.

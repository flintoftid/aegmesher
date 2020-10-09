![](https://github.com/flintoftid/aegmesher/blob/master/examples/jet/Jet_unstructured.jpg "Jet input unstructure mesh")
![](https://github.com/flintoftid/aegmesher/blob/master/examples/jet/Jet_structured_2.jpg "Jet output structure mesh, medium res")
![](https://github.com/flintoftid/aegmesher/blob/master/examples/jet/Jet_structured_1.jpg "Jet output structure mesh, high res")

# Jet from STL file

This example uses an [STL model](Jet.stl) of a Saab Viggen jet fighter that is available from [3dvia][] 
under a [Creative Commons Attribution Licence](http://creativecommons.org/licenses/by/2.5) - see tthe
[licence file](Licence.txt). 

To convert the STL file into Gmsh format rename the file `Jet.stl` and then create a 
Gmsh script [stl2msh.geo](stl2msh.geo) containing the lines

    Merge "Jet.stl";
    Physical Surface("Jet")={1};

and use Gmsh to perform the conversion with

    gmsh -2 -o "Jet.msh" stl2msh.geo

This method of conversion ensures that the surface is in a physical group named `Jet`.

An example MATLAB/Octave script to create the structured mesh using the mesher is provided in the
file [meshJet.m](meshJet.m):

    function meshJet()

      testName = 'Jet';

      % Import unstructured mesh.
      [ mesh ] = meshReadGmsh( [ testName , '.msh' ] );

      % Save the unstructured mesh.
      meshSaveMesh( [ testName , '_input_mesh' , '.mat' ] , mesh );

      % Set meshing options using function is test source directory.
      [ options ] = meshSetDefaultOptions( mesh.numGroups , ...
         'useDensity' , false , 'dmin' , 2 , 'dmax' , 2 );
      options.mesh.meshType = 'CUBIC';
      options.mesh.useMeshCompVol = false;
      options.mesh.useDensity = false;
      options.mesh.dmin = 2;
      options.mesh.dmax = 2;  

      groupNamesToMap = { 'Jet' }; 
      groupIdxToMap = meshGetGroupIndices( mesh , groupNamesToMap );
      idxJet = groupIdxToMap(1);
      options.group(idxJet).type = 'SURFACE';
      options.group(idxJet).materialName = 'PEC';

      % Generate mesh lines.
      [ lines ] = meshCreateLines( mesh , groupNamesToMap , options );

      % Map groups onto structured mesh.
      [ smesh ] = meshMapGroups( mesh , groupNamesToMap , lines , options );

      % Save the structured mesh. 
      meshSaveMesh( [ testName , '_structured_mesh' , '.mat' ] , smesh );

      % Convert structured mesh into unstructured format.
      [ unmesh ] = meshSmesh2Unmesh( smesh );
      
      % Export structured mesh in Gmsh format.
      meshWriteGmsh( 'structuredMesh.msh' , unmesh );

    end % function



[3dvia]: http://www.3dvia.com/content/2C7A92223406182A

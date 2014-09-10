#
# Test driver function.
#
# Each test for this driver should have a subdirectory called TESTNAME
# containing an unstructured mesh called TESTNAME.<suf>, where <suf> is
# one of 'geo' (Gmsh BREP format), 'h5' (AMELET-HDF format), 'stl' (STL 
# format) or 'msh' (Gmsh mesh format). Optionally the directoy can also
# contain:
#
# 1. A MATLAB/Octave startup script startup.m.cmake.
#

function( meshTest TESTNAME TESTTAG H5_GROUP_NAME H5_MESH_NAME )

  set( THIS_TEST_INPUT_DIR "${MESH_SOURCE_DIR}/tests/${TESTNAME}" )
  
  configure_file( "${MESH_SOURCE_DIR}/tests/startup.m.cmake" startup.m )

  # Process input unstructured mesh to Gmsh format.
  if( EXISTS "${MESH_SOURCE_DIR}/tests/${TESTNAME}/${TESTNAME}.geo" )
    if( WITH_GMSH )
      add_test( NAME ${TESTTAG}_geo2msh COMMAND ${GMSH_EXECUTABLE} -2 -o "${TESTNAME}.msh" "${MESH_SOURCE_DIR}/tests/${TESTNAME}/${TESTNAME}.geo" )
    endif( WITH_GMSH )
  elseif( EXISTS "${MESH_SOURCE_DIR}/tests/${TESTNAME}/${TESTNAME}.h5" )    
    add_test( NAME ${TESTTAG}_h52msh COMMAND ${MEXEC} "meshAmelet2Gmsh( '${TESTNAME}.msh' , '${MESH_SOURCE_DIR}/tests/${TESTNAME}/${TESTNAME}.h5' , '${H5_GROUP_NAME}' , '${H5_MESH_NAME }' ) ; exit " )
  elseif( EXISTS "${MESH_SOURCE_DIR}/tests/${TESTNAME}/${TESTNAME}.stl" )   
    add_test( NAME ${TESTTAG}_stl2msh COMMAND ${GMSH_EXECUTABLE} -2 -o "${TESTNAME}.msh" "${MESH_SOURCE_DIR}/tests/${TESTNAME}/${TESTNAME}.stl" )  
  elseif( EXISTS "${MESH_SOURCE_DIR}/tests/${TESTNAME}/${TESTNAME}.msh" )
    file( COPY "${MESH_SOURCE_DIR}/tests/${TESTNAME}/${TESTNAME}.msh" DESTINATION . )  
  else()
    message( ERROR , "No input mesh found for ${TESTNAME}!" )
  endif()

  # Unstructured mesh exporters.
  if( WITH_CONCEPT )
    add_test( NAME ${TESTTAG}_msh2surf COMMAND ${MEXEC} "meshGmsh2Surf( '${TESTNAME}.surf'    , '${TESTNAME}.msh' ) ; exit"  )
    add_test( NAME ${TESTTAG}_msh2wire COMMAND ${MEXEC} "meshGmsh2Wire( '${TESTNAME}.wire'    , '${TESTNAME}.msh' ) ; exit"  )
    add_test( NAME ${TESTTAG}_surf2msh COMMAND ${MEXEC} "meshSurf2Gmsh( '${TESTNAME}_out.msh' , '${TESTNAME}.surf' ) ; exit" )
  endif( WITH_CONCEPT )

  # Mesh mapping.
  if( WITH_MESHER )
  
    add_test( NAME ${TESTTAG}_mesher COMMAND ${MEXEC} "meshTestDriver( '${TESTNAME}' , '${WITH_GVULTURE}' ) ; exit " )

    if( WITH_GMSH )
      add_test( NAME ${TESTTAG}_surfchk COMMAND ${GMSH_EXECUTABLE} -check structuredmesh.msh )
    endif( WITH_GMSH )

    if( WITH_GVULTURE )
      add_test( NAME ${TESTTAG}_gvulture COMMAND ${GVULTURE_EXECUTABLE} -e -p -m vulture.mesh )
    endif( WITH_GVULTURE)
 
  endif( WITH_MESHER )

endfunction()

#
# Tests.
#

#set_property(TEST test1 PROPERTY WILL_FAIL TRUE)

# Timing tests.
add_subdirectory( TimeIntersections )

# Basic tests.
add_subdirectory ( Cube )
add_subdirectory ( Solid01 )
add_subdirectory ( Sphere01 )
add_subdirectory ( Surface01 )
add_subdirectory ( Surface02 )
add_subdirectory ( Surface03 )
add_subdirectory ( Surface04 )
add_subdirectory ( CubesAndPlane )

# AMELET tests.

# Complex model tests.
add_subdirectory ( WireBox )
add_subdirectory ( Blade1 )

# Create test timing summary - must be last!
add_subdirectory ( Summary )

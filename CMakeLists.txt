#
# MESH
#

project ( MESH C )

cmake_minimum_required( VERSION 2.8.0 )

# Project name and version.
set( ${PROJECT_NAME}_PACKAGE "\"MESH\"" )
set( ${PROJECT_NAME}_VERSION_MAJOR "0" )
set( ${PROJECT_NAME}_VERSION_MINOR "1" )
set( ${PROJECT_NAME}_VERSION_PATCH "0" )
set( ${PROJECT_NAME}_VERSION_STRING "\"${${PROJECT_NAME}_VERSION_MAJOR}.${${PROJECT_NAME}_VERSION_MINOR}.${${PROJECT_NAME}_VERSION_PATCH}\"" )

option( WITH_TESTS     "Run test suite"               ON  )
option( WITH_BIG_TESTS "Run time consuming tests"     OFF )
option( WITH_GMSH      "Include Gmsh tests"           ON  )
option( WITH_MESHER    "Include mesher tests"         OFF )
option( WITH_AMELET    "Include CONCEPT tests"        OFF )
option( WITH_CONCEPT   "Include AMELET tests"         OFF )
option( WITH_GVULTURE  "Include gvulture tests"       OFF )
option( WITH_MATLAB    "Use MATLAB instead of Octave" OFF )

# Directory with test input data.
set( TEST_INPUT_DIR ${CMAKE_SOURCE_DIR}/tests )

if( WITH_TESTS )

  enable_testing()

  if( WITH_MATLAB )
  
    find_program( MATLAB matlab )
    if( MATLAB )
      message( STATUS "MATLAB: ${MATLAB}" )
      set( MEXEC  matlab "-nosplash" "-nodisplay" "-nodesktop" "-r" CACHE INTERNAL "" ) 
    else( MATLAB )
      message( FATAL_ERROR "Cannot find MATLAB" )
    endif( MATLAB )
    
  else( WITH_MATLAB )
  
    find_program( OCTAVE octave )
    if( OCTAVE )
      message( STATUS "Octave: ${OCTAVE}" )
      set( MEXEC ${OCTAVE} "-q" "--eval" CACHE INTERNAL "" )
      #set( MEXEC  matlab "-nosplash" "-nojvm" "-nodisplay" "-nodesktop" "-r" CACHE INTERNAL "" ) 
    else( OCTAVE )
      message( FATAL_ERROR "Cannot find octave" )
    endif( OCTAVE )

  endif( WITH_MATLAB )
  
  if( WITH_GMSH )
    find_program( GMSH_EXECUTABLE gmsh )
    if( GMSH_EXECUTABLE )
      message( STATUS "Found Gmsh: ${GMSH_EXECUTABLE}" )
    else( GMSH_EXECUTABLE )
      message( STATUS "Gmsh not found: disabling associated tests" )
      set( WITH_GMSH OFF )
    endif( GMSH_EXECUTABLE )
  endif( WITH_GMSH )

  if( WITH_AMELET )
    find_program( H5TOTXT_EXECUTABLE NAMES h5totxt )
    if( H5TOTXT_EXECUTABLE )
      message( STATUS "Found h5utils (h5totxt): ${H5TOTXT_EXECUTABLE}" )   
    else( H5TOTXT_EXECUTABLE )
      message( WARNING "h5utils not found: disabling AMELET tests" )
      set( WITH_AMELET OFF )
    endif( H5TOTXT_EXECUTABLE )
  endif( WITH_AMELET )
  
  if( WITH_GVULTURE )
    find_program( GVULTURE_EXECUTABLE NAMES gvulture )
    if( GVULTURE_EXECUTABLE )
      message( STATUS "Found Vulture preprocessor (gvulture): ${GVULTURE_EXECUTABLE}" )   
    else( VULTURE_EXECUTABLE )
      message( WARNING "Vulture prepprocessor not found: disabling associated tests" )
      set( WITH_GVULTURE OFF )
    endif( GVULTURE_EXECUTABLE )
  endif( WITH_GVULTURE )

  add_subdirectory ( tests )

endif( WITH_TESTS )

install( DIRECTORY mesh/ DESTINATION share/octave/packages/aegmesher FILES_MATCHING PATTERN "*.m" )
#install( DIRECTORY mesh/private/ DESTINATION share/octave/packages/aegmesher/private FILES_MATCHING PATTERN "*.m" )
install( DIRECTORY doc/ DESTINATION share/doc/aegmesher FILES_MATCHING PATTERN "*.txt" )


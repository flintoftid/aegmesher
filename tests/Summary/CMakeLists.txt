
# [FIXME] Currently the test names have to be added manually.
configure_file( "${MESH_SOURCE_DIR}/tests/startup.m.cmake" startup.m )
add_test( NAME SUMMARY COMMAND ${MEXEC} "meshTestTimingSummary( true , { 'Cube' , 'Solid01' , 'Sphere01' , 'Surface01' , 'Surface02' , 'Surface03' , 'Surface04' , 'CubesAndPlane' , 'WireBox' , 'Blade1' } ) ; exit" )
 


configure_file( "${MESH_SOURCE_DIR}/tests/TimeIntersections/startup.m.cmake" startup.m )

add_test( NAME TIMING_intersect COMMAND ${MEXEC} "meshTimeIntersections( 1e6 ) ; exit" )


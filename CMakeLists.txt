CMAKE_MINIMUM_REQUIRED(VERSION 3.1)

PROJECT(SimpleCompiler)

  SET(CMAKE_CXX_STANDARD 14)
  SET(CMAKE_CXX_STANDARD_REQUIRED ON)
  SET(CMAKE_CXX_EXTENSIONS OFF)

  ADD_CUSTOM_COMMAND(
    OUTPUT frontend.cpp

    COMMAND bison -o frontend.cpp.1 "${CMAKE_SOURCE_DIR}/src/frontend.y" -t --report=all
    COMMAND sed -f "${CMAKE_SOURCE_DIR}/src/move.sed" -i ${MOVE_SED} frontend.cpp.1
    COMMAND re2c frontend.cpp.1 -o frontend.cpp
    COMMAND rm frontend.cpp.1

    MAIN_DEPENDENCY src/frontend.y src/move.sed

    COMMENT "Generating frontend.cpp"
  )

  ADD_CUSTOM_TARGET(
    GenerateFrontend
    DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/frontend.cpp
  )

  ADD_LIBRARY(SimpleCompiler.dummy src/SimpleCompiler.cpp)
  ADD_DEPENDENCIES(SimpleCompiler.dummy GenerateFrontend)

  ADD_DEFINITIONS(-Wall -Wpedantic)  
  INCLUDE_DIRECTORIES("${CMAKE_SOURCE_DIR}/src")
  ADD_EXECUTABLE(SimpleCompiler frontend.cpp src/codegen.cpp src/codegen_x86.cpp)
  TARGET_LINK_LIBRARIES(SimpleCompiler SimpleCompiler.dummy)


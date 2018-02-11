CMAKE_MINIMUM_REQUIRED(VERSION 3.1)
INCLUDE(ExternalProject)

# Download and unpack googletest at configure time
CONFIGURE_FILE(
    CMakeLists.gtest.txt.in 
    googletest-download/CMakeLists.txt)

EXECUTE_PROCESS(
  COMMAND ${CMAKE_COMMAND} -G "${CMAKE_GENERATOR}" .
  RESULT_VARIABLE result
  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/googletest-download )

IF(result)
  MESSAGE(FATAL_ERROR "CMake step for googletest failed: ${result}")
ENDIF()

EXECUTE_PROCESS(
  COMMAND ${CMAKE_COMMAND} --build .
  RESULT_VARIABLE result
  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/googletest-download )

IF(result)
  MESSAGE(FATAL_ERROR "Build step for googletest failed: ${result}")
ENDIF()

ADD_SUBDIRECTORY(
  ${CMAKE_BINARY_DIR}/googletest-src
  ${CMAKE_BINARY_DIR}/googletest-build
  EXCLUDE_FROM_ALL)

# Download and unpack textbox at configure time
CONFIGURE_FILE(
  CMakeLists.textbox.txt.in
  textbox-download/CMakeLists.txt)

EXECUTE_PROCESS(
  COMMAND ${CMAKE_COMMAND} -G "${CMAKE_GENERATOR}" .
  RESULT_VARIABLE result
  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/textbox-download )

IF(result)
  MESSAGE(FATAL_ERROR "CMake step for textbox failed: ${result}")
ENDIF()

EXECUTE_PROCESS(
  COMMAND ${CMAKE_COMMAND} --build .
  RESULT_VARIABLE result
  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/textbox-download )

IF(result)
  MESSAGE(FATAL_ERROR "Build step for textbox failed: ${result}")
ENDIF()

SET(textbox_SOURCE_DIR "${CMAKE_BINARY_DIR}/textbox-src")

# Main target
PROJECT(SimpleCompiler)

  SET(CMAKE_CXX_STANDARD 14)
  SET(CMAKE_CXX_STANDARD_REQUIRED ON)
  SET(CMAKE_CXX_EXTENSIONS OFF)
  SET(CMAKE_EXPORT_COMPILE_COMMANDS ON)

  ADD_CUSTOM_COMMAND(
    OUTPUT frontend.cpp

    COMMAND bison -o frontend.cpp.1 "${CMAKE_SOURCE_DIR}/src/frontend.y" -t --report=all --verbose
    COMMAND sed -f "${CMAKE_SOURCE_DIR}/src/move.sed" -i ${MOVE_SED} frontend.cpp.1
    COMMAND re2c frontend.cpp.1 -o frontend.cpp
    COMMAND rm frontend.cpp.1

    DEPENDS src/frontend.y src/move.sed

    COMMENT "Generating frontend.cpp"
  )

  ADD_CUSTOM_TARGET(
    GenerateFrontend
    DEPENDS frontend.cpp
  )

  ADD_LIBRARY(SimpleCompiler.dummy frontend.cpp)
  ADD_DEPENDENCIES(SimpleCompiler.dummy GenerateFrontend)

  ADD_DEFINITIONS(-Wall -Wpedantic)  
  
  INCLUDE_DIRECTORIES("${CMAKE_SOURCE_DIR}/src")
  INCLUDE_DIRECTORIES("${textbox_SOURCE_DIR}")
  
  ADD_LIBRARY(SimpleCompiler.lib src/codegen.cpp src/codegen_x86.cpp src/display.cpp src/ast.cpp) 
  TARGET_LINK_LIBRARIES(SimpleCompiler.lib SimpleCompiler.dummy)
 
  ADD_EXECUTABLE(SimpleCompiler src/SimpleCompiler.cpp)
  TARGET_LINK_LIBRARIES(SimpleCompiler SimpleCompiler.lib)

  ADD_EXECUTABLE(SimpleCompiler.tests src/ast.t.cpp)
  TARGET_LINK_LIBRARIES(SimpleCompiler.tests SimpleCompiler.lib gtest_main gmock)

  ENABLE_TESTING()
  ADD_TEST(NAME    SimpleCompiler.tests
           COMMAND SimpleCompiler.tests "--gtest_output=xml:SimpleCompiler.tests.xml")
    
    

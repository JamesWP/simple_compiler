CMAKE_MINIMUM_REQUIRED(VERSION 3.1)
INCLUDE(ExternalProject)

ExternalProject_Add(
    textbox
    PREFIX ${CMAKE_BINARY_DIR}/textbox
    GIT_REPOSITORY https://gist.github.com/e7e4e07edc84a99284e8f43f7fb6badc.git
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
)
ExternalProject_Get_Property(textbox source_dir)
set(TextboxIncludeDir ${source_dir})

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
  INCLUDE_DIRECTORIES("${TextboxIncludeDir}")
  
  ADD_EXECUTABLE(SimpleCompiler src/SimpleCompiler.cpp src/codegen.cpp src/codegen_x86.cpp src/display.cpp)
  TARGET_LINK_LIBRARIES(SimpleCompiler SimpleCompiler.dummy)


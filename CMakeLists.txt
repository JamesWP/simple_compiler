CMAKE_MINIMUM_REQUIRED(VERSION 3.1)

PROJECT(SimpleCompiler)

  SET(CMAKE_CXX_STANDARD 14)
  SET(CMAKE_CXX_STANDARD_REQUIRED ON)
  SET(CMAKE_CXX_EXTENSIONS OFF)

  ADD_CUSTOM_COMMAND(
    OUTPUT var.cpp

    COMMAND bison -o var.cpp.1 "${CMAKE_SOURCE_DIR}/var.y"
    COMMAND sed -f "${CMAKE_SOURCE_DIR}/move.sed" -i ${MOVE_SED} var.cpp.1
    COMMAND re2c var.cpp.1 -o var.cpp
    COMMAND rm var.cpp.1

    MAIN_DEPENDENCY var.y move.sed

    COMMENT "Generating var.cpp"
  )
  
  INCLUDE_DIRECTORIES("${CMAKE_SOURCE_DIR}")
  ADD_EXECUTABLE(SimpleCompiler var.cpp)

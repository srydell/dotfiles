include_guard()

function(create_target)
  # Simple function to create a target with all PRIVATE keywords

  # Define the supported set of keywords
  set(prefix ARG)
  set(noValues IS_LIBRARY)
  set(singleValues TARGET)
  set(multiValues SOURCES LINK_LIBRARIES INCLUDE)
  # Process the arguments passed in Can be used e.g. via ARG_TARGET
  cmake_parse_arguments(${prefix}
                        "${noValues}"
                        "${singleValues}"
                        "${multiValues}"
                        ${ARGN})

  if(NOT ARG_TARGET)
    message(FATAL_ERROR "Must provide a target.")
  endif()
  if(NOT ARG_SOURCES)
    message(FATAL_ERROR "Must provide sources.")
  endif()

  if(ARG_IS_LIBRARY)
    add_library(${ARG_TARGET} ${ARG_SOURCES})
  else()
    add_executable(${ARG_TARGET} ${ARG_SOURCES})
  endif()

  if(ARG_INCLUDE)
    target_include_directories(${ARG_TARGET} PRIVATE ${ARG_INCLUDE})
  endif()

  if(ARG_LINK_LIBRARIES)
    target_link_libraries(${ARG_TARGET} PRIVATE ${ARG_LINK_LIBRARIES})
  endif()

  set_target_properties(${ARG_TARGET}
                        PROPERTIES CXX_STANDARD_REQUIRED
                                   ON
                                   CXX_EXTENSIONS
                                   OFF)
endfunction()

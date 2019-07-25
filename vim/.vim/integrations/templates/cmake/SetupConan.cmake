include_guard()

# Downloads module to run conan from cmake
function(get_conan_helper)
  if(NOT EXISTS "${CMAKE_BINARY_DIR}/conan.cmake")
    message(
      STATUS
        "Downloading conan.cmake from https://github.com/conan-io/cmake-conan")
    file(
      DOWNLOAD
      "https://raw.githubusercontent.com/conan-io/cmake-conan/v0.14/conan.cmake"
      "${CMAKE_BINARY_DIR}/conan.cmake")
  endif()
  include(${CMAKE_BINARY_DIR}/conan.cmake)
endfunction(get_conan_helper)

function(conan_setup_remotes)
  # Avoid running this command often
  if(_conan_has_set_remotes)
    message(STATUS "Conan remotes already set.")
    return()
  endif()
  # For clara
  conan_add_remote(NAME
                   bincrafters
                   URL
                   https://api.bintray.com/conan/bincrafters/public-conan)

  # For google benchmark
  conan_add_remote(NAME
                   conan-mpusz
                   URL
                   https://api.bintray.com/conan/mpusz/conan-mpusz)
  set(_conan_has_set_remotes
      TRUE
      CACHE INTERNAL
            "This is used to avoid setting the remotes twice. Only takes time.")
endfunction()

include_guard()

# Require that conan is installed
conan_check(REQUIRED)

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

# Minimum CMake version, determined by hdf5.
cmake_minimum_required (VERSION 3.1)

# Adjust CMake's module path.
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/Modules/")

# Options for building BeTR. These come from the xSDK compliance rules.
option(USE_XSDK_DEFAULTS "Set to use xSDK defaults for options [ON]." ON)
option(CMAKE_INSTALL_PREFIX "Sets installation prefix [/usr/local].")
option(XSDK_ENABLE_DEBUG "Enables Debug mode builds [OFF]." OFF)
option(BUILD_SHARED_LIBS "Builds shared libraries [ON]." ON)
option(XSDK_WITH_NETCDF "Enables support for netcdf [OFF]." ON)
option(TPL_NETCDF_LIBRARIES "List of absolute paths to netcdf link libraries [].")
option(TPL_NETCDF_INCLUDE_DIRS "List of absolute paths to netcdf include directories [].")

# For now, we disable shared libs on Macs.
if (APPLE)
  set(BUILD_SHARED_LIBS OFF)
endif()

if (NOT CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX /usr/local)
endif()

include(set_up_platform)

# Make sure compilers are set. This must be done before enabling languages.
if (NOT CMAKE_C_COMPILER)
  if (NOT $ENV{CC} STREQUAL "")
    set(CMAKE_C_COMPILER $ENV{CC})
  else()
    set(CMAKE_C_COMPILER cc)
  endif()
endif()
if (NOT CMAKE_C_FLAGS)
  set(CMAKE_C_FLAGS $ENV{CFLAGS})
endif()
if (NOT CMAKE_CXX_COMPILER)
  if (NOT $ENV{CXX} STREQUAL "")
    set(CMAKE_CXX_COMPILER $ENV{CXX})
  else()
    set(CMAKE_CXX_COMPILER c++)
  endif()
endif()
if (NOT CMAKE_CXX_FLAGS)
  set(CMAKE_CXX_FLAGS $ENV{CXX_FLAGS})
endif()
if (NOT CMAKE_Fortran_COMPILER)
  if (NOT $ENV{FC} STREQUAL "")
    set(CMAKE_Fortran_COMPILER $ENV{FC})
  else()
    set(CMAKE_Fortran_COMPILER gfortran)
  endif()
endif()
if (NOT CMAKE_Fortran_FLAGS)
  set(CMAKE_Fortran_FLAGS $ENV{FCFLAGS})
endif()
set_up_platform()
enable_language(C)
enable_language(CXX)
enable_language(Fortran)

# We declare the project here.
project (betr)

message("-- C compiler is ${CMAKE_C_COMPILER} (${CMAKE_C_COMPILER_ID})")
message("-- CXX compiler is ${CMAKE_CXX_COMPILER} (${CMAKE_CXX_COMPILER_ID})")
message("-- Fortran compiler is ${CMAKE_Fortran_COMPILER} (${CMAKE_Fortran_COMPILER_ID})")

if (BUILD_SHARED_LIBS)
  message("-- BeTR will be built as a shared library.")
else()
  message("-- BeTR will be built as a static library.")
endif()

# Version numbers.
set (BETR_MAJOR_VERSION 0)
set (BETR_MINOR_VERSION 1)
set (BETR_PATCH_VERSION 0)
set (BETR_VERSION "${BETR_MAJOR_VERSION}.${BETR_MINOR_VERSION}.${BETR_PATCH_VERSION}")

# General C compiler flags.
if (CMAKE_C_COMPILER_ID STREQUAL "GNU")
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=c99 -Wall -pedantic-errors -Wextra -Werror-implicit-function-declaration")
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-sign-compare -Wno-unused-parameter -Wno-unused-but-set-variable -Wno-int-to-pointer-cast -Wno-pointer-to-int-cast")

  if (BUILD_SHARED_LIBS)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIC")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fPIC")
  endif()

  if (LINUX EQUAL 1)
    # Counter some of GCC's more recent stinginess on Linux.
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -D_POSIX_C_SOURCE=200809L")# -D_BSD_SOURCE")

  endif()

elseif (CMAKE_C_COMPILER_ID STREQUAL "Clang")
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=c99 -Wall -pedantic-errors -Wextra -Werror-implicit-function-declaration -fno-builtin")
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-sign-compare -Wno-unused-parameter -Wno-int-to-pointer-cast -Wno-pointer-to-int-cast -Wno-unused-function")
elseif (CMAKE_C_COMPILER_ID STREQUAL "Intel")
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=c99 -Wall -lpthread")
endif()
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${SYS_FLAGS}")
message("Fortran compiler id is ${CMAKE_Fortran_COMPILER_ID}")
# Fortran compiler flags.
if (CMAKE_Fortran_COMPILER_ID STREQUAL "GNU")
  set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -W -Wall -std=gnu -pedantic -Wno-unused-variable -Wno-unused-parameter -Werror=use-without-only -DCPRGNU")
elseif (CMAKE_Fortran_COMPILER_ID STREQUAL "Intel")
  set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -DCPRINTEL")
#  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -lmkl")
endif()


# Figure out the system type.
set(BETR_HAVE_BOOL 1) # All reasonable C99 compilers have this now.
if (APPLE EQUAL 1)
  set(SYS_FLAGS "-DAPPLE=1")
  set(DYLIB_SUFFIX "dylib")
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -framework Accelerate")
else ()
  if (LINUX EQUAL 1)
    set(SYS_FLAGS "-DLINUX=1")
    set(DYLIB_SUFFIX "so")
  else()
    if (WIN32 EQUAL 1)
      set(BETR_HAVE_BOOL 0) # MS doesn't have reasonable C compilers.
      set(SYS_FLAGS "-DWINDOWS=1")
      set(DYLIB_SUFFIX "dll")
    endif()
  endif ()
endif ()

# Here we make sure CMake-installed binaries use the correct runpath, and 
# that the path is not stripped during installation.
set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib")
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

# Check third-party library dependencies.
# Basic libraries to be linked in.
set(BETR_LIBRARIES m)
if (${NEED_LAPACK})
  include(FindBLAS)
  include(FindLAPACK)
  find_package(BLAS REQUIRED)
  find_package(LAPACK REQUIRED)
  if (${LAPACK_LIBRARY_DIR})
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -L${LAPACK_LIBRARY_DIR}")
  endif()
  if (${BLAS_LIBRARY_DIR})
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -L${BLAS_LIBRARY_DIR}")
  endif()
  set(BETR_LIBRARIES ${BETR_LIBRARIES};${LAPACK_LIBRARIES};${BLAS_LIBRARIES})
endif()

set(BETR_NEED_PETSC 0)

#X#if (XSDK_WITH_NETCDF)
#X#  if (NOT TPL_NETCDF_LIBRARIES)
#X#    message(FATAL_ERROR "TPL_NETCDF_LIBRARIES option be set for netcdf support to be enabled.")
#X#  endif()
#X##X#  foreach(lib ${TPL_NETCDF_LIBRARIES})
#X##X#    if (NOT EXISTS ${lib})
#X##X#      message(FATAL_ERROR "netcdf library not found: ${lib}")
#X##X#    endif()
#X##X#  endforeach()
#X#
#X#  if (NOT TPL_NETCDF_INCLUDE_DIRS)
#X#    message(FATAL_ERROR "TPL_NETCDF_INCLUDE_DIRS option be set for netcdf support to be enabled.")
#X#  endif()
#X##X#  foreach(dir ${TPL_NETCDF_INCLUDE_DIRS})
#X##X#    if (NOT EXISTS ${dir})
#X##X#      message(FATAL_ERROR "netcdf include directory not found: ${dir}")
#X##X#    endif()
#X##X#  endforeach()
#X#
#X#  message("-- Enabled support for netcdf.")
#X#  list(APPEND BETR_TPLS ${TPL_NETCDF_LIBRARIES})
#X#  list(APPEND BETR_INCLUDE_DIRS ${TPL_NETCDF_INCLUDE_DIRS})
#X#  set(BETR_HAVE_NETCDF 1)
#X#else()
#X#  set(BETR_HAVE_NETCDF 0)
#X#endif()


# Other third-party libraries.
add_subdirectory(3rd-party)

# Include the binary directory in the header file search path,
# since it's where we place the third-party libraries.
include_directories("${PROJECT_BINARY_DIR}")
include_directories("${PROJECT_BINARY_DIR}/include")
link_directories("${PROJECT_BINARY_DIR}/lib")
include_directories(${BETR_INCDIRS})

# Unit testing.
enable_testing()

# Source code itself.
include_directories("${PROJECT_SOURCE_DIR}")
add_subdirectory(src)

# Drivers for benchmarks.
#X#add_subdirectory(drivers)

# Benchmarks.
#X#add_subdirectory(benchmarks)

# Now that we have gathered all our libraries, generate an betr.cmake 
# file that contains all the vital information.
configure_file(
  "${CMAKE_CURRENT_SOURCE_DIR}/cmake/Templates/betr.cmake.in"
  "${CMAKE_CURRENT_BINARY_DIR}/betr.cmake"
  @ONLY
)

# Install miscellaneous build/test files.
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/betr.cmake DESTINATION share/betr)


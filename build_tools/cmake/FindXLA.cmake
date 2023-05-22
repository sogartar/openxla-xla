#[=======================================================================[.rst:
FindXLA
----------
Try to find the XLA compiler library.

::
  This module defines the following variables.
::
  XLA_FOUND - Was XLA found.
  XLA_INCLUDE_DIRS - the XLA include directories.
  XLA_LIBRARIES - Link to this.

::
  This module defines the following targets.
::
  XLA::xla_cc

::
  This module accepts the following variables.
::
  XLA_ROOT - The path(s) to the XLA source code or the XLA binary directory.
#]=======================================================================]

include(FindPackageHandleStandardArgs)
include(CMakeParseArguments)

unset(XLA_INCLUDE_HINTS)
unset(XLA_LIB_HINTS)
unset(XLA_INCLUDE_DIRS)
unset(XLA_LIBRARIES)

foreach(DIR IN LISTS XLA_ROOT)
    list(APPEND XLA_INCLUDE_HINTS
        "${DIR}"
        "${DIR}/bazel-bin"
        "${DIR}/bazel-repo/external/com_google_absl"
        "${DIR}/third_party/tsl"
        "${DIR}/bazel-bin/external/tsl"
        "${DIR}/bazel-repo/external/eigen_archive"
        "${DIR}/bazel-repo/external/com_google_protobuf/src"
        "${DIR}/bazel-repo/external/llvm-project/llvm/include"
        "${DIR}/bazel-bin/external/llvm-project/llvm/include"
    )
endforeach()

function(find_paths)
    cmake_parse_arguments(
        FN_ARG
        ""
        "INCLUDE_DIRS_VAR"
        "PATHS"
        ${ARGN}
    )
    unset(${FN_ARG_INCLUDE_DIRS_VAR})
    foreach(PATH_ IN LISTS FN_ARG_PATHS)
        string(REGEX REPLACE "[^A-Za-z0-9_]" "_" INCLUDE_DIR_VAR "${PATH_}")
        set(INCLUDE_DIR_VAR "${INCLUDE_DIR_VAR}_INCLUDE_DIR")
        find_path(${INCLUDE_DIR_VAR} "${PATH_}" HINTS ${XLA_INCLUDE_HINTS})
        if(NOT ${INCLUDE_DIR_VAR} AND XLA_FIND_REQUIRED)
            message(FATAL_ERROR "\"${PATH_}\" not found.")
        endif()
        list(APPEND ${FN_ARG_INCLUDE_DIRS_VAR} "${${INCLUDE_DIR_VAR}}")
    endforeach()
    set(${FN_ARG_INCLUDE_DIRS_VAR} ${${FN_ARG_INCLUDE_DIRS_VAR}} PARENT_SCOPE)
endfunction()

find_paths(INCLUDE_DIRS_VAR XLA_INCLUDE_DIRS PATHS
    "xla/xla.pb.h"
    "xla/shape.h"
    "absl/container/inlined_vector.h"
    "tsl/platform/status.h"
    "tsl/protobuf/error_codes.pb.h"
    "Eigen/Core"
    "google/protobuf/port_def.inc"
    "llvm/Target/TargetMachine.h"
    "llvm/Config/abi-breaking.h"
)

find_library(xla_cc_LIBRARY "xla_cc"
    PATH_SUFFIXES xla
    HINTS ${XLA_INCLUDE_HINTS}
)

function(find_libraries)
    cmake_parse_arguments(
        FN_ARG
        ""
        "LIBRARIES_VAR"
        "NAMES;HINTS"
        ${ARGN}
    )

    unset(XLA_LIB_HINTS)
    foreach(ROOT_DIR IN LISTS XLA_ROOT)
        foreach(HINT_DIR IN LISTS FN_ARG_HINTS)
            list(APPEND XLA_LIB_HINTS "${ROOT_DIR}/${HINT_DIR}")
        endforeach()
    endforeach()

    foreach(NAME_ IN LISTS FN_ARG_NAMES)
        string(REGEX REPLACE "[^A-Za-z0-9_]" "_" LIB_PATH_VAR "${NAME_}")
        set(LIB_PATH_VAR "${LIB_PATH_VAR}_LIBRARY")
        find_library(${LIB_PATH_VAR} "${NAME_}" HINTS ${XLA_LIB_HINTS} NO_CACHE)
        if(NOT ${LIB_PATH_VAR} AND XLA_FIND_REQUIRED)
            message(FATAL_ERROR "Library \"${NAME_}\" not found.")
        endif()
        list(APPEND ${FN_ARG_LIBRARIES_VAR} "${${LIB_PATH_VAR}}")
    endforeach()
    set(${FN_ARG_LIBRARIES_VAR} ${${FN_ARG_LIBRARIES_VAR}} PARENT_SCOPE)
endfunction()

find_libraries(LIBRARIES_VAR xla_cc_ADDITIONAL_LIBRARIES
    NAMES allocator_registry_impl
    HINTS bazel-bin/external/tsl/tsl/framework
)
find_libraries(LIBRARIES_VAR xla_cc_ADDITIONAL_LIBRARIES
    NAMES env_impl
    HINTS bazel-bin/external/tsl/tsl/platform/default
)
find_libraries(LIBRARIES_VAR xla_cc_ADDITIONAL_LIBRARIES
    NAMES
        autotuning_proto_cc_impl
        bfc_memory_map_proto_cc_impl
        coordination_config_proto_cc_impl
        distributed_runtime_payloads_proto_cc_impl
        #dnn_proto_cc_impl
        histogram_proto_cc_impl
    HINTS bazel-bin/external/tsl/tsl/protobuf
)
# TODO: How can we avoid the conflict with
# library dnn_proto_cc_impl in bazel-bin/xla/stream_executor?
find_libraries(LIBRARIES_VAR xla_cc_ADDITIONAL_LIBRARIES
    NAMES external_Stsl_Stsl_Sprotobuf_Slibdnn_Uproto_Ucc_Uimpl
    HINTS bazel-bin/_solib_k8
)
find_libraries(LIBRARIES_VAR xla_cc_ADDITIONAL_LIBRARIES
    NAMES time_utils_impl
    HINTS bazel-bin/external/tsl/tsl/profiler/utils
)
find_libraries(LIBRARIES_VAR xla_cc_ADDITIONAL_LIBRARIES
    NAMES traceme_recorder_impl
    HINTS bazel-bin/external/tsl/tsl/profiler/backends/cpu
)

find_libraries(LIBRARIES_VAR xla_cc_ADDITIONAL_LIBRARIES
    NAMES
        xla_data_proto_cc_impl
        xla_proto_cc_impl
    HINTS bazel-bin/xla
)
find_libraries(LIBRARIES_VAR xla_cc_ADDITIONAL_LIBRARIES
    NAMES backend_configs_cc_impl
    HINTS bazel-bin/xla/service/gpu
)
find_libraries(LIBRARIES_VAR xla_cc_ADDITIONAL_LIBRARIES
    NAMES
        hlo_proto_cc_impl
        memory_space_assignment_proto_cc_impl
    HINTS bazel-bin/xla/service
)
find_libraries(LIBRARIES_VAR xla_cc_ADDITIONAL_LIBRARIES
    NAMES dnn_proto_cc_impl
    HINTS bazel-bin/xla/stream_executor
)

if(XLA_INCLUDE_DIRS AND xla_cc_LIBRARY AND xla_cc_ADDITIONAL_LIBRARIES)
    list(APPEND XLA_LIBRARIES
        ${xla_cc_LIBRARY}
        ${xla_cc_ADDITIONAL_LIBRARIES})
    add_library(XLA::xla_cc UNKNOWN IMPORTED)
    set_target_properties(
        XLA::xla_cc
        PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${XLA_INCLUDE_DIRS}"
            IMPORTED_LINK_INTERFACE_LANGUAGES "C++"
            IMPORTED_LOCATION "${xla_cc_LIBRARY}"
            INTERFACE_LINK_LIBRARIES "${xla_cc_ADDITIONAL_LIBRARIES}"
    )
endif()
find_package_handle_standard_args(
    XLA
    REQUIRED_VARS
    XLA_INCLUDE_DIRS
    XLA_LIBRARIES
    xla_cc_LIBRARY
)

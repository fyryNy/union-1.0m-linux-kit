cmake_minimum_required(VERSION 3.25)

if(NOT DEFINED SOURCE_ROOT)
    set(SOURCE_ROOT "${CMAKE_CURRENT_LIST_DIR}")
endif()
cmake_path(ABSOLUTE_PATH SOURCE_ROOT NORMALIZE OUTPUT_VARIABLE SOURCE_ROOT)

if(NOT DEFINED FORCE)
    set(FORCE OFF)
endif()

if(DEFINED VCXPROJ AND NOT VCXPROJ STREQUAL "")
    cmake_path(ABSOLUTE_PATH VCXPROJ BASE_DIRECTORY "${SOURCE_ROOT}"
        NORMALIZE OUTPUT_VARIABLE VCXPROJ)
    set(candidates "${VCXPROJ}")
else()
    file(GLOB_RECURSE all_projects LIST_DIRECTORIES false
        "${SOURCE_ROOT}/*.vcxproj")
    set(candidates)
    foreach(candidate IN LISTS all_projects)
        file(READ "${candidate}" project_xml)
        get_filename_component(candidate_dir "${candidate}" DIRECTORY)
        if(project_xml MATCHES "Union[/\\\\].*1\\.0m" OR
           (EXISTS "${candidate_dir}/UnionAfx.h" AND
            EXISTS "${candidate_dir}/Sources.h" AND
            EXISTS "${candidate_dir}/Interface.cpp"))
            list(APPEND candidates "${candidate}")
        endif()
    endforeach()
endif()

list(LENGTH candidates candidate_count)
if(NOT candidate_count EQUAL 1)
    message(FATAL_ERROR
        "Found ${candidate_count} candidate Union 1.0m vcxproj files below:\n"
        "  ${SOURCE_ROOT}\n"
        "Pass the exact file with: --project relative/path/plugin.vcxproj")
endif()

list(GET candidates 0 VCXPROJ)
if(NOT EXISTS "${VCXPROJ}")
    message(FATAL_ERROR "vcxproj not found: ${VCXPROJ}")
endif()

get_filename_component(PLUGIN_ABS_DIR "${VCXPROJ}" DIRECTORY)
get_filename_component(VCXPROJ_FILE "${VCXPROJ}" NAME)
get_filename_component(PROJECT_NAME "${VCXPROJ}" NAME_WE)
file(RELATIVE_PATH PLUGIN_DIR "${SOURCE_ROOT}" "${PLUGIN_ABS_DIR}")
if(PLUGIN_DIR STREQUAL "")
    set(PLUGIN_DIR ".")
endif()

set(MSVC_WINE_ROOT "$ENV{HOME}/my_msvc/opt/msvc")
file(GLOB MSVC_TOOLSET_CANDIDATES LIST_DIRECTORIES true
    "${MSVC_WINE_ROOT}/VC/Tools/MSVC/*")
list(SORT MSVC_TOOLSET_CANDIDATES COMPARE NATURAL ORDER DESCENDING)
if(NOT MSVC_TOOLSET_CANDIDATES)
    message(FATAL_ERROR
        "No MSVC toolset found below ${MSVC_WINE_ROOT}/VC/Tools/MSVC")
endif()
list(GET MSVC_TOOLSET_CANDIDATES 0 MSVC_TOOLSET_ROOT)
get_filename_component(MSVC_TOOLSET_VERSION "${MSVC_TOOLSET_ROOT}" NAME)

file(GLOB WINDOWS_KIT_CANDIDATES LIST_DIRECTORIES true
    "${MSVC_WINE_ROOT}/Windows Kits/10/Include/*")
list(SORT WINDOWS_KIT_CANDIDATES COMPARE NATURAL ORDER DESCENDING)
if(NOT WINDOWS_KIT_CANDIDATES)
    message(FATAL_ERROR
        "No Windows SDK found below ${MSVC_WINE_ROOT}/Windows Kits/10/Include")
endif()
list(GET WINDOWS_KIT_CANDIDATES 0 WINDOWS_KIT_INCLUDE_ROOT)
get_filename_component(WINDOWS_KIT_VERSION "${WINDOWS_KIT_INCLUDE_ROOT}" NAME)

foreach(required_include
        "${MSVC_TOOLSET_ROOT}/include"
        "${MSVC_TOOLSET_ROOT}/atlmfc/include"
        "${WINDOWS_KIT_INCLUDE_ROOT}/shared"
        "${WINDOWS_KIT_INCLUDE_ROOT}/ucrt"
        "${WINDOWS_KIT_INCLUDE_ROOT}/um"
        "${WINDOWS_KIT_INCLUDE_ROOT}/winrt")
    if(NOT IS_DIRECTORY "${required_include}")
        message(FATAL_ERROR "Required IntelliSense include directory missing: ${required_include}")
    endif()
endforeach()

set(destinations
    "${SOURCE_ROOT}/CMakeLists.txt"
    "${SOURCE_ROOT}/CMakePresets.json"
    "${SOURCE_ROOT}/.clangd"
    "${SOURCE_ROOT}/.vscode/c_cpp_properties.json"
    "${SOURCE_ROOT}/.vscode/settings.json"
    "${SOURCE_ROOT}/cmake/msvc-wine-x86.cmake"
    "${SOURCE_ROOT}/cmake/msvc-wine-link.in"
    "${SOURCE_ROOT}/cmake/IntelliSenseContext.h"
    "${SOURCE_ROOT}/UNION_1.0M_LINUX.md")
if(NOT FORCE)
    foreach(destination IN LISTS destinations)
        if(EXISTS "${destination}")
            message(FATAL_ERROR
                "Refusing to overwrite ${destination}\n"
                "Review it first, then rerun install.fish --force if appropriate.")
        endif()
    endforeach()
endif()

execute_process(
    COMMAND "${CMAKE_COMMAND}" "-DPLUGIN_DIR=${PLUGIN_ABS_DIR}"
        -P "${CMAKE_CURRENT_LIST_DIR}/patches/apply-portability.cmake"
    COMMAND_ERROR_IS_FATAL ANY)

file(MAKE_DIRECTORY "${SOURCE_ROOT}/cmake" "${SOURCE_ROOT}/.vscode")
configure_file("${CMAKE_CURRENT_LIST_DIR}/templates/CMakeLists.txt.in"
    "${SOURCE_ROOT}/CMakeLists.txt" @ONLY)
configure_file("${CMAKE_CURRENT_LIST_DIR}/templates/.clangd.in"
    "${SOURCE_ROOT}/.clangd" @ONLY)
configure_file("${CMAKE_CURRENT_LIST_DIR}/templates/.vscode/c_cpp_properties.json.in"
    "${SOURCE_ROOT}/.vscode/c_cpp_properties.json" @ONLY)
configure_file("${CMAKE_CURRENT_LIST_DIR}/templates/.vscode/settings.json.in"
    "${SOURCE_ROOT}/.vscode/settings.json" @ONLY)
configure_file("${CMAKE_CURRENT_LIST_DIR}/templates/CMakePresets.json"
    "${SOURCE_ROOT}/CMakePresets.json" COPYONLY)
configure_file("${CMAKE_CURRENT_LIST_DIR}/payload/cmake/msvc-wine-x86.cmake"
    "${SOURCE_ROOT}/cmake/msvc-wine-x86.cmake" COPYONLY)
configure_file("${CMAKE_CURRENT_LIST_DIR}/payload/cmake/msvc-wine-link.in"
    "${SOURCE_ROOT}/cmake/msvc-wine-link.in" COPYONLY)
configure_file("${CMAKE_CURRENT_LIST_DIR}/templates/IntelliSenseContext.h"
    "${SOURCE_ROOT}/cmake/IntelliSenseContext.h" COPYONLY)
configure_file("${CMAKE_CURRENT_LIST_DIR}/PROJECT-GUIDE.md.in"
    "${SOURCE_ROOT}/UNION_1.0M_LINUX.md" @ONLY)

set(gitignore "${SOURCE_ROOT}/.gitignore")
if(EXISTS "${gitignore}")
    file(READ "${gitignore}" ignore_text)
else()
    set(ignore_text "")
endif()

set(ignore_entries "")
if(NOT ignore_text MATCHES "(^|\n)/out/($|\n)")
    string(APPEND ignore_entries "/out/\n")
endif()
if(NOT ignore_text MATCHES "(^|\n)/compile_commands\\.json($|\n)")
    string(APPEND ignore_entries "/compile_commands.json\n")
endif()
if(NOT ignore_text MATCHES
        "(^|\n)/cmake/IntelliSenseActivePreset\\.h($|\n)")
    string(APPEND ignore_entries "/cmake/IntelliSenseActivePreset.h\n")
endif()

if(NOT ignore_entries STREQUAL "")
    set(ignore_prefix "")
    if(NOT ignore_text STREQUAL "" AND NOT ignore_text MATCHES "\n$")
        string(APPEND ignore_prefix "\n")
    endif()
    if(NOT ignore_text MATCHES
            "(^|\n)# Union 1\\.0m CMake/msvc-wine generated files($|\n)")
        string(APPEND ignore_prefix
            "# Union 1.0m CMake/msvc-wine generated files\n")
    endif()
    file(APPEND "${gitignore}" "${ignore_prefix}${ignore_entries}")
endif()

message(STATUS "Installed Union 1.0m Linux support for ${PROJECT_NAME}")
message(STATUS "Project directory: ${PLUGIN_DIR}")
message(STATUS "Next: cmake --preset MP-x4-MT-Release-msvc-wine")
message(STATUS "Then: cmake --build --preset MP-x4-MT-Release-msvc-wine")

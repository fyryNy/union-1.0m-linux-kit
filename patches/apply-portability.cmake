cmake_minimum_required(VERSION 3.25)

if(NOT DEFINED PLUGIN_DIR OR NOT IS_DIRECTORY "${PLUGIN_DIR}")
    message(FATAL_ERROR "Pass -DPLUGIN_DIR=/absolute/path/to/the/vcxproj/directory")
endif()

function(replace_if_present path old new)
    if(NOT EXISTS "${path}")
        return()
    endif()
    file(READ "${path}" content)
    string(REPLACE "${old}" "${new}" updated "${content}")
    if(NOT updated STREQUAL content)
        file(WRITE "${path}" "${updated}")
        file(RELATIVE_PATH relative "${PLUGIN_DIR}" "${path}")
        message(STATUS "Patched ${relative}")
    endif()
endfunction()

# Linux treats backslash as a character and paths as case-sensitive. These are
# the known mistakes in copies of the stock Union 1.0m project template.
find_program(sed_executable sed REQUIRED)
file(GLOB_RECURSE template_headers LIST_DIRECTORIES false
    "${PLUGIN_DIR}/*.h" "${PLUGIN_DIR}/*.hpp" "${PLUGIN_DIR}/*.inl")
foreach(header IN LISTS template_headers)
    execute_process(
        COMMAND "${sed_executable}" -i
            "/^[[:space:]]*#[[:space:]]*include/ s#\\\\#/#g" "${header}"
        COMMAND_ERROR_IS_FATAL ANY)
endforeach()

set(union_afx "${PLUGIN_DIR}/UnionAfx.h")
foreach(component Memory Common Temporary Core Vdfs SystemPack ZenGin)
    replace_if_present("${union_afx}" "${component}\\" "${component}/")
endforeach()

file(GLOB_RECURSE zengine_headers LIST_DIRECTORIES false
    "${PLUGIN_DIR}/ZenGin/*/API/zEngine.h")
foreach(header IN LISTS zengine_headers)
    replace_if_present("${header}" "zview.h" "zView.h")
    replace_if_present("${header}" "oViewStatusBar.h" "oViewStatusbar.h")
    replace_if_present("${header}" "oVisFX.h" "oVisFx.h")
    replace_if_present("${header}" "zAIPlayer.h" "zAiPlayer.h")
    replace_if_present("${header}" "oAIShoot.h" "oAiShoot.h")
    replace_if_present("${header}" "oCSPlayer.h" "oCsPlayer.h")
    replace_if_present("${header}" "oCSManager.h" "oCsManager.h")
endforeach()

set(old_ai_player
    "${PLUGIN_DIR}/ZenGin/Gothic_II_Addon/API/zAIPlayer.h")
set(new_ai_player
    "${PLUGIN_DIR}/ZenGin/Gothic_II_Addon/API/zAiPlayer.h")
if(EXISTS "${old_ai_player}" AND NOT EXISTS "${new_ai_player}")
    file(RENAME "${old_ai_player}" "${new_ai_player}")
    message(STATUS "Renamed ZenGin/Gothic_II_Addon/API/zAIPlayer.h -> zAiPlayer.h")
endif()

file(GLOB_RECURSE npc_headers LIST_DIRECTORIES false
    "${PLUGIN_DIR}/ZenGin/*/API/oNpc.h")
foreach(header IN LISTS npc_headers)
    replace_if_present("${header}" "} oCNpc::oSFightAI;" "} oSFightAI;")
endforeach()

message(STATUS "Union 1.0m project portability patch complete")

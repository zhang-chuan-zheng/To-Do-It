function(todoit_fix_localized_msvc_dependencies)
    if(NOT MSVC)
        return()
    endif()

    # CMake 3.30 may decode the UTF-8 /showIncludes prefix from a Chinese-only
    # MSVC installation as code page 936. Ninja then cannot recognize and hide
    # dependency lines. Limit the correction to that exact mojibake value so
    # English and other localized toolchains remain untouched.
    set(_todoit_mojibake_prefix "娉ㄦ剰: 鍖呭惈鏂囦欢:  ")
    if("${CMAKE_CXX_CL_SHOWINCLUDES_PREFIX}" STREQUAL "${_todoit_mojibake_prefix}")
        set(_todoit_correct_prefix "注意: 包含文件:  ")
        set(CMAKE_CXX_CL_SHOWINCLUDES_PREFIX "${_todoit_correct_prefix}" PARENT_SCOPE)
        set(CMAKE_CL_SHOWINCLUDES_PREFIX "${_todoit_correct_prefix}" PARENT_SCOPE)
        message(STATUS "Corrected the localized MSVC dependency prefix for Ninja")
    endif()
endfunction()

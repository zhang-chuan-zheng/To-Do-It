include_guard(GLOBAL)

function(todoit_enable_warnings target_name)
    if(NOT TARGET "${target_name}")
        message(FATAL_ERROR "todoit_enable_warnings: target '${target_name}' does not exist")
    endif()

    if(MSVC)
        target_compile_options("${target_name}" PRIVATE
            /W4
            /permissive-
            /Zc:__cplusplus
            /utf-8
            $<$<BOOL:${TODOIT_WARNINGS_AS_ERRORS}>:/WX>
        )
    else()
        target_compile_options("${target_name}" PRIVATE
            -Wall
            -Wextra
            -Wpedantic
            $<$<BOOL:${TODOIT_WARNINGS_AS_ERRORS}>:-Werror>
        )
    endif()
endfunction()

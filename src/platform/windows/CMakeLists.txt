add_library(todoit_windows_platform STATIC
    NativeAttachmentDialog.cpp
    NativeAttachmentDialog.h
)
add_library(ToDoIt::WindowsPlatform ALIAS todoit_windows_platform)

target_compile_features(todoit_windows_platform PUBLIC cxx_std_20)
target_include_directories(todoit_windows_platform
    PUBLIC
        "${PROJECT_SOURCE_DIR}/src"
)
target_link_libraries(todoit_windows_platform
    PUBLIC
        ToDoIt::Application
        Qt6::Core
)

if(WIN32)
    target_compile_definitions(todoit_windows_platform
        PRIVATE
            NOMINMAX
            WIN32_LEAN_AND_MEAN
    )
    target_link_libraries(todoit_windows_platform
        PRIVATE
            ole32
            shell32
            uuid
    )
endif()

todoit_enable_warnings(todoit_windows_platform)

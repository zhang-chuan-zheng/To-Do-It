add_library(todoit_windows_platform INTERFACE)
add_library(ToDoIt::WindowsPlatform ALIAS todoit_windows_platform)

target_compile_features(todoit_windows_platform INTERFACE cxx_std_20)
target_link_libraries(todoit_windows_platform
    INTERFACE
        ToDoIt::Application
)



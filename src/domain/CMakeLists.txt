add_library(todoit_domain INTERFACE)
add_library(ToDoIt::Domain ALIAS todoit_domain)

target_compile_features(todoit_domain INTERFACE cxx_std_20)
target_include_directories(todoit_domain
    INTERFACE
        "${PROJECT_SOURCE_DIR}/src"
)

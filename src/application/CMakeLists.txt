add_library(todoit_application INTERFACE)
add_library(ToDoIt::Application ALIAS todoit_application)

target_compile_features(todoit_application INTERFACE cxx_std_20)
target_link_libraries(todoit_application
    INTERFACE
        ToDoIt::Domain
)



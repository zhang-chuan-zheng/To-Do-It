add_library(todoit_infrastructure STATIC
    path/InstallPaths.cpp
    path/InstallPaths.h
    persistence/CsvCodec.cpp
    persistence/CsvCodec.h
    persistence/CsvEventRepository.cpp
    persistence/CsvEventRepository.h
)
add_library(ToDoIt::Infrastructure ALIAS todoit_infrastructure)

target_compile_features(todoit_infrastructure PUBLIC cxx_std_20)
target_include_directories(todoit_infrastructure
    PUBLIC
        "${PROJECT_SOURCE_DIR}/src"
)
target_link_libraries(todoit_infrastructure
    PUBLIC
        ToDoIt::Application
    PRIVATE
        Qt6::Core
)

todoit_enable_warnings(todoit_infrastructure)


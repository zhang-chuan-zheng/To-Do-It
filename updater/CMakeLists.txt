add_library(todoit_update_core STATIC
    EventCsvMigrator.cpp
    EventCsvMigrator.h
    UpdateCoordinator.cpp
    UpdateCoordinator.h
    UpdateHistoryWriter.cpp
    UpdateHistoryWriter.h
    UpdateManifest.cpp
    UpdateManifest.h
    UpdateReport.h
)
add_library(ToDoIt::UpdateCore ALIAS todoit_update_core)

target_compile_features(todoit_update_core PUBLIC cxx_std_20)
target_include_directories(todoit_update_core
    PUBLIC
        "${PROJECT_SOURCE_DIR}/updater"
)
target_link_libraries(todoit_update_core
    PUBLIC
        Qt6::Core
    PRIVATE
        ToDoIt::Infrastructure
)
todoit_enable_warnings(todoit_update_core)

qt_add_executable(ToDoItMigrator
    main.cpp
)
target_link_libraries(ToDoItMigrator
    PRIVATE
        ToDoIt::UpdateCore
        Qt6::Core
)
todoit_enable_warnings(ToDoItMigrator)

# The migrator remains next to the application so the installer can run it
# after deploying the new files and before reporting a successful update.
install(TARGETS ToDoItMigrator
    RUNTIME DESTINATION .
)

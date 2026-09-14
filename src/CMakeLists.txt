add_subdirectory(domain)
add_subdirectory(application)
add_subdirectory(infrastructure)
add_subdirectory(platform/windows)
add_subdirectory(presentation/controllers)

qt_add_executable(ToDoIt
    WIN32
    main.cpp
)

# Keep qt_add_executable() and qt_add_qml_module() in the same directory scope.
# Qt finalizes executable-backed QML modules from this scope.
include(presentation/qml/CMakeLists.txt)

target_link_libraries(ToDoIt
    PRIVATE
        ToDoIt::Infrastructure
        ToDoIt::PresentationControllers
        ToDoIt::WindowsPlatform
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::QuickEffects
)

todoit_enable_warnings(ToDoIt)

install(TARGETS ToDoIt
    RUNTIME DESTINATION .
)

# Generate a self-contained Qt Quick deployment at install time. This copies
# the Qt runtime, QML imports, plugins, and compiler runtime used by ToDoIt.
qt_generate_deploy_qml_app_script(
    TARGET ToDoIt
    OUTPUT_SCRIPT todoit_deploy_qml_script
    NO_UNSUPPORTED_PLATFORM_ERROR
)
install(SCRIPT "${todoit_deploy_qml_script}")

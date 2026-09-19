add_subdirectory(domain)
add_subdirectory(application)
add_subdirectory(infrastructure)
add_subdirectory(platform/windows)
add_subdirectory(presentation/controllers)

qt_add_executable(ToDoIt
    WIN32
    main.cpp
)

if(WIN32)
    set(todoit_default_executable_icon
        "${PROJECT_SOURCE_DIR}/assets/logos/default/app.ico")
    set(todoit_custom_executable_icon
        "${PROJECT_SOURCE_DIR}/assets/logos/custom/app.ico")
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
        "${todoit_default_executable_icon}"
        "${todoit_custom_executable_icon}"
    )

    set(todoit_executable_icon "${todoit_default_executable_icon}")
    if(EXISTS "${todoit_custom_executable_icon}")
        set(todoit_executable_icon "${todoit_custom_executable_icon}")
    endif()
    if(NOT EXISTS "${todoit_executable_icon}")
        message(FATAL_ERROR
            "Missing Windows application icon: ${todoit_executable_icon}")
    endif()

    file(TO_CMAKE_PATH "${todoit_executable_icon}" TODOIT_EXECUTABLE_ICON)
    configure_file(
        "${PROJECT_SOURCE_DIR}/src/platform/windows/resources/ToDoIt.rc.in"
        "${CMAKE_CURRENT_BINARY_DIR}/ToDoIt.rc"
        @ONLY
    )
    target_sources(ToDoIt PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/ToDoIt.rc")
endif()

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

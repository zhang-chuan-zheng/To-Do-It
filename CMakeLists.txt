cmake_minimum_required(VERSION 3.24)

project(ToDoIt
    VERSION 0.2.1
    DESCRIPTION "Offline Windows task list application"
    LANGUAGES CXX
)

include(GNUInstallDirs)

# The Windows executable and the Qt runtime must share one directory.  Qt's
# deploy script derives QT_DEPLOY_BIN_DIR while Qt6 is discovered, so set the
# install bindir before find_package(Qt6).  Keeping the executable in the
# installation root also preserves the paths used by Qt IFW shortcuts and the
# maintenance tool.
if(WIN32)
    set(CMAKE_INSTALL_BINDIR ".")
endif()

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")

option(TODOIT_WARNINGS_AS_ERRORS "Treat To Do It compiler warnings as errors" OFF)

find_package(Qt6 6.11 REQUIRED COMPONENTS Quick QuickControls2 QuickEffects)
qt_standard_project_setup(REQUIRES 6.11)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
include(CompilerWarnings)
include(LocalizedMsvc)
todoit_fix_localized_msvc_dependencies()

add_subdirectory(src)
add_subdirectory(updater)

set(TODOIT_RELEASE_MANIFEST
    "${CMAKE_CURRENT_SOURCE_DIR}/updater/manifests/${PROJECT_VERSION}.json")
if(NOT EXISTS "${TODOIT_RELEASE_MANIFEST}")
    message(FATAL_ERROR
        "Missing release manifest: ${TODOIT_RELEASE_MANIFEST}. "
        "Every application version must declare its data schema and migration chain.")
endif()

# Runtime data is intentionally excluded: installing or updating must never own,
# overwrite, or remove [InstallDir]/data/event.csv.
install(FILES "${TODOIT_RELEASE_MANIFEST}"
    DESTINATION .
    RENAME release-manifest.json
)
install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/assets/"
    DESTINATION assets
)
install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/config/default-resources.json"
    DESTINATION defaults/config
)
install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/third_party/README.md"
    DESTINATION licenses
    RENAME THIRD_PARTY_NOTICES.md
)

include(CTest)
if(BUILD_TESTING)
    find_package(Qt6 6.11 REQUIRED COMPONENTS Test)
    add_subdirectory(tests)
endif()

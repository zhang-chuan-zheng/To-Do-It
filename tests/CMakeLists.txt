qt_add_executable(ToDoItAppShellControllerTest
    framework/AppShellControllerTest.cpp
)

target_link_libraries(ToDoItAppShellControllerTest
    PRIVATE
        Qt6::Test
        ToDoIt::PresentationControllers
)

todoit_enable_warnings(ToDoItAppShellControllerTest)

add_test(
    NAME ToDoIt.AppShellController
    COMMAND ToDoItAppShellControllerTest
)

set_tests_properties(ToDoIt.AppShellController PROPERTIES
    ENVIRONMENT_MODIFICATION
        "PATH=path_list_prepend:$<TARGET_FILE_DIR:Qt6::Core>"
)

qt_add_executable(ToDoItUpdateCoordinatorTest
    updater/UpdateCoordinatorTest.cpp
)
target_link_libraries(ToDoItUpdateCoordinatorTest
    PRIVATE
        Qt6::Test
        ToDoIt::UpdateCore
)
todoit_enable_warnings(ToDoItUpdateCoordinatorTest)

add_test(
    NAME ToDoIt.UpdateCoordinator
    COMMAND ToDoItUpdateCoordinatorTest
)
set_tests_properties(ToDoIt.UpdateCoordinator PROPERTIES
    ENVIRONMENT_MODIFICATION
        "PATH=path_list_prepend:$<TARGET_FILE_DIR:Qt6::Core>"
)

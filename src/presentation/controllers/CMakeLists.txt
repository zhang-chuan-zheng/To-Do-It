add_library(todoit_presentation_controllers STATIC
    AppShellController.cpp
    AppShellController.h
    EventDataController.cpp
    EventDataController.h
    QuoteController.cpp
    QuoteController.h
    RichTextFormatter.cpp
    RichTextFormatter.h
)
add_library(ToDoIt::PresentationControllers ALIAS todoit_presentation_controllers)

target_compile_features(todoit_presentation_controllers PUBLIC cxx_std_20)
target_compile_definitions(todoit_presentation_controllers
    PRIVATE
        TODOIT_PROJECT_VERSION="${PROJECT_VERSION}"
)
target_include_directories(todoit_presentation_controllers
    PUBLIC
        "${PROJECT_SOURCE_DIR}/src"
)
target_link_libraries(todoit_presentation_controllers
    PUBLIC
        Qt6::Core
        Qt6::Gui
        ToDoIt::Application
    PRIVATE
        Qt6::Quick
)

todoit_enable_warnings(todoit_presentation_controllers)

set(todoit_qml_root "${CMAKE_CURRENT_LIST_DIR}")

set(todoit_qml_files
    "${todoit_qml_root}/Main.qml"
    "${todoit_qml_root}/pages/MainPage.qml"
    "${todoit_qml_root}/components/AddEventButton.qml"
    "${todoit_qml_root}/components/AppLogo.qml"
    "${todoit_qml_root}/components/AttachmentStrip.qml"
    "${todoit_qml_root}/components/BottomHelpBar.qml"
    "${todoit_qml_root}/components/CompactDateEditor.qml"
    "${todoit_qml_root}/components/ColorPalettePopup.qml"
    "${todoit_qml_root}/components/DonationPopup.qml"
    "${todoit_qml_root}/components/EditableStatusComboBox.qml"
    "${todoit_qml_root}/components/EventCard.qml"
    "${todoit_qml_root}/components/EventTableHeader.qml"
    "${todoit_qml_root}/components/EventTreeView.qml"
    "${todoit_qml_root}/components/ExpandableSearchBox.qml"
    "${todoit_qml_root}/components/FieldFrame.qml"
    "${todoit_qml_root}/components/FramelessTitleBar.qml"
    "${todoit_qml_root}/components/GlassPanel.qml"
    "${todoit_qml_root}/components/GlassToolTip.qml"
    "${todoit_qml_root}/components/InfoFilterBar.qml"
    "${todoit_qml_root}/components/ImportanceSelector.qml"
    "${todoit_qml_root}/components/IconImage.qml"
    "${todoit_qml_root}/components/QuoteBanner.qml"
    "${todoit_qml_root}/components/RoundIconButton.qml"
    "${todoit_qml_root}/components/RichNoteEditor.qml"
    "${todoit_qml_root}/components/SearchFieldSelector.qml"
    "${todoit_qml_root}/components/SortButton.qml"
    "${todoit_qml_root}/components/StatusFilterComboBox.qml"
    "${todoit_qml_root}/components/StatusSummary.qml"
    "${todoit_qml_root}/components/WindowResizeHandles.qml"
    "${todoit_qml_root}/effects/GlassSurface.qml"
    "${todoit_qml_root}/effects/PopupGlassBackground.qml"
    "${todoit_qml_root}/styles/Metrics.qml"
    "${todoit_qml_root}/styles/Motion.qml"
    "${todoit_qml_root}/styles/IconCatalog.qml"
    "${todoit_qml_root}/styles/Theme.qml"
    "${todoit_qml_root}/styles/Typography.qml"
)

foreach(todoit_qml_file IN LISTS todoit_qml_files)
    file(RELATIVE_PATH todoit_qml_alias "${todoit_qml_root}" "${todoit_qml_file}")
    set_source_files_properties("${todoit_qml_file}" PROPERTIES
        QT_RESOURCE_ALIAS "${todoit_qml_alias}"
    )
endforeach()

set(todoit_qml_singletons
    "${todoit_qml_root}/styles/IconCatalog.qml"
    "${todoit_qml_root}/styles/Metrics.qml"
    "${todoit_qml_root}/styles/Motion.qml"
    "${todoit_qml_root}/styles/Theme.qml"
    "${todoit_qml_root}/styles/Typography.qml"
)
set_source_files_properties(${todoit_qml_singletons} PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
)

set(todoit_asset_root "${todoit_qml_root}/../../../assets")
set(todoit_quote_file "${todoit_asset_root}/quotes/philosophy_quotes.json")
set_source_files_properties("${todoit_quote_file}" PROPERTIES
    QT_RESOURCE_ALIAS "content/philosophy_quotes.json"
)
set(todoit_default_app_logo "${todoit_asset_root}/logos/default/app.svg")
set(todoit_custom_app_logo "${todoit_asset_root}/logos/custom/app.svg")
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
    "${todoit_default_app_logo}"
    "${todoit_custom_app_logo}"
)
set(todoit_app_logo "${todoit_default_app_logo}")
if(EXISTS "${todoit_custom_app_logo}")
    set(todoit_app_logo "${todoit_custom_app_logo}")
endif()

set(todoit_icon_files
    "${todoit_app_logo}"
    "${todoit_asset_root}/icons/default/search.svg"
    "${todoit_asset_root}/icons/default/minimize.svg"
    "${todoit_asset_root}/icons/default/maximize.svg"
    "${todoit_asset_root}/icons/default/restore.svg"
    "${todoit_asset_root}/icons/default/close.svg"
    "${todoit_asset_root}/icons/default/chevron-down.svg"
    "${todoit_asset_root}/icons/default/calendar.svg"
    "${todoit_asset_root}/icons/default/sort-up.svg"
    "${todoit_asset_root}/icons/default/sort-down.svg"
    "${todoit_asset_root}/icons/default/add.svg"
    "${todoit_asset_root}/icons/default/attachment-add.svg"
    "${todoit_asset_root}/icons/default/folder.svg"
    "${todoit_asset_root}/icons/default/palette.svg"
    "${todoit_asset_root}/icons/default/donate.svg"
    "${todoit_asset_root}/icons/default/arrow-right.svg"
    "${todoit_asset_root}/images/default/donation-qr-placeholder.svg"
)

set(todoit_icon_aliases
    "app.svg"
    "search.svg"
    "minimize.svg"
    "maximize.svg"
    "restore.svg"
    "close.svg"
    "chevron-down.svg"
    "calendar.svg"
    "sort-up.svg"
    "sort-down.svg"
    "add.svg"
    "attachment-add.svg"
    "folder.svg"
    "palette.svg"
    "donate.svg"
    "arrow-right.svg"
    "donation-qr-placeholder.svg"
)

list(LENGTH todoit_icon_files todoit_icon_count)
math(EXPR todoit_icon_last_index "${todoit_icon_count} - 1")
foreach(todoit_icon_index RANGE ${todoit_icon_last_index})
    list(GET todoit_icon_files ${todoit_icon_index} todoit_icon_file)
    list(GET todoit_icon_aliases ${todoit_icon_index} todoit_icon_alias)
    if(todoit_icon_alias STREQUAL "donation-qr-placeholder.svg")
        set(todoit_resource_alias "images/${todoit_icon_alias}")
    else()
        set(todoit_resource_alias "icons/${todoit_icon_alias}")
    endif()
    set_source_files_properties("${todoit_icon_file}" PROPERTIES
        QT_RESOURCE_ALIAS "${todoit_resource_alias}"
    )
endforeach()

qt_add_qml_module(ToDoIt
    URI ToDoIt
    VERSION 1.0
    QML_FILES
        ${todoit_qml_files}
    RESOURCES
        ${todoit_icon_files}
        "${todoit_quote_file}"
)

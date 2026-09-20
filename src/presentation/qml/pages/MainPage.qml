import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import ToDoIt.Controllers 1.0

Item {
    id: root
    focus: true
    property var hostWindow
    property string defaultHelpText: EventData.loadError.length > 0
        ? EventData.loadError : (EventData.saveError.length > 0
            ? EventData.saveError : (QuoteData.loadError.length > 0
                ? QuoteData.loadError : qsTr("将鼠标移到组件上可查看操作说明")))
    property string helpText: defaultHelpText
    signal addEventRequested()
    signal statusFilterRequested(string status)
    signal sortRequested(string field, string direction)

    function showHelp(message) {
        helpText = message.length > 0 ? message : defaultHelpText
    }

    function flushPendingChanges() {
        taskTree.flushPersistence()
    }

    function refreshQuote() {
        if (!hostWindow || !hostWindow.visible
                || hostWindow.visibility === Window.Minimized)
            return
        QuoteData.refreshQuote()
    }

    function pointInsideItem(item, scenePosition) {
        if (!item || !item.mapFromItem)
            return false
        const localPosition = item.mapFromItem(null, scenePosition.x, scenePosition.y)
        return localPosition.x >= 0 && localPosition.x <= item.width
            && localPosition.y >= 0 && localPosition.y <= item.height
    }

    function clearFocusWhenTappedOutside(scenePosition) {
        if (titleBar.pointInsideSearch(scenePosition))
            return
        const focusedItem = hostWindow ? hostWindow.activeFocusItem : null
        if (!focusedItem || focusedItem === root
                || pointInsideItem(focusedItem, scenePosition))
            return
        root.forceActiveFocus(Qt.MouseFocusReason)
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped: function(eventPoint) {
            const scenePosition = Qt.point(eventPoint.scenePosition.x,
                                           eventPoint.scenePosition.y)
            Qt.callLater(function() {
                root.clearFocusWhenTappedOutside(scenePosition)
            })
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Metrics.pageMargin
        spacing: Metrics.spacingSmall

        FramelessTitleBar {
            id: titleBar
            Layout.fillWidth: true
            Layout.preferredHeight: Metrics.titleBarHeight
            hostWindow: root.hostWindow
            onBackgroundPressed: root.forceActiveFocus(Qt.MouseFocusReason)
            onHelpRequested: function(message) { root.showHelp(message) }
            onSearchEdited: function(text, field) { taskTree.setSearch(text, field) }
            onSearchSubmitted: function(text, field) { taskTree.setSearch(text, field) }
        }
        InfoFilterBar {
            Layout.fillWidth: true
            Layout.preferredHeight: Metrics.infoBarHeight
            filterOptions: taskTree.availableFilterOptions
            pendingCount: taskTree.summaryPendingCount
            completedCount: taskTree.summaryCompletedCount
            quote: QuoteData.quote
            quoteAuthor: QuoteData.author
            onFilterRequested: function(status) {
                taskTree.setStatusFilter(status)
                root.statusFilterRequested(status)
            }
            onHelpRequested: function(message) { root.showHelp(message) }
            onQuoteRefreshRequested: root.refreshQuote()
        }
        GlassPanel {
            Layout.fillWidth: true
            Layout.fillHeight: true
            surfaceLevel: 0
            panelRadius: Metrics.radiusLarge
            contentPadding: Metrics.eventOuterPadding

            ColumnLayout {
                anchors.fill: parent
                spacing: Metrics.eventFieldGap

                EventTableHeader {
                    id: tableHeader
                    Layout.fillWidth: true
                    Layout.preferredHeight: Metrics.tableHeaderHeight
                    sortDirections: taskTree.sortDirections
                    onSortRequested: function(field, direction) {
                        taskTree.applySortRequest(field, direction)
                        root.sortRequested(field, direction)
                    }
                }

                EventTreeView {
                    id: taskTree
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    initialEvents: EventData.events
                    eventIdFactory: function() { return EventData.createEventId() }
                    currentDateTimeFactory: function() {
                        return EventData.currentChinaDateTime()
                    }
                    onAddRequested: root.addEventRequested()
                    onPersistenceRequested: function(events) {
                        if (!EventData.saveEvents(events)) {
                            taskTree.persistenceDirty = true
                            root.showHelp(EventData.saveError)
                        }
                    }
                    onHelpRequested: function(message) { root.showHelp(message) }
                    onAttachmentOpened: function(eventTitle, attachmentIndex, folder) {
                        root.showHelp(folder
                            ? qsTr("%1 的附件文件夹已打开").arg(eventTitle)
                            : qsTr("%1 的附件已打开，请注意所有修改均将被保存！").arg(eventTitle))
                    }
                    onReleaseInputFocusRequested: root.forceActiveFocus(Qt.MouseFocusReason)
                }
            }
        }
        BottomHelpBar {
            Layout.fillWidth: true
            Layout.preferredHeight: Metrics.helpBarHeight
            message: root.helpText
            onHelpRequested: function(message) { root.showHelp(message) }
        }
    }

    Timer {
        id: quoteRefreshTimer
        interval: 2 * 60 * 1000
        repeat: true
        running: root.hostWindow && root.hostWindow.visible
            && root.hostWindow.visibility !== Window.Minimized
        onTriggered: root.refreshQuote()
    }
}

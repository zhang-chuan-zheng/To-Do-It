import QtQuick
import QtQuick.Controls

Item {
    id: root
    property var hostWindow
    property url logoSource: IconCatalog.appLogo
    property alias searchText: searchBox.text
    signal helpRequested(string message)
    signal searchEdited(string text, string field)
    signal searchSubmitted(string text, string field)
    signal searchFieldChanged(string field)
    signal backgroundPressed()

    function pointInsideSearch(scenePosition) {
        const localPosition = searchBox.mapFromItem(null, scenePosition.x, scenePosition.y)
        return localPosition.x >= 0 && localPosition.x <= searchBox.width
            && localPosition.y >= 0 && localPosition.y <= searchBox.height
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        property point pressPosition: Qt.point(0, 0)
        property bool systemMoveStarted: false

        onPressed: function(mouse) {
            pressPosition = Qt.point(mouse.x, mouse.y)
            systemMoveStarted = false
            root.backgroundPressed()
            mouse.accepted = true
        }
        onPositionChanged: function(mouse) {
            if (!pressed || systemMoveStarted || !root.hostWindow)
                return

            const deltaX = mouse.x - pressPosition.x
            const deltaY = mouse.y - pressPosition.y
            const threshold = Qt.styleHints.startDragDistance
            if (deltaX * deltaX + deltaY * deltaY < threshold * threshold)
                return

            systemMoveStarted = true
            root.hostWindow.startSystemMove()
        }
        onReleased: systemMoveStarted = false
        onCanceled: systemMoveStarted = false
        onDoubleClicked: {
            if (!root.hostWindow)
                return
            if (root.hostWindow.visibility === Window.Maximized)
                root.hostWindow.showNormal()
            else
                root.hostWindow.showMaximized()
        }
    }

    Row {
        id: identityRow
        anchors.left: parent.left
        anchors.leftMargin: Metrics.spacingTiny
        anchors.verticalCenter: parent.verticalCenter
        spacing: Metrics.spacingSmall
        AppLogo { source: root.logoSource }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("To Do It")
            color: Theme.textPrimary
            font.family: Typography.family
            font.pixelSize: Typography.titleSize
            font.weight: Typography.strongWeight
        }
        Item { width: Metrics.searchTitleGap; height: 1 }
        ExpandableSearchBox {
            id: searchBox
            anchors.verticalCenter: parent.verticalCenter
            onQueryEdited: function(text, field) { root.searchEdited(text, field) }
            onQuerySubmitted: function(text, field) { root.searchSubmitted(text, field) }
            onFieldChanged: function(field) { root.searchFieldChanged(field) }
            onHelpVisibilityChanged: function(message, visible) { root.helpRequested(visible ? message : "") }
        }
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: Metrics.spacingTiny
        anchors.verticalCenter: parent.verticalCenter
        spacing: Metrics.spacingTiny
        RoundIconButton {
            iconSource: IconCatalog.minimize; helpText: qsTr("最小化窗口"); chromeStyle: true
            onClicked: { if (root.hostWindow) root.hostWindow.showMinimized() }
            onHelpVisibilityChanged: function(message, visible) { root.helpRequested(visible ? message : "") }
        }
        RoundIconButton {
            iconSource: root.hostWindow && root.hostWindow.visibility === Window.Maximized
                ? IconCatalog.restore : IconCatalog.maximize
            helpText: root.hostWindow && root.hostWindow.visibility === Window.Maximized ? qsTr("还原窗口") : qsTr("最大化窗口")
            chromeStyle: true
            onClicked: {
                if (!root.hostWindow)
                    return
                if (root.hostWindow.visibility === Window.Maximized)
                    root.hostWindow.showNormal()
                else
                    root.hostWindow.showMaximized()
            }
            onHelpVisibilityChanged: function(message, visible) { root.helpRequested(visible ? message : "") }
        }
        RoundIconButton {
            iconSource: IconCatalog.close; helpText: qsTr("关闭软件"); destructive: true; chromeStyle: true
            onClicked: { if (root.hostWindow) root.hostWindow.close() }
            onHelpVisibilityChanged: function(message, visible) { root.helpRequested(visible ? message : "") }
        }
    }
}

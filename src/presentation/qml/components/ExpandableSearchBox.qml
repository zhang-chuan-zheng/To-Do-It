import QtQuick
import QtQuick.Controls

Item {
    id: root
    property alias text: searchInput.text
    property string selectedField: fieldSelector.selectedField
    property bool openRequested: false
    readonly property bool inputLocked: searchInput.activeFocus || searchInput.text.length > 0 || fieldSelector.popup.visible
    readonly property bool expanded: openRequested || inputLocked
    property int collapseDelay: Motion.searchCollapseDelay
    signal queryEdited(string text, string field)
    signal querySubmitted(string text, string field)
    signal fieldChanged(string field)
    signal helpVisibilityChanged(string message, bool visible)

    function collapseImmediatelyIfIdle() {
        if (hoverHandler.hovered || searchInput.activeFocus
                || searchInput.text.length > 0 || fieldSelector.popup.visible)
            return
        collapseTimer.stop()
        openRequested = false
    }

    implicitWidth: expanded ? Metrics.searchExpandedWidth : Metrics.searchCollapsedWidth
    implicitHeight: Metrics.searchCollapsedWidth
    width: implicitWidth
    height: implicitHeight
    clip: true
    Accessible.name: qsTr("搜索事项")

    HoverHandler {
        id: hoverHandler
        onHoveredChanged: {
            if (hovered) {
                collapseTimer.stop()
                root.openRequested = true
                root.helpVisibilityChanged(qsTr("在当前状态筛选结果中搜索事项名称、备注或附件名称"), true)
            } else {
                root.helpVisibilityChanged("", false)
                if (!root.inputLocked)
                    collapseTimer.restart()
            }
        }
    }

    Timer {
        id: collapseTimer
        interval: root.collapseDelay
        onTriggered: {
            if (!hoverHandler.hovered && !root.inputLocked)
                root.openRequested = false
        }
    }

    GlassSurface {
        anchors.fill: parent
        surfaceLevel: 1
        radius: height / 2
        interactive: hoverHandler.hovered || searchInput.activeFocus
    }

    Item {
        width: Metrics.searchCollapsedWidth
        height: parent.height
        IconImage {
            anchors.centerIn: parent
            width: 16
            height: 16
            source: IconCatalog.search
        }
        TapHandler {
            onTapped: {
                root.openRequested = true
                searchInput.forceActiveFocus()
            }
        }
    }

    Item {
        x: Metrics.searchCollapsedWidth
        width: Math.max(0, root.width - x)
        height: parent.height
        opacity: root.expanded ? 1 : 0
        visible: opacity > 0

        SearchFieldSelector {
            id: fieldSelector
            anchors.left: parent.left
            anchors.leftMargin: Metrics.spacingTiny
            anchors.verticalCenter: parent.verticalCenter
            onFieldSelected: function(field) {
                root.fieldChanged(field)
                root.queryEdited(searchInput.text, field)
            }
        }

        TextField {
            id: searchInput
            anchors.left: fieldSelector.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: Metrics.spacingSmall
            anchors.rightMargin: Metrics.spacingSmall
            placeholderText: qsTr("搜索事项")
            color: Theme.textPrimary
            placeholderTextColor: Theme.textMuted
            selectionColor: Theme.accent
            selectedTextColor: Theme.windowBaseColor
            font.family: Typography.family
            font.pixelSize: Typography.bodySize
            verticalAlignment: TextInput.AlignVCenter
            background: Rectangle { color: "transparent" }
            onActiveFocusChanged: {
                if (activeFocus) {
                    root.openRequested = true
                    collapseTimer.stop()
                } else {
                    root.collapseImmediatelyIfIdle()
                }
            }
            onTextEdited: {
                root.queryEdited(text, root.selectedField)
                if (text.length === 0 && !activeFocus)
                    root.collapseImmediatelyIfIdle()
            }
            onAccepted: root.querySubmitted(text, root.selectedField)
        }

        Behavior on opacity { NumberAnimation { duration: Motion.normalDuration } }
    }

    Behavior on width {
        NumberAnimation { duration: Motion.searchExpandDuration; easing.type: Motion.standardEasing }
    }
}

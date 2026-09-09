import QtQuick
import QtQuick.Controls

Item {
    id: root
    property string helpText: qsTr("新建一个一级事项")
    property bool rootDropActive: false
    readonly property bool hovered: hoverHandler.hovered
    signal addRequested()
    signal rootDropRequested(string draggedId)
    signal helpVisibilityChanged(string message, bool visible)
    implicitHeight: Metrics.addButtonHeight
    Accessible.role: Accessible.Button
    Accessible.name: qsTr("添加事项")
    Accessible.onPressAction: addRequested()

    GlassSurface {
        anchors.fill: parent
        radius: Metrics.radiusMedium
        surfaceLevel: 0
        interactive: false
        fillColor: root.hovered || root.rootDropActive ? Theme.eventHover : Theme.surfaceLow
        border.color: root.hovered || root.rootDropActive ? Theme.outlineStrong : Theme.outline
    }

    Row {
        anchors.centerIn: parent
        spacing: Metrics.spacingSmall

        IconImage {
            anchors.verticalCenter: parent.verticalCenter
            width: 20
            height: 20
            source: IconCatalog.add
            accessibleName: qsTr("添加事项")
        }

        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("添加事项")
            color: Theme.textPrimary
            font.family: Typography.family
            font.pixelSize: Typography.bodySize
            font.weight: Typography.mediumWeight
        }
    }

    HoverHandler {
        id: hoverHandler
        onHoveredChanged: root.helpVisibilityChanged(root.helpText, hovered)
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: root.addRequested()
    }

    DropArea {
        anchors.fill: parent
        keys: ["todoit-event-card"]
        onEntered: root.rootDropActive = true
        onExited: root.rootDropActive = false
        onDropped: function(drop) {
            root.rootDropActive = false
            const sourceId = drop.source ? drop.source.eventId : ""
            if (sourceId.length === 0)
                return
            root.rootDropRequested(sourceId)
            drop.acceptProposedAction()
        }
    }
}

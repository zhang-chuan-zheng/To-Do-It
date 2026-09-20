import QtQuick
import QtQuick.Controls

Popup {
    id: root
    signal createChildRequested()
    signal deleteRequested()

    width: 164
    height: menuColumn.implicitHeight + topPadding + bottomPadding
    padding: Metrics.spacingTiny
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    background: PopupGlassBackground {
        surfaceLevel: 2
        radius: Metrics.radiusSmall
    }

    function openAt(localX, localY, availableWidth, availableHeight) {
        x = Math.max(Metrics.spacingTiny,
                     Math.min(localX, availableWidth - width
                              - Metrics.spacingTiny))
        y = Math.max(Metrics.spacingTiny,
                     Math.min(localY, availableHeight - height
                              - Metrics.spacingTiny))
        open()
    }

    contentItem: Column {
        id: menuColumn
        spacing: 2

        Button {
            width: root.availableWidth
            height: 34
            hoverEnabled: true
            focusPolicy: Qt.NoFocus
            Accessible.name: qsTr("新建子事项")
            contentItem: Label {
                text: qsTr("新建子事项")
                color: Theme.textPrimary
                font.family: Typography.family
                font.pixelSize: Typography.bodySize
                verticalAlignment: Text.AlignVCenter
                leftPadding: Metrics.spacingMedium
            }
            background: Rectangle {
                radius: Metrics.radiusSmall
                color: parent.hovered || parent.down
                    ? Theme.surfaceHover : "transparent"
                border.width: parent.visualFocus ? 1 : 0
                border.color: Theme.focusRing
            }
            onClicked: {
                root.close()
                root.createChildRequested()
            }
        }

        Button {
            width: root.availableWidth
            height: 34
            hoverEnabled: true
            focusPolicy: Qt.NoFocus
            Accessible.name: qsTr("删除事项")
            contentItem: Label {
                text: qsTr("删除事项")
                color: parent.hovered || parent.down
                    ? Theme.danger : Theme.textPrimary
                font.family: Typography.family
                font.pixelSize: Typography.bodySize
                verticalAlignment: Text.AlignVCenter
                leftPadding: Metrics.spacingMedium
            }
            background: Rectangle {
                radius: Metrics.radiusSmall
                color: parent.hovered || parent.down
                    ? Theme.dangerSurface : "transparent"
                border.width: parent.visualFocus ? 1 : 0
                border.color: Theme.focusRing
            }
            onClicked: {
                root.close()
                root.deleteRequested()
            }
        }
    }
}

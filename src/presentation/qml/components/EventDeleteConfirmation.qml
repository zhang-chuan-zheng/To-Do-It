import QtQuick
import QtQuick.Controls

Popup {
    id: root
    property string eventTitle: ""
    property int descendantCount: 0
    signal deletionConfirmed()

    width: Math.min(420, parent ? parent.width - Metrics.spacingHuge * 2 : 420)
    height: dialogContent.implicitHeight + topPadding + bottomPadding
    x: parent ? Math.max(0, (parent.width - width) / 2) : 0
    y: parent ? Math.max(0, (parent.height - height) / 2) : 0
    padding: Metrics.spacingLarge
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    background: PopupGlassBackground {
        surfaceLevel: 2
        radius: Metrics.radiusMedium
    }

    contentItem: Column {
        id: dialogContent
        spacing: Metrics.spacingMedium

        Label {
            width: parent.width
            text: qsTr("确认删除事项")
            color: Theme.textPrimary
            font.family: Typography.family
            font.pixelSize: Typography.titleSize
            font.weight: Typography.strongWeight
        }

        Label {
            width: parent.width
            wrapMode: Text.Wrap
            text: root.descendantCount > 0
                ? qsTr("“%1”包含 %2 个子孙事项，确认后将一并删除。此操作不可撤销。")
                    .arg(root.eventTitle).arg(root.descendantCount)
                : qsTr("确认删除“%1”？此操作不可撤销。")
                    .arg(root.eventTitle)
            color: Theme.textSecondary
            font.family: Typography.family
            font.pixelSize: Typography.bodySize
        }

        Item {
            width: parent.width
            height: 32

            Row {
                anchors.right: parent.right
                spacing: Metrics.spacingSmall

                Button {
                    width: 76
                    height: 32
                    text: qsTr("取消")
                    onClicked: root.close()
                    contentItem: Label {
                        text: parent.text
                        color: Theme.textPrimary
                        font.family: Typography.family
                        font.pixelSize: Typography.bodySize
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: GlassSurface {
                        radius: Metrics.radiusSmall
                        surfaceLevel: 0
                        interactive: parent.hovered || parent.down
                    }
                }

                Button {
                    width: 76
                    height: 32
                    text: qsTr("删除")
                    onClicked: {
                        root.deletionConfirmed()
                        root.close()
                    }
                    contentItem: Label {
                        text: parent.text
                        color: Theme.textPrimary
                        font.family: Typography.family
                        font.pixelSize: Typography.bodySize
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: GlassSurface {
                        radius: Metrics.radiusSmall
                        surfaceLevel: 1
                        interactive: parent.hovered || parent.down
                        fillColor: parent.hovered || parent.down
                            ? Theme.dangerSurface : Theme.surfaceLow
                        border.color: parent.visualFocus
                            ? Theme.focusRing : Theme.outlineStrong
                    }
                }
            }
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

ComboBox {
    id: root
    property var options: [qsTr("未完成事项"), qsTr("全部事项")]
    readonly property string selectedStatus: currentText
    signal filterRequested(string status)
    signal helpVisibilityChanged(string message, bool visible)
    model: options
    implicitWidth: 142
    implicitHeight: 34
    leftPadding: Metrics.spacingMedium
    rightPadding: 30
    hoverEnabled: true
    font.family: Typography.family
    font.pixelSize: Typography.bodySize
    Accessible.name: qsTr("事件状态筛选")

    contentItem: Text {
        text: root.displayText
        color: Theme.textPrimary
        font: root.font
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }
    indicator: IconImage {
        x: root.width - width - Metrics.spacingMedium
        y: (root.height - height) / 2
        width: 10
        height: 10
        source: IconCatalog.chevronDown
    }
    background: GlassSurface {
        surfaceLevel: 0
        radius: Metrics.radiusSmall
        interactive: root.hovered || root.visualFocus || root.popup.visible
        border.color: root.visualFocus ? Theme.focusRing : Theme.outline
    }
    delegate: ItemDelegate {
        id: optionDelegate
        required property var modelData
        required property int index
        width: root.popup.width - root.popup.leftPadding - root.popup.rightPadding
        height: 34
        text: modelData
        highlighted: root.highlightedIndex === index
        font.family: Typography.family
        font.pixelSize: Typography.bodySize
        contentItem: Text {
            text: optionDelegate.text
            color: Theme.textPrimary
            font: optionDelegate.font
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }
        background: Rectangle {
            radius: Metrics.radiusSmall
            color: optionDelegate.highlighted ? Theme.surfaceHover : "transparent"
        }
    }
    popup: Popup {
        y: root.height + Metrics.spacingTiny
        width: Math.max(root.width, 154)
        implicitHeight: Math.min(contentItem.implicitHeight + topPadding + bottomPadding, 230)
        padding: Metrics.spacingTiny
        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: root.delegateModel
            currentIndex: root.highlightedIndex
        }
        background: PopupGlassBackground { surfaceLevel: 2; radius: Metrics.radiusSmall }
    }
    ToolTip.visible: hovered
    ToolTip.text: qsTr("筛选事项；默认显示所有未完成事项")
    ToolTip.delay: 450
    onActivated: filterRequested(currentText)
    onHoveredChanged: helpVisibilityChanged(qsTr("筛选事项；默认显示所有未完成事项"), hovered)
}

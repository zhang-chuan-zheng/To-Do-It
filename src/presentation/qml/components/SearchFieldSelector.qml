pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls


ComboBox {
    id: root
    property var options: [qsTr("全部"), qsTr("事项名称"), qsTr("备注"), qsTr("附件名称")]
    readonly property string selectedField: currentText
    signal fieldSelected(string field)
    model: options
    implicitWidth: Metrics.searchSelectorWidth
    implicitHeight: 30
    leftPadding: Metrics.spacingSmall
    rightPadding: 24
    font.family: Typography.family
    font.pixelSize: Typography.secondarySize

    contentItem: Text {
        text: root.displayText
        color: Theme.textSecondary
        font: root.font
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    indicator: IconImage {
        x: root.width - width - Metrics.spacingSmall
        y: (root.height - height) / 2
        width: 10
        height: 10
        source: IconCatalog.chevronDown
    }

    background: GlassSurface {
        radius: Metrics.radiusSmall
        surfaceLevel: 0
        fillColor: "transparent"
        interactive: false
        border.color: "transparent"
    }

    delegate: ItemDelegate {
        id: optionDelegate
        required property var modelData
        required property int index
        width: root.popup.width - root.popup.leftPadding - root.popup.rightPadding
        height: 32
        text: modelData
        highlighted: root.highlightedIndex === index
        font.family: Typography.family
        font.pixelSize: Typography.secondarySize
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
        width: Math.max(root.width, 116)
        implicitHeight: Math.min(contentItem.implicitHeight + topPadding + bottomPadding, 180)
        padding: Metrics.spacingTiny
        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: root.delegateModel
            currentIndex: root.highlightedIndex
        }
        background: PopupGlassBackground { surfaceLevel: 2; radius: Metrics.radiusSmall }
    }

    onActivated: fieldSelected(currentText)
}

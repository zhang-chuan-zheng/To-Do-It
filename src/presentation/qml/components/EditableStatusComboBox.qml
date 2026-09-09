pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

ComboBox {
    id: root
    property string statusText: qsTr("进行中")
    property var statusOptions: [qsTr("进行中"), qsTr("已完成"), qsTr("已取消"), qsTr("待确认")]
    readonly property bool editing: activeFocus || popup.visible
    signal statusEdited(string status)

    model: statusOptions
    editable: true
    leftPadding: Metrics.spacingSmall
    rightPadding: 22
    font.family: Typography.family
    font.pixelSize: Typography.secondarySize

    Component.onCompleted: editText = statusText
    onStatusTextChanged: {
        if (!activeFocus && editText !== statusText)
            editText = statusText
    }
    onActivated: function(index) {
        editText = statusOptions[index]
        statusEdited(editText)
    }
    onAccepted: statusEdited(editText.length > 0 ? editText : qsTr("进行中"))

    contentItem: TextInput {
        leftPadding: root.leftPadding
        rightPadding: root.rightPadding
        text: root.editText
        color: Theme.statusColor(root.editText)
        selectionColor: Theme.accent
        selectedTextColor: Theme.windowBaseColor
        font: root.font
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        readOnly: !root.editable
        validator: root.validator
        inputMethodHints: root.inputMethodHints
        onTextEdited: root.editText = text
    }

    indicator: IconImage {
        x: root.width - width - Metrics.spacingSmall
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
        id: statusDelegate
        required property var modelData
        required property int index
        width: root.popup.width - root.popup.leftPadding - root.popup.rightPadding
        height: 30
        text: modelData
        highlighted: root.highlightedIndex === index
        contentItem: Text {
            text: statusDelegate.text
            color: Theme.statusColor(statusDelegate.text)
            font.family: Typography.family
            font.pixelSize: Typography.secondarySize
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: Metrics.radiusSmall
            color: statusDelegate.highlighted ? Theme.surfaceHover : "transparent"
        }
    }

    popup: Popup {
        y: root.height + Metrics.spacingTiny
        width: Math.max(root.width, 132)
        padding: Metrics.spacingTiny
        contentItem: ListView {
            implicitHeight: contentHeight
            clip: true
            model: root.delegateModel
            currentIndex: root.highlightedIndex
        }
        background: PopupGlassBackground { surfaceLevel: 2; radius: Metrics.radiusSmall }
    }
}

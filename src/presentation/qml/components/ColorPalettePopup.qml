pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

Popup {
    id: root

    property color selectedColor: Theme.textSecondary
    property bool updatingChannels: false
    property string pendingColorModel: ""
    property int redValue: 232
    property int greenValue: 235
    property int blueValue: 239
    property int cyanValue: 3
    property int magentaValue: 2
    property int yellowValue: 0
    property int blackValue: 6
    property var paletteColors: [
        "#E8EBEF", "#B6BBC4", "#839BAB", "#83AFC4",
        "#82A997", "#A89B7D", "#D3A36A", "#C47D7D",
        "#B58BC7", "#7899C6", "#6FA8A2", "#D0C487"
    ]
    signal interactionStarted()
    signal applyRequested(color colorValue)

    function clampChannel(value, maximum, fallback) {
        const number = Number(value)
        if (!isFinite(number))
            return fallback
        return Math.max(0, Math.min(maximum, Math.round(number)))
    }

    function updateCmykFromRgb() {
        const red = redValue / 255
        const green = greenValue / 255
        const blue = blueValue / 255
        const black = 1 - Math.max(red, green, blue)
        blackValue = Math.round(black * 100)
        if (black >= 0.999999) {
            cyanValue = 0
            magentaValue = 0
            yellowValue = 0
            return
        }
        cyanValue = Math.round(((1 - red - black) / (1 - black)) * 100)
        magentaValue = Math.round(((1 - green - black) / (1 - black)) * 100)
        yellowValue = Math.round(((1 - blue - black) / (1 - black)) * 100)
    }

    function setFromRgb(red, green, blue) {
        updatingChannels = true
        redValue = clampChannel(red, 255, redValue)
        greenValue = clampChannel(green, 255, greenValue)
        blueValue = clampChannel(blue, 255, blueValue)
        updateCmykFromRgb()
        selectedColor = Qt.rgba(redValue / 255, greenValue / 255, blueValue / 255, 1)
        updatingChannels = false
        refreshEditorTexts()
    }

    function setFromCmyk(cyan, magenta, yellow, black) {
        updatingChannels = true
        cyanValue = clampChannel(cyan, 100, cyanValue)
        magentaValue = clampChannel(magenta, 100, magentaValue)
        yellowValue = clampChannel(yellow, 100, yellowValue)
        blackValue = clampChannel(black, 100, blackValue)
        redValue = Math.round(255 * (1 - cyanValue / 100) * (1 - blackValue / 100))
        greenValue = Math.round(255 * (1 - magentaValue / 100) * (1 - blackValue / 100))
        blueValue = Math.round(255 * (1 - yellowValue / 100) * (1 - blackValue / 100))
        selectedColor = Qt.rgba(redValue / 255, greenValue / 255, blueValue / 255, 1)
        updatingChannels = false
        refreshEditorTexts()
    }

    function synchronizeFromSelectedColor() {
        if (updatingChannels)
            return
        setFromRgb(Math.round(selectedColor.r * 255),
                   Math.round(selectedColor.g * 255),
                   Math.round(selectedColor.b * 255))
    }

    function commitRgbChannel(channelIndex, value) {
        if (channelIndex === 0)
            setFromRgb(value, greenValue, blueValue)
        else if (channelIndex === 1)
            setFromRgb(redValue, value, blueValue)
        else
            setFromRgb(redValue, greenValue, value)
    }

    function commitCmykChannel(channelIndex, value) {
        if (channelIndex === 0)
            setFromCmyk(value, magentaValue, yellowValue, blackValue)
        else if (channelIndex === 1)
            setFromCmyk(cyanValue, value, yellowValue, blackValue)
        else if (channelIndex === 2)
            setFromCmyk(cyanValue, magentaValue, value, blackValue)
        else
            setFromCmyk(cyanValue, magentaValue, yellowValue, value)
    }

    function channelEditorModel(mode) {
        if (mode === "rgb") {
            return [
                { "label": "R", "value": redValue, "maximum": 255 },
                { "label": "G", "value": greenValue, "maximum": 255 },
                { "label": "B", "value": blueValue, "maximum": 255 }
            ]
        }
        return [
            { "label": "C", "value": cyanValue, "maximum": 100 },
            { "label": "M", "value": magentaValue, "maximum": 100 },
            { "label": "Y", "value": yellowValue, "maximum": 100 },
            { "label": "K", "value": blackValue, "maximum": 100 }
        ]
    }

    function editorValue(repeater, index, fallback) {
        const editor = repeater.itemAt(index)
        return editor ? editor.editorText : fallback
    }

    function refreshEditorTexts() {
        const rgbValues = [redValue, greenValue, blueValue]
        const cmykValues = [cyanValue, magentaValue, yellowValue, blackValue]
        for (let index = 0; index < rgbValues.length; ++index) {
            const editor = rgbRepeater.itemAt(index)
            if (editor)
                editor.editorText = String(rgbValues[index])
        }
        for (let index = 0; index < cmykValues.length; ++index) {
            const editor = cmykRepeater.itemAt(index)
            if (editor)
                editor.editorText = String(cmykValues[index])
        }
    }

    function commitPendingChannels() {
        if (pendingColorModel === "rgb") {
            setFromRgb(editorValue(rgbRepeater, 0, redValue),
                       editorValue(rgbRepeater, 1, greenValue),
                       editorValue(rgbRepeater, 2, blueValue))
        } else if (pendingColorModel === "cmyk") {
            setFromCmyk(editorValue(cmykRepeater, 0, cyanValue),
                        editorValue(cmykRepeater, 1, magentaValue),
                        editorValue(cmykRepeater, 2, yellowValue),
                        editorValue(cmykRepeater, 3, blackValue))
        }
        pendingColorModel = ""
    }

    width: 296
    height: paletteContent.implicitHeight + topPadding + bottomPadding
    padding: Metrics.spacingSmall
    modal: false
    focus: false
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
    z: 500

    onSelectedColorChanged: synchronizeFromSelectedColor()
    Component.onCompleted: synchronizeFromSelectedColor()

    background: PopupGlassBackground {
        radius: Metrics.radiusMedium
        surfaceLevel: 2
    }

    contentItem: Column {
        id: paletteContent
        width: root.availableWidth
        spacing: Metrics.spacingSmall

        Item {
            width: parent.width
            height: 28

            Label {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("文字颜色")
                color: Theme.textPrimary
                font.family: Typography.family
                font.pixelSize: Typography.secondarySize
                font.weight: Typography.mediumWeight
            }

            Rectangle {
                anchors.right: closeButton.left
                anchors.rightMargin: Metrics.spacingSmall
                anchors.verticalCenter: parent.verticalCenter
                width: 16
                height: 16
                radius: width / 2
                color: root.selectedColor
                border.width: 1
                border.color: Theme.outlineStrong
            }

            RoundIconButton {
                id: closeButton
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 24
                height: 24
                iconText: ""
                iconSource: IconCatalog.close
                iconSize: 13
                chromeStyle: true
                focusPolicy: Qt.NoFocus
                helpText: qsTr("关闭调色盘")
                onPressed: root.interactionStarted()
                onClicked: root.close()
            }
        }

        Grid {
            width: parent.width
            columns: 6
            spacing: Metrics.spacingSmall

            Repeater {
                model: root.paletteColors

                delegate: Item {
                    id: colorSwatch
                    required property int index
                    required property var modelData
                    width: 26
                    height: 26
                    Accessible.role: Accessible.Button
                    Accessible.name: qsTr("选择颜色 %1").arg(modelData)

                    Rectangle {
                        anchors.centerIn: parent
                        width: 22
                        height: 22
                        radius: width / 2
                        color: colorSwatch.modelData
                        border.width: root.selectedColor.toString().toLowerCase()
                                      === String(colorSwatch.modelData).toLowerCase() ? 3 : 1
                        border.color: root.selectedColor.toString().toLowerCase()
                                      === String(colorSwatch.modelData).toLowerCase()
                                      ? Theme.accentStrong : Theme.outlineStrong
                    }

                    HoverHandler { id: swatchHover }
                    TapHandler {
                        onPressedChanged: {
                            if (pressed)
                                root.interactionStarted()
                        }
                        onTapped: {
                            root.pendingColorModel = ""
                            root.selectedColor = colorSwatch.modelData
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: "transparent"
                        border.width: swatchHover.hovered ? 1 : 0
                        border.color: Theme.focusRing
                    }
                }
            }
        }

        Label {
            text: qsTr("RGB")
            color: Theme.textSecondary
            font.family: Typography.family
            font.pixelSize: Typography.captionSize
            font.weight: Typography.mediumWeight
        }

        Row {
            width: parent.width
            spacing: Metrics.spacingSmall

            Repeater {
                id: rgbRepeater
                model: root.channelEditorModel("rgb")
                delegate: Row {
                    id: rgbChannel
                    required property int index
                    required property var modelData
                    property alias editorText: rgbField.text
                    width: (paletteContent.width - Metrics.spacingSmall * 2) / 3
                    spacing: Metrics.spacingTiny
                    height: 24

                    Label {
                        width: 16
                        height: parent.height
                        text: rgbChannel.modelData.label
                        color: Theme.textMuted
                        font.family: Typography.family
                        font.pixelSize: Typography.captionSize
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    TextField {
                        id: rgbField
                        width: parent.width - 16 - parent.spacing
                        height: parent.height
                        text: String(rgbChannel.modelData.value)
                        color: Theme.textPrimary
                        selectionColor: Theme.accent
                        selectedTextColor: Theme.windowBaseColor
                        horizontalAlignment: TextInput.AlignHCenter
                        verticalAlignment: TextInput.AlignVCenter
                        leftPadding: 2
                        rightPadding: 2
                        topPadding: 0
                        bottomPadding: 0
                        inputMethodHints: Qt.ImhDigitsOnly
                        validator: IntValidator { bottom: 0; top: rgbChannel.modelData.maximum }
                        background: GlassSurface {
                            radius: Metrics.radiusSmall
                            surfaceLevel: 0
                            interactive: parent.activeFocus
                        }
                        onActiveFocusChanged: {
                            if (activeFocus)
                                root.interactionStarted()
                        }
                        onTextEdited: root.pendingColorModel = "rgb"
                        onEditingFinished: {
                            root.commitRgbChannel(rgbChannel.index, text)
                            root.pendingColorModel = ""
                        }
                    }
                }
            }
        }

        Label {
            text: qsTr("CMYK（百分比）")
            color: Theme.textSecondary
            font.family: Typography.family
            font.pixelSize: Typography.captionSize
            font.weight: Typography.mediumWeight
        }

        Row {
            width: parent.width
            spacing: Metrics.spacingSmall

            Repeater {
                id: cmykRepeater
                model: root.channelEditorModel("cmyk")
                delegate: Row {
                    id: cmykChannel
                    required property int index
                    required property var modelData
                    property alias editorText: cmykField.text
                    width: (paletteContent.width - Metrics.spacingSmall * 3) / 4
                    spacing: Metrics.spacingTiny
                    height: 24

                    Label {
                        width: 14
                        height: parent.height
                        text: cmykChannel.modelData.label
                        color: Theme.textMuted
                        font.family: Typography.family
                        font.pixelSize: Typography.captionSize
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    TextField {
                        id: cmykField
                        width: parent.width - 14 - parent.spacing
                        height: parent.height
                        text: String(cmykChannel.modelData.value)
                        color: Theme.textPrimary
                        selectionColor: Theme.accent
                        selectedTextColor: Theme.windowBaseColor
                        horizontalAlignment: TextInput.AlignHCenter
                        verticalAlignment: TextInput.AlignVCenter
                        leftPadding: 1
                        rightPadding: 1
                        topPadding: 0
                        bottomPadding: 0
                        inputMethodHints: Qt.ImhDigitsOnly
                        validator: IntValidator { bottom: 0; top: 100 }
                        background: GlassSurface {
                            radius: Metrics.radiusSmall
                            surfaceLevel: 0
                            interactive: parent.activeFocus
                        }
                        onActiveFocusChanged: {
                            if (activeFocus)
                                root.interactionStarted()
                        }
                        onTextEdited: root.pendingColorModel = "cmyk"
                        onEditingFinished: {
                            root.commitCmykChannel(cmykChannel.index, text)
                            root.pendingColorModel = ""
                        }
                    }
                }
            }
        }

        Label {
            width: parent.width
            text: qsTr("调色盘会保持打开，可继续选择其他文字并应用颜色。")
            color: Theme.textMuted
            font.family: Typography.family
            font.pixelSize: Typography.captionSize
            wrapMode: Text.Wrap
        }

        Button {
            id: applyButton
            width: parent.width
            height: 30
            text: qsTr("应用到所选文字")
            hoverEnabled: true
            focusPolicy: Qt.NoFocus
            onPressed: root.interactionStarted()
            onClicked: {
                root.commitPendingChannels()
                root.applyRequested(root.selectedColor)
            }

            contentItem: Label {
                text: applyButton.text
                color: Theme.textPrimary
                font.family: Typography.family
                font.pixelSize: Typography.secondarySize
                font.weight: Typography.mediumWeight
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: GlassSurface {
                radius: Metrics.radiusSmall
                surfaceLevel: 1
                interactive: applyButton.hovered || applyButton.down
                border.color: applyButton.down ? Theme.focusRing : Theme.outlineStrong
            }
        }
    }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Motion.fastDuration }
            NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: Motion.fastDuration }
        }
    }
    exit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Motion.fastDuration }
            NumberAnimation { property: "scale"; from: 1; to: 0.96; duration: Motion.fastDuration }
        }
    }
}

import QtQuick
import QtQuick.Controls
import ToDoIt.Controllers 1.0

Item {
    id: root
    property alias text: noteInput.text
    property int savedSelectionStart: -1
    property int savedSelectionEnd: -1
    property bool toolbarPointerActive: false
    property bool applyingFormat: false
    property int minimumTextHeight: 48
    readonly property bool editing: noteInput.activeFocus || colorPalette.visible
    signal noteEdited(string html)
    signal helpRequested(string message)
    implicitHeight: noteSurface.y + noteSurface.height

    function captureSelection() {
        const start = Math.min(noteInput.selectionStart, noteInput.selectionEnd)
        const end = Math.max(noteInput.selectionStart, noteInput.selectionEnd)
        if (end <= start)
            return false
        savedSelectionStart = start
        savedSelectionEnd = end
        return true
    }

    function clearSavedSelection() {
        savedSelectionStart = -1
        savedSelectionEnd = -1
    }

    function selectedRangeIsValid() {
        return savedSelectionStart >= 0
            && savedSelectionEnd > savedSelectionStart
    }

    function beginToolbarInteraction() {
        captureSelection()
        toolbarPointerActive = true
    }

    function endToolbarInteraction() {
        Qt.callLater(function() { root.toolbarPointerActive = false })
    }

    function restoreSelection() {
        if (!selectedRangeIsValid())
            return
        noteInput.forceActiveFocus(Qt.OtherFocusReason)
        noteInput.select(savedSelectionStart, savedSelectionEnd)
    }

    function publishFormattedText() {
        Qt.callLater(function() {
            root.applyingFormat = false
            root.noteEdited(noteInput.text)
        })
    }

    function toggleSelectedBold() {
        captureSelection()
        if (!selectedRangeIsValid()) {
            helpRequested(qsTr("请先选择需要加粗的备注文字"))
            return
        }
        const start = savedSelectionStart
        const end = savedSelectionEnd
        applyingFormat = true
        if (!RichTextFormatter.toggleBold(noteInput.textDocument, start, end)) {
            applyingFormat = false
            helpRequested(qsTr("无法设置所选文字的加粗格式"))
            return
        }
        restoreSelection()
        publishFormattedText()
    }

    function showColorPalette() {
        captureSelection()
        colorPalette.open()
    }

    function applySelectedColor(color) {
        captureSelection()
        if (!selectedRangeIsValid()) {
            helpRequested(qsTr("请先在备注中选择需要设置颜色的文字"))
            return
        }
        applyingFormat = true
        if (!RichTextFormatter.applyColor(noteInput.textDocument,
                                          savedSelectionStart,
                                          savedSelectionEnd,
                                          color)) {
            applyingFormat = false
            helpRequested(qsTr("无法设置所选文字的颜色"))
            return
        }
        restoreSelection()
        publishFormattedText()
    }

    Row {
        id: noteToolbar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 28

        Label {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("备注 · 富文本")
            color: Theme.textSecondary
            font.family: Typography.family
            font.pixelSize: Typography.captionSize
            font.weight: Typography.mediumWeight
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Metrics.spacingTiny

            Button {
                width: 28
                height: 24
                text: "B"
                focusPolicy: Qt.NoFocus
                onPressedChanged: {
                    if (pressed)
                        root.beginToolbarInteraction()
                    else
                        root.endToolbarInteraction()
                }
                onClicked: root.toggleSelectedBold()
                contentItem: Label {
                    text: "B"
                    color: Theme.textPrimary
                    font.family: Typography.family
                    font.pixelSize: Typography.secondarySize
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: GlassSurface {
                    radius: Metrics.radiusSmall
                    surfaceLevel: 0
                    interactive: parent.hovered
                }
            }

            RoundIconButton {
                width: 28
                height: 24
                iconSource: IconCatalog.palette
                iconSize: 17
                focusPolicy: Qt.NoFocus
                helpText: qsTr("打开文字调色盘")
                onPressedChanged: {
                    if (pressed)
                        root.beginToolbarInteraction()
                    else
                        root.endToolbarInteraction()
                }
                onClicked: root.showColorPalette()
            }
        }
    }

    GlassSurface {
        id: noteSurface
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: noteToolbar.bottom
        anchors.topMargin: Metrics.spacingTiny
        height: Math.max(root.minimumTextHeight,
                         noteInput.contentHeight + noteInput.topPadding
                         + noteInput.bottomPadding + 2)
        radius: Metrics.radiusSmall
        surfaceLevel: 0
        interactive: noteInput.activeFocus || noteHover.hovered
    }

    TextArea {
        id: noteInput
        anchors.fill: noteSurface
        anchors.margins: 1
        padding: Metrics.spacingSmall
        wrapMode: TextEdit.Wrap
        textFormat: TextEdit.RichText
        color: Theme.textSecondary
        placeholderText: qsTr("在此输入备注；可设置加粗和文字颜色……")
        placeholderTextColor: Theme.textMuted
        selectionColor: Theme.accent
        selectedTextColor: Theme.windowBaseColor
        font.family: Typography.family
        font.pixelSize: Typography.secondarySize
        background: Item {}
        onTextChanged: {
            if (activeFocus && !root.applyingFormat) {
                root.clearSavedSelection()
                root.noteEdited(text)
            }
        }
        onSelectionStartChanged: selectionCaptureTimer.restart()
        onSelectionEndChanged: selectionCaptureTimer.restart()
    }

    Timer {
        id: selectionCaptureTimer
        interval: 0
        onTriggered: {
            if (noteInput.selectionStart !== noteInput.selectionEnd) {
                root.captureSelection()
            } else if (noteInput.activeFocus && !root.toolbarPointerActive) {
                root.clearSavedSelection()
            }
        }
    }

    ColorPalettePopup {
        id: colorPalette
        x: Math.max(0, root.width - width)
        y: noteToolbar.height + Metrics.spacingTiny
        selectedColor: Theme.textSecondary
        onInteractionStarted: root.captureSelection()
        onApplyRequested: function(color) { root.applySelectedColor(color) }
        onClosed: {
            noteInput.focus = false
            root.clearSavedSelection()
        }
    }

    HoverHandler {
        id: noteHover
        target: noteSurface
    }
}

import QtQuick
import QtQuick.Controls
import QtCore
import Qt.labs.folderlistmodel

Popup {
    id: root

    property var selectedEntries: []
    property bool committed: false
    signal selectionAccepted(var entries)
    signal selectionCancelled()

    parent: Overlay.overlay
    width: Math.min(720, parent ? parent.width - 48 : 720)
    height: Math.min(520, parent ? parent.height - 48 : 520)
    x: parent ? Math.round((parent.width - width) / 2) : 0
    y: parent ? Math.round((parent.height - height) / 2) : 0
    padding: Metrics.spacingMedium
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    function localPathToUrl(path) {
        const normalized = String(path).replace(/\\/g, "/")
        if (/^file:\/\//i.test(normalized))
            return normalized
        return /^[A-Za-z]:/.test(normalized)
            ? "file:///" + normalized : "file://" + normalized
    }

    function defaultFolderUrl() {
        return localPathToUrl(StandardPaths.writableLocation(StandardPaths.DocumentsLocation))
    }

    function displayPath(url) {
        let text = decodeURIComponent(String(url))
        if (/^file:\/\/\/[a-z]:/i.test(text))
            text = text.substring(8)
        else if (/^file:\/\//i.test(text))
            text = "//" + text.substring(7)
        return text.replace(/\//g, "\\")
    }

    function entryIndex(url) {
        const value = String(url)
        for (let index = 0; index < selectedEntries.length; ++index) {
            if (selectedEntries[index].url === value)
                return index
        }
        return -1
    }

    function isSelected(url) {
        return entryIndex(url) >= 0
    }

    function toggleSelection(url, isFolder) {
        const value = String(url)
        const entries = selectedEntries.slice()
        const index = entryIndex(value)
        if (index >= 0)
            entries.splice(index, 1)
        else
            entries.push({ "url": value, "isFolder": Boolean(isFolder) })
        selectedEntries = entries
    }

    function enterFolder(url) {
        selectedEntries = []
        browserModel.folder = url
    }

    function beginSelection() {
        committed = false
        selectedEntries = []
        if (!String(browserModel.folder).length)
            browserModel.folder = defaultFolderUrl()
        open()
    }

    function commitSelection() {
        let entries = selectedEntries.slice()
        if (entries.length === 0) {
            entries = [{
                "url": String(browserModel.folder),
                "isFolder": true
            }]
        }
        committed = true
        selectionAccepted(entries)
        close()
    }

    onClosed: {
        if (!committed)
            selectionCancelled()
        selectedEntries = []
    }

    background: PopupGlassBackground {
        radius: Metrics.radiusLarge
        surfaceLevel: 2
    }

    Overlay.modal: Rectangle {
        color: Qt.rgba(0.01, 0.015, 0.025, 0.52)
    }

    FolderListModel {
        id: browserModel
        folder: root.defaultFolderUrl()
        showDirs: true
        showFiles: true
        showDotAndDotDot: false
        showHidden: false
        showOnlyReadable: true
        nameFilters: ["*"]
        sortField: FolderListModel.Name
    }

    contentItem: Column {
        spacing: Metrics.spacingSmall

        Row {
            width: parent.width
            height: 34
            spacing: Metrics.spacingSmall

            RoundIconButton {
                width: 34
                height: 34
                iconSource: IconCatalog.chevronDown
                rotation: 90
                iconSize: 14
                helpText: qsTr("返回上一级目录")
                enabled: String(browserModel.parentFolder).length > 0
                onClicked: root.enterFolder(browserModel.parentFolder)
            }

            TextField {
                width: parent.width - 34 - parent.spacing
                height: 34
                readOnly: true
                selectByMouse: true
                text: root.displayPath(browserModel.folder)
                color: Theme.textSecondary
                selectionColor: Theme.accent
                selectedTextColor: Theme.windowBaseColor
                leftPadding: Metrics.spacingSmall
                rightPadding: Metrics.spacingSmall
                verticalAlignment: TextInput.AlignVCenter
                font.family: Typography.family
                font.pixelSize: Typography.secondarySize
                background: GlassSurface {
                    radius: Metrics.radiusSmall
                    surfaceLevel: 0
                }
            }
        }

        GlassSurface {
            width: parent.width
            height: parent.height - 34 - actionRow.height
                    - parent.spacing * 2
            radius: Metrics.radiusMedium
            surfaceLevel: 0

            ListView {
                id: entryList
                anchors.fill: parent
                anchors.margins: 1
                clip: true
                model: browserModel
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar {}

                delegate: Item {
                    id: entryDelegate
                    required property string fileName
                    required property url fileUrl
                    required property bool fileIsDir

                    width: entryList.width
                    height: 38
                    readonly property bool selected: root.isSelected(fileUrl)

                    GlassSurface {
                        anchors.fill: parent
                        anchors.leftMargin: Metrics.spacingTiny
                        anchors.rightMargin: Metrics.spacingTiny
                        radius: Metrics.radiusSmall
                        surfaceLevel: 0
                        interactive: entryHover.hovered || entryDelegate.selected
                        border.color: entryDelegate.selected
                            ? Theme.focusRing : (entryHover.hovered ? Theme.outlineStrong : "transparent")
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: Metrics.spacingSmall
                        anchors.rightMargin: Metrics.spacingSmall
                        spacing: Metrics.spacingSmall

                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 22
                            height: 22

                            IconImage {
                                anchors.fill: parent
                                visible: entryDelegate.fileIsDir
                                source: IconCatalog.folder
                                accessibleName: qsTr("文件夹")
                            }

                            Label {
                                anchors.fill: parent
                                visible: !entryDelegate.fileIsDir
                                text: {
                                    const dot = entryDelegate.fileName.lastIndexOf(".")
                                    return dot >= 0
                                        ? entryDelegate.fileName.substring(dot + 1).toUpperCase().substring(0, 4)
                                        : qsTr("文件")
                                }
                                color: Theme.textMuted
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.family: Typography.family
                                font.pixelSize: 8
                                font.weight: Typography.mediumWeight
                            }
                        }

                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 22 - selectionMark.width
                                   - parent.spacing * 2
                            text: entryDelegate.fileName
                            color: Theme.textPrimary
                            elide: Text.ElideMiddle
                            font.family: Typography.family
                            font.pixelSize: Typography.bodySize
                        }

                        Rectangle {
                            id: selectionMark
                            anchors.verticalCenter: parent.verticalCenter
                            width: 18
                            height: 18
                            radius: 5
                            color: entryDelegate.selected ? Theme.accent : "transparent"
                            border.width: 1
                            border.color: entryDelegate.selected
                                ? Theme.accentStrong : Theme.outlineStrong

                            Label {
                                anchors.centerIn: parent
                                visible: entryDelegate.selected
                                text: "✓"
                                color: Theme.windowBaseColor
                                font.family: Typography.family
                                font.pixelSize: Typography.secondarySize
                                font.weight: Typography.strongWeight
                            }
                        }
                    }

                    HoverHandler { id: entryHover }
                    TapHandler {
                        acceptedButtons: Qt.LeftButton
                        onSingleTapped: root.toggleSelection(entryDelegate.fileUrl,
                                                             entryDelegate.fileIsDir)
                        onDoubleTapped: {
                            if (entryDelegate.fileIsDir)
                                root.enterFolder(entryDelegate.fileUrl)
                        }
                    }
                }

                Label {
                    anchors.centerIn: parent
                    visible: browserModel.status === FolderListModel.Ready
                             && browserModel.count === 0
                    text: qsTr("此文件夹为空")
                    color: Theme.textMuted
                    font.family: Typography.family
                    font.pixelSize: Typography.bodySize
                }
            }
        }

        Row {
            id: actionRow
            width: parent.width
            height: 38
            spacing: Metrics.spacingSmall

            Label {
                width: parent.width - cancelButton.width - addButton.width
                       - parent.spacing * 2
                anchors.verticalCenter: parent.verticalCenter
                text: root.selectedEntries.length > 0
                    ? qsTr("已选择 %1 项；双击文件夹可进入").arg(root.selectedEntries.length)
                    : qsTr("未选择条目时，添加当前文件夹")
                color: Theme.textMuted
                font.family: Typography.family
                font.pixelSize: Typography.secondarySize
                elide: Text.ElideRight
            }

            Button {
                id: cancelButton
                width: 72
                height: 34
                text: qsTr("取消")
                onClicked: root.close()
                contentItem: Label {
                    text: cancelButton.text
                    color: Theme.textSecondary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: Typography.family
                    font.pixelSize: Typography.secondarySize
                }
                background: GlassSurface {
                    radius: Metrics.radiusSmall
                    surfaceLevel: 0
                    interactive: cancelButton.hovered || cancelButton.down
                }
            }

            Button {
                id: addButton
                width: 72
                height: 34
                text: qsTr("添加")
                onClicked: root.commitSelection()
                contentItem: Label {
                    text: addButton.text
                    color: Theme.textPrimary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: Typography.family
                    font.pixelSize: Typography.secondarySize
                    font.weight: Typography.mediumWeight
                }
                background: GlassSurface {
                    radius: Metrics.radiusSmall
                    surfaceLevel: 1
                    interactive: addButton.hovered || addButton.down
                    border.color: Theme.focusRing
                }
            }
        }
    }
}

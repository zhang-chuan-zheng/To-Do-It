import QtQuick
import QtQuick.Controls

Item {
    id: root
    property var attachmentKinds: []
    signal addRequested()
    signal removeRequested(int index)
    signal openRequested(int index)
    implicitHeight: Metrics.attachmentTileSize

    function displayPath(value) {
        let text = String(value)
        if (text.indexOf("/") < 0 && text.indexOf("\\") < 0)
            return qsTr("示例附件.%1").arg(text.toLowerCase())
        if (/^file:\/\/\/[a-z]:/i.test(text)) {
            text = text.substring(8)
        } else if (/^file:\/\//i.test(text)) {
            text = "//" + text.substring(7)
        }
        return decodeURIComponent(text).replace(/\//g, "\\")
    }

    function displayKind(value) {
        if (isFolderAttachment(value))
            return qsTr("文件夹")
        const path = displayPath(value)
        const dotIndex = path.lastIndexOf(".")
        if (dotIndex < 0 || dotIndex === path.length - 1)
            return "FILE"
        return path.substring(dotIndex + 1).toUpperCase().substring(0, 4)
    }

    function isFolderAttachment(value) {
        const text = String(value)
        return text.endsWith("/") || text.endsWith("\\")
    }

    Row {
        anchors.left: parent.left
        anchors.top: parent.top
        spacing: Metrics.spacingTiny

        Label {
            width: 34
            height: Metrics.attachmentTileSize
            text: qsTr("附件")
            color: Theme.textSecondary
            font.family: Typography.family
            font.pixelSize: Typography.bodySize
            font.weight: Typography.mediumWeight
            topPadding: 1
            verticalAlignment: Text.AlignTop
        }

        Repeater {
            model: root.attachmentKinds
            delegate: Button {
                id: attachmentTile
                required property int index
                required property var modelData
                width: Metrics.attachmentTileSize
                height: Metrics.attachmentTileSize
                hoverEnabled: true
                text: root.displayKind(modelData)

                contentItem: Item {
                    IconImage {
                        visible: root.isFolderAttachment(attachmentTile.modelData)
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        source: IconCatalog.folder
                        accessibleName: qsTr("文件夹附件")
                    }
                    Label {
                        visible: !root.isFolderAttachment(attachmentTile.modelData)
                        anchors.fill: parent
                        text: attachmentTile.text
                        color: Theme.textSecondary
                        font.family: Typography.family
                        font.pixelSize: 8
                        font.weight: Typography.mediumWeight
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                background: GlassSurface {
                    radius: Metrics.radiusSmall
                    surfaceLevel: 1
                    interactive: attachmentTile.hovered
                }
                GlassToolTip {
                    visible: attachmentTile.hovered
                    text: root.displayPath(attachmentTile.modelData)
                }
                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onDoubleTapped: root.openRequested(attachmentTile.index)
                }

                RoundIconButton {
                    visible: attachmentTile.hovered
                    anchors.right: parent.right
                    anchors.top: parent.top
                    width: 13
                    height: 13
                    iconText: ""
                    iconSource: IconCatalog.close
                    destructive: true
                    helpText: qsTr("解除附件关联")
                    onClicked: root.removeRequested(attachmentTile.index)
                }
            }
        }

        RoundIconButton {
            id: addButton
            width: Metrics.attachmentTileSize
            height: Metrics.attachmentTileSize
            iconText: ""
            iconSource: IconCatalog.attachmentAdd
            iconSize: 24
            helpText: qsTr("添加文件或文件夹附件")
            onClicked: root.addRequested()
        }
    }
}

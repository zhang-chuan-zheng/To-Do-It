import QtQuick
import QtQuick.Controls

GlassPanel {
    id: root
    property string quote: qsTr("专注当下，完成重要的事。")
    property string author: qsTr("To Do It")
    signal refreshRequested()
    signal helpRequested(string message)
    surfaceLevel: 0
    panelRadius: Metrics.radiusSmall
    contentPadding: Metrics.spacingMedium

    Label {
        anchors.fill: parent
        text: root.quote + "  — " + root.author
        color: Theme.textSecondary
        elide: Text.ElideRight
        font.family: Typography.family
        font.pixelSize: Typography.bodySize
        font.weight: Typography.mediumWeight
        fontSizeMode: Text.HorizontalFit
        minimumPixelSize: 1
        verticalAlignment: Text.AlignVCenter
    }

    HoverHandler {
        onHoveredChanged: root.helpRequested(hovered ? qsTr("双击可换一句本地哲学名言") : "")
    }
    TapHandler {
        acceptedButtons: Qt.LeftButton
        onDoubleTapped: root.refreshRequested()
    }
}

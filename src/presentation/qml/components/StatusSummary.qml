import QtQuick
import QtQuick.Controls

GlassPanel {
    id: root
    property int pendingCount: 0
    property int completedCount: 0
    implicitWidth: 208
    implicitHeight: 32
    surfaceLevel: 0
    panelRadius: Metrics.radiusSmall
    contentPadding: Metrics.spacingSmall

    Label {
        anchors.fill: parent
        text: qsTr("%1 项待完成 · %2 项已完成")
            .arg(root.pendingCount).arg(root.completedCount)
        color: Theme.textPrimary
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.family: Typography.family
        font.pixelSize: Typography.bodySize
        font.weight: Typography.mediumWeight
    }
}

import QtQuick
import QtQuick.Controls

GlassPanel {
    id: root
    property string label: qsTr("已完成")
    property int matchedCount: 0
    property int totalCount: 0
    readonly property int percentage: totalCount > 0 ? Math.round(matchedCount * 100 / totalCount) : 0
    implicitWidth: 166
    implicitHeight: 34
    surfaceLevel: 0
    panelRadius: Metrics.radiusSmall
    contentPadding: Metrics.spacingSmall

    Label {
        anchors.fill: parent
        text: qsTr("%1 %2 项 · %3%").arg(root.label).arg(root.matchedCount).arg(root.percentage)
        color: Theme.textPrimary
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.family: Typography.family
        font.pixelSize: Typography.bodySize
        font.weight: Typography.mediumWeight
    }
}

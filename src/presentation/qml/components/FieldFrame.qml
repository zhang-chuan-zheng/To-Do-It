import QtQuick

Item {
    id: root
    default property alias contentData: content.data
    property real contentPadding: Metrics.spacingSmall
    property bool highlighted: false
    property color fillColor: highlighted ? Theme.surfaceHover : Theme.surfaceLow

    GlassSurface {
        anchors.fill: parent
        radius: Metrics.radiusSmall
        surfaceLevel: 0
        interactive: root.highlighted
        fillColor: root.fillColor
        border.color: root.highlighted ? Theme.outlineStrong : Theme.fieldOutline
    }

    Item {
        id: content
        anchors.fill: parent
        anchors.margins: root.contentPadding
    }
}

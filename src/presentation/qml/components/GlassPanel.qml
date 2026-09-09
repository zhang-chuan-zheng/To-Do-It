import QtQuick

Item {
    id: root
    default property alias contentData: content.data
    property int surfaceLevel: 1
    property real panelRadius: Metrics.radiusMedium
    property real contentPadding: Metrics.panelPadding
    property bool interactive: false

    GlassSurface {
        anchors.fill: parent
        surfaceLevel: root.surfaceLevel
        radius: root.panelRadius
        interactive: root.interactive
    }

    Item {
        id: content
        anchors.fill: parent
        anchors.margins: root.contentPadding
    }
}



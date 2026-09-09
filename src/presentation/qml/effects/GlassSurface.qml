import QtQuick

Rectangle {
    id: surface
    property int surfaceLevel: 1
    property bool interactive: false
    property color fillColor: interactive ? Theme.surfaceHover : Theme.surfaceColor(surfaceLevel)
    radius: Metrics.radiusMedium
    color: fillColor
    border.width: 1
    border.color: interactive ? Theme.outlineStrong : Theme.outline
    antialiasing: true

    Behavior on fillColor { ColorAnimation { duration: Motion.fastDuration } }
    Behavior on border.color { ColorAnimation { duration: Motion.fastDuration } }
}


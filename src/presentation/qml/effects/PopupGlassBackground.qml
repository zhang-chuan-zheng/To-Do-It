import QtQuick
import QtQuick.Effects
import QtQuick.Window

Rectangle {
    id: surface

    property int surfaceLevel: 2
    property real blurAmount: 0.72
    readonly property Item backdropSource: surface.Window.window
        ? surface.Window.window["popupBackdropSource"] : null

    radius: Metrics.radiusSmall
    color: "transparent"
    clip: true
    antialiasing: true

    ShaderEffectSource {
        id: backdropSnapshot

        anchors.fill: parent
        sourceItem: surface.backdropSource
        sourceRect: {
            if (!surface.backdropSource)
                return Qt.rect(0, 0, 0, 0)
            const origin = surface.mapToItem(surface.backdropSource, 0, 0)
            return Qt.rect(origin.x, origin.y, surface.width, surface.height)
        }
        live: surface.visible
        recursive: false
        smooth: true
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: backdropSnapshot
        visible: surface.backdropSource !== null
        blurEnabled: true
        blur: surface.blurAmount
        blurMax: 32
        autoPaddingEnabled: false
    }

    Rectangle {
        anchors.fill: parent
        radius: surface.radius
        color: Theme.windowBaseColor
        opacity: 0.84
    }

    Rectangle {
        anchors.fill: parent
        radius: surface.radius
        color: Theme.surfaceColor(surface.surfaceLevel)
    }

    Rectangle {
        anchors.fill: parent
        radius: surface.radius
        color: "transparent"
        border.width: 1
        border.color: Theme.outlineStrong
    }
}

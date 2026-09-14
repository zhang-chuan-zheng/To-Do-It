import QtQuick
import QtQuick.Controls
import QtQuick.Effects

ApplicationWindow {
    id: window

    readonly property Item popupBackdropSource: mainPage

    width: Metrics.windowDefaultWidth
    height: Metrics.windowDefaultHeight
    minimumWidth: Metrics.windowMinimumWidth
    minimumHeight: Metrics.windowMinimumHeight
    visible: true
    flags: Qt.Window | Qt.FramelessWindowHint
    color: "transparent"
    title: qsTr("To Do It")
    onClosing: mainPage.flushPendingChanges()

    // Explicit solid fallback for this phase. Real Acrylic/DWM blur is added
    // later by the platform window-effects layer.
    background: Item {
        id: windowBackground

        // Rectangle.clip only clips to rectangular bounds and does not follow
        // Rectangle.radius. Render the base and ambient glows into one texture,
        // then mask that texture with the actual rounded window silhouette.
        Item {
            id: backgroundSource
            anchors.fill: parent
            visible: false
            layer.enabled: true

            Rectangle {
                anchors.fill: parent
                color: Theme.windowBaseColor
            }

            Rectangle {
                width: parent.width * 0.58
                height: parent.height * 0.72
                x: -width * 0.18
                y: -height * 0.28
                radius: width / 2
                color: Theme.ambientGlowPrimary
                opacity: Theme.ambientGlowOpacity
            }

            Rectangle {
                width: parent.width * 0.34
                height: parent.height * 0.52
                x: parent.width * 0.32
                y: -height * 0.32
                radius: width / 2
                color: Theme.ambientGlowTertiary
                opacity: Theme.ambientGlowOpacity * 0.7
            }

            Rectangle {
                width: parent.width * 0.45
                height: parent.height * 0.60
                x: parent.width - width * 0.72
                y: parent.height - height * 0.60
                radius: width / 2
                color: Theme.ambientGlowSecondary
                opacity: Theme.ambientGlowOpacity
            }
        }

        Rectangle {
            id: roundedWindowMask
            anchors.fill: parent
            radius: Metrics.radiusLarge
            color: "white"
            visible: false
            antialiasing: true
            layer.enabled: true
        }

        MultiEffect {
            anchors.fill: parent
            source: backgroundSource
            maskEnabled: true
            maskSource: roundedWindowMask
            autoPaddingEnabled: false
        }
    }

    MainPage {
        id: mainPage
        anchors.fill: parent
        hostWindow: window
    }

    WindowResizeHandles {
        hostWindow: window
    }
}

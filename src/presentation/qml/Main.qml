import QtQuick
import QtQuick.Controls

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
    background: Rectangle {
        color: Theme.windowBaseColor
        radius: Metrics.radiusLarge
        clip: true

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

    MainPage {
        id: mainPage
        anchors.fill: parent
        hostWindow: window
    }

    WindowResizeHandles {
        hostWindow: window
    }
}

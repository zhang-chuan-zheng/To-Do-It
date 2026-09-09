import QtQuick
import QtQuick.Controls

Button {
    id: root
    property string iconText: "•"
    property url iconSource
    property int iconSize: 16
    property string helpText: ""
    property bool destructive: false
    property bool chromeStyle: false
    signal helpVisibilityChanged(string message, bool visible)

    implicitWidth: Metrics.iconButton
    implicitHeight: Metrics.iconButton
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    Accessible.name: helpText

    contentItem: Item {
        IconImage {
            anchors.centerIn: parent
            width: Math.min(root.iconSize, parent.width - 6)
            height: width
            source: root.iconSource
            fallbackText: root.iconText
            fallbackColor: root.destructive && root.hovered ? "white" : Theme.textPrimary
            accessibleName: root.helpText
        }
    }

    background: GlassSurface {
        radius: Metrics.radiusSmall
        surfaceLevel: 0
        interactive: root.hovered || root.down || root.visualFocus
        fillColor: root.destructive && (root.hovered || root.down)
                   ? Theme.dangerSurface
                   : (interactive ? Theme.surfaceHover
                                  : (root.chromeStyle ? "transparent" : Theme.surfaceLow))
        border.color: root.visualFocus ? Theme.focusRing
                                      : (interactive ? Theme.outlineStrong
                                                     : (root.chromeStyle ? "transparent" : Theme.outline))
    }

    ToolTip.visible: hovered && helpText.length > 0
    ToolTip.text: helpText
    ToolTip.delay: 450
    onHoveredChanged: helpVisibilityChanged(helpText, hovered)
}

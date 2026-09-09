import QtQuick

Item {
    id: root
    property url source
    property string accessibleName: ""
    property string fallbackText: ""
    property color fallbackColor: Theme.textSecondary
    readonly property bool loaded: icon.status === Image.Ready
    Accessible.name: accessibleName

    Image {
        id: icon
        anchors.fill: parent
        source: root.source
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
    }

    Text {
        anchors.centerIn: parent
        visible: !root.loaded && root.fallbackText.length > 0
        text: root.fallbackText
        color: root.fallbackColor
        font.family: Typography.family
        font.pixelSize: Math.max(9, Math.min(parent.width, parent.height) * 0.56)
    }
}

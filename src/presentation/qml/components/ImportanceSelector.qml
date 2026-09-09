import QtQuick

FieldFrame {
    id: root
    property int levelIndex: 3
    signal levelRequested(int levelIndex)
    contentPadding: 5

    Row {
        anchors.fill: parent
        spacing: 2

        Repeater {
            model: 5
            delegate: Rectangle {
                id: segment
                required property int index
                width: (parent.width - parent.spacing * 4) / 5
                height: parent.height
                radius: height / 2
                color: index < root.levelIndex ? Theme.importanceColor(index) : Theme.importanceInactive
                opacity: index < root.levelIndex ? 0.96 : 0.72

                TapHandler {
                    onTapped: {
                        root.levelIndex = segment.index + 1
                        root.levelRequested(root.levelIndex)
                    }
                }
            }
        }
    }
}

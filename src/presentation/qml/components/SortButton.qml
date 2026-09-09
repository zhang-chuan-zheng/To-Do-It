import QtQuick
import QtQuick.Controls

Item {
    id: root
    property string direction: "none"
    signal directionRequested(string direction)
    implicitWidth: 16
    implicitHeight: 22

    Column {
        anchors.centerIn: parent
        spacing: 0

        Item {
            width: 14
            height: 11
            Rectangle {
                anchors.centerIn: parent
                width: 11
                height: 11
                radius: width / 2
                color: Theme.accent
                opacity: root.direction === "ascending" ? 0.34 : 0
                border.width: root.direction === "ascending" ? 1 : 0
                border.color: Theme.accentStrong
            }
            IconImage {
                anchors.centerIn: parent
                width: 8
                height: 8
                source: IconCatalog.sortUp
                opacity: root.direction === "ascending" ? 1 : 0.34
            }
            TapHandler {
                onTapped: root.directionRequested(root.direction === "ascending" ? "none" : "ascending")
            }
        }

        Item {
            width: 14
            height: 11
            Rectangle {
                anchors.centerIn: parent
                width: 11
                height: 11
                radius: width / 2
                color: Theme.accent
                opacity: root.direction === "descending" ? 0.34 : 0
                border.width: root.direction === "descending" ? 1 : 0
                border.color: Theme.accentStrong
            }
            IconImage {
                anchors.centerIn: parent
                width: 8
                height: 8
                source: IconCatalog.sortDown
                opacity: root.direction === "descending" ? 1 : 0.34
            }
            TapHandler {
                onTapped: root.directionRequested(root.direction === "descending" ? "none" : "descending")
            }
        }
    }
}

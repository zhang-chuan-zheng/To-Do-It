import QtQuick
import QtQuick.Controls

Item {
    id: root
    property var sortDirections: ({})
    signal sortRequested(string field, string direction)

    function directionFor(field) { return sortDirections[field] || "none" }

    readonly property real fixedWidth: Metrics.sequenceColumnWidth + Metrics.importanceColumnWidth
        + Metrics.dateColumnWidth * 2 + Metrics.statusColumnWidth + Metrics.durationColumnWidth
    readonly property real titleWidth: Math.max(Metrics.titleColumnMinimumWidth,
        width - Metrics.eventOuterPadding * 2 - Metrics.scrollBarGutter
        - fixedWidth - Metrics.eventFieldGap * 6)

    component HeaderCell: Item {
        id: cell
        property string title
        property string sortField
        property string sortDirection: "none"
        property bool showTrailingSeparator: true
        property bool sortable: sortField.length > 0
        signal requested(string field, string direction)

        Rectangle {
            visible: cell.showTrailingSeparator
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: Math.round(parent.height * 0.48)
            color: Theme.outlineStrong
            opacity: 0.55
        }

        Row {
            anchors.centerIn: parent
            spacing: 2

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: cell.title
                color: Theme.textPrimary
                font.family: Typography.family
                font.pixelSize: Typography.bodySize
                font.weight: Typography.mediumWeight
            }

            SortButton {
                visible: cell.sortable
                anchors.verticalCenter: parent.verticalCenter
                width: 16
                height: 22
                direction: cell.sortDirection
                onDirectionRequested: function(direction) {
                    cell.requested(cell.sortField, direction)
                }
            }
        }
    }

    Row {
        x: Metrics.eventOuterPadding
        width: parent.width - Metrics.eventOuterPadding * 2 - Metrics.scrollBarGutter
        height: parent.height
        spacing: Metrics.eventFieldGap

        HeaderCell { width: Metrics.sequenceColumnWidth; height: parent.height; title: qsTr("序号") }
        HeaderCell {
            width: root.titleWidth; height: parent.height; title: qsTr("事项名称"); sortField: "titleText"
            sortDirection: root.directionFor(sortField)
            onRequested: function(field, direction) { root.sortRequested(field, direction) }
        }
        HeaderCell {
            width: Metrics.importanceColumnWidth; height: parent.height; title: qsTr("重要程度"); sortField: "importance"
            sortDirection: root.directionFor(sortField)
            onRequested: function(field, direction) { root.sortRequested(field, direction) }
        }
        HeaderCell {
            width: Metrics.dateColumnWidth; height: parent.height; title: qsTr("开始时间"); sortField: "startAt"
            sortDirection: root.directionFor(sortField)
            onRequested: function(field, direction) { root.sortRequested(field, direction) }
        }
        HeaderCell {
            width: Metrics.dateColumnWidth; height: parent.height; title: qsTr("完成时间"); sortField: "completedAt"
            sortDirection: root.directionFor(sortField)
            onRequested: function(field, direction) { root.sortRequested(field, direction) }
        }
        HeaderCell { width: Metrics.statusColumnWidth; height: parent.height; title: qsTr("项目状态") }
        HeaderCell {
            width: Metrics.durationColumnWidth; height: parent.height; title: qsTr("持续时间"); sortField: "duration"
            showTrailingSeparator: false
            sortDirection: root.directionFor(sortField)
            onRequested: function(field, direction) { root.sortRequested(field, direction) }
        }
    }
}

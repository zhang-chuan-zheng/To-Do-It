import QtQuick

Item {
    id: root
    required property var hostWindow
    property int handleWidth: Metrics.windowResizeHandleWidth
    readonly property bool resizeEnabled: hostWindow
        && hostWindow.visibility !== Window.Maximized
        && hostWindow.visibility !== Window.FullScreen

    anchors.fill: parent
    z: 1000

    function beginResize(edges) {
        if (resizeEnabled)
            hostWindow.startSystemResize(edges)
    }

    component ResizeHandle: MouseArea {
        property int resizeEdges: 0
        enabled: root.resizeEnabled
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        preventStealing: true
        onPressed: function(mouse) {
            root.beginResize(resizeEdges)
            mouse.accepted = true
        }
    }

    ResizeHandle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.handleWidth
        resizeEdges: Qt.LeftEdge
        cursorShape: Qt.SizeHorCursor
    }
    ResizeHandle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.handleWidth
        resizeEdges: Qt.RightEdge
        cursorShape: Qt.SizeHorCursor
    }
    ResizeHandle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.handleWidth
        resizeEdges: Qt.TopEdge
        cursorShape: Qt.SizeVerCursor
    }
    ResizeHandle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.handleWidth
        resizeEdges: Qt.BottomEdge
        cursorShape: Qt.SizeVerCursor
    }

    ResizeHandle {
        anchors.left: parent.left
        anchors.top: parent.top
        width: root.handleWidth * 2
        height: root.handleWidth * 2
        resizeEdges: Qt.LeftEdge | Qt.TopEdge
        cursorShape: Qt.SizeFDiagCursor
    }
    ResizeHandle {
        anchors.right: parent.right
        anchors.top: parent.top
        width: root.handleWidth * 2
        height: root.handleWidth * 2
        resizeEdges: Qt.RightEdge | Qt.TopEdge
        cursorShape: Qt.SizeBDiagCursor
    }
    ResizeHandle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: root.handleWidth * 2
        height: root.handleWidth * 2
        resizeEdges: Qt.LeftEdge | Qt.BottomEdge
        cursorShape: Qt.SizeBDiagCursor
    }
    ResizeHandle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: root.handleWidth * 2
        height: root.handleWidth * 2
        resizeEdges: Qt.RightEdge | Qt.BottomEdge
        cursorShape: Qt.SizeFDiagCursor
    }
}

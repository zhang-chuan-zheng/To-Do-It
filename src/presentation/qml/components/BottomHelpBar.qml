import QtQuick
import QtQuick.Controls

Item {
    id: root
    property string message: qsTr("将鼠标移到组件上可查看操作说明")
    property string severity: "info"
    readonly property color messageColor: severity === "error" ? Theme.danger
        : (severity === "warning" ? Theme.warning : Theme.textSecondary)
    TextField {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.message
        readOnly: true
        selectByMouse: true
        persistentSelection: true
        color: root.messageColor
        selectionColor: Theme.accent
        selectedTextColor: Theme.windowBaseColor
        leftPadding: 0
        rightPadding: 0
        topPadding: 0
        bottomPadding: 0
        verticalAlignment: TextInput.AlignVCenter
        font.family: Typography.family
        font.pixelSize: Typography.captionSize
        background: Item {}
    }
}

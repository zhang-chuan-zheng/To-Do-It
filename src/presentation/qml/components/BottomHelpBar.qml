import QtQuick
import QtQuick.Controls

Item {
    id: root
    property string message: qsTr("将鼠标移到组件上可查看操作说明")
    property string severity: "info"
    readonly property color messageColor: severity === "error" ? Theme.danger
        : (severity === "warning" ? Theme.warning : Theme.textSecondary)
    property url donationQrSource: IconCatalog.donationQr
    signal helpRequested(string message)

    TextField {
        anchors.left: parent.left
        anchors.right: donationArea.left
        anchors.rightMargin: Metrics.spacingSmall
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

    Row {
        id: donationArea
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 24
        spacing: Metrics.spacingTiny

        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("打赏一下")
            color: Theme.textSecondary
            font.family: Typography.family
            font.pixelSize: Typography.captionSize
            font.weight: Typography.mediumWeight
        }

        IconImage {
            anchors.verticalCenter: parent.verticalCenter
            width: 14
            height: 14
            source: IconCatalog.arrowRight
            accessibleName: qsTr("指向打赏按钮")
        }

        RoundIconButton {
            id: donationButton
            anchors.verticalCenter: parent.verticalCenter
            width: 24
            height: 24
            iconSource: IconCatalog.donate
            iconSize: 15
            helpText: qsTr("显示打赏二维码")
            onClicked: donationPopup.visible ? donationPopup.close() : donationPopup.open()
            onHelpVisibilityChanged: function(message, visible) {
                root.helpRequested(visible ? qsTr("点击显示打赏二维码") : "")
            }
        }
    }

    DonationPopup {
        id: donationPopup
        parent: root
        x: root.width - width
        y: -height - Metrics.spacingSmall
        qrSource: root.donationQrSource
    }
}

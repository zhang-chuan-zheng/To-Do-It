import QtQuick
import QtQuick.Controls

Popup {
    id: root
    property url qrSource: IconCatalog.donationQr

    width: 248
    height: donationContent.implicitHeight + topPadding + bottomPadding
    padding: Metrics.spacingMedium
    modal: false
    focus: false
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    z: 600

    background: PopupGlassBackground {
        radius: Metrics.radiusLarge
        surfaceLevel: 2
    }

    contentItem: Column {
        id: donationContent
        width: root.availableWidth
        spacing: Metrics.spacingSmall

        Item {
            width: parent.width
            height: 26

            Label {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("支持 To Do It")
                color: Theme.textPrimary
                font.family: Typography.family
                font.pixelSize: Typography.bodySize
                font.weight: Typography.mediumWeight
            }

            RoundIconButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 24
                height: 24
                iconSource: IconCatalog.close
                iconSize: 13
                chromeStyle: true
                helpText: qsTr("关闭")
                onClicked: root.close()
            }
        }

        GlassSurface {
            width: parent.width
            height: width
            radius: Metrics.radiusMedium
            surfaceLevel: 0

            Image {
                anchors.fill: parent
                anchors.margins: Metrics.spacingSmall
                source: root.qrSource
                fillMode: Image.PreserveAspectFit
                smooth: true
                asynchronous: true
                Accessible.name: qsTr("打赏二维码")
            }
        }

        Label {
            width: parent.width
            text: qsTr("当前为可替换占位图；正式二维码可通过资源配置接口替换。")
            color: Theme.textMuted
            font.family: Typography.family
            font.pixelSize: Typography.captionSize
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
        }
    }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Motion.fastDuration }
            NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: Motion.fastDuration }
        }
    }
    exit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Motion.fastDuration }
            NumberAnimation { property: "scale"; from: 1; to: 0.96; duration: Motion.fastDuration }
        }
    }
}

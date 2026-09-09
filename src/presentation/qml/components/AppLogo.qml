import QtQuick
import QtQuick.Controls

Item {
    id: root
    property url source: IconCatalog.appLogo
    property string accessibleName: qsTr("To Do It 标志")
    readonly property bool hasImage: logoImage.loaded
    implicitWidth: Metrics.logoSize
    implicitHeight: Metrics.logoSize
    Accessible.name: accessibleName

    IconImage {
        id: logoImage
        anchors.fill: parent
        source: root.source
        accessibleName: root.accessibleName
    }
}

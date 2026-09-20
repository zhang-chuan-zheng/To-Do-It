pragma Singleton
import QtQuick

QtObject {
    property bool reducedMotion: false
    readonly property int fastDuration: reducedMotion ? 0 : 100
    readonly property int normalDuration: reducedMotion ? 0 : 180
    readonly property int detailsDuration: reducedMotion ? 0 : 220
    readonly property int searchExpandDuration: reducedMotion ? 0 : 220
    readonly property int reorderDuration: reducedMotion ? 0 : 260
    readonly property int dragPreviewDuration: reducedMotion ? 0 : 150
    readonly property int quoteRollDuration: reducedMotion ? 0 : 360
    readonly property int searchCollapseDelay: 800
    readonly property int standardEasing: Easing.OutCubic
}

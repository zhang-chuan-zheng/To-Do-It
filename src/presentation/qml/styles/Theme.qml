pragma Singleton
import QtQuick

QtObject {
    property string activeVariant: "graphite"
    readonly property var availableVariants: ["aurora", "graphite"]
    readonly property color windowBaseColor: activeVariant === "graphite" ? "#1B1E22" : "#111927"
    readonly property color ambientGlowPrimary: activeVariant === "graphite" ? "#6F7D80" : "#4D8DFF"
    readonly property color ambientGlowSecondary: activeVariant === "graphite" ? "#71464F" : "#8D5BFF"
    readonly property color ambientGlowTertiary: activeVariant === "graphite" ? "#34475A" : "#2A8A92"
    readonly property real ambientGlowOpacity: activeVariant === "graphite" ? 0.12 : 0.16
    readonly property color surfaceLow: Qt.rgba(0.95, 0.97, 1, 0.045)
    readonly property color surfaceMedium: Qt.rgba(0.95, 0.97, 1, 0.072)
    readonly property color surfaceHigh: Qt.rgba(0.95, 0.97, 1, 0.105)
    readonly property color surfaceHover: Qt.rgba(0.95, 0.97, 1, 0.135)
    readonly property color eventHover: Qt.rgba(0.65, 0.75, 0.84, 0.11)
    readonly property color outline: Qt.rgba(0.92, 0.95, 1, 0.13)
    readonly property color outlineStrong: Qt.rgba(0.92, 0.95, 1, 0.24)
    readonly property color fieldOutline: Qt.rgba(0.92, 0.95, 1, 0.22)
    readonly property color highlight: Qt.rgba(1, 1, 1, 0.16)
    readonly property color popupTint: Qt.rgba(0.105, 0.12, 0.14, 0.84)
    readonly property color textPrimary: "#E8EBEF"
    readonly property color textSecondary: "#B6BBC4"
    readonly property color textMuted: "#818892"
    readonly property color accent: activeVariant === "graphite" ? "#839BAB" : "#77A9FF"
    readonly property color accentStrong: activeVariant === "graphite" ? "#B8C8D2" : "#9CC0FF"
    readonly property color importanceInactive: "#343B43"
    readonly property color statusActive: "#83AFC4"
    readonly property color statusDone: "#82A997"
    readonly property color statusCancelled: "#9B8790"
    readonly property color statusPending: "#A89B7D"
    readonly property color warning: "#F4C66A"
    readonly property color danger: "#FF7E8A"
    readonly property color dangerSurface: Qt.rgba(1, 0.18, 0.24, 0.28)
    readonly property color focusRing: Qt.rgba(0.46, 0.66, 1, 0.78)

    function surfaceColor(level) {
        return level >= 2 ? surfaceHigh : (level === 1 ? surfaceMedium : surfaceLow)
    }

    function importanceColor(index) {
        const colors = ["#586A78", "#62798A", "#6B899C", "#739AAF", "#7CABC2"]
        return colors[Math.max(0, Math.min(4, index))]
    }

    function statusColor(status) {
        if (status === "已完成")
            return statusDone
        if (status === "已取消")
            return statusCancelled
        if (status === "待确认")
            return statusPending
        return statusActive
    }

    function useVariant(variantId) {
        if (availableVariants.indexOf(variantId) < 0)
            return false
        activeVariant = variantId
        return true
    }
}

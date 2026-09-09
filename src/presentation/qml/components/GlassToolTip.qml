import QtQuick
import QtQuick.Controls

ToolTip {
    id: root

    property int maximumTextWidth: 460

    delay: 350
    timeout: -1
    padding: Metrics.spacingSmall
    margins: Metrics.spacingSmall
    width: Math.min(maximumTextWidth + leftPadding + rightPadding,
                    Math.max(120 + leftPadding + rightPadding,
                             toolTipLabel.implicitWidth + leftPadding + rightPadding))

    contentItem: Label {
        id: toolTipLabel

        width: root.availableWidth
        text: root.text
        color: Theme.textPrimary
        font.family: Typography.family
        font.pixelSize: Typography.captionSize
        wrapMode: Text.WrapAnywhere
    }

    background: PopupGlassBackground {
        radius: Metrics.radiusSmall
        surfaceLevel: 2
    }
}

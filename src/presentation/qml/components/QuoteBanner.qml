import QtQuick
import QtQuick.Controls

GlassPanel {
    id: root
    property string quote: qsTr("专注当下，完成重要的事。")
    property string author: qsTr("To Do It")
    property string displayedQuote: ""
    property string displayedAuthor: ""
    property string pendingQuote: ""
    property string pendingAuthor: ""
    property bool initialized: false
    property bool transitionQueued: false
    signal refreshRequested()
    signal helpRequested(string message)
    surfaceLevel: 0
    panelRadius: Metrics.radiusSmall
    contentPadding: Metrics.spacingSmall
    clip: true

    function combinedText(quoteText, authorText) {
        return quoteText + "  — " + authorText
    }

    function queueTransition() {
        pendingQuote = quote
        pendingAuthor = author
        if (!initialized) {
            displayedQuote = pendingQuote
            displayedAuthor = pendingAuthor
            return
        }
        if (pendingQuote === displayedQuote
                && pendingAuthor === displayedAuthor)
            return
        if (transitionQueued)
            return
        transitionQueued = true
        Qt.callLater(function() {
            root.transitionQueued = false
            root.startTransitionIfNeeded()
        })
    }

    function startTransitionIfNeeded() {
        if (quoteRollAnimation.running)
            return
        if (pendingQuote === displayedQuote
                && pendingAuthor === displayedAuthor)
            return
        quoteContent.y = 0
        quoteContent.opacity = 1
        quoteContent.scale = 1
        quoteRollAnimation.start()
    }

    onQuoteChanged: queueTransition()
    onAuthorChanged: queueTransition()

    Item {
        id: quoteViewport
        anchors.fill: parent
        clip: true

        Item {
            id: quoteContent
            width: parent.width
            height: parent.height
            transformOrigin: Item.Center

            Label {
                anchors.fill: parent
                text: root.combinedText(root.displayedQuote,
                                        root.displayedAuthor)
                color: Theme.textSecondary
                elide: Text.ElideRight
                font.family: Typography.family
                font.pixelSize: Typography.bodySize
                font.weight: Typography.mediumWeight
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: 1
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    SequentialAnimation {
        id: quoteRollAnimation

        ParallelAnimation {
            NumberAnimation {
                target: quoteContent
                property: "y"
                to: quoteViewport.height * 0.9
                duration: Motion.quoteRollDuration
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: quoteContent
                property: "scale"
                to: 0.56
                duration: Motion.quoteRollDuration
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: quoteContent
                property: "opacity"
                to: 0
                duration: Motion.quoteRollDuration
                easing.type: Easing.InCubic
            }
        }

        ScriptAction {
            script: {
                root.displayedQuote = root.pendingQuote
                root.displayedAuthor = root.pendingAuthor
                quoteContent.y = -quoteViewport.height * 0.9
                quoteContent.scale = 0.56
                quoteContent.opacity = 0
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: quoteContent
                property: "y"
                to: 0
                duration: Motion.quoteRollDuration
                easing.type: Motion.standardEasing
            }
            NumberAnimation {
                target: quoteContent
                property: "scale"
                to: 1
                duration: Motion.quoteRollDuration
                easing.type: Motion.standardEasing
            }
            NumberAnimation {
                target: quoteContent
                property: "opacity"
                to: 1
                duration: Motion.quoteRollDuration
                easing.type: Motion.standardEasing
            }
        }

        onFinished: {
            quoteContent.y = 0
            quoteContent.scale = 1
            quoteContent.opacity = 1
            if (root.pendingQuote !== root.displayedQuote
                    || root.pendingAuthor !== root.displayedAuthor)
                Qt.callLater(function() { root.startTransitionIfNeeded() })
        }
    }

    HoverHandler {
        onHoveredChanged: root.helpRequested(hovered
            ? qsTr("每2分钟自动滚动换一句本地哲学名言；双击可立即切换") : "")
    }
    TapHandler {
        acceptedButtons: Qt.LeftButton
        onDoubleTapped: root.refreshRequested()
    }

    Component.onCompleted: {
        pendingQuote = quote
        pendingAuthor = author
        displayedQuote = quote
        displayedAuthor = author
        initialized = true
    }
}

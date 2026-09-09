import QtQuick
import QtQuick.Controls

Item {
    id: root
    property string eventId: ""
    property string sequenceText: "1"
    property string eventTitle: ""
    property int depth: 0
    property string childRatio: ""
    property int importanceLevel: 3
    property string startText: ""
    property string completionText: ""
    property string statusText: qsTr("进行中")
    property string durationText: ""
    property string noteText: ""
    property string attachmentKinds: ""
    property var availableStatusOptions: [qsTr("进行中"), qsTr("已完成"), qsTr("已取消")]
    property bool draftMode: false
    property bool detailsActive: false
    property real indentOffset: 0
    property real importanceGlobalX: 0
    readonly property real localSequenceWidth: depth === 0
        ? Metrics.sequenceColumnWidth : Metrics.nestedSequenceColumnWidth
    readonly property real localTitleWidth: Math.max(80,
        importanceGlobalX - indentOffset - Metrics.eventOuterPadding
        - localSequenceWidth - Metrics.eventFieldGap * 2)
    readonly property bool editingLocked: titleInput.activeFocus || startEditor.editing
        || completionEditor.editing || statusEditor.editing || noteEditor.editing
    property bool detailsPinned: false
    readonly property bool detailsVisible: detailsActive || detailsPinned
    property string dropMode: ""
    signal deleteRequested()
    signal fieldEdited(string field, var value)
    signal moveRequested(string draggedId, string targetId, string mode)
    signal attachmentAddRequested()
    signal attachmentRemoveRequested(int index)
    signal attachmentOpenRequested(int index)
    signal draftAbandonRequested()
    signal titleAccepted(bool pointerInside)
    signal hoverStateChanged(bool hovered)
    signal dragStateChanged(string eventId, bool dragging)
    signal activationRequested()
    signal releaseInputFocusRequested()
    signal editingStateChanged(bool editing)
    signal helpRequested(string message)

    function pointInsideItem(item, pointInCard) {
        if (!item || !item.mapFromItem)
            return false
        const localPoint = item.mapFromItem(root, pointInCard.x, pointInCard.y)
        return localPoint.x >= 0 && localPoint.x <= item.width
            && localPoint.y >= 0 && localPoint.y <= item.height
    }

    function pointInsideEditableControl(pointInCard) {
        return pointInsideItem(titleInput, pointInCard)
            || pointInsideItem(startEditor, pointInCard)
            || pointInsideItem(completionEditor, pointInCard)
            || pointInsideItem(statusEditor, pointInCard)
            || (detailsVisible && pointInsideItem(noteEditor, pointInCard))
    }

    implicitHeight: Metrics.eventRowHeight
        + (detailsVisible
            ? Metrics.eventFieldGap + detailsPanel.implicitHeight + Metrics.eventOuterPadding
            : 0)

    GlassSurface {
        anchors.fill: parent
        radius: Metrics.radiusMedium
        surfaceLevel: 0
        interactive: cardHover.hovered || root.editingLocked
        fillColor: root.dropMode.length > 0 || cardHover.hovered ? Theme.eventHover : Theme.surfaceLow
        border.color: root.dropMode.length > 0 || cardHover.hovered ? Theme.focusRing : Theme.outline
    }

    HoverHandler {
        id: cardHover
        onHoveredChanged: {
            root.hoverStateChanged(hovered)
            root.helpRequested(hovered
                ? qsTr("拖动整个事项卡可调整层级；右键可删除；悬停展开备注") : "")
            if (hovered) {
                draftExitTimer.stop()
            } else if (root.draftMode) {
                draftExitTimer.restart()
            }
        }
    }

    Timer {
        id: draftExitTimer
        interval: 800
        onTriggered: {
            if (root.draftMode && !cardHover.hovered
                    && titleInput.text.trim().length === 0
                    && !titleInput.inputMethodComposing
                    && !startEditor.editing && !completionEditor.editing
                    && !statusEditor.editing && !noteEditor.editing)
                root.draftAbandonRequested()
        }
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: root.deleteRequested()
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped: function(eventPoint) {
            if (!root.pointInsideEditableControl(eventPoint.position))
                root.releaseInputFocusRequested()
            root.activationRequested()
        }
    }

    Item {
        id: dragProxy
        width: root.width
        height: Metrics.eventRowHeight

        Drag.active: false
        Drag.source: root
        Drag.keys: ["todoit-event-card"]
        Drag.supportedActions: Qt.MoveAction
        Drag.dragType: Drag.Internal
        Drag.hotSpot.x: eventRow.x + cardDrag.centroid.pressPosition.x
        Drag.hotSpot.y: eventRow.y + cardDrag.centroid.pressPosition.y
    }

    DragHandler {
        id: cardDrag
        parent: eventRow
        target: dragProxy
        acceptedButtons: Qt.LeftButton
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        dragThreshold: 5
        grabPermissions: PointerHandler.CanTakeOverFromItems
            | PointerHandler.CanTakeOverFromHandlersOfDifferentType
            | PointerHandler.ApprovesTakeOverByAnything
        enabled: !root.draftMode
        onActiveChanged: {
            if (active) {
                root.forceActiveFocus(Qt.MouseFocusReason)
                dragProxy.Drag.active = true
                root.dragStateChanged(root.eventId, true)
                return
            }

            if (dragProxy.Drag.active)
                dragProxy.Drag.drop()
            root.dragStateChanged(root.eventId, false)
            dragProxy.x = 0
            dragProxy.y = 0
        }
    }

    DropArea {
        id: dropZone
        anchors.fill: parent
        keys: ["todoit-event-card"]

        function modeFor(yPosition) {
            const edgeZone = Math.min(10, root.height * 0.16)
            if (yPosition < edgeZone)
                return "before"
            if (yPosition > root.height - edgeZone)
                return "after"
            return "child"
        }

        onEntered: function(drag) {
            if (drag.source && drag.source.eventId !== root.eventId)
                root.dropMode = modeFor(drag.y)
        }
        onPositionChanged: function(drag) {
            if (drag.source && drag.source.eventId !== root.eventId)
                root.dropMode = modeFor(drag.y)
        }
        onExited: root.dropMode = ""
        onDropped: function(drop) {
            const sourceId = drop.source ? drop.source.eventId : ""
            const requestedMode = modeFor(drop.y)
            root.dropMode = ""
            if (sourceId.length === 0 || sourceId === root.eventId)
                return
            root.moveRequested(sourceId, root.eventId, requestedMode)
            drop.acceptProposedAction()
        }
    }

    Rectangle {
        visible: root.dropMode === "before" || root.dropMode === "after"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: root.dropMode === "before" ? parent.top : undefined
        anchors.bottom: root.dropMode === "after" ? parent.bottom : undefined
        height: 2
        radius: 1
        color: Theme.accentStrong
        z: 20
    }

    Item {
        visible: root.depth > 0
        x: -18
        y: 1
        width: 22
        height: Metrics.eventRowHeight / 2
        opacity: 0.35

        Column {
            x: 0
            y: 0
            spacing: 3
            Repeater {
                model: 7
                delegate: Rectangle {
                    required property int index
                    width: 1
                    height: 1
                    radius: 1
                    color: Theme.textMuted
                }
            }
        }
        Row {
            x: 0
            y: parent.height - 1
            spacing: 3
            Repeater {
                model: 6
                delegate: Rectangle {
                    required property int index
                    width: 1
                    height: 1
                    radius: 1
                    color: Theme.textMuted
                }
            }
        }
    }

    Row {
        id: eventRow
        x: Metrics.eventOuterPadding
        y: Metrics.eventOuterPadding
        width: parent.width - Metrics.eventOuterPadding * 2
        height: Metrics.eventRowHeight - Metrics.eventOuterPadding * 2
        spacing: Metrics.eventFieldGap

        FieldFrame {
            width: root.localSequenceWidth
            height: parent.height
            contentPadding: Metrics.spacingTiny
            Label {
                anchors.fill: parent
                text: root.sequenceText
                color: Theme.textSecondary
                font.family: Typography.family
                font.pixelSize: Typography.secondarySize
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        FieldFrame {
            width: root.localTitleWidth
            height: parent.height
            contentPadding: Metrics.spacingSmall

            TextField {
                id: titleInput
                property bool acceptingReturn: false
                anchors.left: parent.left
                anchors.right: ratioLabel.visible ? ratioLabel.left : parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.rightMargin: ratioLabel.visible ? Metrics.spacingSmall : 0
                text: root.eventTitle
                color: Theme.textPrimary
                selectionColor: Theme.accent
                selectedTextColor: Theme.windowBaseColor
                font.family: Typography.family
                font.pixelSize: Typography.bodySize
                verticalAlignment: TextInput.AlignVCenter
                placeholderText: root.draftMode ? qsTr("请输入事项名称") : ""
                placeholderTextColor: Theme.textMuted
                background: Item {}
                onTextEdited: {
                    if (root.draftMode && !cardHover.hovered && text.trim().length === 0)
                        draftExitTimer.restart()
                    else
                        draftExitTimer.stop()
                }
                onEditingFinished: {
                    if (!acceptingReturn)
                        root.fieldEdited("titleText", text)
                    if (root.draftMode && !cardHover.hovered)
                        draftExitTimer.restart()
                }
                onAccepted: {
                    acceptingReturn = true
                    root.fieldEdited("titleText", text)
                    focus = false
                    root.titleAccepted(cardHover.hovered)
                    acceptingReturn = false
                }
                onActiveFocusChanged: {
                    if (!activeFocus && root.draftMode && !cardHover.hovered)
                        draftExitTimer.restart()
                }
            }

            Label {
                id: ratioLabel
                visible: root.childRatio.length > 0
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.childRatio
                color: Theme.textMuted
                font.family: Typography.family
                font.pixelSize: Typography.captionSize
            }
        }

        ImportanceSelector {
            width: Metrics.importanceColumnWidth
            height: parent.height
            levelIndex: root.importanceLevel
            onLevelRequested: function(levelIndex) { root.fieldEdited("importance", levelIndex) }
        }

        CompactDateEditor {
            id: startEditor
            width: Metrics.dateColumnWidth
            height: parent.height
            text: root.startText
            allowEmpty: false
            onValueEdited: function(value) { root.fieldEdited("startAt", value) }
            onValidationFailed: function(message) { root.helpRequested(message) }
        }

        CompactDateEditor {
            id: completionEditor
            width: Metrics.dateColumnWidth
            height: parent.height
            text: root.completionText
            allowEmpty: true
            onValueEdited: function(value) { root.fieldEdited("completedAt", value) }
            onValidationFailed: function(message) { root.helpRequested(message) }
        }

        EditableStatusComboBox {
            id: statusEditor
            width: Metrics.statusColumnWidth
            height: parent.height
            statusText: root.statusText
            statusOptions: root.availableStatusOptions
            onStatusEdited: function(status) { root.fieldEdited("stateText", status) }
        }

        FieldFrame {
            width: Metrics.durationColumnWidth
            height: parent.height
            contentPadding: Metrics.spacingTiny
            Label {
                anchors.fill: parent
                text: root.durationText
                color: Theme.textSecondary
                font.family: Typography.family
                font.pixelSize: Typography.secondarySize
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
        }
    }

    FieldFrame {
        id: detailsPanel
        visible: root.detailsVisible
        clip: true
        x: Metrics.eventOuterPadding
        y: Metrics.eventRowHeight + Metrics.eventFieldGap
        width: parent.width - Metrics.eventOuterPadding * 2
        implicitHeight: detailsContent.implicitHeight + contentPadding * 2
        height: implicitHeight
        contentPadding: Metrics.spacingSmall

        Column {
            id: detailsContent
            anchors.fill: parent
            spacing: Metrics.spacingTiny

            AttachmentStrip {
                width: parent.width
                height: implicitHeight
                attachmentKinds: root.attachmentKinds.length > 0
                    ? root.attachmentKinds.split("|") : []
                onAddRequested: root.attachmentAddRequested()
                onRemoveRequested: function(index) { root.attachmentRemoveRequested(index) }
                onOpenRequested: function(index) { root.attachmentOpenRequested(index) }
            }

            RichNoteEditor {
                id: noteEditor
                width: parent.width
                height: implicitHeight
                text: root.noteText
                onNoteEdited: function(html) { root.fieldEdited("note", html) }
                onHelpRequested: function(message) { root.helpRequested(message) }
            }
        }
    }

    Behavior on implicitHeight {
        NumberAnimation { duration: Motion.detailsDuration; easing.type: Easing.InOutCubic }
    }

    onDraftModeChanged: {
        if (draftMode)
            Qt.callLater(function() { titleInput.forceActiveFocus(Qt.OtherFocusReason) })
    }

    onEditingLockedChanged: root.editingStateChanged(editingLocked)

    Component.onCompleted: {
        if (draftMode)
            Qt.callLater(function() { titleInput.forceActiveFocus(Qt.OtherFocusReason) })
    }
}

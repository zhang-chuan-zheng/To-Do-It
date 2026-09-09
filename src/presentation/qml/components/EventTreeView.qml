pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

ScrollView {
    id: root

    property var initialEvents: []
    property var eventIdFactory
    property var currentDateTimeFactory
    property var eventModel: visibleModel
    property string searchText: ""
    property string searchField: qsTr("全部")
    property string statusFilter: qsTr("未完成事项")
    property var sortKeys: []
    property var sortDirections: ({})
    property string pendingAttachmentEventId: ""
    property string pinnedEventId: ""
    property string activeDetailsEventId: ""
    property string pendingDetailsEventId: ""
    property string hoveredDetailsEventId: ""
    property string editingDetailsEventId: ""
    property string deferredHoverEventId: ""
    property bool detailsTransitionActive: false
    property bool transitionTargetHovered: false
    property bool hasDraft: false
    property bool persistenceDirty: false
    property bool reorderAnimationActive: false
    property bool dragInProgress: false
    property string draggedEventId: ""
    property string dragHoverEventId: ""
    property int totalSourceCount: 0
    property int summaryMatchedCount: 0
    property string summaryLabel: qsTr("已完成")
    property var availableFilterOptions: [qsTr("未完成事项"), qsTr("全部事项")]
    property var availableStatusOptions: [qsTr("进行中"), qsTr("已完成"), qsTr("已取消")]
    readonly property int itemCount: eventModel ? eventModel.count : 0
    readonly property real fixedWidth: Metrics.sequenceColumnWidth + Metrics.importanceColumnWidth
        + Metrics.dateColumnWidth * 2 + Metrics.statusColumnWidth + Metrics.durationColumnWidth
    readonly property real titleColumnWidth: Math.max(Metrics.titleColumnMinimumWidth,
        width - Metrics.scrollBarGutter - Metrics.eventOuterPadding * 2
        - fixedWidth - Metrics.eventFieldGap * 6)

    signal addRequested()
    signal deleteRequested(string eventId)
    signal helpRequested(string message)
    signal attachmentOpened(string eventTitle, int attachmentIndex)
    signal releaseInputFocusRequested()
    signal persistenceRequested(var events)

    clip: true
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical: ScrollBar {
        id: eventScrollBar

        parent: root
        anchors.top: root.top
        anchors.right: root.right
        anchors.bottom: root.bottom
        z: 50
        policy: ScrollBar.AsNeeded
        minimumSize: Metrics.scrollBarMinimumSize
        width: Metrics.scrollBarWidth

        contentItem: Rectangle {
            implicitWidth: Metrics.scrollBarWidth
            radius: width / 2
            color: eventScrollBar.pressed || eventScrollBar.hovered
                ? Theme.accentStrong : Theme.textMuted
            opacity: eventScrollBar.pressed ? 0.72 : (eventScrollBar.hovered ? 0.52 : 0.30)
        }
        background: Rectangle {
            implicitWidth: Metrics.scrollBarWidth
            radius: width / 2
            color: Theme.surfaceMedium
            opacity: eventScrollBar.active ? 0.62 : 0.36
        }
    }

    function sourceIndexForId(eventId) {
        for (let index = 0; index < sourceModel.count; ++index) {
            if (sourceModel.get(index).eventKey === eventId)
                return index
        }
        return -1
    }

    function visibleIndexForId(eventId) {
        for (let index = 0; index < visibleModel.count; ++index) {
            if (visibleModel.get(index).eventKey === eventId)
                return index
        }
        return -1
    }

    function effectiveStatus(item) {
        const value = String(item.stateText || "").trim()
        return value.length > 0 ? value : qsTr("进行中")
    }

    function refreshStatusMetadata() {
        const filterValues = [qsTr("未完成事项"), qsTr("全部事项")]
        const editValues = [qsTr("进行中"), qsTr("已完成"), qsTr("已取消")]
        let total = 0
        let matched = 0
        let completed = 0

        for (let index = 0; index < sourceModel.count; ++index) {
            const item = sourceModel.get(index)
            if (item.isDraft)
                continue
            ++total
            const status = effectiveStatus(item)
            if (filterValues.indexOf(status) < 0)
                filterValues.push(status)
            if (editValues.indexOf(status) < 0)
                editValues.push(status)
            if (status === qsTr("已完成"))
                ++completed
            if (statusFilter === qsTr("未完成事项") && status !== qsTr("已完成"))
                ++matched
            else if (statusFilter !== qsTr("全部事项") && status === statusFilter)
                ++matched
        }

        totalSourceCount = total
        if (statusFilter === qsTr("全部事项")) {
            summaryLabel = qsTr("已完成")
            summaryMatchedCount = completed
        } else {
            summaryLabel = statusFilter
            summaryMatchedCount = matched
        }
        availableFilterOptions = filterValues
        availableStatusOptions = editValues
    }

    function replaceSourceEvents(events) {
        sourceModel.clear()
        const sourceEvents = events || []
        for (let index = 0; index < sourceEvents.length; ++index) {
            const event = sourceEvents[index]
            sourceModel.append({
                "eventKey": String(event.eventKey || ""),
                "parentId": String(event.parentId || ""),
                "titleText": String(event.titleText || ""),
                "importance": Number(event.importance || 3),
                "startAt": String(event.startAt || ""),
                "completedAt": String(event.completedAt || "—"),
                "stateText": String(event.stateText || qsTr("进行中")),
                "duration": String(event.duration || ""),
                "note": String(event.note || ""),
                "files": String(event.files || ""),
                "manualOrder": Number(event.manualOrder || 0),
                "isDraft": false
            })
        }
        rebuildVisibleModel()
    }

    function persistentSnapshot() {
        const rows = []
        for (let index = 0; index < sourceModel.count; ++index) {
            const item = sourceModel.get(index)
            if (item.isDraft || String(item.titleText).trim().length === 0)
                continue
            rows.push({
                "eventKey": item.eventKey,
                "parentId": item.parentId,
                "titleText": item.titleText,
                "importance": item.importance,
                "startAt": item.startAt,
                "completedAt": item.completedAt,
                "stateText": item.stateText,
                "note": item.note,
                "files": item.files,
                "manualOrder": item.manualOrder
            })
        }
        return rows
    }

    function schedulePersistence() {
        persistenceDirty = true
    }

    function flushPersistence() {
        if (!persistenceDirty)
            return
        persistenceDirty = false
        persistenceRequested(persistentSnapshot())
    }

    function sourceItemForId(eventId) {
        const index = sourceIndexForId(eventId)
        return index >= 0 ? sourceModel.get(index) : null
    }

    function normalizedText(value) {
        return String(value || "").toLowerCase()
    }

    function matchesStatus(item) {
        if (statusFilter === qsTr("全部事项"))
            return true
        if (statusFilter === qsTr("未完成事项"))
            return item.stateText !== qsTr("已完成")
        return item.stateText === statusFilter
    }

    function matchesSearch(item) {
        const needle = normalizedText(searchText).trim()
        if (needle.length === 0)
            return true

        if (searchField === qsTr("事项名称"))
            return normalizedText(item.titleText).indexOf(needle) >= 0
        if (searchField === qsTr("备注"))
            return normalizedText(item.note).indexOf(needle) >= 0
        if (searchField === qsTr("附件名称"))
            return normalizedText(item.files).indexOf(needle) >= 0

        return normalizedText(item.titleText).indexOf(needle) >= 0
            || normalizedText(item.note).indexOf(needle) >= 0
            || normalizedText(item.files).indexOf(needle) >= 0
    }

    function includedEventIds() {
        const included = ({})
        for (let index = 0; index < sourceModel.count; ++index) {
            const item = sourceModel.get(index)
            if (!item.isDraft && (!matchesStatus(item) || !matchesSearch(item)))
                continue

            included[item.eventKey] = true
            let ancestorId = item.parentId
            while (ancestorId.length > 0) {
                included[ancestorId] = true
                const ancestor = sourceItemForId(ancestorId)
                if (!ancestor)
                    break
                ancestorId = ancestor.parentId
            }
        }
        return included
    }

    function alphabeticSequence(index) {
        let value = index + 1
        let result = ""
        while (value > 0) {
            value -= 1
            result = String.fromCharCode(97 + value % 26) + result
            value = Math.floor(value / 26)
        }
        return result
    }

    function romanSequence(index) {
        let value = index + 1
        const values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1]
        const symbols = ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"]
        let result = ""
        for (let position = 0; position < values.length; ++position) {
            while (value >= values[position]) {
                result += symbols[position]
                value -= values[position]
            }
        }
        return result
    }

    function displaySequence(index, depth) {
        const style = depth % 3
        if (style === 0)
            return String(index + 1)
        if (style === 1)
            return alphabeticSequence(index)
        return romanSequence(index)
    }

    function childRatioFor(eventId) {
        let completed = 0
        let total = 0
        for (let index = 0; index < sourceModel.count; ++index) {
            const child = sourceModel.get(index)
            if (child.parentId !== eventId || child.stateText === qsTr("已取消"))
                continue
            total += 1
            if (child.stateText === qsTr("已完成"))
                completed += 1
        }
        return total > 0 ? completed + "/" + total : ""
    }

    function compareValues(leftItem, rightItem, field, direction) {
        let leftValue = leftItem[field]
        let rightValue = rightItem[field]
        const multiplier = direction === "descending" ? -1 : 1

        if (field === "completedAt") {
            const leftEmpty = !leftValue || leftValue === "—"
            const rightEmpty = !rightValue || rightValue === "—"
            if (leftEmpty !== rightEmpty)
                return direction === "descending"
                    ? (leftEmpty ? -1 : 1) : (leftEmpty ? 1 : -1)
        }

        if (field === "importance") {
            leftValue = Number(leftValue)
            rightValue = Number(rightValue)
        } else {
            leftValue = normalizedText(leftValue)
            rightValue = normalizedText(rightValue)
        }

        if (leftValue < rightValue)
            return -1 * multiplier
        if (leftValue > rightValue)
            return 1 * multiplier
        return 0
    }

    function compareSourceIndices(leftIndex, rightIndex) {
        const leftItem = sourceModel.get(leftIndex)
        const rightItem = sourceModel.get(rightIndex)
        if (leftItem.isDraft !== rightItem.isDraft)
            return leftItem.isDraft ? 1 : -1
        for (let index = 0; index < sortKeys.length; ++index) {
            const key = sortKeys[index]
            const result = compareValues(leftItem, rightItem, key.field, key.direction)
            if (result !== 0)
                return result
        }
        if (leftItem.manualOrder !== rightItem.manualOrder)
            return leftItem.manualOrder - rightItem.manualOrder
        return leftIndex - rightIndex
    }

    function updateSortState() {
        const directions = ({})
        for (let index = 0; index < sortKeys.length; ++index) {
            directions[sortKeys[index].field] = sortKeys[index].direction
        }
        sortDirections = directions
    }

    function beginReorderAnimation() {
        reorderAnimationActive = true
        reorderAnimationTimer.restart()
    }

    function syncVisibleRows(rows) {
        const desiredIds = ({})
        for (let index = 0; index < rows.length; ++index)
            desiredIds[rows[index].eventKey] = true

        for (let index = visibleModel.count - 1; index >= 0; --index) {
            if (!desiredIds[visibleModel.get(index).eventKey])
                visibleModel.remove(index)
        }

        for (let targetIndex = 0; targetIndex < rows.length; ++targetIndex) {
            const row = rows[targetIndex]
            let currentIndex = -1
            for (let index = targetIndex; index < visibleModel.count; ++index) {
                if (visibleModel.get(index).eventKey === row.eventKey) {
                    currentIndex = index
                    break
                }
            }
            if (currentIndex < 0) {
                visibleModel.insert(targetIndex, row)
            } else {
                if (currentIndex !== targetIndex)
                    visibleModel.move(currentIndex, targetIndex, 1)
                visibleModel.set(targetIndex, row)
            }
        }
    }

    function rebuildVisibleModel() {
        refreshStatusMetadata()
        const included = includedEventIds()
        const children = ({})
        const rows = []
        let draftFound = false

        for (let index = 0; index < sourceModel.count; ++index) {
            const item = sourceModel.get(index)
            if (item.isDraft)
                draftFound = true
            if (!included[item.eventKey])
                continue
            const parentKey = item.parentId || ""
            if (!children[parentKey])
                children[parentKey] = []
            children[parentKey].push(index)
        }

        function appendChildren(parentId, depth) {
            const indices = children[parentId] || []
            indices.sort(function(left, right) { return root.compareSourceIndices(left, right) })

            for (let position = 0; position < indices.length; ++position) {
                const sourceIndex = indices[position]
                const item = sourceModel.get(sourceIndex)
                rows.push({
                    "eventKey": item.eventKey,
                    "parentId": item.parentId,
                    "sequence": root.displaySequence(position, depth),
                    "titleText": item.titleText,
                    "depthLevel": depth,
                    "ratio": root.childRatioFor(item.eventKey),
                    "importance": item.importance,
                    "startAt": item.startAt,
                    "completedAt": item.completedAt,
                    "stateText": item.stateText,
                    "duration": item.duration,
                    "note": item.note,
                    "files": item.files,
                    "isDraft": item.isDraft
                })
                appendChildren(item.eventKey, depth + 1)
            }
        }

        appendChildren("", 0)
        hasDraft = draftFound
        syncVisibleRows(rows)
        if (activeDetailsEventId.length > 0 && sourceIndexForId(activeDetailsEventId) < 0)
            activeDetailsEventId = ""
    }

    function setSearch(text, field) {
        searchText = text
        searchField = field
        rebuildVisibleModel()
    }

    function setStatusFilter(status) {
        statusFilter = status
        rebuildVisibleModel()
    }

    function requestDetailsHover(eventId, hovered) {
        if (dragInProgress) {
            if (hovered)
                dragHoverEventId = eventId
            else if (dragHoverEventId === eventId)
                dragHoverEventId = ""
            return
        }

        if (detailsTransitionActive) {
            if (eventId === activeDetailsEventId) {
                transitionTargetHovered = hovered
                if (hovered)
                    hoveredDetailsEventId = eventId
            } else if (hovered) {
                deferredHoverEventId = eventId
            } else if (deferredHoverEventId === eventId) {
                deferredHoverEventId = ""
            }
            return
        }

        if (hovered) {
            hoveredDetailsEventId = eventId
            detailCloseTimer.stop()
            if (activeDetailsEventId === eventId)
                return
            pendingDetailsEventId = eventId
            detailSwitchTimer.restart()
            return
        }

        if (hoveredDetailsEventId === eventId)
            hoveredDetailsEventId = ""
        if (pendingDetailsEventId === eventId) {
            pendingDetailsEventId = ""
            detailSwitchTimer.stop()
        }
        if (activeDetailsEventId === eventId && editingDetailsEventId !== eventId)
            detailCloseTimer.restart()
    }

    function activateDetails(eventId) {
        if (eventId.length === 0 || dragInProgress)
            return
        if (editingDetailsEventId.length > 0 && editingDetailsEventId !== eventId) {
            releaseInputFocusRequested()
            editingDetailsEventId = ""
        }
        pendingDetailsEventId = ""
        detailSwitchTimer.stop()
        detailCloseTimer.stop()
        if (activeDetailsEventId !== eventId) {
            deferredHoverEventId = ""
            detailsTransitionActive = true
            transitionTargetHovered = true
            detailsTransitionTimer.restart()
        }
        activeDetailsEventId = eventId
    }

    function updateDetailsEditing(eventId, editing) {
        if (editing) {
            editingDetailsEventId = eventId
            activateDetails(eventId)
            return
        }
        if (editingDetailsEventId === eventId)
            editingDetailsEventId = ""
        if (pendingDetailsEventId.length > 0
                && hoveredDetailsEventId === pendingDetailsEventId) {
            detailSwitchTimer.restart()
        } else if (activeDetailsEventId === eventId
                   && hoveredDetailsEventId !== eventId) {
            detailCloseTimer.restart()
        }
    }

    function updateDragState(eventId, dragging) {
        if (dragging) {
            dragInProgress = true
            draggedEventId = eventId
            dragHoverEventId = ""
            pendingDetailsEventId = ""
            deferredHoverEventId = ""
            detailSwitchTimer.stop()
            detailCloseTimer.stop()
            return
        }

        if (!dragInProgress || draggedEventId !== eventId)
            return

        const postDragHoverEventId = dragHoverEventId
        dragInProgress = false
        draggedEventId = ""
        dragHoverEventId = ""
        if (postDragHoverEventId.length > 0)
            Qt.callLater(function() {
                root.requestDetailsHover(postDragHoverEventId, true)
            })
    }

    function applySortRequest(field, direction) {
        const keys = sortKeys.slice(0)
        let existingIndex = -1
        for (let index = 0; index < keys.length; ++index) {
            if (keys[index].field === field) {
                existingIndex = index
                break
            }
        }

        if (direction === "none") {
            if (existingIndex >= 0)
                keys.splice(existingIndex, 1)
        } else if (existingIndex >= 0) {
            keys[existingIndex] = { "field": field, "direction": direction }
        } else {
            keys.push({ "field": field, "direction": direction })
        }

        sortKeys = keys
        updateSortState()
        beginReorderAnimation()
        rebuildVisibleModel()
    }

    function parsedDateTime(value) {
        const match = /^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})$/.exec(String(value || ""))
        if (!match)
            return NaN
        return new Date(Number(match[1]), Number(match[2]) - 1, Number(match[3]),
                        Number(match[4]), Number(match[5]), 0, 0).getTime()
    }

    function timeEditIsValid(item, field, value) {
        if (field === "startAt" && (value === "—" || value.length === 0))
            return false
        if (field === "completedAt" && (value === "—" || value.length === 0))
            return true

        const editedTime = parsedDateTime(value)
        if (isNaN(editedTime))
            return false
        if (field === "completedAt") {
            const startTime = parsedDateTime(item.startAt)
            return !isNaN(startTime) && editedTime >= startTime
                && editedTime <= currentReferenceTime()
        }
        const completionTime = parsedDateTime(item.completedAt)
        return isNaN(completionTime) || completionTime >= editedTime
    }

    function updateEventField(eventId, field, value) {
        const sourceIndex = sourceIndexForId(eventId)
        if (sourceIndex < 0)
            return
        const item = sourceModel.get(sourceIndex)
        const previousState = item.stateText
        if (field === "note") {
            sourceModel.setProperty(sourceIndex, field, value)
            const visibleIndex = visibleIndexForId(eventId)
            if (visibleIndex >= 0)
                visibleModel.setProperty(visibleIndex, field, value)
            schedulePersistence()
            return
        }
        if ((field === "startAt" || field === "completedAt")
                && !timeEditIsValid(item, field, String(value))) {
            helpRequested(field === "completedAt"
                ? qsTr("完成时间必须位于开始时间与当前时间之间")
                : qsTr("开始时间不能为空，且不得晚于已有完成时间"))
            return
        }
        if (field === "titleText") {
            const title = String(value).trim()
            if (!item.isDraft && title.length === 0) {
                helpRequested(qsTr("事项名称不能为空"))
                rebuildVisibleModel()
                return
            }
            value = title
        }
        if (field === "stateText") {
            value = String(value).trim().length > 0 ? String(value).trim() : qsTr("进行中")
            if (value === qsTr("已完成") && previousState !== qsTr("已完成")) {
                const startTime = parsedDateTime(item.startAt)
                if (!isNaN(startTime) && startTime > currentReferenceTime()) {
                    helpRequested(qsTr("开始时间尚未到达，不能标记为已完成"))
                    return
                }
            }
        }
        if (sortKeys.length > 0)
            beginReorderAnimation()
        sourceModel.setProperty(sourceIndex, field, value)
        if (field === "stateText" && value === qsTr("已完成")
                && previousState !== qsTr("已完成")) {
            sourceModel.setProperty(sourceIndex, "completedAt", currentDateTimeText())
            helpRequested(qsTr("完成时间已自动设置为当前时间，可继续手动修改"))
        } else if (field === "stateText" && value !== qsTr("已完成")
                   && previousState === qsTr("已完成")) {
            sourceModel.setProperty(sourceIndex, "completedAt", "—")
        }
        if (field === "titleText" && item.isDraft && String(value).length > 0)
            sourceModel.setProperty(sourceIndex, "isDraft", false)
        rebuildVisibleModel()
        schedulePersistence()
    }

    function paddedNumber(value) {
        return value < 10 ? "0" + value : String(value)
    }

    function currentDateTimeText() {
        if (currentDateTimeFactory) {
            const chinaTime = String(currentDateTimeFactory())
            if (chinaTime.length > 0)
                return chinaTime
        }
        const now = new Date()
        return now.getFullYear() + "-" + paddedNumber(now.getMonth() + 1)
            + "-" + paddedNumber(now.getDate()) + " " + paddedNumber(now.getHours())
            + ":" + paddedNumber(now.getMinutes())
    }

    function currentReferenceTime() {
        return parsedDateTime(currentDateTimeText())
    }

    function beginDraft() {
        if (hasDraft)
            return
        const eventId = eventIdFactory ? String(eventIdFactory()) : ""
        if (eventId.length === 0) {
            helpRequested(qsTr("无法创建事项编号，请稍后重试"))
            return
        }
        sourceModel.append({
            "eventKey": eventId,
            "parentId": "",
            "titleText": "",
            "importance": 3,
            "startAt": currentDateTimeText(),
            "completedAt": "—",
            "stateText": qsTr("进行中"),
            "duration": "00 天 00 时 00 分",
            "note": "",
            "files": "",
            "manualOrder": nextChildOrder(""),
            "isDraft": true
        })
        rebuildVisibleModel()
        helpRequested(qsTr("请填写事项名称；重要程度默认为 5，开始时间默认为当前时间"))
    }

    function finishTitleEditing(eventId, pointerInside) {
        releaseInputFocusRequested()
        if (editingDetailsEventId === eventId)
            editingDetailsEventId = ""
        if (pointerInside)
            return
        pendingDetailsEventId = ""
        hoveredDetailsEventId = ""
        deferredHoverEventId = ""
        detailSwitchTimer.stop()
        detailCloseTimer.stop()
        if (activeDetailsEventId === eventId)
            activeDetailsEventId = ""
    }

    function abandonDraft(eventId) {
        const sourceIndex = sourceIndexForId(eventId)
        if (sourceIndex < 0)
            return
        const item = sourceModel.get(sourceIndex)
        if (!item.isDraft || String(item.titleText).trim().length > 0)
            return
        if (activeDetailsEventId === eventId)
            activeDetailsEventId = ""
        if (editingDetailsEventId === eventId)
            editingDetailsEventId = ""
        sourceModel.remove(sourceIndex)
        rebuildVisibleModel()
        helpRequested(qsTr("未填写事项名称，已取消新建事项"))
    }

    function isDescendant(candidateId, ancestorId) {
        let currentId = candidateId
        while (currentId.length > 0) {
            if (currentId === ancestorId)
                return true
            const currentItem = sourceItemForId(currentId)
            if (!currentItem)
                return false
            currentId = currentItem.parentId
        }
        return false
    }

    function nextChildOrder(parentId) {
        let maximum = -1
        for (let index = 0; index < sourceModel.count; ++index) {
            const item = sourceModel.get(index)
            if (item.parentId === parentId)
                maximum = Math.max(maximum, Number(item.manualOrder))
        }
        return maximum + 1
    }

    function moveEvent(draggedId, targetId, mode) {
        const draggedIndex = sourceIndexForId(draggedId)
        const targetIndex = sourceIndexForId(targetId)
        if (draggedIndex < 0 || targetIndex < 0 || draggedId === targetId)
            return
        if (isDescendant(targetId, draggedId)) {
            helpRequested(qsTr("不能把事项移动到它自己的子孙事项中"))
            return
        }

        const target = sourceModel.get(targetIndex)
        dragHoverEventId = targetId
        let newParentId = target.parentId
        let newOrder = Number(target.manualOrder)
        if (mode === "child") {
            newParentId = targetId
            newOrder = nextChildOrder(targetId)
        } else if (mode === "before") {
            newOrder -= 0.25
        } else {
            newOrder += 0.25
        }

        sourceModel.setProperty(draggedIndex, "parentId", newParentId)
        sourceModel.setProperty(draggedIndex, "manualOrder", newOrder)
        beginReorderAnimation()
        rebuildVisibleModel()
        schedulePersistence()
        helpRequested(mode === "child"
            ? qsTr("事项已成为目标事项的子事项")
            : qsTr("事项已移动到目标事项的同级位置"))
    }

    function moveEventToRoot(draggedId) {
        const draggedIndex = sourceIndexForId(draggedId)
        if (draggedIndex < 0)
            return
        sourceModel.setProperty(draggedIndex, "parentId", "")
        sourceModel.setProperty(draggedIndex, "manualOrder", nextChildOrder(""))
        beginReorderAnimation()
        rebuildVisibleModel()
        schedulePersistence()
        helpRequested(qsTr("事项及其全部子事项已移回一级"))
    }

    function requestAttachments(eventId) {
        pendingAttachmentEventId = eventId
        pinnedEventId = eventId
        activateDetails(eventId)
        attachmentDialog.open()
    }

    function attachSelectedFiles(selectedFiles) {
        const sourceIndex = sourceIndexForId(pendingAttachmentEventId)
        if (sourceIndex < 0)
            return
        const item = sourceModel.get(sourceIndex)
        const paths = item.files.length > 0 ? item.files.split("|") : []
        for (let index = 0; index < selectedFiles.length; ++index) {
            const value = String(selectedFiles[index])
            if (paths.indexOf(value) < 0)
                paths.push(value)
        }
        sourceModel.setProperty(sourceIndex, "files", paths.join("|"))
        rebuildVisibleModel()
        schedulePersistence()
        helpRequested(qsTr("已关联 %1 个附件").arg(selectedFiles.length))
        attachmentRevealTimer.restart()
    }

    function removeAttachment(eventId, attachmentIndex) {
        const sourceIndex = sourceIndexForId(eventId)
        if (sourceIndex < 0)
            return
        const item = sourceModel.get(sourceIndex)
        const paths = item.files.length > 0 ? item.files.split("|") : []
        if (attachmentIndex < 0 || attachmentIndex >= paths.length)
            return
        paths.splice(attachmentIndex, 1)
        sourceModel.setProperty(sourceIndex, "files", paths.join("|"))
        rebuildVisibleModel()
        schedulePersistence()
        helpRequested(qsTr("已解除附件关联，原文件没有从磁盘删除"))
    }

    function openAttachment(eventId, attachmentIndex) {
        const item = sourceItemForId(eventId)
        if (!item)
            return
        const paths = item.files.length > 0 ? item.files.split("|") : []
        if (attachmentIndex < 0 || attachmentIndex >= paths.length)
            return
        const path = paths[attachmentIndex]
        if (path.indexOf("/") >= 0 || path.indexOf("\\") >= 0)
            Qt.openUrlExternally(path)
        attachmentOpened(item.titleText, attachmentIndex)
    }

    ListModel { id: sourceModel }

    ListModel { id: visibleModel }

    FileDialog {
        id: attachmentDialog
        title: qsTr("选择要关联的附件")
        fileMode: FileDialog.OpenFiles
        nameFilters: [qsTr("所有文件 (*)")]
        onAccepted: root.attachSelectedFiles(selectedFiles)
        onRejected: root.pinnedEventId = ""
    }

    Timer {
        id: persistenceTimer
        interval: 5 * 60 * 1000
        repeat: true
        running: true
        onTriggered: {
            if (root.persistenceDirty)
                root.flushPersistence()
        }
    }

    Timer {
        id: attachmentRevealTimer
        interval: 2500
        onTriggered: root.pinnedEventId = ""
    }

    Timer {
        id: reorderAnimationTimer
        interval: Motion.reorderDuration + 80
        onTriggered: root.reorderAnimationActive = false
    }

    Timer {
        id: detailSwitchTimer
        interval: 240
        onTriggered: {
            if (root.pendingDetailsEventId.length > 0
                    && root.hoveredDetailsEventId === root.pendingDetailsEventId)
                root.activateDetails(root.pendingDetailsEventId)
        }
    }

    Timer {
        id: detailsTransitionTimer
        interval: Motion.detailsDuration + 40
        onTriggered: {
            root.detailsTransitionActive = false
            if (root.transitionTargetHovered) {
                root.hoveredDetailsEventId = root.activeDetailsEventId
                root.deferredHoverEventId = ""
                return
            }
            if (root.deferredHoverEventId.length > 0) {
                const nextEventId = root.deferredHoverEventId
                root.deferredHoverEventId = ""
                root.requestDetailsHover(nextEventId, true)
                return
            }
            root.hoveredDetailsEventId = ""
            detailCloseTimer.restart()
        }
    }

    Timer {
        id: detailCloseTimer
        interval: 420
        onTriggered: {
            if (root.activeDetailsEventId.length > 0
                    && root.hoveredDetailsEventId !== root.activeDetailsEventId
                    && root.editingDetailsEventId !== root.activeDetailsEventId)
                root.activeDetailsEventId = ""
        }
    }

    Item {
        width: Math.max(0, root.width - Metrics.scrollBarGutter)
        height: eventColumn.implicitHeight
        implicitWidth: width
        implicitHeight: height

        Column {
            id: eventColumn
            width: parent.width
            spacing: Metrics.eventCardGap
            move: Transition {
                NumberAnimation {
                    properties: "x,y"
                    duration: root.reorderAnimationActive ? Motion.reorderDuration : 0
                    easing.type: Motion.standardEasing
                }
            }

            Repeater {
                model: root.eventModel
                delegate: EventCard {
                    id: eventDelegate
                    required property int index
                    required property string eventKey
                    required property string parentId
                    required property string sequence
                    required property string titleText
                    required property int depthLevel
                    required property string ratio
                    required property int importance
                    required property string startAt
                    required property string completedAt
                    required property string stateText
                    required property string duration
                    required property string note
                    required property string files
                    required property bool isDraft

                    readonly property real hierarchyIndent: depthLevel === 0 ? 0
                        : Metrics.sequenceColumnWidth + Metrics.eventFieldGap
                          + (depthLevel - 1) * (Metrics.nestedSequenceColumnWidth + Metrics.eventFieldGap)
                    x: hierarchyIndent
                    width: eventColumn.width - hierarchyIndent
                    height: implicitHeight
                    eventId: eventKey
                    draftMode: isDraft
                    detailsActive: root.activeDetailsEventId === eventKey
                    detailsPinned: root.pinnedEventId === eventKey
                    sequenceText: sequence
                    eventTitle: titleText
                    depth: depthLevel
                    childRatio: ratio
                    importanceLevel: importance
                    startText: startAt
                    completionText: completedAt
                    statusText: stateText
                    durationText: duration
                    noteText: note
                    attachmentKinds: files
                    availableStatusOptions: root.availableStatusOptions
                    indentOffset: hierarchyIndent
                    importanceGlobalX: Metrics.eventOuterPadding + Metrics.sequenceColumnWidth
                        + Metrics.eventFieldGap + root.titleColumnWidth + Metrics.eventFieldGap
                    onDeleteRequested: root.deleteRequested(eventKey)
                    onFieldEdited: function(field, value) { root.updateEventField(eventKey, field, value) }
                    onMoveRequested: function(draggedId, targetId, mode) {
                        root.moveEvent(draggedId, targetId, mode)
                    }
                    onAttachmentAddRequested: root.requestAttachments(eventKey)
                    onAttachmentRemoveRequested: function(attachmentIndex) {
                        root.removeAttachment(eventKey, attachmentIndex)
                    }
                    onAttachmentOpenRequested: function(attachmentIndex) {
                        root.openAttachment(eventKey, attachmentIndex)
                    }
                    onDraftAbandonRequested: root.abandonDraft(eventKey)
                    onTitleAccepted: function(pointerInside) {
                        root.finishTitleEditing(eventKey, pointerInside)
                    }
                    onHoverStateChanged: function(hovered) {
                        root.requestDetailsHover(eventKey, hovered)
                    }
                    onDragStateChanged: function(eventId, dragging) {
                        root.updateDragState(eventId, dragging)
                    }
                    onActivationRequested: root.activateDetails(eventKey)
                    onReleaseInputFocusRequested: root.releaseInputFocusRequested()
                    onEditingStateChanged: function(editing) {
                        root.updateDetailsEditing(eventKey, editing)
                    }
                    onHelpRequested: function(message) { root.helpRequested(message) }
                }
            }

            AddEventButton {
                width: parent.width
                visible: !root.hasDraft
                onAddRequested: {
                    root.releaseInputFocusRequested()
                    root.beginDraft()
                    root.addRequested()
                }
                onRootDropRequested: function(draggedId) { root.moveEventToRoot(draggedId) }
                onHelpVisibilityChanged: function(message, visible) {
                    root.helpRequested(visible ? message : "")
                }
            }
        }
    }

    Component.onCompleted: {
        updateSortState()
        replaceSourceEvents(initialEvents)
    }
}

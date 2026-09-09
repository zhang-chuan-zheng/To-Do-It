import QtQuick
import QtQuick.Controls

FieldFrame {
    id: root
    property string text: ""
    property bool allowEmpty: true
    property bool invalidInput: false
    property bool synchronizingText: false
    readonly property var digitPositions: [0, 1, 2, 3, 5, 6, 8, 9, 11, 12, 14, 15]
    readonly property bool editing: dateInput.activeFocus
    readonly property bool visuallyEmpty: digitText(dateInput.text).length === 0
    signal valueEdited(string value)
    signal validationFailed(string message)
    contentPadding: Metrics.spacingSmall

    function digitText(value) {
        return String(value || "").replace(/\D/g, "")
    }

    function blankDisplayValue() {
        return "    " + "-" + "  " + "-" + "  " + " " + "  " + ":" + "  "
    }

    function displayValueFromDigits(digits) {
        let value = blankDisplayValue().split("")
        for (let index = 0; index < Math.min(digits.length, digitPositions.length); ++index)
            value[digitPositions[index]] = digits.charAt(index)
        return value.join("")
    }

    function completeDigits(value) {
        let digits = ""
        for (let index = 0; index < digitPositions.length; ++index) {
            const character = String(value || "").charAt(digitPositions[index])
            if (!/^\d$/.test(character))
                return ""
            digits += character
        }
        return digits
    }

    function setEditorText(value, cursorPosition) {
        synchronizingText = true
        dateInput.text = value
        dateInput.cursorPosition = Math.max(0, Math.min(16, cursorPosition))
        synchronizingText = false
    }

    function replaceCharacter(value, position, character) {
        return value.substring(0, position) + character + value.substring(position + 1)
    }

    function digitPositionAtOrAfter(position) {
        for (let index = 0; index < digitPositions.length; ++index) {
            if (digitPositions[index] >= position)
                return digitPositions[index]
        }
        return -1
    }

    function digitPositionBefore(position) {
        for (let index = digitPositions.length - 1; index >= 0; --index) {
            if (digitPositions[index] < position)
                return digitPositions[index]
        }
        return -1
    }

    function clearSelection(value) {
        const selectionBegin = Math.min(dateInput.selectionStart, dateInput.selectionEnd)
        const selectionEnd = Math.max(dateInput.selectionStart, dateInput.selectionEnd)
        let result = value
        for (let index = 0; index < digitPositions.length; ++index) {
            const position = digitPositions[index]
            if (position >= selectionBegin && position < selectionEnd)
                result = replaceCharacter(result, position, " ")
        }
        return result
    }

    function enterDigit(digit) {
        let value = dateInput.text.length === 16 ? dateInput.text : blankDisplayValue()
        let position = dateInput.cursorPosition
        if (dateInput.selectionStart !== dateInput.selectionEnd) {
            position = Math.min(dateInput.selectionStart, dateInput.selectionEnd)
            value = clearSelection(value)
        }
        const targetPosition = digitPositionAtOrAfter(position)
        if (targetPosition < 0)
            return
        value = replaceCharacter(value, targetPosition, digit)
        const nextPosition = digitPositionAtOrAfter(targetPosition + 1)
        setEditorText(value, nextPosition < 0 ? 16 : nextPosition)
        invalidInput = false
    }

    function eraseBackward() {
        let value = dateInput.text.length === 16 ? dateInput.text : blankDisplayValue()
        let cursorPosition = dateInput.cursorPosition
        if (dateInput.selectionStart !== dateInput.selectionEnd) {
            cursorPosition = Math.min(dateInput.selectionStart, dateInput.selectionEnd)
            value = clearSelection(value)
            setEditorText(value, cursorPosition)
            return
        }
        const targetPosition = digitPositionBefore(cursorPosition)
        if (targetPosition >= 0)
            setEditorText(replaceCharacter(value, targetPosition, " "), targetPosition)
    }

    function eraseForward() {
        let value = dateInput.text.length === 16 ? dateInput.text : blankDisplayValue()
        let cursorPosition = dateInput.cursorPosition
        if (dateInput.selectionStart !== dateInput.selectionEnd) {
            cursorPosition = Math.min(dateInput.selectionStart, dateInput.selectionEnd)
            value = clearSelection(value)
            setEditorText(value, cursorPosition)
            return
        }
        const targetPosition = digitPositionAtOrAfter(cursorPosition)
        if (targetPosition >= 0)
            setEditorText(replaceCharacter(value, targetPosition, " "), cursorPosition)
    }

    function loadValue(value) {
        const digits = digitText(value)
        setEditorText(digits.length === 12 ? displayValueFromDigits(digits)
                                          : blankDisplayValue(), 0)
        invalidInput = false
    }

    function daysInMonth(year, month) {
        if (month === 2) {
            const leapYear = year % 400 === 0 || (year % 4 === 0 && year % 100 !== 0)
            return leapYear ? 29 : 28
        }
        return [4, 6, 9, 11].indexOf(month) >= 0 ? 30 : 31
    }

    function commit() {
        const enteredDigits = digitText(dateInput.text)
        if (enteredDigits.length === 0) {
            if (!allowEmpty) {
                invalidInput = true
                validationFailed(qsTr("开始时间不能为空"))
                return
            }
            invalidInput = false
            if (text !== "—" && text !== "")
                valueEdited("—")
            return
        }
        const digits = completeDigits(dateInput.text)
        if (digits.length !== 12) {
            invalidInput = true
            validationFailed(qsTr("时间必须完整填写到分钟"))
            return
        }

        const year = Number(digits.substring(0, 4))
        const month = Number(digits.substring(4, 6))
        const day = Number(digits.substring(6, 8))
        const hour = Number(digits.substring(8, 10))
        const minute = Number(digits.substring(10, 12))
        const valid = year >= 1 && year <= 9999
            && month >= 1 && month <= 12
            && day >= 1 && day <= daysInMonth(year, month)
            && hour >= 0 && hour <= 23
            && minute >= 0 && minute <= 59
        if (!valid) {
            invalidInput = true
            validationFailed(qsTr("日期或时间超出有效范围"))
            return
        }

        invalidInput = false
        const value = displayValueFromDigits(digits)
        if (value !== text)
            valueEdited(value)
    }

    onTextChanged: {
        if (!editing)
            loadValue(text)
    }
    Component.onCompleted: loadValue(text)

    TextField {
        id: dateInput
        anchors.fill: parent
        leftPadding: 0
        rightPadding: 0
        topPadding: 0
        bottomPadding: 0
        maximumLength: 16
        inputMethodHints: Qt.ImhDigitsOnly
        selectByMouse: true
        horizontalAlignment: TextInput.AlignHCenter
        verticalAlignment: TextInput.AlignVCenter
        color: root.invalidInput ? Theme.danger : Theme.textSecondary
        selectionColor: Theme.accent
        selectedTextColor: Theme.windowBaseColor
        font.family: Typography.family
        font.pixelSize: Typography.secondarySize
        opacity: activeFocus || !root.visuallyEmpty ? 1 : 0
        background: Item {}
        onTextEdited: {
            if (root.synchronizingText)
                return
            const cursor = cursorPosition
            const digits = root.digitText(text).substring(0, 12)
            root.setEditorText(root.displayValueFromDigits(digits), cursor)
            root.invalidInput = false
        }
        onEditingFinished: root.commit()
        Keys.onReturnPressed: root.commit()
        Keys.onEnterPressed: root.commit()
        Keys.onPressed: function(event) {
            const shortcutModifier = event.modifiers
                & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)
            if (!shortcutModifier && /^\d$/.test(event.text)) {
                root.enterDigit(event.text)
                event.accepted = true
            } else if (event.key === Qt.Key_Backspace) {
                root.eraseBackward()
                event.accepted = true
            } else if (event.key === Qt.Key_Delete) {
                root.eraseForward()
                event.accepted = true
            } else if (event.key === Qt.Key_Left && !(event.modifiers & Qt.ShiftModifier)) {
                dateInput.deselect()
                dateInput.cursorPosition = Math.max(0, dateInput.cursorPosition - 1)
                event.accepted = true
            } else if (event.key === Qt.Key_Right && !(event.modifiers & Qt.ShiftModifier)) {
                dateInput.deselect()
                dateInput.cursorPosition = Math.min(16, dateInput.cursorPosition + 1)
                event.accepted = true
            }
        }
    }

    Label {
        visible: root.visuallyEmpty && !dateInput.activeFocus
        anchors.centerIn: parent
        text: "—"
        color: Theme.textMuted
        font.family: Typography.family
        font.pixelSize: Typography.secondarySize

        TapHandler {
            onTapped: {
                dateInput.forceActiveFocus(Qt.MouseFocusReason)
                dateInput.cursorPosition = 0
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -Metrics.spacingSmall
        visible: root.invalidInput
        color: "transparent"
        radius: Metrics.radiusSmall
        border.width: 1
        border.color: Theme.danger
    }
}

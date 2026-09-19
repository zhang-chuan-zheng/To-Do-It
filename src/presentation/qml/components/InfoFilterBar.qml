import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property alias selectedStatus: filterBox.selectedStatus
    property alias filterOptions: filterBox.options
    property alias summaryLabel: statusSummary.label
    property alias matchedCount: statusSummary.matchedCount
    property alias totalCount: statusSummary.totalCount
    property alias quote: quoteBanner.quote
    property alias quoteAuthor: quoteBanner.author
    signal filterRequested(string status)
    signal quoteRefreshRequested()
    signal helpRequested(string message)

    RowLayout {
        anchors.fill: parent
        spacing: Metrics.spacingSmall
        QuoteBanner {
            id: quoteBanner
            Layout.fillWidth: true
            Layout.minimumWidth: 360
            Layout.fillHeight: true
            onRefreshRequested: root.quoteRefreshRequested()
            onHelpRequested: function(message) { root.helpRequested(message) }
        }
        StatusFilterComboBox {
            id: filterBox
            Layout.preferredWidth: implicitWidth
            Layout.fillHeight: true
            onFilterRequested: function(status) { root.filterRequested(status) }
            onHelpVisibilityChanged: function(message, visible) { root.helpRequested(visible ? message : "") }
        }
        StatusSummary {
            id: statusSummary
            Layout.preferredWidth: implicitWidth
            Layout.fillHeight: true
        }
    }
}

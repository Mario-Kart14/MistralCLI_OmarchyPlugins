import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

Panel {
    id: root
    moduleName: "omarchy.vibe"
    ipcTarget: "omarchy.vibe"
    manageIpc: false

    readonly property color foreground: bar ? bar.foreground : Color.foreground
    readonly property color urgent: bar ? bar.urgent : Color.urgent
    readonly property color dim: Qt.darker(foreground, 1.55)
    readonly property color surface: Color.popups.background
    readonly property color track: Style.selectedFillFor(foreground, Color.accent)
    readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

    property bool cursorActive: false
    property double nowMs: Date.now()

    // Simulated provider data for Vibe CLI
    readonly property var provider: ({
        "providerId": "vibe",
        "providerName": "Vibe CLI",
        "tierLabel": "Mistral",
        "usageStatusText": "Mistral AI",
        "authHelpText": "Vibe CLI is configured and ready to use",
        "hasPromptStats": true,
        "todayPrompts": 0,
        "todaySessions": 0,
        "limits": [
            {
                "label": "Session (5-hour)",
                "percent": 0.25,
                "resetsAt": new Date(Date.now() + 2 * 3600 * 1000).toISOString(),
                "title": "Session"
            },
            {
                "label": "Weekly",
                "percent": 0.45,
                "resetsAt": new Date(Date.now() + 3 * 24 * 3600 * 1000).toISOString(),
                "title": "Weekly"
            }
        ],
        "balance": null,
        "modelUsage": {
            "mistral-large": {"inputTokens": 15240, "outputTokens": 8760, "cacheReadInputTokens": 0, "cacheCreationInputTokens": 0},
            "mistral-small": {"inputTokens": 8760, "outputTokens": 5120, "cacheReadInputTokens": 0, "cacheCreationInputTokens": 0},
            "codestral": {"inputTokens": 5120, "outputTokens": 2480, "cacheReadInputTokens": 0, "cacheCreationInputTokens": 0},
            "mistral-embed": {"inputTokens": 2480, "outputTokens": 1200, "cacheReadInputTokens": 0, "cacheCreationInputTokens": 0}
        },
        "recentDays": [
            {"date": "2024-09-15", "messageCount": 23400},
            {"date": "2024-09-14", "messageCount": 18900},
            {"date": "2024-09-13", "messageCount": 15600},
            {"date": "2024-09-12", "messageCount": 12300},
            {"date": "2024-09-11", "messageCount": 9800},
            {"date": "2024-09-10", "messageCount": 7500},
            {"date": "2024-09-09", "messageCount": 5200}
        ],
        "syncEnabled": false,
        "syncDeviceCount": 0
    })

    readonly property var providers: [root.provider]
    property string selectedProviderId: "vibe"
    readonly property int providerIndex: 0
    readonly property var limits: limitWindows(provider)
    readonly property var models: modelRows(provider)
    readonly property var headline: bindingWindow(provider)
    readonly property var balance: null
    readonly property bool balanceAlarming: false
    readonly property bool alarming: (!!headline && headline.percent >= 0.9) || balanceAlarming

    function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)) }
    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

    function selectProvider(index) {
        if (providers.length === 0) return
        var wrapped = ((index % providers.length) + providers.length) % providers.length
        selectedProviderId = providers[wrapped].providerId
    }

    function refreshNow() {
        // Simulated refresh - in real implementation this would call usage.refreshAll(true)
        nowMs = Date.now()
    }

    function launchAgent() {
        if (root.bar) root.bar.run("vibe")
        root.close()
    }

    function setAsDefaultAgent() {
        Quickshell.exec("omarchy", ["default", "agent", "vibe"])
        root.close()
    }

    // Functions from omarchy.agents Panel.qml
    function windowIsLong(text) {
        return text.indexOf("week") >= 0 || text.indexOf("7-day") >= 0 || text.indexOf("seven") >= 0
          || text.indexOf("month") >= 0 || text.indexOf("30-day") >= 0
    }

    function windowSpanMs(label) {
        var text = String(label || "").toLowerCase()
        if (text.indexOf("month") >= 0 || text.indexOf("30-day") >= 0) return 30 * 24 * 3600 * 1000
        if (windowIsLong(text)) return 7 * 24 * 3600 * 1000
        var hours = text.match(/(\\d+)\\s*-?\\s*h(?:our)?\\b/)
        if (hours) return Number(hours[1]) * 3600 * 1000
        var minutes = text.match(/(\\d+)\\s*-?\\s*m(?:in(?:ute)?s?)?\\b/)
        if (minutes) return Number(minutes[1]) * 60 * 1000
        return 0
    }

    function windowTitle(label) {
        var text = String(label || "").toLowerCase()
        if (text.indexOf("month") >= 0) return "Monthly"
        if (windowIsLong(text)) return "Weekly"
        if (text.indexOf("session") >= 0 || windowSpanMs(label) > 0) return "Session"
        var plain = String(label || "").replace(/\\s*\\(.*\\)\\s*/, "").trim()
        return plain === "" ? "Limit" : plain
    }

    function limitWindow(label, percent, resetAt, title) {
        return {
            title: String(title || "") !== "" ? String(title) : windowTitle(label),
            percent: Number(percent),
            resetAt: String(resetAt || "")
        }
    }

    function limitWindows(p) {
        if (!p) return []
        var out = []
        var list = p.limits || []
        for (var i = 0; i < list.length; i++) {
            var entry = list[i] || {}
            var percent = Number(entry.percent)
            if (percent >= 0) out.push(limitWindow(entry.label, percent, entry.resetsAt, entry.title))
        }
        return out
    }

    function bindingWindow(p) {
        var windows = limitWindows(p)
        var best = null
        for (var i = 0; i < windows.length; i++) {
            if (!best || windows[i].percent > best.percent) best = windows[i]
        }
        return best
    }

    function resetMsFor(w) {
        if (!w || w.resetAt === "") return -1
        var ms = new Date(w.resetAt).getTime()
        return isFinite(ms) ? ms - root.nowMs : -1
    }

    function formatDuration(ms) {
        if (!(ms > 0)) return "now"
        var minutes = Math.floor(ms / 60000)
        var hours = Math.floor(minutes / 60)
        var days = Math.floor(hours / 24)
        if (days > 0) return days + "d " + (hours % 24) + "h"
        if (hours > 0) return hours + "h " + (minutes % 60) + "m"
        return Math.max(1, minutes) + "m"
    }

    function heroMeta(p) {
        if (!p) return ""
        if (String(p.usageStatusText || "") !== "") return p.usageStatusText
        var tier = String(p.tierLabel || "")
        if (tier === "") return "Subscription"
        return tier.charAt(0).toUpperCase() + tier.slice(1)
    }

    function todayDate() {
        var now = new Date(root.nowMs)
        return now.getFullYear() + "-" + String(now.getMonth() + 1).padStart(2, "0") + "-" + String(now.getDate()).padStart(2, "0")
    }

    function dayName(date) {
        var parsed = new Date(String(date || "") + "T00:00:00")
        if (isNaN(parsed.getTime())) return String(date || "")
        return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][parsed.getDay()]
    }

    function dayLabel(date, today) {
        if (today) return "Today"
        return dayName(date)
    }

    function dayTooltip(day, today) {
        if (!day) return ""
        var parsed = new Date(String(day.date) + "T00:00:00")
        var label = isNaN(parsed.getTime()) ? String(day.date) : dayName(day.date) + " " + (parsed.getMonth() + 1) + "/" + parsed.getDate()
        var text = label + " \u2022 " + formatTokenCount(Number(day.messageCount || 0)) + " tokens"
        if (today && provider && provider.hasPromptStats !== false)
            text += " \u2022 " + Number(provider.todayPrompts || 0) + " prompts \u2022 " + Number(provider.todaySessions || 0) + " sessions"
        return text
    }

    function weekPeak(p) {
        var days = p ? (p.recentDays || []) : []
        var peak = 0
        for (var i = 0; i < days.length; i++) peak = Math.max(peak, Number(days[i].messageCount || 0))
        return peak
    }

    function modelRows(p) {
        var usageByModel = p ? (p.modelUsage || {}) : {}
        var rows = []
        for (var id in usageByModel) {
            var bucket = usageByModel[id] || {}
            var input = Number(bucket.inputTokens || 0)
            var output = Number(bucket.outputTokens || 0)
            var cacheRead = Number(bucket.cacheReadInputTokens || 0)
            var cacheWrite = Number(bucket.cacheCreationInputTokens || 0)
            rows.push({
                name: id,
                total: input + output + cacheRead + cacheWrite,
                input: input,
                output: output,
                cacheRead: cacheRead,
                cacheWrite: cacheWrite
            })
        }
        rows.sort(function(a, b) { return b.total - a.total })
        return rows.slice(0, 4)
    }

    function modelTooltip(row) {
        if (!row) return ""
        return "In " + formatTokenCount(row.input) + " \u2022 out " + formatTokenCount(row.output) + " \u2022 cache read " + formatTokenCount(row.cacheRead) + " \u2022 cache write " + formatTokenCount(row.cacheWrite)
    }

    function footerText() {
        if (provider && provider.syncEnabled && provider.syncDeviceCount > 0)
            return "Merged from " + provider.syncDeviceCount + " device" + (provider.syncDeviceCount === 1 ? "" : "s")
        return ""
    }

    function formatTokenCount(count) {
        if (count >= 1000000) return (count / 1000000).toFixed(1) + "M"
        if (count >= 1000) return (count / 1000).toFixed(1) + "K"
        return count.toString()
    }

    function iconCandidatesForProvider(p, surfaceColor) {
        if (!p) return []
        var candidates = []
        // For Vibe CLI, we'll use the lightning bolt emoji as icon
        return candidates
    }

    visible: providers.length > 0
    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    onProviderIndexChanged: if (panelFlick) panelFlick.contentY = 0
    onOpenedChanged: if (opened) {
        cursorActive = false
        nowMs = Date.now()
        if (panelFlick) panelFlick.contentY = 0
        Qt.callLater(function() { keyCatcher.forceActiveFocus() })
    }

    Timer {
        interval: 30000
        running: root.opened
        repeat: true
        onTriggered: root.nowMs = Date.now()
    }

    IpcHandler {
        target: root.ipcTarget
        function open(): void { root.open() }
        function close(): void { root.close() }
        function show(): void { root.open() }
        function hide(): void { root.close() }
        function toggle(): void { root.toggle() }
        function refresh(): string { root.refreshNow(); return "ok" }
        function next(): string { root.selectProvider(root.providerIndex + 1); return "ok" }
    }

    BarIconButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        text: "⚡"
        active: root.alarming
        onPressed: function(buttonCode) {
            if (buttonCode === Qt.RightButton) root.launchAgent()
            else if (buttonCode === Qt.MiddleButton) root.selectProvider(root.providerIndex + 1)
            else root.toggle()
        }
    }

    KeyboardPanel {
        id: panel
        anchorItem: button
        owner: root
        bar: root.bar
        open: root.opened
        focusTarget: keyCatcher
        contentWidth: panel.fittedContentWidth(Style.space(380))
        contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(640))

        PanelKeyCatcher {
            id: keyCatcher
            anchors.fill: parent

            onMoveRequested: function(dx, dy) {
                if (dx !== 0) {
                    root.cursorActive = true
                    root.selectProvider(root.providerIndex + dx)
                }
                if (dy !== 0)
                    panelFlick.contentY = root.clamp(panelFlick.contentY + dy * Style.space(56), 0,
                                               Math.max(0, panelFlick.contentHeight - panelFlick.height))
            }
            onActivateRequested: root.refreshNow()
            onCloseRequested: root.close()
            onTabRequested: function(direction) { root.switchPanel(direction) }
            onTextKey: function(t) { if (t === "r" || t === "R") root.refreshNow() }

            Flickable {
                id: panelFlick
                anchors.fill: parent
                contentWidth: width
                contentHeight: column.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick
                interactive: contentHeight > height

                Column {
                    id: column
                    width: panelFlick.width
                    spacing: Style.space(12)

                    PanelHero {
                        id: hero
                        visible: !!root.provider
                        width: parent.width
                        title: root.provider ? root.provider.providerName : ""
                        meta: root.heroMeta(root.provider)
                        foreground: root.foreground
                        fontFamily: root.fontFamily

                        iconComponent: Component {
                            Item {
                                id: heroMark
                                width: Style.font.display
                                height: Style.font.display

                                Text {
                                    textFormat: Text.PlainText
                                    anchors.centerIn: parent
                                    text: "⚡"
                                    color: root.foreground
                                    font.family: root.fontFamily
                                    font.pixelSize: Style.font.display
                                }
                            }
                        }
                    }

                    Text {
                        visible: root.providers.length === 0
                        width: parent.width
                        topPadding: Style.space(24)
                        text: "No AI coding subscriptions found.\nAgents show up here once you've used them."
                        color: root.dim
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.body
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }

                    Row {
                        id: providerSwitch
                        visible: root.providers.length > 1
                        width: parent.width
                        spacing: Style.spacing.md

                        readonly property real cellWidth: root.providers.length > 0
                          ? (width - spacing * (root.providers.length - 1)) / root.providers.length
                          : 0

                        Repeater {
                            model: root.providers
                            Button {
                                required property var modelData
                                required property int index

                                width: providerSwitch.cellWidth
                                text: modelData.providerName
                                selected: index === root.providerIndex
                                hasCursor: root.cursorActive && index === root.providerIndex
                                bordered: true
                                foreground: root.foreground
                                fontFamily: root.fontFamily
                                fontSize: Style.font.bodySmall
                                verticalPadding: Style.spacing.controlPaddingY
                                onClicked: {
                                    root.cursorActive = true
                                    root.selectProvider(index)
                                }
                                onHovered: function(isHovered) { if (isHovered) root.cursorActive = true }
                            }
                        }
                    }

                    BorderSurface {
                        visible: !!root.provider && String(root.provider.usageStatusText || "") !== ""
                        width: parent.width
                        implicitHeight: statusText.implicitHeight + Style.spacing.xl * 2
                        color: root.alpha(root.urgent, 0.10)
                        borderSpec: Border.flat(root.alpha(root.urgent, 0.35), 1)
                        radius: Style.cornerRadius

                        Text {
                            id: statusText
                            textFormat: Text.PlainText
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: Style.space(12)
                            anchors.rightMargin: Style.space(12)
                            text: root.provider ? String(root.provider.authHelpText || "") : ""
                            color: root.dim
                            font.family: root.fontFamily
                            font.pixelSize: Style.font.caption
                            wrapMode: Text.WordWrap
                        }
                    }

                    PanelSeparator {
                        visible: limitsSection.visible
                        foreground: root.foreground
                    }

                    Column {
                        id: limitsSection
                        visible: root.limits.length > 0
                        width: parent.width
                        spacing: Style.space(10)

                        PanelSectionHeader {
                            text: "LIMITS"
                            foreground: root.foreground
                            fontFamily: root.fontFamily
                        }

                        Repeater {
                            model: root.limits
                            LimitRow {
                                required property var modelData
                                width: limitsSection.width
                                window: modelData
                            }
                        }
                    }

                    PanelSeparator {
                        visible: usageSection.visible
                        foreground: root.foreground
                    }

                    Column {
                        id: usageSection
                        visible: !!root.provider && root.provider.recentDays && root.provider.recentDays.length > 0
                        width: parent.width
                        spacing: Style.spacing.md

                        readonly property var days: root.provider ? (root.provider.recentDays || []) : []
                        readonly property real peak: Math.max(1, root.weekPeak(root.provider))

                        PanelSectionHeader {
                            width: parent.width
                            text: "TOKENS BY DAY"
                            foreground: root.foreground
                            fontFamily: root.fontFamily
                        }

                        Repeater {
                            model: usageSection.days
                            DayRow {
                                required property var modelData
                                required property int index

                                width: usageSection.width
                                day: modelData
                                ratio: Number(modelData.messageCount || 0) / usageSection.peak
                                today: String(modelData.date || "") === root.todayDate()
                            }
                        }
                    }

                    PanelSeparator {
                        visible: modelSection.visible
                        foreground: root.foreground
                    }

                    Column {
                        id: modelSection
                        visible: root.models.length > 0
                        width: parent.width
                        spacing: Style.spacing.md

                        PanelSectionHeader {
                            width: parent.width
                            text: "TOKENS BY MODEL"
                            foreground: root.foreground
                            fontFamily: root.fontFamily
                        }

                        Repeater {
                            model: root.models
                            ModelRow {
                                required property var modelData
                                width: modelSection.width
                                row: modelData
                                share: modelData.total / Math.max(1, root.models[0].total)
                            }
                        }
                    }

                    WidgetButton {
                        width: parent.width
                        text: "Set as Default Agent"
                        tooltipText: "Set Vibe CLI as the default AI agent"
                        onPressed: setAsDefaultAgent()
                    }

                    Text {
                        textFormat: Text.PlainText
                        visible: text !== ""
                        width: parent.width
                        topPadding: Style.space(2)
                        text: root.footerText()
                        color: root.dim
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }

    component LimitRow: Column {
        id: limitRow
        property var window: null

        readonly property bool alarming: window && window.percent >= 0.9

        spacing: Style.space(6)

        Item {
            width: parent.width
            implicitHeight: Math.max(limitLabel.implicitHeight, limitValue.implicitHeight)

            Text {
                id: limitLabel
                textFormat: Text.PlainText
                text: limitRow.window ? limitRow.window.title : ""
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                elide: Text.ElideRight
                anchors.left: parent.left
                anchors.right: limitValue.left
                anchors.rightMargin: Style.spacing.sm
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                id: limitValue
                textFormat: Text.PlainText
                text: limitRow.window && limitRow.window.percent >= 0 ? Math.round(limitRow.window.percent * 100) + "%" : "\u2014"
                color: limitRow.alarming ? root.urgent : root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Meter {
            width: parent.width
            value: limitRow.window ? limitRow.window.percent : -1
            alarming: limitRow.alarming
        }

        Text {
            id: resetText
            textFormat: Text.PlainText
            width: parent.width
            text: {
                var remainingMs = root.resetMsFor(limitRow.window)
                return remainingMs > 0 ? "Resets in " + root.formatDuration(remainingMs) : ""
            }
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
        }
    }

    component Meter: Item {
        id: meter
        property real value: -1
        property bool alarming: false
        property real thickness: Math.max(Style.space(4), Math.round(Style.spacing.controlHeight * 0.14))

        implicitHeight: thickness

        Rectangle {
            id: meterTrack
            anchors.fill: parent
            radius: height / 2
            color: root.track
        }

        Rectangle {
            anchors.left: meterTrack.left
            anchors.verticalCenter: meterTrack.verticalCenter
            height: meterTrack.height
            radius: meterTrack.radius
            width: meterTrack.width * root.clamp(meter.value, 0, 1)
            color: meter.alarming ? root.urgent : root.foreground

            Behavior on width {
                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
            }
        }
    }

    component DayRow: Item {
        id: dayRow
        property var day: null
        property real ratio: 0
        property bool today: false

        implicitHeight: Math.max(dayLabel.implicitHeight, dayValue.implicitHeight) + Style.spacing.sm

        Text {
            id: dayLabel
            textFormat: Text.PlainText
            text: root.dayLabel(dayRow.day ? dayRow.day.date : "", dayRow.today)
            color: dayRow.today ? root.foreground : root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: dayRow.today
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: Style.space(52)
        }

        Rectangle {
            id: dayTrack
            anchors.left: dayLabel.right
            anchors.right: dayValue.left
            anchors.leftMargin: Style.space(8)
            anchors.rightMargin: Style.space(10)
            anchors.verticalCenter: parent.verticalCenter
            height: Math.max(Style.space(4), Math.round(Style.spacing.controlHeight * 0.14))
            radius: height / 2
            color: root.track

            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                radius: parent.radius
                width: parent.width * root.clamp(dayRow.ratio, 0, 1)
                color: dayRow.today ? root.foreground : root.alpha(root.foreground, 0.55)

                Behavior on width {
                    NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                }
            }
        }

        Text {
            id: dayValue
            textFormat: Text.PlainText
            text: root.formatTokenCount(dayRow.day ? Number(dayRow.day.messageCount || 0) : 0)
            color: dayRow.today ? root.foreground : root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            horizontalAlignment: Text.AlignRight
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: Style.space(52)
        }

        MouseArea {
            id: dayHover
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }

        PanelToolTip {
            visible: dayHover.containsMouse
            text: root.dayTooltip(dayRow.day, dayRow.today)
            fontFamily: root.fontFamily
        }
    }

    component ModelRow: Item {
        id: modelRow
        property var row: null
        property real share: 0

        implicitHeight: modelName.implicitHeight + Style.spacing.lg

        Rectangle {
            anchors.fill: parent
            radius: Style.cornerRadius
            color: root.alpha(root.foreground, 0.05)
        }

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * root.clamp(modelRow.share, 0, 1)
            radius: Style.cornerRadius
            color: root.alpha(root.foreground, 0.14)

            Behavior on width {
                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
            }
        }

        Text {
            id: modelName
            textFormat: Text.PlainText
            text: modelRow.row ? modelRow.row.name : ""
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            elide: Text.ElideRight
            anchors.left: parent.left
            anchors.leftMargin: Style.space(8)
            anchors.right: modelTokens.left
            anchors.rightMargin: Style.space(8)
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            id: modelTokens
            textFormat: Text.PlainText
            text: modelRow.row ? root.formatTokenCount(modelRow.row.total) : ""
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            font.bold: true
            anchors.right: parent.right
            anchors.rightMargin: Style.space(8)
            anchors.verticalCenter: parent.verticalCenter
        }

        MouseArea {
            id: modelHover
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }

        PanelToolTip {
            visible: modelHover.containsMouse
            text: root.modelTooltip(modelRow.row)
            fontFamily: root.fontFamily
        }
    }
}

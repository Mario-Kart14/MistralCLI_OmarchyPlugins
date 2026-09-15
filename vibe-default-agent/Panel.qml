import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

Panel {
    id: root
    moduleName: "io.github.mario-kart14.vibe-default-agent"
    manageIpc: false

    readonly property color foreground: bar ? bar.foreground : Color.foreground
    readonly property color urgent: bar ? bar.urgent : Color.urgent
    readonly property color dim: Qt.darker(foreground, 1.55)
    readonly property color surface: Color.popups.background
    readonly property color track: Style.selectedFillFor(foreground, Color.accent)
    readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

    property var anchorItem: null
    property var hostWidget: null
    property string defaultAgent: ""

    // Données d'utilisation simulées pour Vibe CLI
    property var usageData: {
        "models": [
            {"name": "mistral-large", "tokens": 15240, "percent": 32},
            {"name": "mistral-small", "tokens": 8760, "percent": 18},
            {"name": "codestral", "tokens": 5120, "percent": 11},
            {"name": "mistral-embed", "tokens": 2480, "percent": 5}
        ],
        "daily": [
            {"date": "2024-09-15", "tokens": 23400, "isToday": true},
            {"date": "2024-09-14", "tokens": 18900, "isToday": false},
            {"date": "2024-09-13", "tokens": 15600, "isToday": false},
            {"date": "2024-09-12", "tokens": 12300, "isToday": false},
            {"date": "2024-09-11", "tokens": 9800, "isToday": false},
            {"date": "2024-09-10", "tokens": 7500, "isToday": false},
            {"date": "2024-09-09", "tokens": 5200, "isToday": false}
        ],
        "monthly": 456780
    }

    property bool cursorActive: false
    property double nowMs: Date.now()

    function open() {
        root.controller.show()
    }

    function close() {
        root.controller.hide()
    }

    function switchPanel(direction) {
        if (root.bar && typeof root.bar.switchPanelFrom === "function")
            return root.bar.switchPanelFrom(root.hostWidget || root, direction)
        return false
    }

    function setAsDefaultAgent() {
        Quickshell.exec("omarchy", ["default", "agent", "vibe"])
        defaultAgent = "vibe"
        close()
    }

    function checkVibeInstalled() {
        Quickshell.exec("which", ["vibe"])
    }

    function launchVibe() {
        Quickshell.execDetached("vibe")
        close()
    }

    // Fonction pour formater les tokens
    function formatTokenCount(count) {
        if (count >= 1000000) return (count / 1000000).toFixed(1) + "M"
        if (count >= 1000) return (count / 1000).toFixed(1) + "K"
        return count.toString()
    }

    // Fonction pour obtenir la date d'aujourd'hui
    function todayDate() {
        var now = new Date(root.nowMs)
        return now.getFullYear() + "-" + String(now.getMonth() + 1).padStart(2, "0") + "-" + String(now.getDate()).padStart(2, "0")
    }

    // Mise à jour initiale
    Component.onCompleted: {
        // Vérifier l'agent par défaut actuel
        var process = Qt.createQmlObject('import QtCore 3.0; Process {}', root)
        process.program = "omarchy"
        process.arguments = ["default", "agent"]
        process.start()
        process.waitForFinished(1000)
        var output = process.readAllStandardOutput().toString().trim()
        if (output) {
            defaultAgent = output
        }
        process.destroy()
    }

    // Timer pour rafraîchir les données
    Timer {
        interval: 30000
        running: root.opened
        repeat: true
        onTriggered: root.nowMs = Date.now()
    }

    KeyboardPanel {
        id: panel
        anchorItem: root.anchorItem
        owner: root.hostWidget || root
        bar: root.bar
        open: root.opened
        focusTarget: keyCatcher
        contentWidth: panel.fittedContentWidth(Style.space(380))
        contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(640))

        PanelKeyCatcher {
            id: keyCatcher
            anchors.fill: parent
            onCloseRequested: root.close()
            onTabRequested: function(direction) { root.switchPanel(direction) }

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

                    // Hero: icône + titre + statut
                    PanelHero {
                        id: hero
                        visible: true
                        width: parent.width
                        title: "Vibe CLI"
                        meta: defaultAgent === "vibe" ? "Default Agent" : "Not Default"
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

                    // Statut de l'agent par défaut
                    BorderSurface {
                        visible: true
                        width: parent.width
                        implicitHeight: statusText.implicitHeight + Style.spacing.xl * 2
                        color: root.alpha(root.urgent, defaultAgent === "vibe" ? 0.10 : 0.05)
                        borderSpec: Border.flat(root.alpha(root.foreground, 0.2), 1)
                        radius: Style.cornerRadius

                        Text {
                            id: statusText
                            textFormat: Text.PlainText
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: Style.space(12)
                            anchors.rightMargin: Style.space(12)
                            text: defaultAgent === "vibe" ? "Vibe CLI is your default AI agent" : "Vibe CLI is not the default agent"
                            color: defaultAgent === "vibe" ? root.foreground : root.dim
                            font.family: root.fontFamily
                            font.pixelSize: Style.font.caption
                            wrapMode: Text.WordWrap
                        }
                    }

                    // Séparateur
                    PanelSeparator {
                        visible: true
                        foreground: root.foreground
                    }

                    // Tokens par modèle
                    Column {
                        id: modelSection
                        visible: true
                        width: parent.width
                        spacing: Style.spacing.md

                        PanelSectionHeader {
                            width: parent.width
                            text: "TOKENS BY MODEL"
                            foreground: root.foreground
                            fontFamily: root.fontFamily
                        }

                        Repeater {
                            model: root.usageData.models

                            ModelRow {
                                required property var modelData
                                width: modelSection.width
                                row: modelData
                                share: modelData.tokens / Math.max(1, root.usageData.models[0].tokens)
                            }
                        }
                    }

                    // Séparateur
                    PanelSeparator {
                        visible: true
                        foreground: root.foreground
                    }

                    // Tokens par jour
                    Column {
                        id: usageSection
                        visible: true
                        width: parent.width
                        spacing: Style.spacing.md

                        readonly property real peak: Math.max.apply(null, root.usageData.daily.map(function(d) { return d.tokens }))

                        PanelSectionHeader {
                            width: parent.width
                            text: "TOKENS BY DAY"
                            foreground: root.foreground
                            fontFamily: root.fontFamily
                        }

                        Repeater {
                            model: root.usageData.daily

                            DayRow {
                                required property var modelData
                                required property int index
                                width: usageSection.width
                                day: modelData
                                ratio: Number(modelData.tokens) / usageSection.peak
                                today: modelData.isToday || (String(modelData.date) === root.todayDate())
                            }
                        }
                    }

                    // Séparateur
                    PanelSeparator {
                        visible: true
                        foreground: root.foreground
                    }

                    // Tokens par mois
                    Column {
                        id: monthlySection
                        visible: true
                        width: parent.width
                        spacing: Style.spacing.md

                        PanelSectionHeader {
                            width: parent.width
                            text: "TOKENS BY MONTH"
                            foreground: root.foreground
                            fontFamily: root.fontFamily
                        }

                        Item {
                            width: parent.width
                            implicitHeight: Math.max(monthlyLabel.implicitHeight, monthlyValue.implicitHeight)

                            Text {
                                id: monthlyLabel
                                text: "This Month"
                                color: root.foreground
                                font.family: root.fontFamily
                                font.pixelSize: Style.font.body
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                id: monthlyValue
                                textFormat: Text.PlainText
                                text: root.formatTokenCount(root.usageData.monthly)
                                color: root.foreground
                                font.family: root.fontFamily
                                font.pixelSize: Style.font.caption
                                font.bold: true
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Meter {
                            visible: true
                            width: parent.width
                            value: Math.min(1, root.usageData.monthly / 500000) // Supposons un limite de 500K tokens/mois
                            alarming: root.usageData.monthly / 500000 >= 0.9
                        }

                        Text {
                            textFormat: Text.PlainText
                            visible: true
                            width: parent.width
                            text: root.formatTokenCount(root.usageData.monthly) + " of 500K tokens used"
                            color: root.dim
                            font.family: root.fontFamily
                            font.pixelSize: Style.font.caption
                        }
                    }

                    // Actions
                    Column {
                        width: parent.width
                        spacing: Style.spacing.md

                        WidgetButton {
                            width: parent.width
                            text: defaultAgent === "vibe" ? "✓ Default Agent Set" : "Set as Default Agent"
                            tooltipText: "Set Vibe CLI as the default AI agent"
                            onPressed: setAsDefaultAgent()
                        }

                        WidgetButton {
                            width: parent.width
                            text: "Check Installation"
                            tooltipText: "Check if Vibe CLI is installed"
                            onPressed: checkVibeInstalled()
                        }

                        WidgetButton {
                            width: parent.width
                            text: "Launch Vibe CLI"
                            tooltipText: "Launch Vibe CLI directly"
                            onPressed: launchVibe()
                        }
                    }

                    Text {
                        textFormat: Text.PlainText
                        visible: true
                        width: parent.width
                        topPadding: Style.space(2)
                        text: "Note: Token usage data is simulated. Real usage tracking requires integration with Omarchy's agent system."
                        color: root.dim
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }

    // Composant pour les barres de progression des modèles
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
            text: modelRow.row ? root.formatTokenCount(modelRow.row.tokens) : ""
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
            text: modelRow.row ? "Total: " + root.formatTokenCount(modelRow.row.tokens) + " tokens (" + modelRow.row.percent + "%)" : ""
            fontFamily: root.fontFamily
        }
    }

    // Composant pour les barres de progression des jours
    component DayRow: Item {
        id: dayRow
        property var day: null
        property real ratio: 0
        property bool today: false

        implicitHeight: Math.max(dayLabel.implicitHeight, dayValue.implicitHeight) + Style.spacing.sm

        Text {
            id: dayLabel
            textFormat: Text.PlainText
            text: dayRow.today ? "Today" : root.dayName(dayRow.day ? dayRow.day.date : "")
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
            text: root.formatTokenCount(dayRow.day ? Number(dayRow.day.tokens) : 0)
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
            text: dayRow.day ? root.dayName(dayRow.day.date) + " • " + root.formatTokenCount(dayRow.day.tokens) + " tokens" : ""
            fontFamily: root.fontFamily
        }
    }

    // Fonction pour obtenir le nom du jour
    function dayName(date) {
        var parsed = new Date(String(date || "") + "T00:00:00")
        if (isNaN(parsed.getTime())) return String(date || "")
        return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][parsed.getDay()]
    }

    // Composant Meter (barre de progression)
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
}

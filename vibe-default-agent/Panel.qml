import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

Panel {
    id: root
    moduleName: "io.github.mario-kart14.vibe-default-agent"
    manageIpc: false

    property var anchorItem: null
    property var hostWidget: null
    property string defaultAgent: ""
    property var usageData: ({})

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

    // Fonction pour définir Vibe CLI comme agent par défaut
    function setAsDefaultAgent() {
        Quickshell.exec("omarchy", ["default", "agent", "vibe"])
        defaultAgent = "vibe"
        updateUsageData()
        close()
    }

    // Fonction pour vérifier si Vibe CLI est installé
    function checkVibeInstalled() {
        Quickshell.exec("which", ["vibe"])
    }

    // Fonction pour lancer Vibe CLI
    function launchVibe() {
        Quickshell.execDetached("vibe")
        close()
    }

    // Fonction pour récupérer l'agent par défaut actuel
    function getCurrentDefaultAgent() {
        var process = Qt.createQmlObject('import QtCore 3.0; Process {}', root)
        process.program = "omarchy"
        process.arguments = ["default", "agent"]
        process.start()
        process.waitForFinished()
        var output = process.readAllStandardOutput().toString().trim()
        if (output) {
            defaultAgent = output
        }
        process.destroy()
    }

    // Fonction pour récupérer les données d'utilisation
    function updateUsageData() {
        var process = Qt.createQmlObject('import QtCore 3.0; Process {}', root)
        process.program = "omarchy"
        process.arguments = ["agent", "usage-update"]
        process.start()
        process.waitForFinished()
        
        // Lire les données d'utilisation depuis le fichier Omarchy
        // (Omarchy stocke les données dans ~/.local/share/omarchy/agent-usage.json)
        var usageFile = Qt.createQmlObject('import QtCore 3.0; File {}', root)
        var filePath = "/.local/share/omarchy/agent-usage.json"
        var homePath = QtstandardPaths.standardLocations(QtStandardPaths.HomeLocation)[0]
        var fullPath = homePath + filePath
        
        try {
            var file = new File(fullPath)
            if (file.exists) {
                file.open(QtCore.QIODevice.ReadOnly)
                var jsonData = JSON.parse(file.readAll().toString())
                file.close()
                usageData = jsonData
            }
        } catch (e) {
            console.log("Error reading usage data:", e)
        }
    }

    // Appel initial pour récupérer les données
    Component.onCompleted: {
        getCurrentDefaultAgent()
        updateUsageData()
    }

    KeyboardPanel {
        id: panel
        anchorItem: root.anchorItem
        owner: root.hostWidget || root
        bar: root.bar
        open: root.opened
        focusTarget: keyCatcher
        contentWidth: panel.fittedContentWidth(Style.space(280))
        contentHeight: panel.fittedContentHeight(content.implicitHeight)

        PanelKeyCatcher {
            id: keyCatcher
            anchors.fill: parent
            onCloseRequested: root.close()
            onTabRequested: function(direction) { root.switchPanel(direction) }

            Column {
                id: content
                width: parent.width
                spacing: Style.space(8)
                padding: Style.space(12)

                // En-tête avec icône
                Row {
                    spacing: Style.space(8)
                    
                    Text {
                        text: "🔷"
                        font.pixelSize: Style.font.displayMedium
                    }
                    
                    Text {
                        text: "Vibe CLI Agent"
                        color: root.barForeground
                        font.family: root.bar ? root.bar.fontFamily : Style.font.family
                        font.pixelSize: Style.font.subtitle
                        font.bold: true
                    }
                }

                // Statut de l'agent par défaut
                Row {
                    spacing: Style.space(8)
                    
                    Text {
                        text: "Default Agent:"
                        color: root.barForeground
                        font.family: root.bar ? root.bar.fontFamily : Style.font.family
                        font.pixelSize: Style.font.body
                    }
                    
                    Text {
                        text: defaultAgent ? defaultAgent : "Not set"
                        color: defaultAgent === "vibe" ? "#4CAF50" : "#FF5722"
                        font.family: root.bar ? root.bar.fontFamily : Style.font.family
                        font.pixelSize: Style.font.body
                        font.bold: true
                    }
                }

                // Section Utilisation des tokens
                Text {
                    width: parent.width
                    text: "Token Usage"
                    color: root.barForeground
                    font.family: root.bar ? root.bar.fontFamily : Style.font.family
                    font.pixelSize: Style.font.subtitle
                    font.bold: true
                    wrapMode: Text.WordWrap
                }

                // Utilisation par modèle (simulée - à adapter selon les données réelles)
                Column {
                    spacing: Style.space(4)
                    
                    Text {
                        text: "By Model:"
                        color: root.barForeground
                        font.family: root.bar ? root.bar.fontFamily : Style.font.family
                        font.pixelSize: Style.font.small
                        font.bold: true
                    }
                    
                    Repeater {
                        model: [
                            { name: "mistral-large", tokens: "15,240", percent: "32%" },
                            { name: "mistral-small", tokens: "8,760", percent: "18%" },
                            { name: "codestral", tokens: "5,120", percent: "11%" },
                            { name: "mistral-embed", tokens: "2,480", percent: "5%" }
                        ]
                        
                        delegate: Row {
                            spacing: Style.space(8)
                            
                            Text {
                                width: 120
                                text: modelData.name
                                color: root.barForeground
                                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                                font.pixelSize: Style.font.small
                            }
                            
                            Text {
                                width: 80
                                text: modelData.tokens
                                color: root.barForeground
                                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                                font.pixelSize: Style.font.small
                                horizontalAlignment: Text.AlignRight
                            }
                            
                            Text {
                                text: modelData.percent
                                color: modelData.percent === "32%" ? "#4CAF50" : root.barForeground
                                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                                font.pixelSize: Style.font.small
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }

                // Utilisation par jour
                Text {
                    text: "By Day:"
                    color: root.barForeground
                    font.family: root.bar ? root.bar.fontFamily : Style.font.family
                    font.pixelSize: Style.font.small
                    font.bold: true
                }
                
                Row {
                    spacing: Style.space(8)
                    
                    Text {
                        width: 120
                        text: "Today"
                        color: root.barForeground
                        font.family: root.bar ? root.bar.fontFamily : Style.font.family
                        font.pixelSize: Style.font.small
                    }
                    
                    Text {
                        text: "23,400"
                        color: root.barForeground
                        font.family: root.bar ? root.bar.fontFamily : Style.font.family
                        font.pixelSize: Style.font.small
                        horizontalAlignment: Text.AlignRight
                    }
                    
                    Text {
                        text: "tokens"
                        color: root.barForeground
                        font.family: root.bar ? root.bar.fontFamily : Style.font.family
                        font.pixelSize: Style.font.small
                    }
                }

                // Utilisation par mois
                Text {
                    text: "By Month:"
                    color: root.barForeground
                    font.family: root.bar ? root.bar.fontFamily : Style.font.family
                    font.pixelSize: Style.font.small
                    font.bold: true
                }
                
                Row {
                    spacing: Style.space(8)
                    
                    Text {
                        width: 120
                        text: "This Month"
                        color: root.barForeground
                        font.family: root.bar ? root.bar.fontFamily : Style.font.family
                        font.pixelSize: Style.font.small
                    }
                    
                    Text {
                        text: "456,780"
                        color: root.barForeground
                        font.family: root.bar ? root.bar.fontFamily : Style.font.family
                        font.pixelSize: Style.font.small
                        horizontalAlignment: Text.AlignRight
                    }
                    
                    Text {
                        text: "tokens"
                        color: root.barForeground
                        font.family: root.bar ? root.bar.fontFamily : Style.font.family
                        font.pixelSize: Style.font.small
                    }
                }

                // Séparateur
                Item {
                    height: Style.space(4)
                    width: parent.width
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width * 0.8
                        height: 1
                        color: root.barForeground
                        opacity: 0.3
                    }
                }

                // Bouton pour définir comme agent par défaut
                WidgetButton {
                    width: parent.width
                    text: defaultAgent === "vibe" ? "✓ Default Agent Set" : "Set as Default Agent"
                    tooltipText: "Set Vibe CLI as the default AI agent"
                    onPressed: setAsDefaultAgent()
                }

                // Bouton pour vérifier l'installation
                WidgetButton {
                    width: parent.width
                    text: "Check Installation"
                    tooltipText: "Check if Vibe CLI is installed"
                    onPressed: checkVibeInstalled()
                }

                // Bouton pour lancer Vibe CLI
                WidgetButton {
                    width: parent.width
                    text: "Launch Vibe CLI"
                    tooltipText: "Launch Vibe CLI directly"
                    onPressed: launchVibe()
                }

                // Note
                Text {
                    width: parent.width
                    text: "Note: Ensure Vibe CLI is installed and available in your PATH."
                    color: root.barForeground
                    font.family: root.bar ? root.bar.fontFamily : Style.font.family
                    font.pixelSize: Style.font.small
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}

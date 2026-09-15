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

                // Titre
                Text {
                    width: parent.width
                    text: "Vibe CLI Agent"
                    color: root.barForeground
                    font.family: root.bar ? root.bar.fontFamily : Style.font.family
                    font.pixelSize: Style.font.subtitle
                    font.bold: true
                    wrapMode: Text.WordWrap
                }

                // Description
                Text {
                    width: parent.width
                    text: "Configure Vibe CLI as your default AI agent in Omarchy."
                    color: root.barForeground
                    font.family: root.bar ? root.bar.fontFamily : Style.font.family
                    font.pixelSize: Style.font.body
                    wrapMode: Text.WordWrap
                }

                // Bouton pour définir comme agent par défaut
                WidgetButton {
                    width: parent.width
                    text: "Set as Default Agent"
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

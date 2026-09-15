import QtQuick
import Quickshell
import qs.Ui

BarWidget {
    id: root
    moduleName: "io.github.mario-kart14.vibe-default-agent"

    readonly property bool opened: panelLoader.item
        ? panelLoader.item.opened === true
        : false

    function open() {
        if (panelLoader.item) panelLoader.item.open()
    }

    function close() {
        if (panelLoader.item) panelLoader.item.close()
    }

    function toggle() {
        if (panelLoader.item) panelLoader.item.toggle()
    }

    function closeForPopoutSwitch() {
        if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
    }

    function injectPanel() {
        if (!panelLoader.item) return
        panelLoader.item.bar = root.bar
        panelLoader.item.anchorItem = button
        panelLoader.item.hostWidget = root
    }

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    onBarChanged: injectPanel()

    Loader {
        id: panelLoader
        active: true
        source: Qt.resolvedUrl("Panel.qml")
        visible: false
        onLoaded: {
            root.injectPanel()
            Qt.callLater(root.injectPanel)
        }
    }

    // Utilisation de BarIconButton comme dans omarchy.agents
    BarIconButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        text: "⚡"  // Icône personnalisée pour Vibe CLI
        active: false
        onPressed: function(buttonCode) {
            if (buttonCode === Qt.RightButton) {
                Quickshell.execDetached("vibe")
            } else {
                root.toggle()
            }
        }
    }
}

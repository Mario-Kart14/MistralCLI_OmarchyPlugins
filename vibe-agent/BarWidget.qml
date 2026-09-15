import QtQuick
import Quickshell
import qs.Ui

BarWidget {
    id: root
    moduleName: "omarchy.vibe"
    ipcTarget: "omarchy.vibe"
    manageIpc: false

    readonly property color foreground: bar ? bar.foreground : Color.foreground
    readonly property color urgent: bar ? bar.urgent : Color.urgent
    readonly property bool alarming: panelLoader.item ? panelLoader.item.tokensExhausted : false

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

    BarIconButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        text: panelLoader.item ? (panelLoader.item.tokensExhausted ? "🔴" : "🤖") : "🤖"
        active: root.alarming
        onPressed: function(buttonCode) {
            if (buttonCode === Qt.RightButton) root.launchAgent()
            else if (buttonCode === Qt.MiddleButton) {
                if (panelLoader.item) panelLoader.item.selectProvider(panelLoader.item.providerIndex + 1)
            }
            else root.toggle()
        }
    }

    IpcHandler {
        target: root.ipcTarget
        function open(): void { root.open() }
        function close(): void { root.close() }
        function show(): void { root.open() }
        function hide(): void { root.close() }
        function toggle(): void { root.toggle() }
    }
}

import QtQuick
import Quickshell

ShellRoot {
    id: root

    readonly property bool testing: Quickshell.env("QS_TESTING") === "1"
    readonly property string themePath: Quickshell.env("QS_THEME_PATH") || "/usr/share/kira-qylock/themes/clockwork/orbital"

    readonly property var sddm: shim.sddm
    readonly property var config: shim.config
    readonly property var userModel: shim.userModel
    readonly property var sessionModel: shim.sessionModel
    readonly property var keyboard: QtObject {
        property bool numLock: false
        property bool capsLock: false
    }

    GreetdShim {
        id: shim
        themePath: root.themePath
        testing: root.testing
    }

    FloatingWindow {
        visible: true
        color: "black"
        implicitWidth: root.testing ? 1280 : 1920
        implicitHeight: root.testing ? 720 : 1080

        Loader {
            anchors.fill: parent
            source: "file://" + root.themePath + "/Main.qml"
            onLoaded: item.forceActiveFocus()
            onStatusChanged: if (status === Loader.Error) console.error("greeter: theme failed to load:", source)
        }
    }
}

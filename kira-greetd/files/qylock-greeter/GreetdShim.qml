import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd

Item {
    id: shim

    property string themePath: ""
    property bool testing: false
    property bool busy: false
    property string pendingPassword: ""
    property var pendingCmd: []
    property var pendingEnv: []

    readonly property string stateDir: "/var/lib/greetd"
    readonly property string launchedMarker: "/run/greetd/launched"

    FileView {
        id: themeConf
        path: shim.themePath + "/theme.conf"
        blockLoading: true
        printErrors: false
    }

    FileView {
        id: passwd
        path: "/etc/passwd"
        blockLoading: true
        printErrors: false
    }

    FileView {
        id: lastUser
        path: shim.stateDir + "/last-user"
        blockLoading: true
        printErrors: false
    }

    property var config: ({ background: "bg.png" })

    function loadConfig() {
        var out = { background: "bg.png" };
        var lines = (themeConf.text() || "").split("\n");
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            if (line === "" || line[0] === "#" || line[0] === "[") continue;
            var eq = line.indexOf("=");
            if (eq > 0) out[line.substring(0, eq).trim()] = line.substring(eq + 1).trim();
        }
        config = out;
    }

    property var userModel: ListModel {
        property string lastUser: ""
        property int lastIndex: 0
        function rowCount() { return count; }
        function index(row, col) { return row; }
    }

    property var sessionModel: ListModel {
        property int lastIndex: 0
        function rowCount() { return count; }
        function index(row, col) { return row; }
    }

    property var sddm: QtObject {
        property string hostName: "kira"
        signal loginFailed()
        signal loginSucceeded()
        function login(user, password, sessionIndex) { shim.startLogin(user, password, sessionIndex); }
        function reboot() { if (shim.testing) return; Quickshell.execDetached(["/etc/greetd/kira-login/scripts/power.sh", "reboot"]); }
        function powerOff() { if (shim.testing) return; Quickshell.execDetached(["/etc/greetd/kira-login/scripts/power.sh", "shutdown"]); }
    }

    function loadUsers() {
        var last = (lastUser.text() || "").trim();
        var rows = (passwd.text() || "").split("\n");
        var found = [];
        for (var i = 0; i < rows.length; i++) {
            var f = rows[i].split(":");
            if (f.length < 7) continue;
            var uid = parseInt(f[2]);
            if (uid < 1000 || uid >= 60000) continue;
            if (/(nologin|false)$/.test(f[6])) continue;
            found.push({ name: f[0], realName: f[4].split(",")[0] || f[0], icon: "", homeDir: f[5] });
        }
        found.sort(function(a, b) { return (a.name === last ? 0 : 1) - (b.name === last ? 0 : 1); });
        for (var j = 0; j < found.length; j++) userModel.append(found[j]);
        userModel.lastUser = found.length > 0 ? found[0].name : "";
        userModel.lastIndex = 0;
    }

    Process {
        id: sessionList
        command: ["/etc/greetd/kira-login/scripts/sessions.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                var list = [];
                try { list = JSON.parse(this.text); } catch (e) { console.warn("greeter: bad session list", e); }
                for (var i = 0; i < list.length; i++)
                    sessionModel.append({ name: list[i].name, cmd: list[i].cmd.join(" ") });
                sessionModel.lastIndex = 0;
            }
        }
    }

    function sessionEnv(name) {
        if (name === "tty") return ["XDG_SESSION_TYPE=tty"];
        return ["XDG_SESSION_TYPE=wayland", "XDG_SESSION_DESKTOP=" + name, "XDG_CURRENT_DESKTOP=" + name];
    }

    function startLogin(user, password, sessionIndex) {
        if (busy) return;
        var s = sessionModel.get(sessionIndex);
        if (!s) { sddm.loginFailed(); return; }
        busy = true;
        pendingPassword = password;
        pendingCmd = s.cmd === "__TTY__" ? ["sh", "-l"] : s.cmd.split(" ");
        pendingEnv = sessionEnv(s.name);
        shim.pendingUser = user;
        shim.pendingSessionName = s.name;
        if (testing) {
            testTimer.start();
        } else {
            Greetd.createSession(user);
        }
    }

    property string pendingUser: ""
    property string pendingSessionName: ""

    function remember() {
        Quickshell.execDetached(["sh", "-c", "printf %s \"$1\" > \"$3/last-user\"; printf %s \"$2\" > \"$3/last-session\"", "sh", pendingUser, pendingSessionName, stateDir]);
    }

    function failLogin() {
        busy = false;
        pendingPassword = "";
        sddm.loginFailed();
    }

    Timer {
        id: testTimer
        interval: 700
        onTriggered: {
            if (shim.pendingPassword === "test") sddm.loginSucceeded();
            else shim.failLogin();
        }
    }

    Timer {
        id: launchTimer
        interval: 500
        onTriggered: {
            Quickshell.execDetached(["touch", shim.launchedMarker]);
            Greetd.launch(shim.pendingCmd, shim.pendingEnv);
        }
    }

    Connections {
        target: Greetd
        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (!responseRequired) return;
            Greetd.respond(shim.pendingPassword);
            shim.pendingPassword = "";
        }
        function onAuthFailure(message) {
            Greetd.cancelSession();
            shim.failLogin();
        }
        function onReadyToLaunch() {
            shim.remember();
            sddm.loginSucceeded();
            launchTimer.start();
        }
    }

    Component.onCompleted: {
        loadConfig();
        loadUsers();
        sessionList.running = true;
    }
}

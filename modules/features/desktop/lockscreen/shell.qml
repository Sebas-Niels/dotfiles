pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland

ShellRoot {
    id: root

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property string user: Quickshell.env("USER") ?? ""
    readonly property string wallpaper: "file://" + Quickshell.env("HOME") + "/.local/state/aperture-theme/current/wallpaper"
    readonly property var main: {
        const screens = Quickshell.screens;
        for (let i = 0; i < screens.length; i++)
            if (screens[i].width === 3440)
                return screens[i];
        return screens.length > 0 ? screens[0] : null;
    }

    property string password: ""
    property bool checking: false
    property bool failed: false
    property int failures: 0
    property real shown: 0

    function submit() {
        if (checking || password.length === 0)
            return;
        checking = true;
        failed = false;
        if (!pam.start()) {
            checking = false;
            reject();
        }
    }

    function reject() {
        password = "";
        failed = true;
        failures++;
    }

    function type(event) {
        if (checking)
            return;
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            submit();
        } else if (event.key === Qt.Key_Escape
                || (event.key === Qt.Key_U && (event.modifiers & Qt.ControlModifier))
                || (event.key === Qt.Key_Backspace && (event.modifiers & Qt.ControlModifier))) {
            password = "";
        } else if (event.key === Qt.Key_Backspace) {
            password = password.slice(0, -1);
        } else if (event.text.length > 0 && event.text.charCodeAt(0) >= 32) {
            password += event.text;
            failed = false;
        } else {
            return;
        }
        event.accepted = true;
    }

    PamContext {
        id: pam
        config: "aperture-lock"

        onPamMessage: {
            if (responseRequired)
                respond(root.password);
        }
        onCompleted: result => {
            root.checking = false;
            if (result === PamResult.Success)
                fadeOut.start();
            else
                root.reject();
        }
        onError: () => {
            root.checking = false;
            root.reject();
        }
    }

    NumberAnimation {
        id: fadeIn
        target: root
        property: "shown"
        to: 1
        duration: 450
        easing.type: Easing.OutCubic
        running: true
    }

    SequentialAnimation {
        id: fadeOut

        NumberAnimation {
            target: root
            property: "shown"
            to: 0
            duration: 280
            easing.type: Easing.InCubic
        }
        ScriptAction {
            script: {
                lock.locked = false;
                Qt.quit();
            }
        }
    }

    FileView {
        path: Quickshell.env("HOME") + "/.local/state/aperture-theme/current/lockscreen.json"
        printErrors: false

        JsonAdapter {
            id: theme
            property string mantle: "#1b1d2c"
            property string surface: "#2f334d"
            property string overlay: "#444a73"
            property string text: "#e4f3fa"
            property string subtext: "#a9b8e8"
            property string accent: "#82aaff"
            property string accent2: "#c099ff"
            property string red: "#ff757f"
            property string shade: "#1b1d2c"
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    WlSessionLock {
        id: lock
        locked: true

        WlSessionLockSurface {
            id: surface

            color: "black"

            Item {
                id: page

                readonly property real u: Math.max(0.5, Math.min(height / 1440, 1))

                anchors.fill: parent
                focus: true
                Keys.onPressed: event => root.type(event)

                Image {
                    id: wall
                    anchors.fill: parent
                    source: root.wallpaper
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: false
                    cache: false
                    visible: false
                }

                MultiEffect {
                    anchors.fill: parent
                    source: wall
                    autoPaddingEnabled: false
                    blurEnabled: true
                    blurMax: 64
                    blur: 0.35 + 0.65 * root.shown
                    saturation: -0.1 * root.shown
                    scale: 1.06 - 0.03 * root.shown
                    opacity: 0.4 + 0.6 * root.shown
                }

                Rectangle {
                    anchors.fill: parent
                    opacity: root.shown
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.alpha(theme.shade, 0.55) }
                        GradientStop { position: 0.5; color: Qt.alpha(theme.shade, 0.35) }
                        GradientStop { position: 1.0; color: Qt.alpha(theme.shade, 0.7) }
                    }
                }

                Column {
                    id: content

                    visible: surface.screen === root.main
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: (1 - root.shown) * 30 * page.u
                    spacing: 0
                    opacity: root.shown

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(clock.date, "dddd, d MMMM").toUpperCase()
                        color: theme.subtext
                        font.family: root.fontFamily
                        font.pixelSize: Math.round(20 * page.u)
                        font.letterSpacing: 6 * page.u
                        font.weight: Font.Medium
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(clock.date, "HH:mm")
                        color: theme.text
                        font.family: root.fontFamily
                        font.pixelSize: Math.round(196 * page.u)
                        font.weight: Font.Light
                        font.letterSpacing: -4 * page.u
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: Qt.alpha("black", 0.45)
                            shadowBlur: 1
                            shadowVerticalOffset: 4
                        }
                    }

                    Item {
                        width: 1
                        height: Math.round(56 * page.u)
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Math.round(12 * page.u)

                        Rectangle {
                            width: Math.round(34 * page.u)
                            height: width
                            radius: width / 2
                            anchors.verticalCenter: parent.verticalCenter
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: theme.accent }
                                GradientStop { position: 1.0; color: theme.accent2 }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: root.user.charAt(0).toUpperCase()
                                color: theme.mantle
                                font.family: root.fontFamily
                                font.pixelSize: Math.round(16 * page.u)
                                font.weight: Font.Bold
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.user
                            color: theme.text
                            font.family: root.fontFamily
                            font.pixelSize: Math.round(18 * page.u)
                            font.weight: Font.Medium
                        }
                    }

                    Item {
                        width: 1
                        height: Math.round(20 * page.u)
                    }

                    Rectangle {
                        id: pill

                        property real shake: 0

                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.horizontalCenterOffset: shake
                        width: Math.round(380 * page.u)
                        height: Math.round(56 * page.u)
                        radius: height / 2
                        color: Qt.alpha(theme.shade, 0.45)
                        border.width: Math.max(1, Math.round(1.5 * page.u))
                        border.color: root.failed ? theme.red
                            : root.checking ? theme.accent
                            : root.password.length > 0 ? Qt.alpha(theme.accent, 0.8)
                            : Qt.alpha(theme.overlay, 0.9)

                        Behavior on border.color { ColorAnimation { duration: 180 } }

                        SequentialAnimation {
                            id: shakeAnim
                            loops: 1
                            NumberAnimation { target: pill; property: "shake"; to: -14; duration: 50 }
                            NumberAnimation { target: pill; property: "shake"; to: 12; duration: 70 }
                            NumberAnimation { target: pill; property: "shake"; to: -8; duration: 70 }
                            NumberAnimation { target: pill; property: "shake"; to: 5; duration: 70 }
                            NumberAnimation { target: pill; property: "shake"; to: 0; duration: 60 }
                        }

                        Connections {
                            target: root
                            function onFailuresChanged() {
                                shakeAnim.restart();
                            }
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: Math.round(22 * page.u)
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.checking ? "󰦝" : "󰌾"
                            color: root.failed ? theme.red : root.password.length > 0 ? theme.accent : theme.subtext
                            font.family: root.fontFamily
                            font.pixelSize: Math.round(20 * page.u)

                            Behavior on color { ColorAnimation { duration: 180 } }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: root.failed ? "wrong password" : "enter password"
                            color: root.failed ? theme.red : theme.subtext
                            opacity: root.password.length === 0 && !root.checking ? 0.75 : 0
                            font.family: root.fontFamily
                            font.pixelSize: Math.round(15 * page.u)
                            font.letterSpacing: 1.5 * page.u

                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        Row {
                            id: dots

                            property real pulse: 1

                            anchors.centerIn: parent
                            spacing: Math.round(9 * page.u)
                            opacity: pulse

                            SequentialAnimation on pulse {
                                running: root.checking
                                loops: Animation.Infinite
                                onRunningChanged: if (!running) dots.pulse = 1
                                NumberAnimation { to: 0.35; duration: 450; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1; duration: 450; easing.type: Easing.InOutSine }
                            }

                            Repeater {
                                model: Math.min(root.password.length, 16)

                                Rectangle {
                                    id: dot
                                    width: Math.round(10 * page.u)
                                    height: width
                                    radius: width / 2
                                    color: theme.text
                                    scale: 0

                                    Component.onCompleted: scale = 1
                                    Behavior on scale {
                                        NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 2.5 }
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    visible: content.visible
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Math.round(48 * page.u)
                    text: "type your password to unlock"
                    color: theme.subtext
                    opacity: 0.55 * root.shown
                    font.family: root.fontFamily
                    font.pixelSize: Math.round(13 * page.u)
                    font.letterSpacing: 3 * page.u
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.BlankCursor
                    acceptedButtons: Qt.NoButton
                }
            }
        }
    }
}

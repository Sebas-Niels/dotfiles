pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    // The Xeneon Edge. mango tells clients no model or serial, but nothing else here is
    // 2560x720 (and its connector name can change between boots)
    readonly property var edge: {
        const screens = Quickshell.screens;
        for (let i = 0; i < screens.length; i++)
            if (screens[i].width === 2560 && screens[i].height === 720)
                return screens[i];
        return null;
    }

    // Results, oldest first (true for heads), kept to what the row of dots shows
    property var history: []
    property int heads: 0
    property int tails: 0
    property int streak: 0
    property bool result: true
    property bool revealed: false
    property bool flying: false

    // The coin turns from spinFrom to spinTo while flight runs 0 -> 1, then rocks to rest while
    // settle runs 0 -> 1. Whole turns are multiples of 360, so spinTo % 360 is the face up.
    property real spinFrom: 0
    property real spinTo: 0
    property real flight: 1
    property real settle: 1

    readonly property real angle: flight < 1
        ? spinFrom + (spinTo - spinFrom) * (0.65 * flight + 0.35 * (1 - (1 - flight) * (1 - flight)))
        : spinTo + 22 * Math.pow(1 - settle, 2) * Math.sin(2 * Math.PI * 2.5 * settle)
    // 0 on the table .. 1 at the top of the toss
    readonly property real lift: flight < 1
        ? 4 * flight * (1 - flight)
        : 0.07 * Math.pow(1 - settle, 2) * Math.abs(Math.sin(2 * Math.PI * 1.5 * settle))

    function flip() {
        if (flying)
            return;
        const heads = Math.random() < 0.5;
        const from = spinTo % 360;
        spinFrom = from;
        spinTo = from + 360 * (5 + Math.floor(Math.random() * 3)) + ((heads ? 0 : 180) - from + 360) % 360;
        result = heads;
        revealed = false;
        flying = true;
        toss.restart();
    }

    function land() {
        if (result)
            heads++;
        else
            tails++;
        const last = history.length > 0 ? history[history.length - 1] : null;
        streak = last === result ? streak + 1 : 1;
        history = history.concat([result]).slice(-16);
        revealed = true;
    }

    function reset() {
        if (flying)
            return;
        history = [];
        heads = 0;
        tails = 0;
        streak = 0;
        revealed = false;
    }

    SequentialAnimation {
        id: toss

        NumberAnimation {
            target: root
            property: "flight"
            from: 0
            to: 1
            duration: 1400
        }
        ScriptAction {
            script: root.land()
        }
        NumberAnimation {
            target: root
            property: "settle"
            from: 0
            to: 1
            duration: 900
        }
        ScriptAction {
            script: root.flying = false
        }
    }

    IpcHandler {
        target: "coinflip"

        function flip(): void {
            root.flip();
        }
        function reset(): void {
            root.reset();
        }
        // The theme menu calls this after switching, since the current theme is a symlink
        // that is re-pointed rather than a file that changes
        function reload(): void {
            themeFile.reload();
        }
    }

    // Colours of the current theme, with Moonlight's until it has loaded
    FileView {
        id: themeFile
        path: Quickshell.env("HOME") + "/.local/state/aperture-theme/current/coinflip.json"
        printErrors: false

        JsonAdapter {
            id: theme
            property string bg: "#212337"
            property string mantle: "#1b1d2c"
            property string surface: "#2f334d"
            property string overlay: "#444a73"
            property string text: "#e4f3fa"
            property string subtext: "#a9b8e8"
            property string accent: "#82aaff"
            property string metal: "#ffc777"
            property string metalLight: "#ffe6c2"
            property string metalDark: "#a6814d"
            property string rim: "#80643c"
        }
    }

    // Animated copy of the theme's colours
    Item {
        id: ui
        visible: false

        property color bg: theme.bg
        property color mantle: theme.mantle
        property color surface: theme.surface
        property color overlay: theme.overlay
        property color text: theme.text
        property color subtext: theme.subtext
        property color accent: theme.accent
        property color metal: theme.metal
        property color metalLight: theme.metalLight
        property color metalDark: theme.metalDark
        property color rim: theme.rim

        Behavior on bg { ColorAnimation { duration: 500; easing.type: Easing.OutCubic } }
        Behavior on mantle { ColorAnimation { duration: 500; easing.type: Easing.OutCubic } }
        Behavior on surface { ColorAnimation { duration: 500; easing.type: Easing.OutCubic } }
        Behavior on overlay { ColorAnimation { duration: 500; easing.type: Easing.OutCubic } }
        Behavior on text { ColorAnimation { duration: 500; easing.type: Easing.OutCubic } }
        Behavior on subtext { ColorAnimation { duration: 500; easing.type: Easing.OutCubic } }
        Behavior on accent { ColorAnimation { duration: 500; easing.type: Easing.OutCubic } }
        Behavior on metal { ColorAnimation { duration: 500; easing.type: Easing.OutCubic } }
        Behavior on metalLight { ColorAnimation { duration: 500; easing.type: Easing.OutCubic } }
        Behavior on metalDark { ColorAnimation { duration: 500; easing.type: Easing.OutCubic } }
        Behavior on rim { ColorAnimation { duration: 500; easing.type: Easing.OutCubic } }
    }

    // A column down the right of the Xeneon that windows tile beside. The 5px around the card
    // matches mango's outer gaps; the windows bring their own on the left. On the bottom layer
    // because mango makes room for the newest surface first within a layer: on the top layer
    // it would take the full height and squeeze waybar, rather than sit below it.
    PanelWindow {
        id: win

        readonly property int gap: 5

        screen: root.edge
        visible: root.edge !== null
        color: "transparent"
        anchors {
            top: true
            bottom: true
            right: true
        }
        implicitWidth: 330 + gap
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: implicitWidth
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "aperture-coinflip"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Rectangle {
            id: card

            readonly property real coinSize: Math.min(width * 0.52, height * 0.27)
            // Where the coin rests, and how high a toss takes it
            readonly property real restY: Math.round(height * 0.55)
            readonly property real tossHeight: restY - coinSize * 0.5 - 40

            anchors.fill: parent
            anchors.leftMargin: 0
            anchors.margins: win.gap
            radius: 16
            color: Qt.alpha(ui.mantle, 0.92)
            border.width: 1
            border.color: Qt.alpha(ui.overlay, 0.8)
            clip: true

            // Warm light falling on the spot the coin lands
            Glow {
                width: card.coinSize * 2.4
                height: width
                x: (card.width - width) / 2
                y: card.restY - height / 2
                color: Qt.alpha(ui.metal, 0.11)
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 22
                text: "COIN FLIP"
                color: ui.subtext
                opacity: 0.8 * (1 - Math.min(1, root.lift * 2.5))
                font.family: root.fontFamily
                font.pixelSize: 13
                font.letterSpacing: 6
                font.weight: Font.DemiBold
            }

            // Shadow on the table, smaller and fainter the higher the coin goes
            Glow {
                width: card.coinSize * 1.1 * (1 - root.lift * 0.55)
                height: width
                squash: 0.16
                x: (card.width - width) / 2
                y: card.restY + card.coinSize / 2 + 16 - height / 2
                color: Qt.alpha("black", 0.6 * (1 - root.lift * 0.7))
            }

            Coin {
                id: coin

                property real pressScale: tap.pressed && !root.flying ? 0.95 : 1

                size: card.coinSize
                thickness: Math.round(card.coinSize * 0.075)
                angle: root.angle
                metal: ui.metal
                metalLight: ui.metalLight
                metalDark: ui.metalDark
                rim: ui.rim
                x: (card.width - width) / 2
                y: card.restY - height / 2 - root.lift * card.tossHeight
                // Nearer the eye at the top of the toss
                scale: (1 + 0.14 * root.lift) * pressScale

                Behavior on pressScale {
                    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                }
            }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                y: card.restY + card.coinSize / 2 + 44
                spacing: 4

                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: card.width
                    height: 44

                    Text {
                        anchors.centerIn: parent
                        text: "tap to flip"
                        color: ui.subtext
                        opacity: root.history.length === 0 && !root.flying ? 0.85 : 0
                        font.family: root.fontFamily
                        font.pixelSize: 16
                        font.letterSpacing: 2

                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: root.result ? "HEADS" : "TAILS"
                        color: ui.metal
                        opacity: root.revealed ? 1 : 0
                        scale: root.revealed ? 1 : 0.7
                        font.family: root.fontFamily
                        font.pixelSize: 34
                        font.letterSpacing: 8
                        font.weight: Font.Bold

                        Behavior on opacity { NumberAnimation { duration: root.revealed ? 260 : 120 } }
                        Behavior on scale {
                            NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 2.2 }
                        }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.streak > 1 ? `${root.streak} in a row` : " "
                    color: ui.subtext
                    opacity: root.revealed ? 0.8 : 0
                    font.family: root.fontFamily
                    font.pixelSize: 13

                    Behavior on opacity { NumberAnimation { duration: 260 } }
                }
            }

            // The tally: recent results as coins, newest on the right, and the split so far
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 26
                width: card.width - 56
                spacing: 14
                opacity: root.history.length > 0 ? 1 : 0

                Behavior on opacity { NumberAnimation { duration: 300 } }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 5

                    Repeater {
                        model: root.history

                        Rectangle {
                            required property bool modelData
                            width: 11
                            height: 11
                            radius: 5.5
                            color: modelData ? ui.metal : "transparent"
                            border.width: 2
                            border.color: modelData ? ui.metal : Qt.alpha(ui.metal, 0.55)
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 6

                    Rectangle {
                        anchors.fill: parent
                        radius: 3
                        color: ui.surface
                    }
                    Rectangle {
                        height: parent.height
                        radius: 3
                        width: parent.width * (root.heads + root.tails > 0 ? root.heads / (root.heads + root.tails) : 0.5)
                        color: ui.metal

                        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                    }
                }

                Item {
                    width: parent.width
                    height: headsLabel.height

                    Text {
                        id: headsLabel
                        text: `heads ${root.heads}`
                        color: ui.text
                        font.family: root.fontFamily
                        font.pixelSize: 13
                    }
                    Text {
                        anchors.right: parent.right
                        text: `${root.tails} tails`
                        color: ui.subtext
                        font.family: root.fontFamily
                        font.pixelSize: 13
                    }
                }
            }

            // Anywhere on the card flips (the Xeneon is a touchscreen); a right click or a long
            // press clears the tally
            MouseArea {
                id: tap
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton)
                        root.reset();
                    else
                        root.flip();
                }
                onPressAndHold: root.reset()
            }
        }
    }
}

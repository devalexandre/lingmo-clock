import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import LingmoUI.CompatibleModule 3.0 as LingmoUI

// Timer (countdown) and stopwatch. While either runs it shows up in the status
// bar's Island (com.lingmo.Island, see docs/island-api.md) with pause/resume and
// stop, which drive the same functions as the buttons here.
Item {
    id: panel

    signal timerFinished()

    // ---- Timer state (times in ms since the epoch) ----
    property int timerDuration: 5 * 60 * 1000
    property bool timerRunning: false
    property bool timerPaused: false
    property real timerDeadline: 0
    property real timerFrozen: 0          // remaining ms while paused
    property real now: Date.now()

    readonly property bool timerActive: timerRunning || timerPaused
    readonly property real timerRemaining: timerPaused ? timerFrozen
                                         : timerRunning ? Math.max(0, timerDeadline - now)
                                         : timerDuration

    function startTimer(ms) {
        if (ms !== undefined)
            timerDuration = ms
        timerDeadline = Date.now() + timerDuration
        timerPaused = false
        timerRunning = true
        now = Date.now()
    }
    function pauseTimer() {
        if (!timerRunning)
            return
        timerFrozen = Math.max(0, timerDeadline - Date.now())
        timerPaused = true      // before timerRunning = false: the Island stays up
        timerRunning = false
    }
    function resumeTimer() {
        if (!timerPaused)
            return
        timerDeadline = Date.now() + timerFrozen
        timerRunning = true
        timerPaused = false
        now = Date.now()
    }
    function stopTimer() {
        timerIsland.finishMessage = ""
        timerRunning = false
        timerPaused = false
    }

    // ---- Stopwatch state ----
    property bool swRunning: false
    property bool swPaused: false
    property real swStart: 0              // virtual start: now - elapsed
    property real swFrozen: 0             // elapsed ms while paused

    readonly property bool swActive: swRunning || swPaused
    readonly property real swElapsed: swPaused ? swFrozen : swRunning ? Math.max(0, now - swStart) : 0

    function startStopwatch() {
        swStart = Date.now()
        swPaused = false
        swRunning = true
        now = Date.now()
    }
    function pauseStopwatch() {
        if (!swRunning)
            return
        swFrozen = Date.now() - swStart
        swPaused = true
        swRunning = false
    }
    function resumeStopwatch() {
        if (!swPaused)
            return
        swStart = Date.now() - swFrozen
        swRunning = true
        swPaused = false
        now = Date.now()
    }
    function stopStopwatch() {
        swRunning = false
        swPaused = false
    }

    function format(ms, tenths) {
        const total = Math.floor(ms / 1000)
        const h = Math.floor(total / 3600)
        const m = Math.floor((total % 3600) / 60)
        const s = total % 60
        const pad = (n) => (n < 10 ? "0" : "") + n
        let text = (h > 0 ? h + ":" + pad(m) : pad(m)) + ":" + pad(s)
        if (tenths)
            text += "," + Math.floor((ms % 1000) / 100)
        return text
    }

    // One tick drives both displays; it only runs while something is running
    Timer {
        interval: panel.swRunning ? 100 : 250
        repeat: true
        running: panel.timerRunning || panel.swRunning
        onTriggered: {
            panel.now = Date.now()
            if (panel.timerRunning && panel.now >= panel.timerDeadline) {
                timerIsland.finishMessage = qsTr("Tempo esgotado")
                panel.timerRunning = false
                panel.timerPaused = false
                panel.timerFinished()
            }
        }
    }

    // ---- Island (status bar live activities) ----
    LingmoUI.IslandActivity {
        id: timerIsland
        appId: "lingmo-clock"
        active: panel.timerActive
        kind: "timer"
        title: qsTr("Timer")
        subtitle: panel.timerPaused ? qsTr("Pausado · %1 restantes").arg(panel.format(panel.timerFrozen))
                                    : qsTr("Termina às %1").arg(new Date(panel.timerDeadline).toLocaleTimeString(Qt.locale(), "hh:mm"))
        iconName: "chronometer"
        hints: ({ endTime: panel.timerDeadline, paused: panel.timerPaused, frozenTime: panel.timerFrozen })
        actions: [ panel.timerPaused ? { id: "resume", label: qsTr("Retomar") } : { id: "pause", label: qsTr("Pausar") },
                   { id: "stop", label: qsTr("Parar") } ]
        onActionInvoked: (actionId) => {
            if (actionId === "pause") panel.pauseTimer()
            else if (actionId === "resume") panel.resumeTimer()
            else if (actionId === "stop") panel.stopTimer()
        }
    }

    LingmoUI.IslandActivity {
        id: stopwatchIsland
        appId: "lingmo-clock"
        active: panel.swActive
        kind: "stopwatch"
        title: qsTr("Cronômetro")
        subtitle: panel.swPaused ? qsTr("Pausado · %1").arg(panel.format(panel.swFrozen)) : qsTr("Em andamento")
        iconName: "chronometer"
        hints: ({ startTime: panel.swStart, paused: panel.swPaused, frozenTime: panel.swFrozen })
        actions: [ panel.swPaused ? { id: "resume", label: qsTr("Retomar") } : { id: "pause", label: qsTr("Pausar") },
                   { id: "stop", label: qsTr("Parar") } ]
        onActionInvoked: (actionId) => {
            if (actionId === "pause") panel.pauseStopwatch()
            else if (actionId === "resume") panel.resumeStopwatch()
            else if (actionId === "stop") panel.stopStopwatch()
        }
    }

    // ---- UI ----
    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: LingmoUI.Units.largeSpacing * 2
        anchors.rightMargin: LingmoUI.Units.largeSpacing * 2
        anchors.bottomMargin: LingmoUI.Units.largeSpacing * 2
        spacing: LingmoUI.Units.largeSpacing

        LingmoUI.Card {
            id: timerCard
            Layout.fillWidth: true

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: timerCard.padding
                anchors.rightMargin: timerCard.padding
                anchors.topMargin: LingmoUI.Units.largeSpacing
                anchors.bottomMargin: LingmoUI.Units.largeSpacing
                spacing: LingmoUI.Units.smallSpacing

                Label {
                    text: qsTr("Timer")
                    font.pointSize: LingmoUI.Units.fontSubheading
                    font.weight: Font.DemiBold
                    color: LingmoUI.Theme.textColor
                }

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: panel.format(panel.timerRemaining)
                    font.pointSize: LingmoUI.Units.fontDisplay
                    font.bold: true
                    font.features: { "tnum": 1 }
                    color: panel.timerActive ? LingmoUI.Theme.textColor : LingmoUI.Theme.secondaryTextColor
                }

                LingmoUI.SegmentedControl {
                    Layout.alignment: Qt.AlignHCenter
                    enabled: !panel.timerActive
                    readonly property var minutes: [1, 5, 10, 15, 30]
                    model: minutes.map((m) => qsTr("%1 min").arg(m))
                    currentIndex: minutes.indexOf(Math.round(panel.timerDuration / 60000))
                    onActivated: (index) => panel.timerDuration = minutes[index] * 60000
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: LingmoUI.Units.largeSpacing

                    LingmoUI.ActionButton {
                        text: !panel.timerActive ? qsTr("Iniciar")
                              : panel.timerPaused ? qsTr("Retomar") : qsTr("Pausar")
                        primary: true
                        onClicked: {
                            if (!panel.timerActive) panel.startTimer()
                            else if (panel.timerPaused) panel.resumeTimer()
                            else panel.pauseTimer()
                        }
                    }
                    LingmoUI.ActionButton {
                        text: qsTr("Parar")
                        enabled: panel.timerActive
                        onClicked: panel.stopTimer()
                    }
                }
            }
        }

        LingmoUI.Card {
            id: swCard
            Layout.fillWidth: true

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: swCard.padding
                anchors.rightMargin: swCard.padding
                anchors.topMargin: LingmoUI.Units.largeSpacing
                anchors.bottomMargin: LingmoUI.Units.largeSpacing
                spacing: LingmoUI.Units.smallSpacing

                Label {
                    text: qsTr("Cronômetro")
                    font.pointSize: LingmoUI.Units.fontSubheading
                    font.weight: Font.DemiBold
                    color: LingmoUI.Theme.textColor
                }

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: panel.format(panel.swElapsed, true)
                    font.pointSize: LingmoUI.Units.fontDisplay
                    font.bold: true
                    font.features: { "tnum": 1 }
                    color: panel.swActive ? LingmoUI.Theme.textColor : LingmoUI.Theme.secondaryTextColor
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: LingmoUI.Units.largeSpacing

                    LingmoUI.ActionButton {
                        text: !panel.swActive ? qsTr("Iniciar")
                              : panel.swPaused ? qsTr("Retomar") : qsTr("Pausar")
                        primary: true
                        onClicked: {
                            if (!panel.swActive) panel.startStopwatch()
                            else if (panel.swPaused) panel.resumeStopwatch()
                            else panel.pauseStopwatch()
                        }
                    }
                    LingmoUI.ActionButton {
                        text: qsTr("Zerar")
                        enabled: panel.swActive
                        onClicked: panel.stopStopwatch()
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}

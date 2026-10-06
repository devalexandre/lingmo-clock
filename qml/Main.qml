import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import LingmoUI.CompatibleModule 3.0 as LingmoUI

LingmoUI.Window {
    id: root
    width: 500
    height: 600
    minimumWidth: 400
    minimumHeight: 500
    title: qsTr("Relógio e Alarmes")
    visible: true

    // Same window look as Lingmo Settings
    background.opacity: LingmoUI.Theme.darkMode ? 0.88 : 0.97
    header.height: 40
    contentTopMargin: 0

    LingmoUI.WindowBlur {
        view: root
        geometry: Qt.rect(root.x, root.y, root.width, root.height)
        windowRadius: root.windowRadius
        enabled: true
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Top: the current time, under the window buttons
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.header.height + clockColumn.implicitHeight + LingmoUI.Units.largeSpacing * 2

            ColumnLayout {
                id: clockColumn
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: root.header.height
                spacing: LingmoUI.Units.smallSpacing / 2

                Label {
                    id: clockLabel
                    font.pointSize: LingmoUI.Theme.fontSize * 4
                    font.bold: true
                    color: LingmoUI.Theme.textColor
                    Layout.alignment: Qt.AlignHCenter
                }
                Label {
                    id: dateLabel
                    font.pointSize: LingmoUI.Theme.fontSize * 1.2
                    color: LingmoUI.Theme.disabledTextColor
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            Timer {
                interval: 1000; running: true; repeat: true
                onTriggered: {
                    var d = new Date()
                    clockLabel.text = d.toLocaleTimeString(Qt.locale(), "hh:mm")
                    dateLabel.text = d.toLocaleDateString(Qt.locale(), Locale.LongFormat)
                }
                Component.onCompleted: triggered()
            }
        }

        // Alarms List
        ListView {
            id: alarmList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: alarmManager.alarms
            spacing: LingmoUI.Units.smallSpacing
            leftMargin: LingmoUI.Units.largeSpacing * 2
            rightMargin: LingmoUI.Units.largeSpacing * 2
            topMargin: LingmoUI.Units.smallSpacing
            bottomMargin: LingmoUI.Units.largeSpacing
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {}

            LingmoUI.WheelHandler {
                target: alarmList
            }

            delegate: Card {
                width: ListView.view.width - ListView.view.leftMargin - ListView.view.rightMargin
                height: alarmRow.implicitHeight + LingmoUI.Units.largeSpacing * 2
                hoverEnabled: true

                RowLayout {
                    id: alarmRow
                    anchors.fill: parent
                    anchors.leftMargin: LingmoUI.Units.largeSpacing * 1.5
                    anchors.rightMargin: LingmoUI.Units.largeSpacing
                    spacing: LingmoUI.Units.largeSpacing

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label {
                            text: modelData.time
                            font.pointSize: LingmoUI.Theme.fontSize * 2
                            font.bold: true
                            color: modelData.active ? LingmoUI.Theme.textColor : LingmoUI.Theme.disabledTextColor
                        }
                        Label {
                            text: modelData.label
                            color: LingmoUI.Theme.disabledTextColor
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Switch {
                        checked: modelData.active
                        onToggled: alarmManager.toggleAlarm(modelData.id, checked)
                    }

                    IconButton {
                        iconName: "edit-delete"
                        onClicked: alarmManager.deleteAlarm(modelData.id)
                    }
                }
            }

            Label {
                anchors.centerIn: parent
                text: qsTr("Nenhum alarme configurado.")
                color: LingmoUI.Theme.disabledTextColor
                visible: alarmList.count === 0
            }
        }

        // Add Alarm
        Card {
            Layout.fillWidth: true
            Layout.leftMargin: LingmoUI.Units.largeSpacing * 2
            Layout.rightMargin: LingmoUI.Units.largeSpacing * 2
            Layout.bottomMargin: LingmoUI.Units.largeSpacing * 2
            implicitHeight: addRow.implicitHeight + LingmoUI.Units.largeSpacing * 2

            RowLayout {
                id: addRow
                anchors.fill: parent
                anchors.margins: LingmoUI.Units.largeSpacing
                spacing: LingmoUI.Units.largeSpacing

                TextField {
                    id: timeField
                    placeholderText: "HH:mm"
                    Layout.preferredWidth: 80
                    inputMask: "99:99"
                }
                TextField {
                    id: labelField
                    placeholderText: qsTr("Nome do alarme")
                    Layout.fillWidth: true
                }
                ActionButton {
                    text: qsTr("Adicionar")
                    primary: true
                    onClicked: {
                        if (timeField.text.length === 5) {
                            alarmManager.addAlarm(timeField.text, labelField.text || qsTr("Alarme"))
                            timeField.text = ""
                            labelField.text = ""
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: alarmManager
        function onAlarmRinging(label) {
            ringDialog.title = qsTr("Alarme: ") + label
            ringDialog.open()
        }
    }

    Dialog {
        id: ringDialog
        standardButtons: Dialog.Ok
        anchors.centerIn: parent
        modal: true
        Label {
            text: qsTr("O alarme está tocando!")
            font.pointSize: LingmoUI.Theme.fontSize * 1.5
            color: LingmoUI.Theme.textColor
        }
    }
}

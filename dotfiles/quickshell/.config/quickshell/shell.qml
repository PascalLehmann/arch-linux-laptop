import Quickshell
import QtQuick
import Quickshell.Services.UPower

ShellRoot {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel
            required property var modelData
            screen: modelData

            anchors {
                top:   true
                left:  true
                right: true
            }
            implicitHeight: 32
            color: "#1e1e2e"

            Row {
                id: leftSection
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12
            }

            Row {
                id: centerSection
                anchors.centerIn: parent
                spacing: 12

                Text {
                    id: clockText
                    color: "#ffffff"
                    font.pixelSize: 16
                    text: Qt.formatDateTime(new Date(), "ddd, dd.MM.yyyy hh:mm:ss")
                }
            }

            Row {
                id: rightSection
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
		spacing: 12

Text {
    id: batteryText
    color: "#ffffff"
    font.pixelSize: 14
    text: {
        var dev = UPower.displayDevice
        if (!dev.ready) return "…"
        var pct = Math.round(dev.percentage * 100)
        var stateLabel = ""
        switch (dev.state) {
            case UPowerDeviceState.Charging:         stateLabel = "Lädt"; break
            case UPowerDeviceState.Discharging:      stateLabel = "Entlädt"; break
            case UPowerDeviceState.FullyCharged:     stateLabel = "Voll"; break
            case UPowerDeviceState.PendingCharge:    stateLabel = "Wartet (Laden)"; break
            case UPowerDeviceState.PendingDischarge: stateLabel = "Wartet (Entladen)"; break
            case UPowerDeviceState.Empty:             stateLabel = "Leer"; break
            default:                                  stateLabel = "Unbekannt"; break
        }
        return pct + "% [" + stateLabel + "]"
    }
}            }

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: clockText.text = Qt.formatDateTime(new Date(), "ddd, dd.MM.yyyy hh:mm:ss")
            }
        }
    }
}

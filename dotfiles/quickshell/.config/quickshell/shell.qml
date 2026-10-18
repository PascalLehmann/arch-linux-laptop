  import Quickshell   // Stellt die Quickshell-eigenen QML-Typen bereit (ShellRoot, PanelWindow, ...)
  import QtQuick      // Stellt die Qt-Basis-Typen bereit (Text, Timer, ...)

  // ShellRoot ist der Wurzel-Knoten jeder Quickshell-Konfiguration — vergleichbar
  // mit "ApplicationWindow" in normalen Qt-Apps, nur dass hier mehrere eigenständige
  // Fenster (PanelWindows) als Kinder existieren können.
  ShellRoot {

      // PanelWindow erzeugt ein Fenster über das Wayland-Protokoll "wlr-layer-shell"
      // (das gleiche Protokoll, das auch mako für seine Benachrichtigungs-Overlays nutzt,
      // siehe 02-mako.md) — es "klebt" an einer Bildschirmkante, statt ein normales,
      // verschiebbares Fenster zu sein, und Hyprland reserviert dafür automatisch Platz.
      PanelWindow {
          anchors {
              top:   true   // An der oberen Bildschirmkante andocken
              left:  true   // ... über die volle Breite ...
              right: true   // ... bis zur rechten Kante.
          }
          implicitHeight: 32      // Höhe der Bar in Pixeln
          color: "#1e1e2e"        // Hintergrundfarbe (Platzhalter-Dark-Theme, später anpassbar)

          Text {
              id: clockText
              anchors.centerIn: parent
              color: "#ffffff"
              font.pixelSize: 16
              // Erstbefüllung beim Start, bevor der Timer das erste Mal auslöst:
              text: Qt.formatDateTime(new Date(), "ddd, dd.MM.yyyy hh:mm:ss")
          }

          // Qt bringt keinen "lebenden" Uhr-Typ ohne Weiteres mit — ein Timer,
          // der die Textanzeige jede Sekunde neu berechnet, ist der einfachste,
          // von Quickshell-Version unabhängige Weg.
          Timer {
              interval: 1000   // Millisekunden
              running: true
              repeat: true
              onTriggered: clockText.text = Qt.formatDateTime(new Date(), "ddd, dd.MM.yyyy hh:mm:ss")
          }
      }
  }


import QtQuick
import Quickshell.Io

// RX 9070 XT. Steel at rest, ember when warm, blood when it is actually working.
Item {
  id: root

  property var bar: null
  property string moduleName: ""
  property var settings: ({})

  property int busy: 0
  property int tempC: 0
  property bool haveReading: false

  readonly property int barSize: bar ? bar.barSize : 34
  readonly property bool hot: tempC >= 80 || busy >= 90
  readonly property bool warm: !hot && (tempC >= 65 || busy >= 60)
  readonly property color ink: hot ? "#E5383B" : (warm ? "#C9A227" : "#D8D3C8")

  property bool interactive: true
  property bool pressable: true
  property bool concealed: false

  signal pressed(int button)

  function triggerPress(button) {
    if (bar && bar.hideTooltip) bar.hideTooltip(root)
    if (bar) bar.run("omarchy-launch-or-focus-tui btop")
  }

  function applyReading(raw) {
    var parts = String(raw || "").trim().split(/\s+/)
    if (parts.length < 2) return
    var b = parseInt(parts[0], 10)
    var t = parseInt(parts[1], 10)
    if (!isFinite(b) || !isFinite(t)) return
    busy = Math.max(0, Math.min(100, b))
    tempC = Math.round(t / 1000)
    haveReading = true
  }

  implicitWidth: label.implicitWidth + 16
  implicitHeight: barSize

  Text {
    id: label
    anchors.centerIn: parent
    text: root.haveReading ? ("GPU " + root.busy + "%  " + root.tempC + "°C") : "GPU"
    color: root.ink
    font.family: root.bar ? root.bar.fontFamily : "monospace"
    font.pixelSize: 12
    font.letterSpacing: 0.4
    renderType: Text.NativeRendering

    Behavior on color {
      ColorAnimation { duration: 180 }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    cursorShape: Qt.PointingHandCursor
    onEntered: if (root.bar && root.bar.showTooltip) root.bar.showTooltip(root, "RX 9070 XT  ·  click for btop")
    onExited: if (root.bar && root.bar.hideTooltip) root.bar.hideTooltip(root)
    onClicked: root.triggerPress(Qt.LeftButton)
  }

  Process {
    id: poll
    command: ["bash", "-c", "busy=$(cat /sys/class/drm/card1/device/gpu_busy_percent 2>/dev/null || echo 0); temp=$(cat /sys/class/drm/card1/device/hwmon/hwmon*/temp1_input 2>/dev/null | head -1 || echo 0); printf '%s %s\\n' \"$busy\" \"$temp\""]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyReading(text)
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!poll.running) poll.running = true
  }
}

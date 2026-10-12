import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons

Item {
  id: root

  readonly property int thickness: 2
  readonly property color blood: "#C1121F"
  property string position: "top"
  // Newline-wrapped Hyprland monitor names that currently have a fullscreen window.
  property string coveredList: "\n"

  FileView {
    path: Quickshell.env("HOME") + "/.config/omarchy/shell.json"
    watchChanges: true
    onLoaded: {
      try {
        var cfg = JSON.parse(String(text() || "{}"))
        var next = cfg && cfg.bar && cfg.bar.position ? String(cfg.bar.position) : "top"
        if (next === "top" || next === "bottom" || next === "left" || next === "right")
          root.position = next
      } catch (e) {
        root.position = "top"
      }
    }
    onFileChanged: reload()
  }

  Timer {
    interval: 300
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (!watch.running)
        watch.running = true
    }
  }

  Process {
    id: watch
    command: ["python3", Quickshell.env("HOME") + "/.config/omarchy/plugins/synth.blackshield-edge/fullscreen-monitors.py"]
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = String(text || "").split("\n")
        var acc = "\n"
        for (var i = 0; i < lines.length; ++i) {
          var name = lines[i].trim()
          if (name.length)
            acc += name + "\n"
        }
        root.coveredList = acc
      }
    }
  }

  Variants {
    model: Quickshell.screens

    delegate: Item {
      id: slot
      required property var modelData

      readonly property bool vertical: root.position === "left" || root.position === "right"
      readonly property int span: vertical ? Style.bar.sizeVertical : Style.bar.sizeHorizontal
      readonly property string screenName: modelData && modelData.name ? String(modelData.name) : ""
      readonly property bool hideLine: screenName.length > 0 && root.coveredList.indexOf("\n" + screenName + "\n") !== -1

      Loader {
        active: !slot.hideLine
        sourceComponent: PanelWindow {
          screen: slot.modelData
          color: "transparent"
          surfaceFormat.opaque: false
          exclusionMode: ExclusionMode.Ignore
          WlrLayershell.namespace: "blackshield-edge"
          WlrLayershell.layer: WlrLayer.Overlay
          WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
          mask: Region {}

          anchors.top: root.position === "top" || slot.vertical
          anchors.bottom: root.position === "bottom" || slot.vertical
          anchors.left: root.position === "left" || !slot.vertical
          anchors.right: root.position === "right" || !slot.vertical

          implicitWidth: slot.vertical ? slot.span : 0
          implicitHeight: slot.vertical ? 0 : slot.span

          Rectangle {
            color: root.blood
            width: slot.vertical ? root.thickness : parent.width
            height: slot.vertical ? parent.height : root.thickness
            anchors.left: root.position === "right" ? parent.left : undefined
            anchors.right: root.position === "left" ? parent.right : undefined
            anchors.top: root.position === "bottom" ? parent.top : undefined
            anchors.bottom: root.position === "top" ? parent.bottom : undefined
          }
        }
      }
    }
  }
}

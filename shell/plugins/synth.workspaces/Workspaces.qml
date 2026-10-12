import QtQuick
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "synth.workspaces"

  // Stock shows 1-5 and grows. This desk is a fixed eight, and the focused
  // desk stays a numeral instead of swapping for the stock glyph.
  readonly property var plates: [1, 2, 3, 4, 5, 6, 7, 8]
  readonly property int plateWidth: vertical ? barSize : Style.space(20)
  readonly property int plateGap: vertical ? Style.space(2) : Style.space(1)
  readonly property int plateSpan: plates.length * plateWidth + Math.max(0, plates.length - 1) * plateGap
  readonly property real trailingGap: vertical ? 0 : Style.spaceReal(1.5)

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }
    return null
  }

  function focusWorkspace(id) {
    // Do not go through bar.run. A reloaded plugin can paint before the bar
    // handle exists, and the old guard swallowed the press.
    Util.execDetached("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
  }

  // Size the slot from the plate count. A Row's implicit width ignores a
  // child's explicit width, which collapsed the hit area to nothing while
  // the numerals still painted outside it.
  implicitWidth: plateSpan + trailingGap
  implicitHeight: barSize

  Row {
    id: row
    spacing: root.plateGap

    Repeater {
      model: root.plates

      Item {
        id: cell
        required property int modelData

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData

        // The bar overlay hit-tests these, not the painted text.
        property bool interactive: true
        property bool pressable: true
        property bool concealed: false

        implicitWidth: root.plateWidth
        implicitHeight: root.barSize
        width: root.plateWidth
        height: root.barSize

        function triggerPress(button) {
          root.focusWorkspace(cell.modelData)
        }

        function register() {
          if (root.bar && root.bar.registerClickTarget) root.bar.registerClickTarget(cell)
        }

        function unregister() {
          if (root.bar && root.bar.unregisterClickTarget) root.bar.unregisterClickTarget(cell)
        }

        Component.onCompleted: register()
        Component.onDestruction: unregister()
        Connections {
          target: root
          function onBarChanged() { cell.register() }
        }
        Timer {
          interval: 200
          repeat: true
          running: root.bar === null
          onTriggered: cell.register()
        }

        WidgetButton {
          anchors.fill: parent
          bar: root.bar
          text: String(cell.modelData)
          active: cell.focused
          opacity: cell.occupied || cell.focused ? 1 : 0.5
          horizontalMargin: 6
          verticalPadding: 6
          onPressed: function(button) { cell.triggerPress(button) }
        }
      }
    }
  }
}

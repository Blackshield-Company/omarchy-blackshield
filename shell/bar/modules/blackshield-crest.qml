import QtQuick

// Templar cross + wordmark. Left click opens the menu. Right click opens a terminal.
Item {
  id: root

  property var bar: null
  property string moduleName: ""
  property var settings: ({})

  readonly property color blood: "#C1121F"
  readonly property color bone: "#F5F1E8"
  readonly property int barSize: bar ? bar.barSize : 34

  property bool interactive: true
  property bool pressable: true
  property bool concealed: false

  signal pressed(int button)

  function triggerPress(button) {
    if (bar && bar.hideTooltip) bar.hideTooltip(root)
    if (!bar) return
    if (button === Qt.RightButton) bar.run("xdg-terminal-exec")
    else bar.run("omarchy-shell shell toggle omarchy.menu '{\"menu\":\"root\"}'")
  }

  implicitWidth: row.implicitWidth + 14
  implicitHeight: barSize

  Row {
    id: row
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.leftMargin: 10
    spacing: 8

    Item {
      id: cross
      width: 12
      height: 16
      anchors.verticalCenter: parent.verticalCenter

      Rectangle {
        width: 2
        height: 14
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        color: root.blood
      }

      Rectangle {
        width: 10
        height: 2
        anchors.horizontalCenter: parent.horizontalCenter
        y: 3
        color: root.blood
      }
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: "BLACKSHIELD"
      color: root.bone
      font.family: "Pirata One"
      font.pixelSize: 16
      font.letterSpacing: 0.6
      font.weight: Font.Medium
      renderType: Text.NativeRendering
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onEntered: if (root.bar && root.bar.showTooltip) root.bar.showTooltip(root, "Blackshield  ·  the shield holds")
    onExited: if (root.bar && root.bar.hideTooltip) root.bar.hideTooltip(root)
    onClicked: function(mouse) { root.triggerPress(mouse.button) }
  }
}

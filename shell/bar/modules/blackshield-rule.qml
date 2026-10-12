import QtQuick

Item {
  id: root

  property var bar: null
  property string moduleName: ""
  property var settings: ({})

  readonly property int barSize: bar ? bar.barSize : 34

  implicitWidth: 13
  implicitHeight: barSize

  Rectangle {
    anchors.centerIn: parent
    width: 1
    height: Math.round(root.barSize * 0.42)
    color: "#8F959C"
    opacity: 0.55
  }
}

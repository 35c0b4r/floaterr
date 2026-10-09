import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.35c0b4r.floaterr"

  // The service can finish loading after the bar does, and serviceFor() is not
  // a notifying property, so keep asking until it answers.
  property var service: null
  readonly property bool featureEnabled: root.service ? root.service.dragEnabled === true : false

  function resolveService() {
    if (root.service) return
    var shell = root.bar ? root.bar.shell : null
    root.service = shell && typeof shell.serviceFor === "function"
      ? shell.serviceFor(root.moduleName) : null
  }

  onBarChanged: resolveService()
  Component.onCompleted: resolveService()

  Timer {
    interval: 500
    repeat: true
    running: root.service === null
    onTriggered: root.resolveService()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    // nf-md-mouse / nf-md-mouse_off
    text: root.featureEnabled ? "\u{F037D}" : "\u{F037E}"
    slotSize: Style.bar.statusSlot
    active: root.featureEnabled
    useActiveColor: true
    tooltipText: root.featureEnabled
      ? "Floaterr on: hold middle mouse to move windows (click to disable)"
      : "Floaterr off (click to enable)"
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton && root.service) root.service.toggle()
    }
  }
}

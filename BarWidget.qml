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

  readonly property bool opened: panelLoader.item
    ? panelLoader.item.opened === true
    : false
  readonly property bool popoutSwitchClosing: panelLoader.item
    ? panelLoader.item.popoutSwitchClosing === true
    : false

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function toggle() {
    if (panelLoader.item) panelLoader.item.toggle()
  }

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  function injectPanel() {
    if (!panelLoader.item) return
    panelLoader.item.bar = root.bar
    panelLoader.item.anchorItem = button
    panelLoader.item.hostWidget = root
    panelLoader.item.service = root.service
  }

  function resolveService() {
    if (root.service) return
    var shell = root.bar ? root.bar.shell : null
    root.service = shell && typeof shell.serviceFor === "function"
      ? shell.serviceFor(root.moduleName) : null
  }

  onBarChanged: {
    resolveService()
    injectPanel()
  }
  onServiceChanged: injectPanel()
  Component.onCompleted: resolveService()

  Timer {
    interval: 500
    repeat: true
    running: root.service === null
    onTriggered: root.resolveService()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    // nf-md-mouse / nf-md-mouse_off
    text: root.featureEnabled ? "\u{F037D}" : "\u{F037E}"
    slotSize: Style.bar.statusSlot
    active: root.featureEnabled || root.opened
    useActiveColor: true
    tooltipText: root.featureEnabled
      ? "Floaterr on: click for options, right-click to disable"
      : "Floaterr off: click for options, right-click to enable"
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) {
        if (root.service) root.service.toggle()
      } else if (buttonCode === Qt.LeftButton) {
        root.toggle()
      }
    }
  }
}

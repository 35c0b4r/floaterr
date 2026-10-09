import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Owns the middle-button drag bind. There is one service per shell, while the
// bar builds a widget per monitor, so the on/off state lives here and every
// widget reads it back through shell.serviceFor().
Item {
  id: root

  // Injected by omarchy-shell.
  property var shell: null
  property var manifest: null

  readonly property string buttonKey: "mouse:274"
  readonly property string statePath:
    (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state"))
    + "/floaterr/enabled"

  property bool stateLoaded: false
  property bool dragEnabled: true

  readonly property string unbindLua: 'hl.unbind("' + buttonKey + '")'
  readonly property string bindLua: unbindLua + '; hl.bind("' + buttonKey
    + '", hl.dsp.window.drag(), { mouse = true, description = "Floaterr: move window" })'

  function setEnabled(value) {
    root.dragEnabled = !!value
    root.stateLoaded = true
    Quickshell.execDetached(["sh", "-c", 'mkdir -p "${1%/*}" && printf "%s\\n" "$2" > "$1"',
      "floaterr", root.statePath, root.dragEnabled ? "1" : "0"])
    root.apply()
  }

  function toggle() {
    setEnabled(!root.dragEnabled)
  }

  // Runtime binds don't survive a Hyprland config reload, so this is re-run
  // on every configreloaded as well as on every state change.
  function apply() {
    if (!root.stateLoaded) return
    if (applyProc.running) {
      applyQueued = true
      return
    }
    applyProc.command = ["hyprctl", "eval", root.dragEnabled ? root.bindLua : root.unbindLua]
    applyProc.running = true
  }

  property bool applyQueued: false

  Process {
    id: applyProc
    onRunningChanged: {
      if (running || !root.applyQueued) return
      root.applyQueued = false
      root.apply()
    }
  }

  FileView {
    id: stateFile
    path: root.statePath
    printErrors: false
    onLoaded: {
      root.dragEnabled = String(text()).trim() !== "0"
      root.stateLoaded = true
      startupApply.restart()
    }
    // First run: no state file yet, so the feature starts enabled.
    onLoadFailed: {
      root.stateLoaded = true
      startupApply.restart()
    }
  }

  // A plugin hot-reload destroys the old service (which unbinds) right before
  // creating this one. Give that detached unbind a moment to land first.
  Timer {
    id: startupApply
    interval: 400
    onTriggered: root.apply()
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event && event.name === "configreloaded") root.apply()
    }
  }

  // Disabling or removing the plugin must hand the middle button back to apps.
  Component.onDestruction: {
    if (root.dragEnabled) Quickshell.execDetached(["hyprctl", "eval", root.unbindLua])
  }

  IpcHandler {
    target: "floaterr"
    function toggle(): void { root.toggle() }
    function enable(): void { root.setEnabled(true) }
    function disable(): void { root.setEnabled(false) }
    function status(): string { return root.dragEnabled ? "enabled" : "disabled" }
  }
}

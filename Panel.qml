import QtQuick
import qs.Commons
import qs.Ui

// Dropdown under the bar icon: a hero showing the current state, a quick
// action, and On / Off tiles. All state lives in the service; this panel only
// reads it and calls back into it.
Panel {
  id: root
  moduleName: "io.github.35c0b4r.floaterr"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var service: null

  readonly property bool dragEnabled: root.service ? root.service.dragEnabled === true : false
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color accent: Color.accent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  readonly property string iconOn: "\u{F037D}"    // nf-md-mouse
  readonly property string iconOff: "\u{F037E}"   // nf-md-mouse_off
  readonly property string iconChevron: "\u{F0142}" // nf-md-chevron_right

  // Keyboard cursor over the focusable items, top to bottom, left to right:
  // 0 re-apply row, 1 On tile, 2 Off tile, 3 Done button.
  readonly property int itemCount: 4
  property int cursorIndex: -1

  readonly property var actions: [
    { icon: "\u{F359}", label: "Re-apply Hyprland bind" }  // nf-linux-hyprland
  ]

  function open() {
    root.cursorIndex = -1
    root.controller.show()
  }

  function close() {
    root.controller.hide()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.hostWidget || root, direction)
    return false
  }

  function setDrag(value) {
    if (root.service) root.service.setEnabled(value)
  }

  function runAction(index) {
    if (index === 0 && root.service) root.service.apply()
  }

  function activate(index) {
    if (index === 0) root.runAction(index)
    else if (index === 1) root.setDrag(true)
    else if (index === 2) root.setDrag(false)
    else if (index === 3) root.close()
  }

  function moveCursor(dx, dy) {
    var step = dx !== 0 ? dx : dy
    if (root.cursorIndex < 0) {
      root.cursorIndex = step < 0 ? root.itemCount - 1 : 0
      return
    }
    root.cursorIndex = Math.max(0, Math.min(root.itemCount - 1, root.cursorIndex + step))
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(260))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onMoveRequested: function(dx, dy) { root.moveCursor(dx, dy) }
      onActivateRequested: {
        if (root.cursorIndex < 0) root.setDrag(!root.dragEnabled)
        else root.activate(root.cursorIndex)
      }

      Column {
        id: content
        width: parent.width
        spacing: Style.space(10)

        // Hero: big mouse glyph in a framed box, accent-lit while active.
        BorderSurface {
          width: parent.width
          height: heroColumn.implicitHeight + Style.space(28)
          radius: Style.cornerRadius
          color: root.dragEnabled
            ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.08)
            : "transparent"
          borderSpec: Border.controlSpec("normal", root.foreground, root.accent)

          Behavior on color { ColorAnimation { duration: 120 } }

          Column {
            id: heroColumn
            anchors.centerIn: parent
            spacing: Style.space(4)

            Text {
              textFormat: Text.PlainText
              anchors.horizontalCenter: parent.horizontalCenter
              text: root.dragEnabled ? root.iconOn : root.iconOff
              color: root.dragEnabled ? root.accent : root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.displayLarge * 1.6
            }

            Text {
              textFormat: Text.PlainText
              anchors.horizontalCenter: parent.horizontalCenter
              text: "Floaterr"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
            }

            Text {
              textFormat: Text.PlainText
              anchors.horizontalCenter: parent.horizontalCenter
              text: root.dragEnabled ? "MIDDLE-DRAG ON" : "MIDDLE-DRAG OFF"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.2
            }
          }
        }

        // Quick action with a trailing chevron.
        Column {
          width: parent.width
          spacing: Style.space(2)

          Repeater {
            model: root.actions

            delegate: CursorSurface {
              id: actionRow
              required property var modelData
              required property int index

              width: parent.width
              height: Style.spacing.controlHeight
              hasCursor: root.cursorIndex === index
              foreground: root.foreground
              accent: root.accent

              Text {
                id: actionIcon
                textFormat: Text.PlainText
                anchors.left: parent.left
                anchors.leftMargin: Style.space(10)
                anchors.verticalCenter: parent.verticalCenter
                width: Style.space(20)
                text: actionRow.modelData.icon
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.icon
              }

              Text {
                textFormat: Text.PlainText
                anchors.left: actionIcon.right
                anchors.leftMargin: Style.space(8)
                anchors.right: chevron.left
                anchors.rightMargin: Style.space(8)
                anchors.verticalCenter: parent.verticalCenter
                text: actionRow.modelData.label
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                elide: Text.ElideRight
              }

              Text {
                id: chevron
                textFormat: Text.PlainText
                anchors.right: parent.right
                anchors.rightMargin: Style.space(10)
                anchors.verticalCenter: parent.verticalCenter
                text: root.iconChevron
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.icon
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.cursorIndex = actionRow.index
                onClicked: root.runAction(actionRow.index)
              }
            }
          }
        }

        PanelSeparator { foreground: root.foreground }

        // On / Off tiles.
        Row {
          id: tiles
          width: parent.width
          spacing: Style.space(10)

          Repeater {
            model: [
              { on: true, label: "On" },
              { on: false, label: "Off" }
            ]

            delegate: CursorSurface {
              id: tile
              required property var modelData
              required property int index

              readonly property bool selected: root.dragEnabled === modelData.on

              width: (tiles.width - tiles.spacing) / 2
              height: tileColumn.implicitHeight + Style.space(24)
              hasCursor: root.cursorIndex === 1 + index
              current: selected
              bordered: true
              foreground: root.foreground
              accent: root.accent

              Column {
                id: tileColumn
                anchors.centerIn: parent
                spacing: Style.space(4)

                Text {
                  textFormat: Text.PlainText
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: tile.modelData.on ? root.iconOn : root.iconOff
                  color: tile.selected ? root.accent : root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.displayLarge
                }

                Text {
                  textFormat: Text.PlainText
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: tile.modelData.label
                  color: tile.selected ? root.foreground : root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: tile.selected
                }
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.cursorIndex = 1 + tile.index
                onClicked: root.setDrag(tile.modelData.on)
              }
            }
          }
        }

        // Footer: status line and an accent Done button.
        Item {
          width: parent.width
          height: doneButton.implicitHeight

          Text {
            textFormat: Text.PlainText
            anchors.left: parent.left
            anchors.right: doneButton.left
            anchors.rightMargin: Style.space(8)
            anchors.verticalCenter: parent.verticalCenter
            text: root.dragEnabled ? "Middle-drag moves windows" : "Middle-click goes to apps"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            elide: Text.ElideRight
          }

          Button {
            id: doneButton
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: "Done"
            background: root.accent
            foreground: Color.background
            accent: root.accent
            fontFamily: root.fontFamily
            hasCursor: root.cursorIndex === 3
            onClicked: root.close()
            onHovered: function(h) { if (h) root.cursorIndex = 3 }
          }
        }
      }
    }
  }
}

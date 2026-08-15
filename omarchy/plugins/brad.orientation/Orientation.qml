import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

// Rotate lock for the accelerometer in this convertible.
//
// This is a bar widget of its own rather than an entry in omarchy.indicators,
// which is where it belongs on the merits. The cluster resolves each of its
// items to ../indicators/<id>.qml inside its own plugin directory, so joining
// it means cloning the whole widget and every upstream indicator with it. This
// borrows the same qs.Ui base and the same metrics instead, and sits next to
// the cluster looking like one of its members.
//
// State lives in the `autorotate-off` Omarchy toggle; ~/.local/bin/orientation
// owns the sensor daemon and flips it.
BarIconButton {
  id: root

  property string moduleName: ""
  property var settings: ({})

  // Locked is the state worth noticing, so it reads at full strength and
  // auto-rotate sits at the same 0.45 the cluster dims its off state to.
  property bool locked: false

  function run(process) {
    if (!process.running) process.running = true
  }

  text: locked ? "󰍁" : "󰑵"
  tooltipText: locked ? "Auto-rotate off — click to re-enable" : "Auto-rotate on — click to lock"
  dimmed: !locked
  // The urgent color is for urgency; this is a mode, not a warning.
  useActiveColor: false

  // Mirror BarIndicator, so the widget lines up with the cluster beside it
  // rather than with the wider interactive widgets.
  fontSize: Style.font.caption
  horizontalMargin: 5
  verticalPadding: 5
  fixedWidth: vertical ? -1 : Style.bar.statusSlot
  fixedHeight: vertical ? Style.bar.statusSlot : -1

  onPressed: function(button) { root.run(toggleProcess) }

  // The toggle is a flag file, so its exit code is the whole state and there is
  // nothing to parse.
  Process {
    id: statusProcess

    command: ["omarchy-toggle-enabled", "autorotate-off"]
    onExited: function(exitCode) { root.locked = exitCode === 0 }
  }

  // Re-read on the way out of a toggle rather than waiting for the next tick,
  // so the glyph changes under the click.
  Process {
    id: toggleProcess

    // No shell wrapper: uwsm's env.d puts ~/.local/bin on the session PATH, so
    // the shell process resolves this itself.
    command: ["orientation", "toggle"]
    onExited: root.run(statusProcess)
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.run(statusProcess)
  }
}

import QtQuick
import Quickshell.Io
import qs.Ui

// Omarchy's NightLight indicator only drives hyprsunset, so this mirrors its
// Dnd indicator for sunsetr: lit while the schedule runs, revealed with the
// indicator cluster on bar hover once switched off. Off is sunsetr's `day`
// preset; applying it again resumes the schedule.
//
// A widget of its own beside omarchy.indicators, like the orientation plugin:
// the cluster only loads items from its own directory.
BarIndicator {
  id: root

  active: true
  activeText: "󰖔"
  activeTooltipText: "Turn off nightlight"
  inactiveTooltipText: "Resume nightlight schedule"

  // Stands in for the cluster, which owns the hover peek; the bar exposes the
  // same peek state the cluster reads.
  indicatorHost: QtObject {
    readonly property bool revealInactiveIndicators: !!root.bar && root.bar.centerSectionRevealHeld === true && root.bar._centerHoverRevealSuppressed !== true
  }

  onPressed: function() { if (!toggle.running) toggle.running = true }

  Process {
    id: toggle
    command: ["sunsetr", "preset", "day"]
    onExited: status.running = true
  }

  Process {
    id: status
    command: ["sunsetr", "preset", "active"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.active = text.trim() !== "day"
    }
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!status.running) status.running = true
  }
}

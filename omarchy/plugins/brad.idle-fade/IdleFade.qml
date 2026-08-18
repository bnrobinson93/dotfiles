import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// The warning that the screen is about to go.
//
// v4's idle service has exactly two rungs — screensaver and lock — and the lock
// plugin blanks the panel with a single DPMS disable, so the display goes from
// full brightness to black in one jump with nothing in between. This adds the
// dim step back as a second IdleMonitor that fires a few seconds ahead of the
// lock; `idle-dim` walks the backlight down, and any activity restores it.
//
// A monitor of our own rather than a hook into upstream's: the idle service
// exposes only status over IPC, and the alternatives (shadowing
// omarchy-brightness-display, which the lock calls *after* the screen is
// already locked, or shadowing omarchy-system-lock, which would delay a manual
// lock too) both fade at the wrong moment.
Item {
  id: root

  // Injected by omarchy-shell's service loader.
  property var shell: null

  readonly property string dimCommand: Quickshell.env("HOME") + "/.local/bin/idle-dim"
  readonly property var idleConfig: shell && shell.shellConfig && shell.shellConfig.idle ? shell.shellConfig.idle : ({})
  readonly property int lockSeconds: Number(idleConfig.lock) > 0 ? Number(idleConfig.lock) : 300

  // The fade itself takes about three seconds from full brightness, so it wants
  // to start a beat before the lock and finish as the screen goes.
  readonly property int leadSeconds: 5
  readonly property int fadeTimeoutSeconds: Math.max(1, root.lockSeconds - root.leadSeconds)

  function run(process, argument) {
    if (process.running) return
    process.command = [root.dimCommand, argument]
    process.running = true
  }

  IdleMonitor {
    timeout: root.fadeTimeoutSeconds
    respectInhibitors: true
    onIsIdleChanged: isIdle ? root.run(fadeProcess, "fade") : root.run(restoreProcess, "restore")
  }

  Process { id: fadeProcess }
  Process { id: restoreProcess }

  // Upstream's idle service narrates itself into the shell log; a silent second
  // monitor would be indistinguishable from one that never loaded. Log on the
  // timeout too, since shell.json lands after startup and the first value is
  // the built-in default rather than ours.
  function logTimeout() {
    console.log("brad idle-fade: fade at " + root.fadeTimeoutSeconds + "s, lock at " + root.lockSeconds + "s")
  }

  onFadeTimeoutSecondsChanged: root.logTimeout()
  Component.onCompleted: root.logTimeout()
}

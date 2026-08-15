// Stock omarchy.menu bar widget with the leaf glyph the v3 waybar module used.
// Only the icon differs, so this stays a plain bar-widget rather than a clone of
// omarchy.menu: the stock plugin keeps owning the menu itself (its "menu" kind is
// mounted from the plugin registry, not from the bar layout), and this widget just
// toggles it by id the same way upstream's own widget does.
import QtQuick
import qs.Ui

BarWidget {
  id: root
  moduleName: "brad.menu-button"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    // nf-md-leaf, U+F032A. No fontFamily override: the bar font is a Nerd Font
    // and carries the glyph, whereas upstream's "" needs the omarchy font.
    text: "󰌪"
    horizontalMargin: 7.5
    onPressed: function(button) {
      if (!root.bar) return
      if (button === Qt.RightButton) root.bar.run("xdg-terminal-exec")
      else root.bar.run("omarchy-shell shell toggle omarchy.menu '{\"menu\":\"root\"}'")
    }
  }
}

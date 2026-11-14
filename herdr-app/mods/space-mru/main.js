// Last space: jumps to the most recently used open space other than the shown one,
// like the CLI's last-workspace plugin. Bound to ctrl-b l in keys.json.
//
// The app keeps no visit order, so a copy with props { role: "track" } keeps it in
// shared state: an invisible floating block in the layout (resources/herdr-app/layout.py),
// which renders on every space change. Without that block the order stops updating.

import { View, div } from "gpui-kit";
import { spaces, run, props, closeOverlay, shared, setShared } from "herdr";

const KEY = "space-mru";

export default class SpaceMru extends View {
  init() {
    if (props()?.role === "track") return;
    const open = spaces();
    const last = (shared(KEY) ?? [])
      .map((id) => open.find((s) => s.id === id))
      .find((s) => s && !s.active);
    const overlay = props()?.overlay;
    if (overlay) closeOverlay(overlay);
    if (last) run("space.select", { id: last.id });
  }

  render(cx) {
    if (props()?.role === "track") this.track(cx);
    return div();
  }

  // Writes outside render: setting shared state redraws every mod, this one included.
  track(cx) {
    const open = spaces();
    const active = open.find((s) => s.active)?.id;
    const order = shared(KEY) ?? [];
    if (!active || order[0] === active) return;
    const ids = new Set(open.map((s) => s.id));
    cx.spawn(async () => setShared(KEY, [active, ...order.filter((id) => id !== active && ids.has(id))]));
  }
}

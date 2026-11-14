// Last space: jumps to the most recently used open space other than the shown one,
// like the CLI's last-workspace plugin. Bound to ctrl-b l in keys.json.
// Order comes from ~/.local/state/herdr-space-mru (the herdr-space-mru service).

import { View, div } from "gpui-kit";
import { spaces, run, home, props, closeOverlay, readTextFile } from "herdr";

export default class SpaceMru extends View {
  init(_props, cx) {
    cx.spawn(async () => {
      const text = await readTextFile(`${home()}/.local/state/herdr-space-mru`);
      const open = spaces();
      const last = (text ?? "")
        .split("\n")
        .map((id) => open.find((s) => s.id === id))
        .find((s) => s && !s.active);
      closeOverlay(props().overlay);
      if (last) run("space.select", { id: last.id });
    });
  }

  render() {
    return div();
  }
}

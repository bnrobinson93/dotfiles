// Create-or-jump to ~/Documents/code. Bound to a ctrl-b chord in keys.json.
import { View, div } from "gpui-kit";
import { spaces, run, home, props, closeOverlay } from "herdr";

const NAME = "code";

export default class Jump extends View {
  init() {
    closeOverlay(props().overlay);
    const folder = `${home()}/Documents/code`;
    const at = spaces().find((s) => s.folder === folder || s.name === NAME);
    if (at) run("space.select", { id: at.id });
    else run("space.new", { folder, name: NAME });
  }

  render() {
    return div();
  }
}

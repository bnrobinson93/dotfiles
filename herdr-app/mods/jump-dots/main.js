// Create-or-jump to ~/.dotfiles. Bound to a ctrl-b chord in keys.json.
import { View, div } from "gpui-kit";
import { spaces, run, home, props, closeOverlay } from "herdr";

const NAME = ".dotfiles";

export default class Jump extends View {
  init() {
    closeOverlay(props().overlay);
    const folder = `${home()}/.dotfiles`;
    const at = spaces().find((s) => s.folder === folder || s.name === NAME);
    if (at) run("space.select", { id: at.id });
    else run("space.new", { folder, name: NAME });
  }

  render() {
    return div();
  }
}

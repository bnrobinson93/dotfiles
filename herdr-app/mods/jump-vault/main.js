// Create-or-jump to ~/Documents/Vault. Bound to a ctrl-b chord in keys.json.
import { View, div } from "gpui-kit";
import { spaces, run, home, props, closeOverlay } from "herdr";

const NAME = "Vault";

export default class Jump extends View {
  init() {
    closeOverlay(props().overlay);
    const folder = `${home()}/Documents/Vault`;
    const at = spaces().find((s) => s.folder === folder || s.name === NAME);
    if (at) run("space.select", { id: at.id });
    else run("space.new", { folder, name: NAME });
  }

  render() {
    return div();
  }
}

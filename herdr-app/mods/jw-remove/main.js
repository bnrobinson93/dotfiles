// Remove JJ workspace — jj-waltz's `jw remove` for the focused space, then
// close that space. Mirrors the Rex jj_workspace_remove flow: refuses the
// default workspace. Opened with a key via `mod.open:jw-remove`. y confirms, Esc cancels.

import { View, div } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { exec, run, spaces, focused, theme, props, closeOverlay } from "herdr";

export default class JwRemove extends View {
  init(_props, cx) {
    this.loaded = false;
    this.busy = false;
    this.err = "";
    this.name = "";
    this.root = "";
    this.defaultRoot = "";
    this.isDefault = false;
    this.spaceId = focused()?.space ?? spaces().find((s) => s.active)?.id;
    this.handle = cx.focus_handle();
    this.handle.focus();
    cx.spawn(async (cx) => {
      const cwd = focused()?.cwd || spaces().find((s) => s.active)?.folder || undefined;
      const [cur, root, def] = await Promise.all([
        exec("jw", ["current"], { cwd }),
        exec("jw", ["root"], { cwd }),
        exec("jw", ["path", "^"], { cwd }),
      ]);
      if (cur.code !== 0 || root.code !== 0) { this.err = cur.stderr.trim() || "not inside a JJ workspace"; this.loaded = true; return cx.notify(); }
      this.name = cur.stdout.trim();
      this.root = root.stdout.trim();
      this.defaultRoot = def.stdout.trim();
      this.isDefault = !!this.defaultRoot && this.root === this.defaultRoot;
      this.loaded = true;
      cx.notify();
    });
  }

  remove(cx) {
    if (this.busy || this.err || this.isDefault || !this.loaded) return;
    this.busy = true;
    cx.notify();
    cx.spawn(async (cx) => {
      // Run from the default root so jw isn't inside the directory it forgets.
      const r = await exec("jw", ["remove", this.name, "--keep-bookmark"], { cwd: this.defaultRoot || undefined });
      if (r.code !== 0) { this.busy = false; this.err = r.stderr.trim() || "jw remove failed"; return cx.notify(); }
      this.close();
      if (this.spaceId) run("space.close", { id: this.spaceId, confirmed: true });
    });
  }

  close() { closeOverlay(props().overlay); }

  render() {
    const t = theme();
    const body = () => {
      if (!this.loaded) return div().text_color(t.dim).child("Checking workspace…");
      if (this.err) return div().text_color(t.blocked).child(this.err);
      if (this.isDefault) return div().text_color(t.blocked).child("Refusing to remove the default JJ workspace.");
      return div().text_color(t.muted).child(`Remove workspace “${this.name}” at ${this.root}? This closes its space.`);
    };
    const canRemove = this.loaded && !this.err && !this.isDefault;
    const button = (id, label, bg, fg, onClick) =>
      h_flex().id(id).h(32).px(14).items_center().rounded(8).border_1().border_color(bg).bg(bg).text_color(fg).cursor_pointer().hover((s) => s.opacity(0.88)).on_click((_e, cx) => onClick(cx)).child(label);
    return v_flex()
      .id("jw-remove").track_focus(this.handle)
      .on_key_down((e, cx) => {
        const k = e.key;
        if (k === "escape" || k === "n") this.close();
        else if ((k === "y" || k === "enter") && canRemove) this.remove(cx);
        else return;
        cx.stop_propagation();
      })
      .size_full().min_h(0).p(18).gap(12).bg(t.popover).text_size(13)
      .child(h_flex().items_center()
        .child(div().flex_1().text_size(15).font_semibold().text_color(t.foreground).child("Remove JJ workspace"))
        .child(div().text_size(11).text_color(t.dim).child("Esc")))
      .child(div().flex_1().min_h(0).child(body()))
      .child(h_flex().justify_end().gap(8).text_size(12)
        .child(button("no", "Cancel", t.raised, t.foreground, () => this.close()))
        .when(canRemove, (el) => el.child(button("yes", this.busy ? "removing…" : "Remove", t.blocked, t.solid_foreground, (cx) => this.remove(cx)))));
  }
}

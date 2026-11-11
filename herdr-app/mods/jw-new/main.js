// New JJ workspace — jj-waltz's `jw add`, then open the workspace as a space.
// Mirrors the Rex jj_workspace_new flow. Opened with a key via `mod.open:jw-new`.
// Runs jw in the focused terminal's repo. Type a name, Enter to create, Esc to cancel.

import { View, div } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { exec, run, spaces, focused, theme, props, closeOverlay } from "herdr";

export default class JwNew extends View {
  init(_props, cx) {
    this.busy = false;
    this.msg = "";
    this.handle = cx.focus_handle();
    this.input = InputState.new({ placeholder: "workspace name…" });
    this.input.on("submit", (_e, cx) => this.submit(cx));
    this.input.focus();
    cx.timer.after(300, () => this.input.focus());
  }

  cwd() {
    return focused()?.cwd || spaces().find((s) => s.active)?.folder || undefined;
  }

  submit(cx) {
    if (this.busy) return;
    const name = this.input.value().trim();
    if (!name) return this.close();
    this.busy = true;
    this.msg = "";
    cx.notify();
    cx.spawn(async (cx) => {
      const cwd = this.cwd();
      const add = await exec("jw", ["add", name], { cwd });
      if (add.code !== 0) { this.busy = false; this.msg = add.stderr.trim() || "jw add failed"; return cx.notify(); }
      const p = await exec("jw", ["path", name], { cwd });
      const path = p.stdout.trim();
      if (p.code !== 0 || !path) { this.busy = false; this.msg = `created ${name}, but could not find its path`; return cx.notify(); }
      this.close();
      run("space.new", { folder: path, name });
    });
  }

  close() { closeOverlay(props().overlay); }

  render() {
    const t = theme();
    return v_flex()
      .id("jw-new").track_focus(this.handle)
      .size_full().min_h(0).p(18).gap(12).bg(t.popover).text_size(13)
      .on_key_down((e, cx) => {
        if (e.key === "escape") { this.close(); cx.stop_propagation(); }
      })
      .child(h_flex().items_center()
        .child(div().flex_1().text_size(15).font_semibold().text_color(t.foreground).child("New JJ workspace"))
        .child(div().text_size(11).text_color(t.dim).child("Esc")))
      .child(h_flex().h(36).flex_none().px(10).items_center().rounded(9).border_1().border_color(t.accent).bg(t.background)
        .child(Input.new(this.input).flex_1().h_full().text_size(12.8).text_color(t.foreground)))
      .child(div().text_size(11).text_color(this.msg ? t.blocked : t.dim)
        .child(this.msg || (this.busy ? "creating…" : "Enter to create in the current repo")));
  }
}

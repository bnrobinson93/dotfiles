// New JJ workspace. Enter creates from main; the secondary action stacks on the
// nearest current bookmark. Both fetch first, then open the new workspace as a space.
// Opened with a key via `mod.open:jw-new`.

import { View, div } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { exec, run, spaces, focused, theme, props, closeOverlay, notify } from "herdr";

export default class JwNew extends View {
  init(_props, cx) {
    this.busy = false;
    this.fetching = false;
    this.msg = "";
    this.bookmark = "";
    this.bookmarkLoading = true;
    this.handle = cx.focus_handle();
    this.input = InputState.new({ placeholder: "workspace name…" });
    this.input.on("submit", (event, cx) => {
      if (event.secondary || event.shift) this.submitStack(cx);
      else this.submitMain(cx);
    });
    this.input.focus();
    cx.timer.after(300, () => this.input.focus());

    const cwd = this.cwd();
    cx.spawn(async (cx) => {
      if (!cwd) { this.bookmarkLoading = false; return cx.notify(); }
      const current = await exec("jj", [
        "log", "-r", "heads(::@ & bookmarks() & ~::trunk())", "--no-graph",
        "-T", 'local_bookmarks.map(|b| b.name()).join("\\n")',
      ], { cwd }).catch(() => ({ code: 1, stdout: "" }));
      if (current.code === 0) this.bookmark = current.stdout.trim().split("\n").find(Boolean) || "";
      this.bookmarkLoading = false;
      this.msg = "";
      cx.notify();
    });
  }

  cwd() {
    return focused()?.cwd || spaces().find((s) => s.active)?.folder || undefined;
  }

  submitMain(cx) { this.submit(cx, "trunk()", "main"); }

  submitStack(cx) {
    if (!this.bookmark) {
      this.msg = this.bookmarkLoading ? "Still checking the current bookmark…" : "No current bookmark to stack on.";
      return cx.notify();
    }
    this.submit(cx, `bookmarks(exact:${JSON.stringify(this.bookmark)})`, this.bookmark);
  }

  submit(cx, base, label) {
    if (this.busy) return;
    const name = this.input.value().trim();
    if (!name) return this.close();
    this.busy = true;
    this.msg = "";
    cx.notify();
    cx.spawn(async (cx) => {
      const cwd = this.cwd();
      // Fetch first so trunk() is current; offline still uses the local base.
      this.fetching = true;
      cx.notify();
      const fetch = await exec("jj", ["git", "fetch"], { cwd, timeout: 120000 }).catch((e) => ({ code: 1, stderr: String(e) }));
      if (fetch.code !== 0)
        notify({ title: "jj git fetch failed", body: `${(fetch.stderr || "").trim()}\nCreating ${name} from the local ${label}.`, level: "warning" });
      this.fetching = false;
      cx.notify();
      const add = await exec("jw", ["add", name, "--at", base], { cwd });
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
    const button = (id, label, bg, fg, onClick, disabled) =>
      h_flex().id(id).h(32).px(14).items_center().rounded(8).border_1().border_color(bg).bg(bg)
        .text_color(fg)
        .when(disabled, (el) => el.opacity(0.6))
        .when(!disabled, (el) => el.cursor_pointer().hover((s) => s.opacity(0.88)).on_click((_e, cx) => onClick(cx)))
        .child(div().min_w(0).max_w(260).truncate().child(label));
    const status = this.msg || (this.busy
      ? (this.fetching ? "fetching…" : "creating…")
      : this.bookmarkLoading
        ? "Checking the current bookmark…"
        : this.bookmark
          ? `Enter creates from main. Shift/secondary Enter or Stack creates from ${this.bookmark}.`
          : "Enter creates from main. No current feature bookmark to stack on.");

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
      .child(div().text_size(11).text_color(this.msg ? t.blocked : t.dim).child(status))
      .child(h_flex().justify_end().gap(8).text_size(12)
        .when(Boolean(this.bookmark), (el) => el.child(button("stack", this.busy ? "creating…" : `(⇧↵) Stack on ${this.bookmark}`, t.raised, t.foreground, (cx) => this.submitStack(cx), this.busy)))
        .child(button("main", this.busy ? "creating…" : "Create on main", t.solid, t.solid_foreground, (cx) => this.submitMain(cx), this.busy)));
  }
}

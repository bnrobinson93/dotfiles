// Switch — fuzzy go-to for spaces and project folders, with create-or-jump.
// Opened with a key via `mod.open:switch`. Replaces the old herdr-select:
// existing spaces first, then pinned dirs + zoxide + search-paths folders.
// Enter on a folder focuses its space if one already sits there, else makes it.
// Type to filter, ↑/↓ to move, Enter to go, Esc to leave.

import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { spaces, run, exec, home, theme, props, closeOverlay } from "herdr";

const PINNED = [".dotfiles", "Documents/Vault", "Documents/code"];
// Suffixes jj hands an agent workspace, plus the bare "code" umbrella dir.
const BLACKLIST = [/^code$/, /-(ai[0-9]*|orch.*|exp|explore)$/];
const blacklisted = (name) => BLACKLIST.some((re) => re.test(name));
const base = (p) => p.replace(/\/+$/, "").split("/").pop();

export default class Switch extends View {
  init(_props, cx) {
    this.filter = "";
    this.at = 0;
    this.folders = [];
    this.handle = cx.focus_handle();
    this.input = InputState.new({ placeholder: "Go to a space or folder…" });
    this.input.on("change", (_e, cx) => { this.filter = this.input.value(); this.at = 0; cx.notify(); });
    this.input.on("submit", () => this.go(this.pickable()[this.at]));
    this.input.focus();
    cx.timer.after(400, () => this.input.focus());
    this.load(cx);
  }

  load(cx) {
    cx.spawn(async (cx) => {
      const h = home();
      const out = async (cmd, args) => {
        try { const r = await exec(cmd, args); return r.code === 0 ? r.stdout.split("\n") : []; }
        catch { return []; }
      };
      const roots = (await out("search-paths", [])).filter(Boolean);
      const fd = roots.length ? await out("fd", [".", ...roots, "-d", "1", "-t", "d", "-E", ".Trash"]) : [];
      const paths = [
        ...PINNED.map((p) => `${h}/${p}`),
        ...(await out("zoxide", ["query", "-l"])),
        ...fd,
      ];
      const seen = new Set();
      this.folders = paths
        .map((p) => p.replace(/\/+$/, ""))
        .filter((p) => p && !seen.has(p) && (seen.add(p), true))
        .map((p) => ({ path: p, name: base(p) }))
        .filter((f) => !blacklisted(f.name));
      cx.notify();
    });
  }

  rows() {
    const f = this.filter.toLowerCase();
    const sp = spaces().map((p) => ({ kind: "space", id: p.id, name: p.name, folder: p.folder, status: p.status, active: p.active }));
    const spaceFolders = new Set(sp.map((s) => s.folder).filter(Boolean));
    const fo = this.folders
      .filter((d) => !spaceFolders.has(d.path))
      .map((d) => ({ kind: "folder", ...d }));
    return [...sp, ...fo].filter((r) => !f || `${r.name} ${r.folder ?? r.path}`.toLowerCase().includes(f));
  }

  pickable() { return this.rows(); }

  go(r) {
    if (!r) return;
    this.close();
    if (r.kind === "space") return run("space.select", { id: r.id });
    // create-or-jump: a space already sitting on this folder wins.
    const at = spaces().find((p) => p.folder === r.path);
    if (at) return run("space.select", { id: at.id });
    run("space.new", { folder: r.path, name: r.name });
  }

  close() { closeOverlay(props().overlay); }

  glyph(t, r) {
    if (r.kind === "folder") return div().w(14).flex_none().text_color(t.dim).child("");
    const st = r.status;
    return div().w(14).flex_none().text_color(t[st] ?? t.dim).child(st === "idle" ? "○" : st ? "●" : "·");
  }

  render() {
    const t = theme();
    const rows = this.pickable();
    this.at = Math.max(0, Math.min(this.at, rows.length - 1));
    const sel = rows[this.at];

    const row = (r) => {
      const on = r === sel;
      return h_flex()
        .id(`sw-${r.kind}-${r.id ?? r.path}`)
        .mx(4).px(10).h(32).rounded(7).gap(10).items_center().cursor_pointer()
        .when(on, (el) => el.bg(t.hover))
        .hover((s) => s.bg(t.hover))
        .on_click(() => this.go(r))
        .child(this.glyph(t, r))
        .child(div().flex_1().truncate().text_color(t.foreground).when(r.active, (d) => d.font_semibold()).child(r.name))
        .child(div().text_size(11).text_color(t.dim).truncate().child(r.kind === "space" ? "space" : (r.path.startsWith(home()) ? "~" + r.path.slice(home().length) : r.path)));
    };

    return v_flex()
      .id("switch")
      .track_focus(this.handle)
      .w_full().min_h(0).p(18).gap(10).bg(t.popover).text_size(13)
      .on_key_down((e, cx) => {
        const k = e.key;
        if (k === "escape") return this.close();
        if (k === "down") this.at = (this.at + 1) % Math.max(1, rows.length);
        else if (k === "up") this.at = (this.at + Math.max(1, rows.length) - 1) % Math.max(1, rows.length);
        else if (k === "enter" || k === "return") this.go(sel);
        else return;
        cx.stop_propagation();
        cx.notify();
      })
      .child(h_flex().items_center()
        .child(div().flex_1().text_size(15).font_semibold().text_color(t.foreground).child("Go to…"))
        .child(div().text_size(11).text_color(t.dim).child("Esc")))
      .child(h_flex().h(36).flex_none().px(10).gap(8).items_center().rounded(9).border_1().border_color(t.accent).bg(t.background)
        .child(svg("mods/workspace-chrome/search.svg").size(15).text_color(t.dim))
        .child(Input.new(this.input).flex_1().h_full().text_size(12.8).text_color(t.foreground)))
      .child(v_flex().id("sw-list").h(Math.min(420, Math.max(34, rows.length * 34))).min_h(0).mb(6).overflow_y_scrollbar()
        .children(rows.slice(0, 200).map(row)));
  }
}

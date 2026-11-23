// Switch — fuzzy go-to for spaces and project folders, with create-or-jump.
// Opened with a key via `mod.open:switch`. Replaces the old herdr-select:
// existing spaces first, then pinned dirs + zoxide + search-paths folders.
// Enter on a folder focuses its space if one already sits there, else makes it.
// Type to filter, ↑/↓ to move, Enter to go, Esc to leave.

import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { spaces, run, exec, home, theme, props, closeOverlay } from "herdr";

const PINNED = [".dotfiles", "Documents/Vault", "Documents/code"];
// Suffixes jj hands an agent workspace.
const BLACKLIST = [/-(ai[0-9]*|orch.*|exp|explore)$/];
const IGNORED_SEPS = /[-_.]+/g;
const BOUNDARY_CHARS = "/-_. ";

const blacklisted = (name) => BLACKLIST.some((re) => re.test(name));
const base = (p) => p.replace(/\/+$/, "").split("/").pop();

function shortPath(p, h) {
  if (!p) return "";
  if (p === h) return "~";
  return p.startsWith(`${h}/`) ? `~${p.slice(h.length)}` : p;
}

function fuzzyScore(q, target, tl) {
  const m = q.length;
  const n = target.length;
  if (!m || m > n) return null;

  let qi = 0;
  for (let i = 0; i < n && qi < m; i++) {
    if (tl[i] === q[qi]) qi++;
  }
  if (qi < m) return null;

  const bonus = new Float64Array(n);
  for (let j = 0; j < n; j++) {
    if (j === 0 || BOUNDARY_CHARS.includes(target[j - 1])) bonus[j] = 10;
    else if (target[j] >= "A" && target[j] <= "Z" && target[j - 1] >= "a" && target[j - 1] <= "z") bonus[j] = 8;
  }

  let prev = new Float64Array(n).fill(-Infinity);
  let curr = new Float64Array(n);
  for (let j = 0; j < n; j++) {
    if (tl[j] === q[0]) prev[j] = j * -0.1 + bonus[j];
  }

  for (let i = 1; i < m; i++) {
    const ch = q[i];
    curr.fill(-Infinity, 0, i);
    let bestGap = -Infinity;
    for (let j = i; j < n; j++) {
      if (j >= 2) bestGap = Math.max(bestGap - 1, prev[j - 2] - 3);
      curr[j] = tl[j] === ch ? Math.max(prev[j - 1] + 15, bestGap + bonus[j]) : -Infinity;
    }
    [prev, curr] = [curr, prev];
  }

  let best = -Infinity;
  for (let j = m - 1; j < n; j++) {
    const s = prev[j] + (n - 1 - j) * -0.1;
    if (s > best) best = s;
  }
  return best;
}

function scoreToken(tok, target) {
  const core = tok.replace(IGNORED_SEPS, "") || tok;
  const tl = target.toLowerCase();
  const score = fuzzyScore(core, target, tl);
  if (score === null) return null;
  if (tl.includes(tok)) return score + 10 + 8 * (tok.length - core.length);
  return score;
}

function scoreRow(tokens, r, h) {
  const name = r.name ?? "";
  const path = shortPath(r.folder ?? r.path ?? "", h);
  let total = r.kind === "space" ? 6 : 0;
  for (const tok of tokens) {
    const nameScore = scoreToken(tok, name);
    if (nameScore !== null) { total += nameScore + 40; continue; }
    const pathScore = path ? scoreToken(tok, path) : null;
    if (pathScore !== null) { total += pathScore; continue; }
    const combinedScore = r.kind === "space" && path ? scoreToken(tok, `${name} ${path}`) : null;
    if (combinedScore === null) return null;
    total += combinedScore - 10;
  }
  if (tokens.length === 1 && name.toLowerCase() === tokens[0]) total += 10;
  return total;
}

export default class Switch extends View {
  init(_props, cx) {
    this.filter = "";
    this.at = 0;
    this.folders = [];
    this.handle = cx.focus_handle();
    this.input = InputState.new({ placeholder: "Go to a space or folder…" });
    this.input.on("change", (_e, cx) => { this.filter = this.input.value(); this.at = 0; cx.notify(); });
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
    const tokens = this.filter.trim().toLowerCase().split(/\s+/).filter(Boolean);
    const sp = spaces().map((p) => ({ kind: "space", id: p.id, name: p.name, folder: p.folder, status: p.status, active: p.active }));
    const spaceFolders = new Set(sp.map((s) => s.folder).filter(Boolean));
    const fo = this.folders
      .filter((d) => !spaceFolders.has(d.path))
      .map((d) => ({ kind: "folder", ...d }));
    const all = [...sp, ...fo];
    if (!tokens.length) return all;
    const h = home();
    return all
      .map((r) => ({ r, score: scoreRow(tokens, r, h) }))
      .filter((x) => x.score !== null)
      .sort((a, b) => b.score - a.score)
      .map((x) => x.r);
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
    const h = home();
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
        .child(div().text_size(11).text_color(t.dim).truncate().child(r.kind === "space" ? "space" : shortPath(r.path, h)));
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

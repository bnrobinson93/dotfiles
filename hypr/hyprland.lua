-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })

-- Put ~/.local/bin ahead of everything Hyprland launches. uwsm/env.d/50-local-bin
-- does this for the session, but default/hypr/envs.lua then prepends
-- $OMARCHY_PATH/bin to the environment Hyprland hands its children, so the stock
-- copy of an omarchy-* script wins again in binds, the menu, and autostart. Re-set
-- PATH here -- this file loads after the defaults, and the last env wins -- keeping
-- Omarchy's own bin directory second so dev-link mode still works.
local omarchy_bin = (os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/bin"
local local_bin = (os.getenv("HOME") or "") .. "/.local/bin"
local path_entries = { local_bin, omarchy_bin }
for entry in (os.getenv("PATH") or ""):gmatch("[^:]+") do
  if entry ~= local_bin and entry ~= omarchy_bin then
    table.insert(path_entries, entry)
  end
end
hl.env("PATH", table.concat(path_entries, ":"))

-- Apps that always open on the same workspace. Classes are anchored so nothing
-- else picks them up -- notably org.omarchy.agent, which is a Ghostty window
-- under a class of its own and should stay wherever it is launched.
o.window("^zen$", { workspace = "1" })
o.window("^com\\.mitchellh\\.ghostty$", { workspace = "2" })
o.window("^md\\.obsidian\\.Obsidian$", { workspace = "3" })

-- Web apps that live in the scratchpad. Chromium classes an --app window
-- chrome-<host><path>-Default, and Helium is a Chromium fork that keeps the
-- chrome- prefix, so these match whichever browser the launcher settles on.
-- Matched on host alone: the path varies by entry point -- Omarchy's own
-- SUPER+SHIFT+CTRL+G opens /web/conversations while autostart opens /web.
-- The trailing .* is load-bearing: Hyprland matches window rules against the
-- whole class, so a prefix that stops early matches nothing.
o.window("^chrome-ticktick\\.com__.*$", { workspace = "special:scratchpad silent" })
o.window("^chrome-messages\\.google\\.com__.*$", { workspace = "special:scratchpad silent" })

-- Omarchy floats, centers, and sizes anything tagged floating-window; only the
-- size differs from preference. Applied here so it lands after that default.
o.window({ tag = "floating-window" }, { size = { 920, 560 } })
